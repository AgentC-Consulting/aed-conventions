#!/usr/bin/env ruby
# frozen_string_literal: true

# Test runner for aed_lint.rb.
#
# Ruby stdlib only, no gems — the CLI is driven in-process through
# AedLint::LintCommandLineInvocation with StringIO for stdin/stdout. The Bash
# hook fixture uses a temporary Git repo to exercise dirty-file discovery.
#
#   ruby plugins/aed/scripts/test/run_tests.rb

require "json"
require "fileutils"
require "open3"
require "stringio"
require "tmpdir"
require_relative "../aed_lint"

FIXTURES_DIRECTORY = File.expand_path("fixtures", __dir__)
REPOSITORY_ROOT = File.expand_path("../../../../..", FIXTURES_DIRECTORY)

# Every finding the bad fixtures are expected to produce, as
# [line, rule, severity]. Exact — an unexpected finding fails the suite too.
EXPECTED_FINDINGS_BY_FIXTURE = {
  "bad_naming.cr" => [
    [3, "AED-N5", "warn"],
    [3, "AED-N7", "info"],
    [4, "AED-N4", "info"],
    [5, "AED-N1", "warn"],
    [6, "AED-N2", "warn"],
    [7, "AED-N3", "warn"],
    [8, "AED-N3", "info"],
    [9, "AED-N1", "warn"],
    [11, "AED-N1", "warn"],
    [15, "AED-N8", "info"],
    [22, "AED-N1", "warn"],
    [23, "AED-N1", "info"],
    [33, "AED-N6", "warn"],
    [39, "AED-N6", "warn"]
  ],
  "bad_naming.rb" => [
    [4, "AED-N5", "warn"],
    [4, "AED-N7", "info"],
    [5, "AED-N4", "info"],
    [5, "AED-N4", "info"],
    [6, "AED-N1", "warn"],
    [8, "AED-N2", "warn"],
    [14, "AED-N2", "warn"],
    [15, "AED-N1", "info"],
    [16, "AED-N2", "warn"],
    [21, "AED-N8", "info"],
    [23, "AED-N1", "warn"],
    [27, "AED-N1", "warn"],
    [28, "AED-N1", "info"],
    [37, "AED-N6", "warn"],
    [43, "AED-N6", "warn"]
  ],
  "bad_naming.ex" => [
    [3, "AED-N5", "warn"],
    [3, "AED-N7", "info"],
    [7, "AED-N4", "info"],
    [8, "AED-N1", "warn"],
    [9, "AED-N2", "warn"],
    [10, "AED-N3", "warn"],
    [11, "AED-N3", "info"],
    [14, "AED-N1", "warn"],
    [15, "AED-N1", "warn"],
    [16, "AED-N1", "info"]
  ],
  "bad_plural_class_names.rb" => [
    [2, "AED-N9", "warn"],
    [6, "AED-N9", "warn"],
    [10, "AED-N9", "warn"]
  ],
  "bad_plural_class_names.cr" => [
    [2, "AED-N9", "warn"],
    [5, "AED-N9", "warn"],
    [9, "AED-N9", "warn"]
  ],
  "bad_plural_class_names.ex" => [
    [2, "AED-N9", "warn"],
    [5, "AED-N9", "warn"],
    [8, "AED-N9", "warn"]
  ],
  "bad_method_name.rb" => [[2, "AED-N10", "info"]],
  "bad_method_name.cr" => [[2, "AED-N10", "info"]],
  "bad_method_name.ex" => [[2, "AED-N10", "info"]],
  "wrong_namespace/order_processor.rb" => [[1, "AED-N11", "info"]],
  "wrong_namespace/order_processor.cr" => [[1, "AED-N11", "info"]],
  "wrong_namespace/order_processor.ex" => [[1, "AED-N11", "info"]],
  "n11_projects/amber/src/wrong_folder/order_processor.cr" => [[1, "AED-N11", "info"]]
}.freeze

