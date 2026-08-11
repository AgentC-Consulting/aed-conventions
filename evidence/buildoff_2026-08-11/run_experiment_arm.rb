# Runs ONE experiment arm: a fresh headless Haiku agent building the pet
# tracker in the given worktree, then collects metrics.
# Usage: ruby run_experiment_arm.rb <worktree_path> <output_prefix>
require "json"
require "open3"

worktree_path = ARGV[0]
output_prefix = ARGV[1]
abort "usage: run_experiment_arm.rb <worktree> <prefix>" unless worktree_path && output_prefix

TASK_PROMPT_PATH = "/Users/crimsonknight/.claude/jobs/48fd0087/tmp/dogfood/pet_tracker_task.md"
LINTER = File.expand_path("~/.claude/plugins/cache/aed-conventions/aed/0.1.2/scripts/aed_lint.rb")
stream_path = "#{output_prefix}.stream.jsonl"
metrics_path = "#{output_prefix}.metrics.json"

task_prompt = File.read(TASK_PROMPT_PATH)
started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

stream_file = File.open(stream_path, "w")
exit_status = nil
Dir.chdir(worktree_path) do
  Open3.popen2e({ "ENGRAM_GATE_BYPASS" => "1" },
                "claude", "-p", "--model", "haiku",
                "--output-format", "stream-json", "--verbose",
                "--dangerously-skip-permissions") do |stdin, stdout_and_stderr, wait_thread|
    stdin.write(task_prompt)
    stdin.close
    stdout_and_stderr.each_line { |line| stream_file.write(line) }
    exit_status = wait_thread.value.exitstatus
  end
end
stream_file.close
wall_seconds = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).round(1)

# --- parse the stream for the final result + error/turn counts ---
final_result = nil
tool_error_count = 0
assistant_message_count = 0
compiler_block_count = 0
File.foreach(stream_path) do |line|
  event = JSON.parse(line) rescue next
  final_result = event if event["type"] == "result"
  assistant_message_count += 1 if event["type"] == "assistant"
  content_items = event.dig("message", "content")
  next unless content_items.is_a?(Array)
  content_items.each do |item|
    next unless item.is_a?(Hash) && item["type"] == "tool_result"
    tool_error_count += 1 if item["is_error"]
    result_text = item["content"].is_a?(Array) ? item["content"].map { |c| c["text"].to_s }.join : item["content"].to_s
    compiler_block_count += 1 if result_text.include?("Error:") && (result_text.include?("crystal") || result_text.include?("undefined") || result_text.include?("exhaustive"))
  end
end

# --- post-run verification in the worktree ---
compile_output, compile_status = Open3.capture2e("crystal", "build", "--no-codegen", "src/premium_agentc_app_template.cr", chdir: worktree_path)
changed_files_output, _ = Open3.capture2e("git", "-C", worktree_path, "status", "--porcelain")
changed_files = changed_files_output.lines.map { |l| l[3..].to_s.strip }.reject(&:empty?)
changed_crystal_files = changed_files.select { |f| f.end_with?(".cr") }.map { |f| File.join(worktree_path, f) }.select { |f| File.file?(f) }

lint_warn_count = nil
unless changed_crystal_files.empty?
  lint_json, _ = Open3.capture2e("ruby", LINTER, "--format", "json", *changed_crystal_files)
  parsed = JSON.parse(lint_json) rescue nil
  lint_warn_count = parsed ? parsed["findings"].count { |f| f["severity"] == "warn" } : "unparseable"
end

metrics = {
  worktree: worktree_path,
  wall_seconds: wall_seconds,
  cli_exit: exit_status,
  num_turns: final_result&.dig("num_turns"),
  total_cost_usd: final_result&.dig("total_cost_usd"),
  usage: final_result&.dig("usage"),
  is_error_result: final_result&.dig("is_error"),
  assistant_messages: assistant_message_count,
  tool_errors: tool_error_count,
  compiler_error_events: compiler_block_count,
  final_compile_green: compile_status.success?,
  final_compile_tail: compile_output.lines.last(4).join,
  files_changed_or_added: changed_files,
  aed_warns_in_new_code: lint_warn_count,
}
File.write(metrics_path, JSON.pretty_generate(metrics))
puts JSON.pretty_generate(metrics.reject { |k, _| [:files_changed_or_added, :final_compile_tail, :usage].include?(k) })
