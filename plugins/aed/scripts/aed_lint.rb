#!/usr/bin/env ruby
# frozen_string_literal: true

# aed_lint.rb — the Agent-Enhanced Development naming linter.
#
# Ruby stdlib only (>= 2.6), no gems. Line based analysis, not a parser.
# Every finding is advisory: it names the convention it is grounded in and
# offers a rename to try. It never insults the author.
#
# Usage:
#   ruby aed_lint.rb [--format text|json] [--strict] <files-or-dirs...>
#   ruby aed_lint.rb check-name --kind boolean|collection|attribute|class|method <name...>
#   ruby aed_lint.rb --hook       # reads a Claude Code PostToolUse event on stdin
#
# Canon: https://github.com/AgentC-Consulting/aed-conventions

require "json"

module AedLint
  CANON_URL = "https://github.com/AgentC-Consulting/aed-conventions"

  SUPPORTED_FILE_EXTENSIONS = %w[.rb .cr .ex .exs].freeze

  # A boolean name "reads as a yes/no question or statement" when any of its
  # snake_case tokens is one of these — the auxiliary verb is allowed to sit
  # mid-name (`all_of_the_customers_have_been_processed`).
  AUX_VERBS = %w[
    is are am was were be been has have had can could should would will
    shall must does did do needs need allows allow requires require supports
    contains includes exists matches
  ].freeze

  COLLECTION_PREFIXES = %w[list_of_ collection_of_ array_of_ set_of_].freeze

  VAGUE_NAMES = %w[
    tmp temp foo bar baz qux data obj val vals res res1 res2 ret retval
    info stuff thing things item items arr ary lst str num idx
    do_it handle_it process_it
  ].freeze

  UNDERSPECIFIED_ATTRIBUTE_SUGGESTIONS = {
    "name" => "first_name / last_name / full_name",
    "email" => "email_address",
    "date" => "e.g. subscription_started_on_date",
    "time" => "e.g. account_locked_at_time",
    "status" => "e.g. current_subscription_status",
    "type" => "e.g. customer_billing_type",
    "kind" => "a phrase stating what kind of what",
    "value" => "a phrase stating value of what",
    "amount" => "e.g. total_amount_due_in_cents",
    "count" => "e.g. current_count_of_customer_accounts",
    "total" => "e.g. total_number_of_active_seats",
    "number" => "a phrase stating number of what",
    "flag" => "a yes/no question phrase"
  }.freeze

  PLURAL_EXCEPTIONS = %w[
    status address class analysis basis series species news access process
    bus campus kudos
  ].freeze

  MODEL_SUPERCLASSES = %w[
    ApplicationRecord ActiveRecord::Base Granite::Base Grant::Base
  ].freeze

  CRYSTAL_ATTRIBUTE_KEYWORDS = %w[
    class_property class_getter class_setter property getter setter
  ].freeze

  # ---------------------------------------------------------------- findings

  Finding = Struct.new(:file, :line, :rule, :severity, :message, :suggestion) do
    def as_text_line
      "#{file}:#{line}: [#{rule} #{severity}] #{message} — #{suggestion}"
    end

    def as_json_hash
      {
        "file" => file,
        "line" => line,
        "rule" => rule,
        "severity" => severity,
        "message" => message,
        "suggestion" => suggestion
      }
    end
  end

  # ------------------------------------------------------------ name grammar

  module NameGrammar
    module_function

    def snake_case_tokens(candidate_name)
      candidate_name.to_s.sub(/[?!]\z/, "").split(/[_\s]+/).reject(&:empty?).map(&:downcase)
    end

    def camel_case_words(candidate_name)
      candidate_name.to_s
                    .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                    .split(/[_\s]+/)
                    .reject(&:empty?)
    end

    def snake_case_of(candidate_name)
      camel_case_words(candidate_name).join("_").downcase
    end

    def final_namespace_segment(candidate_name)
      candidate_name.to_s.split(/::|\./).last.to_s
    end

    def reads_as_a_yes_or_no_question?(candidate_name)
      return true if candidate_name.to_s.end_with?("?")

      !(snake_case_tokens(candidate_name) & AUX_VERBS).empty?
    end

    def starts_with_a_collection_prefix?(candidate_name)
      COLLECTION_PREFIXES.any? { |collection_prefix| candidate_name.to_s.start_with?(collection_prefix) }
    end

    def vague_or_single_letter?(candidate_name)
      bare_name = candidate_name.to_s.sub(/[?!]\z/, "")
      # A leading underscore is the idiomatic "intentionally unused / discarded"
      # marker in Crystal, Ruby, and Elixir — `_ = keep_alive` and `_ignored`
      # are deliberate statements, not vague names.
      return false if bare_name.start_with?("_")
      VAGUE_NAMES.include?(bare_name.downcase) || bare_name.length == 1
    end

    def looks_plural?(candidate_word)
      downcased_word = candidate_word.to_s.downcase
      return false unless downcased_word.end_with?("s")
      return false if PLURAL_EXCEPTIONS.include?(downcased_word)
      return false if downcased_word.end_with?("ss", "us", "is")

      true
    end

    def suggested_boolean_names(candidate_name, owning_model_name = nil)
      bare_name = candidate_name.to_s.sub(/[?!]\z/, "")
      owning_prefix = owning_model_name ? "#{snake_case_of(singularized(final_namespace_segment(owning_model_name)))}_" : ""
      "is_this_#{owning_prefix}#{bare_name} / has_been_#{bare_name}"
    end

    def singularized(camel_case_name)
      camel_case_name.to_s.sub(/ies\z/, "y").sub(/([^s])s\z/, '\1')
    end

    def suggested_collection_names(candidate_name)
      COLLECTION_PREFIXES.first(3).map { |collection_prefix| "#{collection_prefix}#{candidate_name}" }.join(" / ")
    end
  end

  # ------------------------------------------------------------- the analyzer

  # A process manager: it receives one source file at initialization and
  # returns the complete list of naming findings from a single `perform`.
  class AnalyzeSourceFileForNamingFindings
    Definition = Struct.new(:kind, :full_name, :line, :indent, :depth, :ending_line)

    DEFINITION_OPENING_PATTERN_FOR_RUBY_FAMILY =
      /\A[ \t]*(?:abstract\s+|private\s+|protected\s+)*(class|module|struct)\s+([A-Z][\w:]*)/.freeze
    DEFINITION_OPENING_PATTERN_FOR_ELIXIR =
      /\A[ \t]*defmodule\s+([A-Z][\w.]*)/.freeze
    METHOD_SIGNATURE_PATTERN =
      /\A\s*(?:private\s+|protected\s+|public\s+|abstract\s+)*defp?\s+(?:self\.)?([A-Za-z_][\w?!]*)\s*\(([^)]*)\)/.freeze
    # `def perform`, `def perform()`, `def perform : Nil`, `def perform do`.
    NO_ARGUMENT_PERFORM_PATTERN =
      /\A\s*(?:private\s+|protected\s+|public\s+)*defp?\s+perform\s*(?:\(\s*\))?\s*(?::\s*[^\s#]+)?\s*(?:do)?\s*\z/.freeze
    LOCAL_ASSIGNMENT_PATTERN = /\A\s*([A-Za-z_]\w*)\s*=(?![=~>])/.freeze
    INSTANCE_VARIABLE_ASSIGNMENT_PATTERN = /\A\s*@([A-Za-z_]\w*)\s*=(?![=~>])/.freeze
    BLOCK_PARAMETER_PATTERN = /(?:\bdo\s*|\{\s*)\|([^|]*)\|/.freeze
    ELIXIR_ANONYMOUS_FUNCTION_PATTERN = /\bfn\s+([A-Za-z_][^->]*?)\s*->/.freeze

    attr_reader :display_path, :language

    def initialize(display_path, source_text)
      @display_path = display_path
      @source_text = source_text
      @list_of_source_lines = source_text.split("\n", -1)
      @language = self.class.language_for_path(display_path)
      @list_of_findings = []
      @list_of_definitions = []
    end

    def self.language_for_path(path_to_classify)
      case File.extname(path_to_classify.to_s).downcase
      when ".rb" then :ruby
      when ".cr" then :crystal
      when ".ex", ".exs" then :elixir
      end
    end

    def perform
      return [] if language.nil?

      collect_the_definitions_declared_in_this_file
      check_every_line_for_naming_findings
      check_the_definitions_for_structural_findings
      @list_of_findings.sort_by { |finding| [finding.line, finding.rule] }
    end

    private

    # -- structure ----------------------------------------------------------

    def collect_the_definitions_declared_in_this_file
      stack_of_open_definitions = []
      @list_of_source_lines.each_with_index do |raw_source_line, zero_based_index|
        line_number = zero_based_index + 1
        next if raw_source_line =~ /\A\s*#/

        source_line = strip_trailing_comment(raw_source_line)
        indentation_width = source_line[/\A[ \t]*/].length
        opened_definition = definition_opened_on(source_line, line_number, indentation_width, stack_of_open_definitions.length)
        if opened_definition
          @list_of_definitions << opened_definition
          stack_of_open_definitions << opened_definition
        elsif source_line =~ /\A[ \t]*end\b/ && !stack_of_open_definitions.empty?
          if stack_of_open_definitions.last.indent == indentation_width
            stack_of_open_definitions.pop.ending_line = line_number
          end
        end
      end
      stack_of_open_definitions.each { |unclosed_definition| unclosed_definition.ending_line = @list_of_source_lines.length }
    end

    def definition_opened_on(source_line, line_number, indentation_width, nesting_depth)
      if language == :elixir
        elixir_match = DEFINITION_OPENING_PATTERN_FOR_ELIXIR.match(source_line)
        return nil unless elixir_match

        Definition.new("defmodule", elixir_match[1], line_number, indentation_width, nesting_depth, nil)
      else
        ruby_family_match = DEFINITION_OPENING_PATTERN_FOR_RUBY_FAMILY.match(source_line)
        return nil unless ruby_family_match

        Definition.new(ruby_family_match[1], ruby_family_match[2], line_number, indentation_width, nesting_depth, nil)
      end
    end

    def innermost_definition_containing(line_number)
      enclosing_definitions = @list_of_definitions.select do |definition|
        definition.line < line_number && definition.ending_line.to_i >= line_number
      end
      enclosing_definitions.max_by(&:depth)
    end

    def source_line_at(line_number)
      strip_trailing_comment(@list_of_source_lines[line_number - 1].to_s)
    end

    # -- per line checks ----------------------------------------------------

    def check_every_line_for_naming_findings
      @list_of_source_lines.each_with_index do |raw_source_line, zero_based_index|
        line_number = zero_based_index + 1
        next if raw_source_line =~ /\A\s*#/

        source_line = strip_trailing_comment(raw_source_line)
        next if source_line.strip.empty?

        check_local_and_instance_variable_names(source_line, line_number)
        check_method_parameter_names(source_line, line_number)
        check_block_parameter_names(source_line, line_number)
        check_attribute_declaration(source_line, line_number)
        check_boolean_columns_declared_by_a_framework_macro(source_line, line_number)
      end
    end

    def check_local_and_instance_variable_names(source_line, line_number)
      instance_variable_match = INSTANCE_VARIABLE_ASSIGNMENT_PATTERN.match(source_line)
      report_vague_name(instance_variable_match[1], line_number, "instance variable") if instance_variable_match

      local_variable_match = LOCAL_ASSIGNMENT_PATTERN.match(source_line)
      return unless local_variable_match

      report_vague_name(local_variable_match[1], line_number, "local variable")
    end

    def check_method_parameter_names(source_line, line_number)
      signature_match = METHOD_SIGNATURE_PATTERN.match(source_line)
      return unless signature_match

      parameter_names_in(signature_match[2]).each do |parameter_name|
        report_vague_name(parameter_name, line_number, "method parameter")
      end
    end

    def check_block_parameter_names(source_line, line_number)
      block_parameter_match = BLOCK_PARAMETER_PATTERN.match(source_line)
      elixir_function_match = ELIXIR_ANONYMOUS_FUNCTION_PATTERN.match(source_line)
      captured_parameter_list = block_parameter_match ? block_parameter_match[1] : (elixir_function_match && elixir_function_match[1])
      return if captured_parameter_list.nil?

      parameter_names_in(captured_parameter_list).each do |parameter_name|
        next unless NameGrammar.vague_or_single_letter?(parameter_name)

        add_finding(
          "AED-N1", "info", line_number,
          "block parameter `#{parameter_name}` is shorthand; the canon prefers names that read like plain English",
          "name it for what one element is, e.g. `customer_record`"
        )
      end
    end

    # Crystal `property/getter/setter`, Ruby `attr_*`, Elixir `field` — one
    # parse feeds AED-N1 (vague), AED-N2 (booleans), AED-N3 (enumerables) and
    # AED-N4 (underspecified single tokens).
    def check_attribute_declaration(source_line, line_number)
      declaration = parse_attribute_declaration(source_line)
      return if declaration.nil?

      declaration[:names].each do |attribute_name|
        report_vague_name(attribute_name, line_number, "attribute")
        check_underspecified_attribute_name(attribute_name, line_number)
        check_boolean_attribute_name(attribute_name, line_number, declaration)
        check_enumerable_attribute_name(attribute_name, line_number, declaration)
      end
    end

    def parse_attribute_declaration(source_line)
      crystal_match = /\A\s*(?:private\s+)?(#{CRYSTAL_ATTRIBUTE_KEYWORDS.join('|')})(\?|!)?\s+(.+)\z/.match(source_line)
      return parse_crystal_attribute_declaration(crystal_match) if crystal_match && language != :elixir

      ruby_attribute_match = /\A\s*(attr_accessor|attr_reader|attr_writer)\s+(.+)\z/.match(source_line)
      if ruby_attribute_match
        return {
          names: ruby_attribute_match[2].scan(/:([A-Za-z_]\w*[?!]?)/).flatten,
          declared_type: nil,
          predicate_keyword: false
        }
      end

      elixir_field_match = /\A\s*field\s+:([A-Za-z_]\w*)\s*(?:,\s*(.+?))?\s*\z/.match(source_line)
      if elixir_field_match && language == :elixir
        return {
          names: [elixir_field_match[1]],
          declared_type: elixir_field_match[2].to_s.strip,
          predicate_keyword: false
        }
      end

      nil
    end

    def parse_crystal_attribute_declaration(crystal_match)
      remainder_of_declaration = crystal_match[3].strip
      if remainder_of_declaration.include?(":")
        name_portion, type_portion = remainder_of_declaration.split(":", 2)
        {
          names: [name_portion.strip.sub(/[?!]\z/, "")].reject(&:empty?),
          declared_type: type_portion.to_s.split(/\s+=\s+/).first.to_s.strip,
          predicate_keyword: crystal_match[2] == "?"
        }
      else
        {
          names: remainder_of_declaration.split(/\s+=\s+/).first.to_s.split(",").map { |bare_name| bare_name.strip.sub(/[?!]\z/, "") }.reject(&:empty?),
          declared_type: nil,
          predicate_keyword: crystal_match[2] == "?"
        }
      end
    end

    def check_underspecified_attribute_name(attribute_name, line_number)
      bare_name = attribute_name.sub(/[?!]\z/, "").downcase
      return unless NameGrammar.snake_case_tokens(bare_name).length == 1

      suggestion_for_this_token = UNDERSPECIFIED_ATTRIBUTE_SUGGESTIONS[bare_name]
      return if suggestion_for_this_token.nil?

      add_finding(
        "AED-N4", "info", line_number,
        "attribute `#{attribute_name}` is a single word; the canon asks attributes to be short statements of purpose",
        suggestion_for_this_token
      )
    end

    def check_boolean_attribute_name(attribute_name, line_number, declaration)
      return unless boolean_declaration?(declaration)
      return if declaration[:predicate_keyword]
      return if NameGrammar.reads_as_a_yes_or_no_question?(attribute_name)

      add_finding(
        "AED-N2", "warn", line_number,
        "boolean attribute `#{attribute_name}` does not read as a yes/no question",
        NameGrammar.suggested_boolean_names(attribute_name, owning_model_name_for(line_number))
      )
    end

    def check_enumerable_attribute_name(attribute_name, line_number, declaration)
      declared_type = declaration[:declared_type].to_s
      if enumerable_declaration?(declared_type)
        return if NameGrammar.starts_with_a_collection_prefix?(attribute_name)

        add_finding(
          "AED-N3", "warn", line_number,
          "enumerable attribute `#{attribute_name}` does not say it holds a collection",
          NameGrammar.suggested_collection_names(attribute_name)
        )
      elsif keyed_collection_declaration?(declared_type)
        # The canon is silent on hashes, so this is only ever a suggestion —
        # and it stays quiet when the name already says how it is keyed.
        return if attribute_name =~ /\A(map_of_|hash_of_|dictionary_of_)/ || attribute_name.include?("_by_")

        add_finding(
          "AED-N3", "info", line_number,
          "keyed collection `#{attribute_name}` reads more clearly when the name says how it is keyed",
          "e.g. `map_of_#{attribute_name}` / `hash_of_#{attribute_name}` / `#{attribute_name}_by_customer_id`"
        )
      end
    end

    def boolean_declaration?(declaration)
      declared_type = declaration[:declared_type].to_s
      return true if language == :crystal && declared_type =~ /\ABool\b/
      return true if language == :elixir && declared_type =~ /\A:boolean\b/

      false
    end

    def enumerable_declaration?(declared_type)
      return true if language == :crystal && declared_type =~ /\A(Array|Set)\(/
      return true if language == :elixir && declared_type =~ /\A\{\s*:array\b/

      false
    end

    def keyed_collection_declaration?(declared_type)
      return true if language == :crystal && declared_type =~ /\AHash\(/
      return true if language == :elixir && declared_type =~ /\A(:map\b|\{\s*:map\b)/

      false
    end

    # Rails/Ecto migration and attribute macros. Framework `has_many` is left
    # alone on purpose — the canon explicitly respects framework conventions.
    def check_boolean_columns_declared_by_a_framework_macro(source_line, line_number)
      boolean_column_names = []
      boolean_column_names.concat(source_line.scan(/\bt\.boolean\s+:([A-Za-z_]\w*)/).flatten)
      boolean_column_names.concat(source_line.scan(/\badd_column\b.*?,\s*:([A-Za-z_]\w*)\s*,\s*:boolean\b/).flatten)
      boolean_column_names.concat(source_line.scan(/\battribute\s+:([A-Za-z_]\w*)\s*,\s*:boolean\b/).flatten)
      boolean_column_names.concat(source_line.scan(/\bfield\s+:([A-Za-z_]\w*)\s*,\s*:boolean\b/).flatten)

      boolean_column_names.uniq.each do |boolean_column_name|
        next if NameGrammar.reads_as_a_yes_or_no_question?(boolean_column_name)

        add_finding(
          "AED-N2", "warn", line_number,
          "boolean attribute `#{boolean_column_name}` does not read as a yes/no question",
          NameGrammar.suggested_boolean_names(boolean_column_name, owning_model_name_for(line_number))
        )
      end
    end

    # -- structural checks --------------------------------------------------

    def check_the_definitions_for_structural_findings
      check_data_models_are_singular
      check_process_manager_perform_signatures
      check_process_manager_class_names_read_as_statements
      check_primary_definition_matches_the_file_name
    end

    def check_data_models_are_singular
      model_definitions_in_this_file.each do |model_definition|
        final_segment = NameGrammar.final_namespace_segment(model_definition.full_name)
        last_camel_case_word = NameGrammar.camel_case_words(final_segment).last.to_s
        next unless NameGrammar.looks_plural?(last_camel_case_word)

        add_finding(
          "AED-N5", "warn", model_definition.line,
          "data model `#{model_definition.full_name}` is plural; data models are singular and concerned with their own individual behavior",
          "e.g. `#{NameGrammar.singularized(final_segment)}`"
        )
      end
    end

    # Only a data model lends its own noun to a boolean suggestion — a
    # migration class would produce nonsense like `is_this_add_column_locked`.
    def owning_model_name_for(line_number)
      owning_definition = innermost_definition_containing(line_number)
      return nil if owning_definition.nil?
      return nil unless model_definitions_in_this_file.include?(owning_definition)

      owning_definition.full_name
    end

    def model_definitions_in_this_file
      if language == :elixir
        schema_line_number = @list_of_source_lines.index { |source_line| source_line =~ /\buse\s+Ecto\.Schema\b/ }
        return [] if schema_line_number.nil?

        enclosing_module = @list_of_definitions.select { |definition| definition.line <= schema_line_number + 1 }.last
        return enclosing_module ? [enclosing_module] : []
      end

      @list_of_definitions.select do |definition|
        next false unless definition.kind == "class"

        declaration_line = source_line_at(definition.line)
        MODEL_SUPERCLASSES.any? do |model_superclass|
          declaration_line =~ /<\s*#{Regexp.escape(model_superclass)}\s*(?:$|#|;)/
        end
      end
    end

    def check_process_manager_perform_signatures
      return if language == :elixir

      definitions_that_define_initialize = {}
      @list_of_source_lines.each_with_index do |raw_source_line, zero_based_index|
        next unless strip_trailing_comment(raw_source_line) =~ /\A\s*(?:private\s+|protected\s+)?def\s+initialize\b/

        owning_definition = innermost_definition_containing(zero_based_index + 1)
        definitions_that_define_initialize[owning_definition] = true if owning_definition
      end

      @list_of_source_lines.each_with_index do |raw_source_line, zero_based_index|
        source_line = strip_trailing_comment(raw_source_line)
        next unless source_line =~ /\A\s*(?:private\s+|protected\s+)?def\s+perform\s*\(\s*[^)\s]/

        line_number = zero_based_index + 1
        owning_definition = innermost_definition_containing(line_number)
        next unless owning_definition && definitions_that_define_initialize[owning_definition]

        add_finding(
          "AED-N6", "warn", line_number,
          "`perform` in `#{owning_definition.full_name}` takes arguments; a process manager receives everything it needs in `initialize`",
          "move these arguments into `initialize` and leave `def perform` with no parameters"
        )
      end
    end

    def check_process_manager_class_names_read_as_statements
      return if language == :elixir

      classes_that_define_a_no_argument_perform.each do |process_manager_definition|
        final_segment = NameGrammar.final_namespace_segment(process_manager_definition.full_name)
        next unless NameGrammar.camel_case_words(final_segment).length < 3

        add_finding(
          "AED-N8", "info", process_manager_definition.line,
          "process manager `#{process_manager_definition.full_name}` is not yet a short statement of the process it performs",
          "e.g. `AddSubscriptionToCustomer`, `PerformCustomerAccountLocking`"
        )
      end
    end

    def check_primary_definition_matches_the_file_name
      primary_definition = primary_definition_of_this_file
      return if primary_definition.nil?

      expected_file_base_name = NameGrammar.snake_case_of(NameGrammar.final_namespace_segment(primary_definition.full_name))
      actual_file_base_name = File.basename(display_path, File.extname(display_path))
      return if expected_file_base_name == actual_file_base_name

      add_finding(
        "AED-N7", "info", primary_definition.line,
        "file is named `#{actual_file_base_name}` but its primary definition is `#{primary_definition.full_name}`; the file name should be the lower snake case of the primary class",
        "rename the file to `#{expected_file_base_name}#{File.extname(display_path)}`"
      )
    end

    def classes_that_define_a_no_argument_perform
      owning_definitions = []
      @list_of_source_lines.each_with_index do |raw_source_line, zero_based_index|
        next unless strip_trailing_comment(raw_source_line).rstrip =~ NO_ARGUMENT_PERFORM_PATTERN

        owning_definition = innermost_definition_containing(zero_based_index + 1)
        next if owning_definition.nil? || owning_definition.kind == "module"

        owning_definitions << owning_definition
      end
      owning_definitions.uniq
    end

    # The primary definition is the first top level one. A namespace module
    # that wraps exactly one definition is transparent — the canon puts
    # namespaces in folders and names the file for the class inside.
    def primary_definition_of_this_file
      return nil if @list_of_definitions.empty?

      shallowest_depth = @list_of_definitions.map(&:depth).min
      first_top_level_definition = @list_of_definitions.find { |definition| definition.depth == shallowest_depth }
      return first_top_level_definition unless first_top_level_definition.kind == "module"

      definitions_nested_directly_inside = @list_of_definitions.select do |definition|
        definition.depth == shallowest_depth + 1 &&
          definition.line > first_top_level_definition.line &&
          definition.line <= first_top_level_definition.ending_line.to_i
      end
      return first_top_level_definition unless definitions_nested_directly_inside.length == 1

      definitions_nested_directly_inside.first
    end

    # -- shared helpers -----------------------------------------------------

    def report_vague_name(candidate_name, line_number, name_role)
      return if candidate_name.nil?
      return unless NameGrammar.vague_or_single_letter?(candidate_name)

      add_finding(
        "AED-N1", "warn", line_number,
        "#{name_role} `#{candidate_name}` does not say what it holds",
        "name it as a short statement of its purpose, e.g. `customer_record_to_update`"
      )
    end

    def parameter_names_in(parameter_list_text)
      collected_parameter_names = []
      current_parameter_text = +""
      nesting_depth = 0
      parameter_list_text.to_s.each_char do |source_character|
        case source_character
        when "(", "[", "{"
          nesting_depth += 1
          current_parameter_text << source_character
        when ")", "]", "}"
          nesting_depth -= 1
          current_parameter_text << source_character
        when ","
          if nesting_depth.zero?
            collected_parameter_names << current_parameter_text
            current_parameter_text = +""
          else
            current_parameter_text << source_character
          end
        else
          current_parameter_text << source_character
        end
      end
      collected_parameter_names << current_parameter_text
      collected_parameter_names.map { |raw_parameter| raw_parameter.strip[/\A[*&]{0,2}@?([A-Za-z_]\w*)/, 1] }.compact
    end

    def strip_trailing_comment(raw_source_line)
      raw_source_line.sub(/\s+#(?!\{).*\z/, "")
    end

    def add_finding(rule_identifier, severity, line_number, message, suggestion)
      candidate_finding = Finding.new(display_path, line_number, rule_identifier, severity, message, suggestion)
      already_reported = @list_of_findings.any? do |existing_finding|
        existing_finding.line == line_number &&
          existing_finding.rule == rule_identifier &&
          existing_finding.message == message
      end
      @list_of_findings << candidate_finding unless already_reported
    end
  end

  # -------------------------------------------------------- name-only checks

  # Used by the `check-name` subcommand at planning time, when there is no
  # file yet — an agent can check a candidate name before writing any code.
  class CheckACandidateNameAgainstTheCanon
    SUPPORTED_KINDS = %w[boolean collection attribute class method].freeze

    Verdict = Struct.new(:name, :acceptable, :reason, :suggestion) do
      def as_text_line
        return "OK #{name}" if acceptable

        "RENAME #{name} — #{reason} — try: #{suggestion}"
      end
    end

    def initialize(kind_of_name, candidate_name)
      @kind_of_name = kind_of_name
      @candidate_name = candidate_name
    end

    def perform
      case @kind_of_name
      when "boolean" then verdict_for_a_boolean_name
      when "collection" then verdict_for_a_collection_name
      when "attribute" then verdict_for_an_attribute_name
      when "class" then verdict_for_a_class_name
      when "method" then verdict_for_a_method_name
      end
    end

    private

    def acceptable_verdict
      Verdict.new(@candidate_name, true, nil, nil)
    end

    def rename_verdict(reason, suggestion)
      Verdict.new(@candidate_name, false, reason, suggestion)
    end

    def verdict_for_a_boolean_name
      return acceptable_verdict if NameGrammar.reads_as_a_yes_or_no_question?(@candidate_name)

      rename_verdict(
        "boolean names read as a yes/no question or statement (AED-N2)",
        NameGrammar.suggested_boolean_names(@candidate_name)
      )
    end

    def verdict_for_a_collection_name
      return acceptable_verdict if NameGrammar.starts_with_a_collection_prefix?(@candidate_name)

      rename_verdict(
        "enumerable attributes say they hold a collection (AED-N3)",
        NameGrammar.suggested_collection_names(@candidate_name)
      )
    end

    def verdict_for_an_attribute_name
      if NameGrammar.vague_or_single_letter?(@candidate_name)
        return rename_verdict(
          "the name does not say what it holds (AED-N1)",
          "a short statement of purpose, e.g. `currently_active_subscription`"
        )
      end

      underspecified_suggestion = UNDERSPECIFIED_ATTRIBUTE_SUGGESTIONS[@candidate_name.to_s.downcase]
      if underspecified_suggestion && NameGrammar.snake_case_tokens(@candidate_name).length == 1
        return rename_verdict(
          "a single word leaves the purpose to be guessed (AED-N4)",
          underspecified_suggestion
        )
      end

      acceptable_verdict
    end

    def verdict_for_a_class_name
      final_segment = NameGrammar.final_namespace_segment(@candidate_name)
      if NameGrammar.vague_or_single_letter?(final_segment)
        return rename_verdict(
          "the name does not say what the class does (AED-N1)",
          "a short statement of the process, e.g. `AddSubscriptionToCustomer`"
        )
      end
      return acceptable_verdict if NameGrammar.camel_case_words(final_segment).length >= 3

      rename_verdict(
        "class names are short statements of the process being performed (AED-N8)",
        "e.g. `AddSubscriptionToCustomer`, `PerformCustomerAccountLocking`"
      )
    end

    def verdict_for_a_method_name
      if NameGrammar.vague_or_single_letter?(@candidate_name)
        return rename_verdict(
          "the name does not say what the method does (AED-N1)",
          "a phrase naming the process, e.g. `lock_customer_account_and_notify`"
        )
      end
      return acceptable_verdict if NameGrammar.snake_case_tokens(@candidate_name).length >= 2

      rename_verdict(
        "method names are phrases or statements that explain the process taking place",
        "a phrase naming the process, e.g. `retry_customers_who_failed_payment_processing`"
      )
    end
  end

  # ------------------------------------------------------------ the CLI shell

  class LintCommandLineInvocation
    USAGE_TEXT = <<~USAGE
      Usage:
        aed_lint.rb [--format text|json] [--strict] <files-or-dirs...>
        aed_lint.rb check-name --kind boolean|collection|attribute|class|method <name...>
        aed_lint.rb --hook
    USAGE

    def initialize(command_line_arguments, standard_output = $stdout, standard_error = $stderr, standard_input = $stdin)
      @command_line_arguments = command_line_arguments
      @standard_output = standard_output
      @standard_error = standard_error
      @standard_input = standard_input
    end

    def perform
      return run_the_check_name_subcommand if @command_line_arguments.first == "check-name"
      return run_the_post_tool_use_hook if @command_line_arguments.include?("--hook")

      run_the_file_linter
    end

    private

    def usage_error(explanation)
      @standard_error.puts("aed_lint: #{explanation}")
      @standard_error.puts(USAGE_TEXT)
      2
    end

    # -- linting files ------------------------------------------------------

    def run_the_file_linter
      output_format = "text"
      strict_mode_requested = false
      list_of_requested_paths = []
      remaining_arguments = @command_line_arguments.dup

      until remaining_arguments.empty?
        current_argument = remaining_arguments.shift
        case current_argument
        when "--format"
          output_format = remaining_arguments.shift.to_s
        when /\A--format=(.+)\z/
          output_format = Regexp.last_match(1)
        when "--strict"
          strict_mode_requested = true
        when "--help", "-h"
          @standard_output.puts(USAGE_TEXT)
          return 0
        when /\A-/
          return usage_error("unknown option #{current_argument}")
        else
          list_of_requested_paths << current_argument
        end
      end

      return usage_error("unknown format #{output_format}") unless %w[text json].include?(output_format)
      return usage_error("no files or directories given") if list_of_requested_paths.empty?

      list_of_files_to_lint = []
      list_of_requested_paths.each do |requested_path|
        if File.directory?(requested_path)
          list_of_files_to_lint.concat(source_files_under(requested_path))
        elsif File.file?(requested_path)
          list_of_files_to_lint << requested_path if in_scope?(requested_path)
        else
          return usage_error("no such file or directory: #{requested_path}")
        end
      end

      list_of_findings = list_of_files_to_lint.sort.flat_map { |path_to_lint| findings_for(path_to_lint) }
      emit_findings(list_of_findings, output_format)

      warning_was_found = list_of_findings.any? { |finding| finding.severity == "warn" }
      warning_was_found && strict_mode_requested ? 1 : 0
    end

    def emit_findings(list_of_findings, output_format)
      if output_format == "json"
        @standard_output.puts(JSON.generate("findings" => list_of_findings.map(&:as_json_hash)))
      else
        list_of_findings.each { |finding| @standard_output.puts(finding.as_text_line) }
      end
    end

    def source_files_under(directory_path)
      Dir.glob(File.join(directory_path, "**", "*")).select do |candidate_path|
        File.file?(candidate_path) && in_scope?(candidate_path)
      end
    end

    def in_scope?(candidate_path)
      SUPPORTED_FILE_EXTENSIONS.include?(File.extname(candidate_path).downcase)
    end

    def findings_for(path_to_lint)
      source_text = File.read(path_to_lint)
      AnalyzeSourceFileForNamingFindings.new(path_to_lint, source_text).perform
    rescue SystemCallError, IOError, ArgumentError
      []
    end

    # -- check-name ---------------------------------------------------------

    def run_the_check_name_subcommand
      remaining_arguments = @command_line_arguments[1..-1] || []
      kind_of_name = nil
      list_of_candidate_names = []

      until remaining_arguments.empty?
        current_argument = remaining_arguments.shift
        case current_argument
        when "--kind"
          kind_of_name = remaining_arguments.shift
        when /\A--kind=(.+)\z/
          kind_of_name = Regexp.last_match(1)
        when /\A-/
          return usage_error("unknown option #{current_argument}")
        else
          list_of_candidate_names << current_argument
        end
      end

      unless CheckACandidateNameAgainstTheCanon::SUPPORTED_KINDS.include?(kind_of_name)
        return usage_error("check-name needs --kind #{CheckACandidateNameAgainstTheCanon::SUPPORTED_KINDS.join('|')}")
      end
      return usage_error("check-name needs at least one candidate name") if list_of_candidate_names.empty?

      every_name_was_acceptable = true
      list_of_candidate_names.each do |candidate_name|
        verdict = CheckACandidateNameAgainstTheCanon.new(kind_of_name, candidate_name).perform
        every_name_was_acceptable = false unless verdict.acceptable
        @standard_output.puts(verdict.as_text_line)
      end

      every_name_was_acceptable ? 0 : 1
    end

    # -- PostToolUse hook ---------------------------------------------------

    # Never exits nonzero and never prints anything that is not the hook JSON.
    def run_the_post_tool_use_hook
      hook_event = JSON.parse(@standard_input.read.to_s)
      edited_file_path = extract_edited_file_path(hook_event)
      return 0 if edited_file_path.nil?
      return 0 unless in_scope?(edited_file_path)
      return 0 unless File.file?(edited_file_path) && File.readable?(edited_file_path)

      relative_path = relative_display_path(edited_file_path)
      list_of_findings = AnalyzeSourceFileForNamingFindings.new(relative_path, File.read(edited_file_path)).perform
      return 0 if list_of_findings.empty?

      @standard_output.puts(JSON.generate(hook_payload_for(relative_path, list_of_findings)))
      0
    rescue StandardError
      0
    end

    def hook_payload_for(relative_path, list_of_findings)
      additional_context = "AED naming check on #{relative_path}:\n" \
                           "#{list_of_findings.map(&:as_text_line).join("\n")}\n" \
                           "These are advisory — the AED canon is at #{CANON_URL}"
      {
        "hookSpecificOutput" => {
          "hookEventName" => "PostToolUse",
          "additionalContext" => additional_context
        }
      }
    end

    def extract_edited_file_path(hook_event)
      return nil unless hook_event.is_a?(Hash)

      tool_input = hook_event["tool_input"]
      return nil unless tool_input.is_a?(Hash)

      candidate_path = tool_input["file_path"] || tool_input["filePath"] || tool_input["path"]
      candidate_path.is_a?(String) && !candidate_path.empty? ? candidate_path : nil
    end

    def relative_display_path(absolute_or_relative_path)
      working_directory_prefix = "#{Dir.pwd}#{File::SEPARATOR}"
      return absolute_or_relative_path[working_directory_prefix.length..-1] if absolute_or_relative_path.start_with?(working_directory_prefix)

      absolute_or_relative_path
    end
  end
end

exit(AedLint::LintCommandLineInvocation.new(ARGV).perform) if $PROGRAM_NAME == __FILE__