RULES_THAT_MUST_FIRE_BY_FIXTURE = {
  "bad_naming.cr" => %w[AED-N1 AED-N2 AED-N3 AED-N4 AED-N5 AED-N6 AED-N7 AED-N8],
  "bad_naming.rb" => %w[AED-N1 AED-N2 AED-N4 AED-N5 AED-N6 AED-N7 AED-N8],
  "bad_naming.ex" => %w[AED-N1 AED-N2 AED-N3 AED-N4 AED-N5 AED-N7],
  "bad_plural_class_names.rb" => %w[AED-N9],
  "bad_plural_class_names.cr" => %w[AED-N9],
  "bad_plural_class_names.ex" => %w[AED-N9],
  "bad_method_name.rb" => %w[AED-N10],
  "bad_method_name.cr" => %w[AED-N10],
  "bad_method_name.ex" => %w[AED-N10],
  "wrong_namespace/order_processor.rb" => %w[AED-N11],
  "wrong_namespace/order_processor.cr" => %w[AED-N11],
  "wrong_namespace/order_processor.ex" => %w[AED-N11],
  "n11_projects/amber/src/wrong_folder/order_processor.cr" => %w[AED-N11]
}.freeze

GOOD_FIXTURE_FILE_NAMES = %w[
  good_naming.cr good_naming.rb good_naming.ex
  good_plural_class_names.cr good_plural_class_names.rb good_plural_class_names.ex
  good_framework_process_overrides.cr good_framework_process_overrides.rb good_framework_process_overrides.ex
  billing/admin/order_processor.rb billing/admin/order_processor.cr billing/admin/order_processor.ex
  good_plural_collective_nouns.rb good_plural_collective_nouns.cr good_plural_collective_nouns.ex
  good_standard_api_method_names.rb good_standard_api_method_names.cr good_standard_api_method_names.ex
  n11_projects/amber/src/amber/router/context.cr
  n11_projects/amber/src/amber/router/request.cr
  n11_projects/amber/src/billing/order_processor.cr
  n11_projects/amber/src/amber/billing/order_processor.cr
  n11_projects/grant/src/adapter/base.cr
  n11_projects/grant/src/grant/adapter/base.cr
  n11_projects/grant/src/adapter/statement.cr
  n11_projects/amber/src/amber/router/statement.cr
  n11_projects/no_manifest/src/aed_fixtures/billing/order_processor.cr
].freeze

SINGULAR_NAME_SUGGESTIONS_BY_FIXTURE = {
  "bad_plural_class_names.rb" => {
    2 => "e.g. `Order`",
    6 => "e.g. `CustomerAddress`",
    10 => "e.g. `Analysis`"
  },
  "bad_plural_class_names.cr" => {
    2 => "e.g. `Order`",
    5 => "e.g. `CustomerStatus`",
    9 => "e.g. `Person`"
  },
  "bad_plural_class_names.ex" => {
    2 => "e.g. `Order`",
    5 => "e.g. `CustomerAddress`",
    8 => "e.g. `Analysis`"
  }
}.freeze

CHECK_NAME_CASES = [
  ["boolean", "has_a_valid_payment_method", true],
  ["boolean", "all_of_the_customers_have_been_processed", true],
  ["boolean", "is_this_an_enterprise_customer", true],
  ["boolean", "payment_method_present", false],
  ["boolean", "locked", false],
  ["collection", "list_of_previous_orders", true],
  ["collection", "collection_of_customers_that_were_retried_and_failed", true],
  ["collection", "orders", false],
  ["attribute", "currently_active_subscription", true],
  ["attribute", "name", false],
  ["attribute", "data", false],
  ["class", "AddSubscriptionToCustomer", true],
  ["class", "LockCustomers", false],
  ["class", "Orders", false],
  ["class", "ProcessCustomersWithExpiredPaymentMethods", true],
  ["class", "OrdersController", true],
  ["class", "CORS", true],
  ["class", "Settings", true],
  ["method", "retry_customers_who_failed_payment_processing", true],
  ["method", "run", true],
  ["method", "process", false],
  ["method", "parse", true],
  ["method", "call", true],
  ["method", "where", true],
  ["method", "callback", true],
  ["method", "retry", false],
  ["method", "perform", true],
  ["method", "valid?", true]
].freeze

