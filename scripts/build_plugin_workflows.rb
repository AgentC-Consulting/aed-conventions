#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate Claude Code commands and Codex skills from shared workflow sources.
#
#   ruby scripts/build_plugin_workflows.rb
#   ruby scripts/build_plugin_workflows.rb --check

require "json"
require "fileutils"

module BuildPluginWorkflows
  REPOSITORY_ROOT = File.expand_path("..", __dir__)
  WORKFLOW_METADATA = {
    "adopt" => {
      "command_description" => "Add or update the project's AED conventions section in agent instructions",
      "skill_description" => "Adopt AED conventions in AGENTS.md for Codex or CLAUDE.md for Claude Code, keeping one canonical section when both harnesses are used."
    },
    "check" => {
      "command_description" => "Run the AED naming linter on given paths or changed files and triage findings",
      "skill_description" => "Run the AED naming linter on explicit paths or changed Ruby, Crystal, or Elixir files, then triage clear renames and judgment calls."
    },
    "scaffold" => {
      "command_description" => "Scaffold a process manager from a When-statement",
      "skill_description" => "Scaffold a process manager from a When-statement, verify its names with the AED linter, and write it in the project's language."
    }
  }.freeze
  CLAUDE_ARGUMENT_LINES = {
    "check" => "Command arguments: $ARGUMENTS",
    "scaffold" => "When-statement argument: $ARGUMENTS"
  }.freeze

  module_function

  def perform(command_line_arguments)
    check_only = command_line_arguments == ["--check"]
    unless check_only || command_line_arguments.empty?
      $stderr.puts("usage: ruby scripts/build_plugin_workflows.rb [--check]")
      return 2
    end

    list_of_mismatched_files = []
    WORKFLOW_METADATA.each do |workflow_name, metadata|
      generated_workflow_files(workflow_name, metadata).each do |relative_path, generated_content|
        absolute_path = File.join(REPOSITORY_ROOT, relative_path)
        if check_only
          list_of_mismatched_files << relative_path unless File.file?(absolute_path) && File.read(absolute_path) == generated_content
        else
          FileUtils.mkdir_p(File.dirname(absolute_path))
          File.write(absolute_path, generated_content)
        end
      end
    end

    if check_only && !list_of_mismatched_files.empty?
      $stderr.puts("generated workflow files are out of date: #{list_of_mismatched_files.join(", ")}")
      return 1
    end

    puts(check_only ? "generated workflow files are current" : "generated Claude commands and Codex skills")
    0
  rescue SystemCallError => error
    $stderr.puts("build_plugin_workflows: #{error.message}")
    1
  end

  def generated_workflow_files(workflow_name, metadata)
    workflow_source_path = File.join(REPOSITORY_ROOT, "plugins/aed/workflows", "#{workflow_name}.md")
    workflow_body = File.read(workflow_source_path).strip
    claude_command_content = render_claude_command(workflow_name, metadata, workflow_body)
    codex_skill_content = render_codex_skill(workflow_name, metadata, workflow_body)

    [
      ["plugins/aed/commands/#{workflow_name}.md", claude_command_content],
      ["plugins/aed/skills/#{workflow_name}/SKILL.md", codex_skill_content]
    ]
  end

  def render_claude_command(workflow_name, metadata, workflow_body)
    argument_line = CLAUDE_ARGUMENT_LINES[workflow_name]
    body_lines = [argument_line, workflow_body].compact
    [
      "---",
      "description: #{JSON.generate(metadata.fetch("command_description"))}",
      "---",
      "",
      body_lines.join("\n\n"),
      ""
    ].join("\n")
  end

  def render_codex_skill(workflow_name, metadata, workflow_body)
    [
      "---",
      "name: #{workflow_name}",
      "description: #{JSON.generate(metadata.fetch("skill_description"))}",
      "---",
      "",
      workflow_body,
      ""
    ].join("\n")
  end
end

exit(BuildPluginWorkflows.perform(ARGV)) if $PROGRAM_NAME == __FILE__
