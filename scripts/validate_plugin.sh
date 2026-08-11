#!/usr/bin/env bash
# Executable rubric for the aed-conventions Claude Code plugin/marketplace
# packaging. Prints one "PASS/FAIL/SKIP <id> <message>" line per check and
# exits nonzero if any check FAILs. No dependencies beyond ruby and git.
#
# Usage: bash scripts/validate_plugin.sh   (run from anywhere; cds to repo root)

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

FAILURES=0

pass() { printf 'PASS %s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s %s\n' "$1" "$2"; FAILURES=$((FAILURES + 1)); }
skip() { printf 'SKIP %s %s\n' "$1" "$2"; }

# ---------------------------------------------------------------------------
# V1: both manifest JSONs parse and contain their required fields.
# ---------------------------------------------------------------------------
V1_MSG=$(ruby -rjson -e '
begin
  mp = JSON.parse(File.read(".claude-plugin/marketplace.json"))
  raise "marketplace.json missing name" unless mp["name"].is_a?(String) && !mp["name"].empty?
  raise "marketplace.json missing owner" unless mp["owner"].is_a?(Hash) && !mp["owner"].empty?
  plugins = mp["plugins"]
  raise "marketplace.json missing plugins[0]" unless plugins.is_a?(Array) && plugins[0].is_a?(Hash)
  raise "marketplace.json plugins[0].name missing" unless plugins[0]["name"].is_a?(String) && !plugins[0]["name"].empty?
  raise "marketplace.json plugins[0].source missing" unless plugins[0]["source"].is_a?(String) && !plugins[0]["source"].empty?

  pj = JSON.parse(File.read("plugins/aed/.claude-plugin/plugin.json"))
  raise "plugin.json missing name" unless pj["name"].is_a?(String) && !pj["name"].empty?
  raise "plugin.json missing description" unless pj["description"].is_a?(String) && !pj["description"].empty?

  puts "both manifests parse and contain required fields"
rescue => e
  STDERR.puts e.message
  exit 1
end
' 2>&1)
if [ $? -eq 0 ]; then pass V1 "$V1_MSG"; else fail V1 "$V1_MSG"; fi

# ---------------------------------------------------------------------------
# V2: plugins[0].source path exists and contains .claude-plugin/plugin.json.
# ---------------------------------------------------------------------------
V2_MSG=$(ruby -rjson -e '
begin
  mp = JSON.parse(File.read(".claude-plugin/marketplace.json"))
  source = mp["plugins"][0]["source"]
  raise "source must start with ./ (got #{source.inspect})" unless source.start_with?("./")
  path = source.sub(%r{\A\./}, "")
  raise "source path #{path} does not exist" unless Dir.exist?(path)
  manifest = File.join(path, ".claude-plugin", "plugin.json")
  raise "#{manifest} does not exist" unless File.exist?(manifest)
  puts "source #{source} exists and contains .claude-plugin/plugin.json"
rescue => e
  STDERR.puts e.message
  exit 1
end
' 2>&1)
if [ $? -eq 0 ]; then pass V2 "$V2_MSG"; else fail V2 "$V2_MSG"; fi

# ---------------------------------------------------------------------------
# V3: hooks.json parses; every ${CLAUDE_PLUGIN_ROOT}-relative command target
# maps to an existing file under plugins/aed.
# ---------------------------------------------------------------------------
V3_MSG=$(ruby -rjson -e '
begin
  hooks_path = "plugins/aed/hooks/hooks.json"
  raise "#{hooks_path} not found" unless File.exist?(hooks_path)
  data = JSON.parse(File.read(hooks_path))
  commands = []
  (data["hooks"] || {}).each do |_event, entries|
    (entries || []).each do |entry|
      (entry["hooks"] || []).each do |h|
        commands << h["command"] if h["command"]
      end
    end
  end
  raise "no commands found in hooks.json" if commands.empty?

  plugin_root = "plugins/aed"
  checked = 0
  commands.each do |cmd|
    cmd.scan(/\$\{CLAUDE_PLUGIN_ROOT\}([^"\s]*)/) do |m|
      rel = m[0]
      full = File.join(plugin_root, rel)
      raise "referenced file #{full} (from command: #{cmd}) does not exist" unless File.exist?(full)
      checked += 1
    end
  end
  raise "no ${CLAUDE_PLUGIN_ROOT} references found to check" if checked.zero?
  puts "hooks.json parses; #{checked} CLAUDE_PLUGIN_ROOT reference(s) resolve to existing files"
rescue => e
  STDERR.puts e.message
  exit 1
end
' 2>&1)
if [ $? -eq 0 ]; then pass V3 "$V3_MSG"; else fail V3 "$V3_MSG"; fi

# ---------------------------------------------------------------------------
# V4: each skills/*/SKILL.md exists, has YAML frontmatter with a non-empty
# description of at most 500 characters.
# ---------------------------------------------------------------------------
V4_MSG=$(ruby -ryaml -e '
begin
  skill_files = Dir.glob("plugins/aed/skills/*/SKILL.md").sort
  raise "no skills/*/SKILL.md files found" if skill_files.empty?
  skill_files.each do |f|
    content = File.read(f)
    m = content.match(/\A---\n(.*?)\n---\n/m)
    raise "#{f}: no YAML frontmatter block" unless m
    fm = (YAML.safe_load(m[1]) rescue nil)
    raise "#{f}: frontmatter did not parse as YAML" unless fm.is_a?(Hash)
    desc = fm["description"]
    raise "#{f}: missing description" unless desc.is_a?(String) && !desc.strip.empty?
    raise "#{f}: description exceeds 500 chars (#{desc.length})" if desc.length > 500
  end
  puts "#{skill_files.length} SKILL.md file(s) have valid frontmatter descriptions"
rescue => e
  STDERR.puts e.message
  exit 1
end
' 2>&1)
if [ $? -eq 0 ]; then pass V4 "$V4_MSG"; else fail V4 "$V4_MSG"; fi

# ---------------------------------------------------------------------------
# V5: each commands/*.md has frontmatter with a non-empty description.
# ---------------------------------------------------------------------------
V5_MSG=$(ruby -ryaml -e '
begin
  cmd_files = Dir.glob("plugins/aed/commands/*.md").sort
  raise "no commands/*.md files found" if cmd_files.empty?
  cmd_files.each do |f|
    content = File.read(f)
    m = content.match(/\A---\n(.*?)\n---\n/m)
    raise "#{f}: no YAML frontmatter block" unless m
    fm = (YAML.safe_load(m[1]) rescue nil)
    raise "#{f}: frontmatter did not parse as YAML" unless fm.is_a?(Hash)
    desc = fm["description"]
    raise "#{f}: missing description" unless desc.is_a?(String) && !desc.strip.empty?
  end
  puts "#{cmd_files.length} command file(s) have frontmatter descriptions"
rescue => e
  STDERR.puts e.message
  exit 1
end
' 2>&1)
if [ $? -eq 0 ]; then pass V5 "$V5_MSG"; else fail V5 "$V5_MSG"; fi

# ---------------------------------------------------------------------------
# V6: linter test suite passes.
# ---------------------------------------------------------------------------
if [ -f "plugins/aed/scripts/test/run_tests.rb" ]; then
  V6_OUT=$(ruby plugins/aed/scripts/test/run_tests.rb 2>&1)
  V6_STATUS=$?
  if [ $V6_STATUS -eq 0 ]; then
    pass V6 "linter test suite passed (plugins/aed/scripts/test/run_tests.rb)"
  else
    fail V6 "linter test suite failed (exit $V6_STATUS): $(printf '%s' "$V6_OUT" | tail -3 | tr '\n' ' ')"
  fi
else
  fail V6 "plugins/aed/scripts/test/run_tests.rb not found (linter not yet landed)"
fi

# ---------------------------------------------------------------------------
# V7: hook smoke test — the real bad-naming fixture yields the documented
# PostToolUse envelope {"hookSpecificOutput":{"hookEventName":...,
# "additionalContext":"…AED-N…"}}; garbage stdin prints nothing and exits 0.
# ---------------------------------------------------------------------------
V7_BAD_FIXTURE="plugins/aed/scripts/test/fixtures/bad_naming.rb"
if [ ! -f "plugins/aed/scripts/aed_lint.rb" ]; then
  fail V7 "plugins/aed/scripts/aed_lint.rb not found (linter not yet landed)"
elif [ ! -f "$V7_BAD_FIXTURE" ]; then
  fail V7 "$V7_BAD_FIXTURE not found (linter fixtures not yet landed)"
else
  V7_DIR=$(mktemp -d)
  PAYLOAD_FILE="$V7_DIR/payload.json"
  ruby -rjson -e 'puts JSON.generate({"hook_event_name" => "PostToolUse", "tool_name" => "Edit", "tool_input" => {"file_path" => ARGV[0]}})' "$V7_BAD_FIXTURE" > "$PAYLOAD_FILE"

  V7_OUT=$(ruby plugins/aed/scripts/aed_lint.rb --hook < "$PAYLOAD_FILE" 2>&1)
  V7_STATUS=$?
  V7_JSON_OK=1
  if [ $V7_STATUS -eq 0 ]; then
    printf '%s' "$V7_OUT" | ruby -rjson -e '
      begin
        d = JSON.parse(STDIN.read)
        ctx = d.dig("hookSpecificOutput", "additionalContext") || d["additionalContext"]
        exit(ctx.to_s.include?("AED-N") ? 0 : 1)
      rescue
        exit 1
      end
    ' >/dev/null 2>&1
    V7_JSON_OK=$?
  fi

  V7_GARBAGE_OUT=$(printf 'not json at all {{{' | ruby plugins/aed/scripts/aed_lint.rb --hook 2>/dev/null)
  V7_GARBAGE_STATUS=$?
  V7_GARBAGE_QUIET=1
  [ -z "$V7_GARBAGE_OUT" ] && V7_GARBAGE_QUIET=0

  rm -rf "$V7_DIR"

  if [ $V7_STATUS -eq 0 ] && [ $V7_JSON_OK -eq 0 ] && [ $V7_GARBAGE_STATUS -eq 0 ] && [ $V7_GARBAGE_QUIET -eq 0 ]; then
    pass V7 "hook returns hookSpecificOutput.additionalContext containing AED-N on $V7_BAD_FIXTURE; garbage stdin prints nothing and exits 0"
  else
    fail V7 "hook smoke test failed (fixture exit=$V7_STATUS json-has-additionalContext=$([ $V7_JSON_OK -eq 0 ] && echo yes || echo no) garbage-exit=$V7_GARBAGE_STATUS garbage-stdout-empty=$([ $V7_GARBAGE_QUIET -eq 0 ] && echo yes || echo no))"
  fi
fi

# ---------------------------------------------------------------------------
# V8: claude plugin validate . — skip (not fail) if the claude CLI is absent.
# ---------------------------------------------------------------------------
if command -v claude >/dev/null 2>&1; then
  V8_OUT=$(claude plugin validate . 2>&1)
  V8_STATUS=$?
  if [ $V8_STATUS -eq 0 ]; then
    pass V8 "claude plugin validate . passed"
  else
    fail V8 "claude plugin validate . failed (exit $V8_STATUS): $(printf '%s' "$V8_OUT" | tail -5 | tr '\n' ' ')"
  fi
else
  skip V8 "claude CLI not found on PATH"
fi

# ---------------------------------------------------------------------------
# V9: plugin.json must not re-declare auto-loaded component paths. Claude Code
# loads skills/, commands/, and hooks/hooks.json automatically; an explicit
# manifest reference to hooks/hooks.json is treated as a DUPLICATE hooks file
# and the whole plugin fails to load (found by the first real install,
# 2026-08-11 — validate_plugin.sh and `claude plugin validate` both missed it).
# ---------------------------------------------------------------------------
V9_OUT=$(ruby -rjson -e '
  manifest = JSON.parse(File.read("plugins/aed/.claude-plugin/plugin.json"))
  offending_keys = ["hooks", "skills", "commands", "agents"].select { |key| manifest.key?(key) }
  if offending_keys.empty?
    puts "no auto-loaded component paths re-declared"
  else
    puts "plugin.json re-declares auto-loaded component key(s): #{offending_keys.join(", ")}"
    exit 1
  end
' 2>&1)
if [ $? -eq 0 ]; then
  pass V9 "$V9_OUT"
else
  fail V9 "$V9_OUT"
fi

echo "----"
if [ $FAILURES -eq 0 ]; then
  echo "validate_plugin.sh: all checks passed"
  exit 0
else
  echo "validate_plugin.sh: $FAILURES check(s) failed"
  exit 1
fi