@count_of_assertions_that_passed = 0
@list_of_assertion_failures = []

def assert_equal(expected_value, actual_value, description_of_the_assertion)
  if expected_value == actual_value
    @count_of_assertions_that_passed += 1
  else
    @list_of_assertion_failures << "#{description_of_the_assertion}\n      expected: #{expected_value.inspect}\n      actual:   #{actual_value.inspect}"
  end
end

def assert_truthy(actual_value, description_of_the_assertion)
  if actual_value
    @count_of_assertions_that_passed += 1
  else
    @list_of_assertion_failures << "#{description_of_the_assertion}\n      expected: truthy\n      actual:   #{actual_value.inspect}"
  end
end

def fixture_path_for(fixture_file_name)
  File.join(FIXTURES_DIRECTORY, fixture_file_name)
end

def findings_for_fixture(fixture_file_name)
  path_to_the_fixture = fixture_path_for(fixture_file_name)
  AedLint::AnalyzeSourceFileForNamingFindings.new(path_to_the_fixture, File.read(path_to_the_fixture)).perform
end

def run_the_linter_command(list_of_arguments, standard_input_text = "")
  captured_standard_output = StringIO.new
  captured_standard_error = StringIO.new
  exit_status = AedLint::LintCommandLineInvocation.new(
    list_of_arguments,
    captured_standard_output,
    captured_standard_error,
    StringIO.new(standard_input_text)
  ).perform
  [exit_status, captured_standard_output.string, captured_standard_error.string]
end

# (a) every expected rule+line fires on the bad fixtures, and nothing else does
EXPECTED_FINDINGS_BY_FIXTURE.each do |fixture_file_name, list_of_expected_findings|
  list_of_actual_findings = findings_for_fixture(fixture_file_name).map do |finding|
    [finding.line, finding.rule, finding.severity]
  end

  list_of_missing_findings = list_of_expected_findings - list_of_actual_findings
  list_of_unexpected_findings = list_of_actual_findings - list_of_expected_findings
  assert_equal([], list_of_missing_findings, "#{fixture_file_name}: expected findings that never fired")
  assert_equal([], list_of_unexpected_findings, "#{fixture_file_name}: findings that fired but were not expected")
  assert_equal(list_of_expected_findings.length, list_of_actual_findings.length, "#{fixture_file_name}: finding count")

  RULES_THAT_MUST_FIRE_BY_FIXTURE[fixture_file_name].each do |rule_identifier|
    assert_truthy(
      list_of_actual_findings.any? { |line_rule_and_severity| line_rule_and_severity[1] == rule_identifier },
      "#{fixture_file_name}: #{rule_identifier} must fire somewhere in this fixture"
    )
  end
end

SINGULAR_NAME_SUGGESTIONS_BY_FIXTURE.each do |fixture_file_name, suggestions_by_line|
  list_of_findings = findings_for_fixture(fixture_file_name)
  suggestions_by_line.each do |line_number, expected_suggestion|
    finding = list_of_findings.find do |candidate_finding|
      candidate_finding.line == line_number && candidate_finding.rule == "AED-N9"
    end
    assert_equal(expected_suggestion, finding&.suggestion, "#{fixture_file_name}: AED-N9 suggests a singular class name on line #{line_number}")
  end
end

orders_file_findings = AedLint::AnalyzeSourceFileForNamingFindings.new(
  "orders.rb",
  "class Orders\n  def process(data)\n    data\n  end\nend\n"
).perform
plural_orders_finding = orders_file_findings.find { |finding| finding.rule == "AED-N9" }
orders_file_name_finding = orders_file_findings.find { |finding| finding.rule == "AED-N7" }
assert_equal("e.g. `Order`", plural_orders_finding&.suggestion, "AED-N9 suggests the singular name for class Orders")
assert_equal(
  "rename the file to `order.rb` to match `Order`",
  orders_file_name_finding&.suggestion,
  "AED-N7 suggests the file name that matches AED-N9's singular class suggestion"
)
assert_equal("warn", plural_orders_finding&.severity, "the original plain Orders class is treated as a data model when its file is orders.rb")

untyped_plural_class_finding = AedLint::AnalyzeSourceFileForNamingFindings.new(
  "unrelated.rb",
  "class Orders\nend\n"
).perform.find { |finding| finding.rule == "AED-N9" }
assert_equal("info", untyped_plural_class_finding&.severity, "plural non-model classes are informational rather than warnings")

cors_class_findings = AedLint::AnalyzeSourceFileForNamingFindings.new(
  "cors.cr",
  "class CORS\nend\n"
).perform
assert_equal([], cors_class_findings.select { |finding| finding.rule == "AED-N9" }, "AED-N9 never singularizes an all-caps acronym")
compound_acronym_findings = AedLint::AnalyzeSourceFileForNamingFindings.new(
  "user_cors.rb",
  "class UserCORS\n  attr_accessor :cors_policy\nend\n"
).perform
assert_equal([], compound_acronym_findings.select { |finding| finding.rule == "AED-N9" }, "AED-N9 does not singularize an all-caps acronym used as a head noun")

orm_orders_findings = AedLint::AnalyzeSourceFileForNamingFindings.new(
  "orders.rb",
  "class Orders < ApplicationRecord\nend\n"
).perform
orm_plural_orders_finding = orm_orders_findings.find { |finding| finding.rule == "AED-N5" }
orm_orders_file_name_finding = orm_orders_findings.find { |finding| finding.rule == "AED-N7" }
assert_equal("e.g. `Order`", orm_plural_orders_finding&.suggestion, "AED-N5 suggests the singular name for an ORM class")
assert_equal(
  "rename the file to `order.rb` to match `Order`",
  orm_orders_file_name_finding&.suggestion,
  "AED-N7 stays consistent with the AED-N5 ORM class suggestion"
)

# (b) the good fixtures produce zero warnings — and in fact zero findings
GOOD_FIXTURE_FILE_NAMES.each do |fixture_file_name|
  list_of_findings = findings_for_fixture(fixture_file_name)
  list_of_warnings = list_of_findings.select { |finding| finding.severity == "warn" }
  assert_equal([], list_of_warnings.map(&:as_text_line), "#{fixture_file_name}: must produce zero warnings")
  assert_equal([], list_of_findings.map(&:as_text_line), "#{fixture_file_name}: produces no findings at all")

  exit_status, = run_the_linter_command([fixture_path_for(fixture_file_name)])
  assert_equal(0, exit_status, "#{fixture_file_name}: linting a clean file exits 0")

  strict_exit_status, = run_the_linter_command(["--strict", fixture_path_for(fixture_file_name)])
  assert_equal(0, strict_exit_status, "#{fixture_file_name}: --strict on a clean file exits 0")
end

# exit codes on a file that does have warnings
warned_exit_status, warned_output, = run_the_linter_command([fixture_path_for("bad_naming.cr")])
assert_equal(0, warned_exit_status, "warnings alone exit 0")
assert_truthy(warned_output.include?("[AED-N5 warn]"), "text format carries the rule and severity")
assert_truthy(warned_output.include?(" — "), "text format carries the suggestion after an em dash")

strict_exit_status, = run_the_linter_command(["--strict", fixture_path_for("bad_naming.cr")])
assert_equal(1, strict_exit_status, "--strict turns warnings into exit 1")

# a directory argument recurses into the supported extensions
directory_exit_status, directory_output, = run_the_linter_command([FIXTURES_DIRECTORY])
assert_equal(0, directory_exit_status, "linting a directory exits 0 without --strict")
%w[bad_naming.cr bad_naming.rb bad_naming.ex].each do |fixture_file_name|
  assert_truthy(directory_output.include?(fixture_file_name), "directory scan reaches #{fixture_file_name}")
end

# usage errors
unknown_format_exit_status, = run_the_linter_command(["--format", "xml", fixture_path_for("bad_naming.cr")])
assert_equal(2, unknown_format_exit_status, "an unknown --format is a usage error")
unknown_option_exit_status, = run_the_linter_command(["--verbose", fixture_path_for("bad_naming.cr")])
assert_equal(2, unknown_option_exit_status, "an unknown option is a usage error")
no_paths_exit_status, = run_the_linter_command([])
assert_equal(2, no_paths_exit_status, "no paths at all is a usage error")
missing_path_exit_status, = run_the_linter_command([File.join(FIXTURES_DIRECTORY, "no_such_file.rb")])
assert_equal(2, missing_path_exit_status, "a path that does not exist is a usage error")

# (c) the json format parses and carries every documented key
json_exit_status, json_output, = run_the_linter_command(["--format", "json", fixture_path_for("bad_naming.cr")])
assert_equal(0, json_exit_status, "--format json exits 0 without --strict")
parsed_json_payload = begin
  JSON.parse(json_output)
rescue JSON::ParserError => parse_error
  parse_error
end
assert_truthy(parsed_json_payload.is_a?(Hash), "json output parses: #{parsed_json_payload.inspect[0, 120]}")
if parsed_json_payload.is_a?(Hash)
  list_of_json_findings = parsed_json_payload["findings"]
  assert_truthy(list_of_json_findings.is_a?(Array) && !list_of_json_findings.empty?, "json output has a non-empty findings array")
  assert_equal(
    %w[file line rule severity message suggestion].sort,
    list_of_json_findings.first.keys.sort,
    "json findings carry exactly the documented keys"
  )
end

# (d) check-name verdicts
CHECK_NAME_CASES.each do |kind_of_name, candidate_name, name_should_be_acceptable|
  verdict_exit_status, verdict_output, = run_the_linter_command(["check-name", "--kind", kind_of_name, candidate_name])
  expected_exit_status = name_should_be_acceptable ? 0 : 1
  expected_prefix = name_should_be_acceptable ? "OK #{candidate_name}" : "RENAME #{candidate_name} — "
  assert_equal(expected_exit_status, verdict_exit_status, "check-name --kind #{kind_of_name} #{candidate_name}: exit status")
  assert_truthy(verdict_output.start_with?(expected_prefix), "check-name --kind #{kind_of_name} #{candidate_name}: #{verdict_output.strip.inspect}")
  assert_truthy(verdict_output.include?(" — try: "), "check-name renames offer a suggestion") unless name_should_be_acceptable
end

several_names_exit_status, several_names_output, = run_the_linter_command(
  ["check-name", "--kind", "collection", "list_of_previous_orders", "orders"]
)
assert_equal(1, several_names_exit_status, "check-name exits 1 when any name needs a rename")
assert_equal(2, several_names_output.lines.length, "check-name prints one verdict per name")

plural_class_verdict_exit_status, plural_class_verdict_output, = run_the_linter_command(
  ["check-name", "--kind", "class", "Orders"]
)
assert_equal(1, plural_class_verdict_exit_status, "check-name rejects a plural data class name")
assert_truthy(plural_class_verdict_output.include?("(AED-N9)"), "check-name reports the plural data-class rule id")
assert_truthy(plural_class_verdict_output.include?("`Order`"), "check-name suggests the singular data-class name")

single_word_method_verdict_exit_status, single_word_method_verdict_output, = run_the_linter_command(
  ["check-name", "--kind", "method", "process"]
)
assert_equal(1, single_word_method_verdict_exit_status, "check-name rejects a bare single-verb method name")
assert_truthy(single_word_method_verdict_output.include?("(AED-N10)"), "check-name reports the method-phrase rule id")

bad_kind_exit_status, = run_the_linter_command(["check-name", "--kind", "colour", "orders"])
assert_equal(2, bad_kind_exit_status, "check-name with an unknown --kind is a usage error")
no_names_exit_status, = run_the_linter_command(["check-name", "--kind", "boolean"])
assert_equal(2, no_names_exit_status, "check-name with no candidate names is a usage error")

# (e) --hook mode
post_tool_use_event = JSON.generate(
  "session_id" => "test",
  "hook_event_name" => "PostToolUse",
  "tool_name" => "Edit",
  "tool_input" => { "file_path" => fixture_path_for("bad_naming.cr") }
)
hook_exit_status, hook_output, = run_the_linter_command(["--hook"], post_tool_use_event)
assert_equal(0, hook_exit_status, "--hook always exits 0")
parsed_hook_payload = begin
  JSON.parse(hook_output)
rescue JSON::ParserError => parse_error
  parse_error
end
assert_truthy(parsed_hook_payload.is_a?(Hash), "--hook stdout parses as JSON: #{parsed_hook_payload.inspect[0, 120]}")
if parsed_hook_payload.is_a?(Hash)
  hook_specific_output = parsed_hook_payload["hookSpecificOutput"] || {}
  assert_equal("PostToolUse", hook_specific_output["hookEventName"], "--hook names the event")
  additional_context = hook_specific_output["additionalContext"].to_s
  assert_truthy(additional_context.include?("AED-N"), "--hook additionalContext carries findings")
  assert_truthy(additional_context.start_with?("AED naming check on "), "--hook additionalContext opens with the file it checked")
  assert_truthy(additional_context.include?("These are advisory"), "--hook additionalContext stays advisory")
end

garbage_exit_status, garbage_output, = run_the_linter_command(["--hook"], "not json at all")
assert_equal(0, garbage_exit_status, "--hook on garbage stdin exits 0")
assert_equal("", garbage_output, "--hook on garbage stdin prints nothing")

empty_stdin_exit_status, empty_stdin_output, = run_the_linter_command(["--hook"], "")
assert_equal(0, empty_stdin_exit_status, "--hook on empty stdin exits 0")
assert_equal("", empty_stdin_output, "--hook on empty stdin prints nothing")

clean_hook_event = JSON.generate("tool_input" => { "file_path" => fixture_path_for("good_naming.cr") })
clean_hook_exit_status, clean_hook_output, = run_the_linter_command(["--hook"], clean_hook_event)
assert_equal(0, clean_hook_exit_status, "--hook on a clean file exits 0")
assert_equal("", clean_hook_output, "--hook on a clean file prints nothing")

out_of_scope_event = JSON.generate("tool_input" => { "file_path" => File.join(FIXTURES_DIRECTORY, "notes.txt") })
out_of_scope_exit_status, out_of_scope_output, = run_the_linter_command(["--hook"], out_of_scope_event)
assert_equal(0, out_of_scope_exit_status, "--hook on an unsupported extension exits 0")
assert_equal("", out_of_scope_output, "--hook on an unsupported extension prints nothing")

pathless_event = JSON.generate("tool_input" => {})
pathless_exit_status, pathless_output, = run_the_linter_command(["--hook"], pathless_event)
assert_equal(0, pathless_exit_status, "--hook without a file_path exits 0")
assert_equal("", pathless_output, "--hook without a file_path prints nothing")

# Codex sends patch text instead of a file_path for apply_patch calls.
apply_patch_event = JSON.parse(File.read(fixture_path_for("apply_patch_hook.json")))
apply_patch_event["cwd"] = REPOSITORY_ROOT
apply_patch_exit_status, apply_patch_output, = run_the_linter_command(["--hook"], JSON.generate(apply_patch_event))
assert_equal(0, apply_patch_exit_status, "--hook handles Codex apply_patch payloads without blocking")
apply_patch_hook_payload = begin
  JSON.parse(apply_patch_output)
rescue JSON::ParserError => parse_error
  parse_error
end
assert_truthy(apply_patch_hook_payload.is_a?(Hash), "Codex apply_patch hook output parses as JSON")
if apply_patch_hook_payload.is_a?(Hash)
  apply_patch_context = apply_patch_hook_payload.dig("hookSpecificOutput", "additionalContext").to_s
  assert_truthy(apply_patch_context.include?("bad_naming.rb"), "Codex apply_patch path is extracted from tool_input.command")
  assert_truthy(apply_patch_context.include?("AED-N"), "Codex apply_patch hook feedback carries naming findings")
end

# Codex Bash writes do not include file paths. The hook checks only files that
# became Git-dirty after this session's SessionStart stamp.
bash_hook_fixture = JSON.parse(File.read(fixture_path_for("bash_hook.json")))
bash_session_id = "aed-bash-test-#{Process.pid}-#{Time.now.to_i}"
temporary_bash_repository = Dir.mktmpdir("aed-lint-bash-hook-")
temporary_bash_source_path = File.join(temporary_bash_repository, "new_process_manager.rb")
bash_session_stamp = File.join(AedLint::HOOK_STAMP_DIRECTORY, "#{bash_session_id}.stamp")
begin
  _git_init_output, _git_init_error, git_init_status = Open3.capture3("git", "-C", temporary_bash_repository, "init", "-q")
  assert_equal(true, git_init_status.success?, "temporary Bash hook repository initializes")

  File.write(temporary_bash_source_path, "class Customer\nend\n")
  _git_add_output, _git_add_error, git_add_status = Open3.capture3("git", "-C", temporary_bash_repository, "add", "new_process_manager.rb")
  assert_equal(true, git_add_status.success?, "temporary Bash hook baseline is staged")
  _git_commit_output, _git_commit_error, git_commit_status = Open3.capture3(
    "git", "-C", temporary_bash_repository, "-c", "user.name=AED Test", "-c", "user.email=aed-test@example.com",
    "commit", "--quiet", "-m", "baseline"
  )
  assert_equal(true, git_commit_status.success?, "temporary Bash hook baseline is committed")

  session_start_event = {
    "session_id" => bash_session_id,
    "hook_event_name" => "SessionStart",
    "cwd" => temporary_bash_repository
  }
  session_start_exit_status, session_start_output, = run_the_linter_command(["--hook"], JSON.generate(session_start_event))
  assert_equal(0, session_start_exit_status, "--hook records a Codex SessionStart stamp")
  assert_equal("", session_start_output, "SessionStart stamp does not print hook feedback")

  sleep 0.02
  bash_command = bash_hook_fixture.dig("tool_input", "command").to_s
  bash_source = bash_command.split("<<'RUBY'\n", 2).last.to_s.sub(/\nRUBY\z/, "")
  File.write(temporary_bash_source_path, bash_source)

  bash_hook_fixture["session_id"] = bash_session_id
  bash_hook_fixture["cwd"] = temporary_bash_repository
  bash_exit_status, bash_output, = run_the_linter_command(["--hook"], JSON.generate(bash_hook_fixture))
  assert_equal(0, bash_exit_status, "--hook handles Codex Bash payloads without blocking")
  bash_hook_payload = begin
    JSON.parse(bash_output)
  rescue JSON::ParserError => parse_error
    parse_error
  end
  assert_truthy(bash_hook_payload.is_a?(Hash), "Codex Bash hook output parses as JSON")
  if bash_hook_payload.is_a?(Hash)
    bash_context = bash_hook_payload.dig("hookSpecificOutput", "additionalContext").to_s
    assert_truthy(bash_context.include?("new_process_manager.rb"), "Codex Bash hook finds Git-dirty source files after SessionStart")
    assert_truthy(bash_context.include?("AED-N"), "Codex Bash hook feedback carries naming findings")
  end
ensure
  FileUtils.rm_f(bash_session_stamp)
  FileUtils.remove_entry(temporary_bash_repository) if File.directory?(temporary_bash_repository)
end

# unsupported extensions are skipped silently in normal linting too
File.write(File.join(FIXTURES_DIRECTORY, ".unsupported_probe.txt"), "data = 1\n")
begin
  skipped_exit_status, skipped_output, = run_the_linter_command([File.join(FIXTURES_DIRECTORY, ".unsupported_probe.txt")])
  assert_equal(0, skipped_exit_status, "an unsupported extension exits 0")
  assert_equal("", skipped_output, "an unsupported extension produces no findings")
ensure
  File.delete(File.join(FIXTURES_DIRECTORY, ".unsupported_probe.txt"))
end

if @list_of_assertion_failures.empty?
  puts "PASS #{@count_of_assertions_that_passed} assertions"
  exit 0
else
  puts "FAIL #{@list_of_assertion_failures.length} of #{@count_of_assertions_that_passed + @list_of_assertion_failures.length} assertions"
  @list_of_assertion_failures.each_with_index do |failure_description, zero_based_index|
    puts "  #{zero_based_index + 1}. #{failure_description}"
  end
  exit 1
end
