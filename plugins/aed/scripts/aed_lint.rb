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
#   ruby aed_lint.rb --hook       # reads a Claude Code or Codex hook event on stdin
#
# Canon: https://github.com/AgentC-Consulting/aed-conventions

require "json"
require "digest"
require "fileutils"
require "open3"
require "tmpdir"

module AedLint
  CANON_URL = "https://github.com/AgentC-Consulting/aed-conventions"

  SUPPORTED_FILE_EXTENSIONS = %w[.rb .cr .ex .exs].freeze
  PATCH_PATH_PATTERN = /^\*\*\* (?:Add File|Update File|Move to): ([^\r\n]+)$/.freeze
  HOOK_STAMP_DIRECTORY = File.join(Dir.tmpdir, "aed_lint_hook")

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

  # These are singular nouns that happen to end in s.
  PLURAL_EXCEPTIONS = %w[
    status address class analysis basis series species news access process
    bus campus kudos business alias gas bias lens physics mathematics
  ].freeze

  # These words name collections, configuration bags, framework surfaces, or
  # other plural concepts rather than one-record data models. Do not offer a
  # singular rename for a class whose name contains one of them.
  COLLECTIVE_DATA_CLASS_WORDS = %w[
    settings options params metrics stats errors headers credentials preferences
    filters styles connections operations
  ].freeze

  UNCOUNTABLE_WORDS = %w[
    data equipment information money rice fish sheep deer aircraft offspring
    moose salmon trout swine media news series species
  ].freeze

  IRREGULAR_PLURALS = {
    "people" => "person",
    "men" => "man",
    "women" => "woman",
    "children" => "child",
    "teeth" => "tooth",
    "feet" => "foot",
    "geese" => "goose",
    "mice" => "mouse",
    "oxen" => "ox",
    "analyses" => "analysis",
    "bases" => "base",
    "crises" => "crisis",
    "diagnoses" => "diagnosis",
    "hypotheses" => "hypothesis",
    "oases" => "oasis",
    "parentheses" => "parenthesis",
    "synopses" => "synopsis",
    "theses" => "thesis",
    "indices" => "index",
    "matrices" => "matrix",
    "vertices" => "vertex",
    "cookies" => "cookie",
    "movies" => "movie",
    "brownies" => "brownie",
    "pies" => "pie",
    "ties" => "tie",
    "lies" => "lie",
    "shoes" => "shoe",
    "canoes" => "canoe",
    "wives" => "wife",
    "lives" => "life",
    "knives" => "knife",
    "leaves" => "leaf",
    "wolves" => "wolf",
    "shelves" => "shelf",
    "selves" => "self",
    "halves" => "half",
    "calves" => "calf",
    "loaves" => "loaf",
    "thieves" => "thief",
    "scarves" => "scarf",
    "dwarves" => "dwarf",
    "houses" => "house",
    "horses" => "horse",
    "buses" => "bus",
    "statuses" => "status"
  }.freeze

  PROCESS_CLASS_START_VERBS = %w[
    activate add adjust aggregate analyze archive assign attach authorize build
    calculate cancel capture change check clean close collect configure confirm
    connect convert create deactivate delete deliver disable dispatch enable
    establish evaluate export fetch find finish fulfill generate handle import
    invite issue lock mark merge migrate notify open perform process publish
    read reconcile refresh register remove render replace report request reset
    restore retry review save schedule send set start stop submit sync transfer
    update upload validate verify
  ].freeze

  FRAMEWORK_CLASS_SUFFIXES = %w[
    controller migration spec specs test tests
  ].freeze

  CLASS_HEAD_BOUNDARIES = %w[
    and as by for from of under with without
  ].freeze

  # Process-manager entry points, language predicates, and common framework
  # methods keep their established one-word names.
  SINGLE_WORD_METHOD_EXCEPTIONS = %w[
    initialize perform create edit update destroy index show new delete change
    save find find_by changeset setup teardown
    parse call validate get clear where count token match add run register encode
    continue build all resolve pluck set select reset id list json first execute
    each decode verify validate url start size import callback tag put params order name
    close open fetch map filter reduce inject select! reject! find! find_by! include?
    includes includes? empty? length last last! keys values to_a to_h to_s inspect
    hash eql? == [] []= transaction preload joins includes having group limit offset
    distinct reorder reselect rewhere unscope unscoped reload insert delete_by update_all
    create! update! destroy! method_missing respond_to_missing? method_added inherited
    included extended append prepend before after around serialize deserialize encode_with
    init decode! parse! load dump validate_each call_next call_next! write read send receive
  ].freeze

  VAGUE_SINGLE_WORD_METHOD_NAMES = %w[process retry handle manage].freeze

  DATA_FIELD_DECLARATION_PATTERN = /\A\s*(?:property|getter|setter|class_property|class_getter|class_setter|attr_reader|attr_writer|attr_accessor|attribute|field|column)\b/.freeze
  JSON_SERIALIZABLE_MARKER_PATTERN = /\b(?:include|extend|use)\s+(?:::)?JSON::Serializable\b/.freeze

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

    def namespace_segments(candidate_name)
      candidate_name.to_s.split(/::|\./)[0...-1]
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
      singularized(candidate_word) != candidate_word.to_s
    end

    def collective_data_class_name?(candidate_name)
      camel_case_words(final_namespace_segment(candidate_name)).any? do |class_word|
        COLLECTIVE_DATA_CLASS_WORDS.include?(class_word.downcase)
      end
    end

    def all_caps_acronym?(candidate_name)
      bare_name = final_namespace_segment(candidate_name)
      bare_name.length > 1 && bare_name =~ /\A[A-Z0-9]+\z/
    end

    def vague_single_word_method?(candidate_name)
      bare_name = candidate_name.to_s.sub(/[?!]\z/, "").downcase
      VAGUE_SINGLE_WORD_METHOD_NAMES.include?(bare_name)
    end

    def suggested_boolean_names(candidate_name, owning_model_name = nil)
      bare_name = candidate_name.to_s.sub(/[?!]\z/, "")
      owning_prefix = owning_model_name ? "#{snake_case_of(singularized(final_namespace_segment(owning_model_name)))}_" : ""
      "is_this_#{owning_prefix}#{bare_name} / has_been_#{bare_name}"
    end

    def singularized(camel_case_name)
      original_word = camel_case_name.to_s
      downcased_word = original_word.downcase
      return original_word if original_word.length > 1 && original_word =~ /\A[A-Z0-9]+\z/
      return original_word if PLURAL_EXCEPTIONS.include?(downcased_word)
      return original_word if UNCOUNTABLE_WORDS.include?(downcased_word)

      singular_word = IRREGULAR_PLURALS[downcased_word]
      singular_word ||= if downcased_word.length > 3 && downcased_word.end_with?("ies")
                          downcased_word.sub(/ies\z/, "y")
                        elsif downcased_word.length > 4 && %w[ches shes xes zes sses].any? { |suffix| downcased_word.end_with?(suffix) }
                          downcased_word.sub(/es\z/, "")
                        elsif downcased_word.length > 3 && downcased_word.end_with?("oes")
                          downcased_word.sub(/oes\z/, "o")
                        elsif downcased_word.length > 2 && downcased_word.end_with?("s") && !downcased_word.end_with?("ss", "us", "is")
                          downcased_word[0...-1]
                        else
                          downcased_word
                        end

      return original_word if singular_word == downcased_word

      preserve_word_case(original_word, singular_word)
    end

    def suggested_singular_data_class_name(candidate_name)
      final_segment = final_namespace_segment(candidate_name)
      list_of_words = camel_case_words(final_segment)
      return nil if list_of_words.empty?
      return nil if FRAMEWORK_CLASS_SUFFIXES.include?(list_of_words.last.downcase)
      return nil if PROCESS_CLASS_START_VERBS.include?(list_of_words.first.downcase)
      return nil if collective_data_class_name?(final_segment)
      return nil if all_caps_acronym?(final_segment)

      first_class_phrase_boundary = list_of_words.index do |class_word|
        CLASS_HEAD_BOUNDARIES.include?(class_word.downcase)
      end
      class_head_words = first_class_phrase_boundary ? list_of_words[0...first_class_phrase_boundary] : list_of_words
      head_word_index = class_head_words.length - 1
      singular_head_word = singularized(list_of_words[head_word_index])
      return nil if singular_head_word == list_of_words[head_word_index]

      list_of_words[head_word_index] = singular_head_word
      list_of_words.join
    end

    def preserve_word_case(original_word, replacement_word)
      return replacement_word if original_word == original_word.downcase
      return replacement_word.upcase if original_word == original_word.upcase

      original_word[0] == original_word[0].upcase ? replacement_word[0].upcase + replacement_word[1..-1] : replacement_word
    end

    def framework_class_name?(candidate_name)
      last_class_word = camel_case_words(final_namespace_segment(candidate_name)).last.to_s.downcase
      FRAMEWORK_CLASS_SUFFIXES.include?(last_class_word)
    end

    def action_method_name?(candidate_name)
      downcased_name = candidate_name.to_s.sub(/[?!]\z/, "").downcase
      SINGLE_WORD_METHOD_EXCEPTIONS.include?(downcased_name) || candidate_name.to_s.match?(/[?!]\z/)
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
    METHOD_NAME_PATTERN =
      /\A\s*(?:(?:private|protected|public|abstract)\s+)*defp?\s+(?:self\.)?([a-z_][\w?!]*)(?=\s*(?:\(|:|,|do\b|\z))/.freeze
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
        check_method_name_phrase(source_line, line_number)
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

    def check_method_name_phrase(source_line, line_number)
      method_match = METHOD_NAME_PATTERN.match(source_line)
      return unless method_match

      method_name = method_match[1]
      return if NameGrammar.action_method_name?(method_name)
      return if NameGrammar.snake_case_tokens(method_name).length >= 2
      return unless NameGrammar.vague_single_word_method?(method_name)

      signature_match = METHOD_SIGNATURE_PATTERN.match(source_line)
      return if signature_match.nil? || parameter_names_in(signature_match[2]).empty?
      return if method_is_a_framework_override?(method_name, line_number)
      return if method_owner_uses_an_external_namespace?(line_number)

      add_finding(
        "AED-N10", "info", line_number,
        "method `#{method_name}` is a vague process name",
        "name the action and what it acts on, e.g. `process_orders_for_expired_payment_methods`"
      )
    end

    def method_is_a_framework_override?(method_name, line_number)
      previous_source_line = @list_of_source_lines[line_number - 2].to_s
      return true if previous_source_line =~ /\A\s*(?:@\[Override\]|@impl\s+true)\s*\z/

      owning_definition = innermost_definition_containing(line_number)
      return false if owning_definition.nil?
      return true if NameGrammar.framework_class_name?(owning_definition.full_name)

      definition_line = source_line_at(owning_definition.line)
      framework_parent_pattern = /<\s*(?:HTTP::Handler|HTTP::Server::Handler|ApplicationController|ActionController::Base|Phoenix\.Controller)\b/
      return true if definition_line =~ framework_parent_pattern

      method_name == "process" && owning_definition.full_name =~ /\A(?:HTTP|Plug|Phoenix)(?:::|\.)/
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
      check_other_data_class_names_are_singular
      check_process_manager_perform_signatures
      check_process_manager_class_names_read_as_statements
      check_primary_definition_matches_the_file_name
      check_primary_definition_is_stored_under_its_namespace_folders
    end

    def check_data_models_are_singular
      model_definitions_in_this_file.each do |model_definition|
        suggested_singular_name = NameGrammar.suggested_singular_data_class_name(model_definition.full_name)
        next if suggested_singular_name.nil?

        add_finding(
          "AED-N5", "warn", model_definition.line,
          "data model `#{model_definition.full_name}` is plural; data models are singular and concerned with their own individual behavior",
          "e.g. `#{suggested_singular_name}`"
        )
      end
    end

    def check_other_data_class_names_are_singular
      known_data_models = model_definitions_in_this_file
      data_class_definitions_in_this_file.each do |data_class_definition|
        next if known_data_models.include?(data_class_definition)
        next if NameGrammar.collective_data_class_name?(data_class_definition.full_name)
        next if NameGrammar.all_caps_acronym?(data_class_definition.full_name)

        suggested_singular_name = NameGrammar.suggested_singular_data_class_name(data_class_definition.full_name)
        next if suggested_singular_name.nil?

        is_data_model = definition_looks_like_a_data_model?(data_class_definition)

        add_finding(
          "AED-N9", is_data_model ? "warn" : "info", data_class_definition.line,
          is_data_model ?
            "data class `#{data_class_definition.full_name}` has a plural head noun; data class names should be singular" :
            "class `#{data_class_definition.full_name}` has a plural head noun, but its source does not identify it as a data model",
          is_data_model ?
            "e.g. `#{suggested_singular_name}`" :
            "if this class represents one record, consider `#{suggested_singular_name}`; otherwise keep the plural name"
        )
      end
    end

    def definition_looks_like_a_data_model?(candidate_definition)
      return true if candidate_definition.kind == "struct"
      return true if language == :elixir && elixir_module_declares_a_struct?(candidate_definition)
      return true if definition_declares_data_fields?(candidate_definition)
      return true if definition_is_json_serializable?(candidate_definition)

      primary_definition_of_this_file == candidate_definition &&
        File.basename(display_path, File.extname(display_path)) ==
          NameGrammar.snake_case_of(NameGrammar.final_namespace_segment(candidate_definition.full_name))
    end

    def definition_declares_data_fields?(candidate_definition)
      source_lines_for_definition(candidate_definition).any? do |source_line|
        source_line =~ DATA_FIELD_DECLARATION_PATTERN
      end
    end

    def definition_is_json_serializable?(candidate_definition)
      source_lines_for_definition(candidate_definition).any? do |source_line|
        source_line =~ JSON_SERIALIZABLE_MARKER_PATTERN
      end
    end

    def source_lines_for_definition(candidate_definition)
      ending_line = candidate_definition.ending_line.to_i
      @list_of_source_lines[(candidate_definition.line - 1)...ending_line].to_a.map do |raw_source_line|
        strip_trailing_comment(raw_source_line)
      end
    end

    def data_class_definitions_in_this_file
      if language == :elixir
        @list_of_definitions.select do |definition|
          definition.kind == "defmodule" && elixir_module_declares_a_struct?(definition)
        end
      else
        @list_of_definitions.select { |definition| %w[class struct].include?(definition.kind) }
      end
    end

    def elixir_module_declares_a_struct?(candidate_module_definition)
      @list_of_source_lines.each_with_index.any? do |raw_source_line, zero_based_index|
        next false unless strip_trailing_comment(raw_source_line) =~ /\A\s*defstruct\b/

        innermost_definition_containing(zero_based_index + 1) == candidate_module_definition
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

      @list_of_source_lines.each_with_index do |raw_source_line, zero_based_index|
        source_line = strip_trailing_comment(raw_source_line)
        next unless source_line =~ /\A\s*(?:private\s+|protected\s+)?def\s+perform\s*\(\s*[^)\s]/

        line_number = zero_based_index + 1
        owning_definition = innermost_definition_containing(line_number)
        next unless owning_definition && %w[class struct].include?(owning_definition.kind)

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

      expected_primary_name = suggested_singular_data_class_name_for(primary_definition) ||
                              NameGrammar.final_namespace_segment(primary_definition.full_name)
      expected_file_base_name = NameGrammar.snake_case_of(expected_primary_name)
      actual_file_base_name = File.basename(display_path, File.extname(display_path))
      return if expected_file_base_name == actual_file_base_name

      if expected_primary_name != NameGrammar.final_namespace_segment(primary_definition.full_name)
        add_finding(
          "AED-N7", "info", primary_definition.line,
          "file is named `#{actual_file_base_name}` but its plural data class `#{primary_definition.full_name}` should be singular; the file name should match the suggested singular name",
          "rename the file to `#{expected_file_base_name}#{File.extname(display_path)}` to match `#{expected_primary_name}`"
        )
        return
      end

      add_finding(
        "AED-N7", "info", primary_definition.line,
        "file is named `#{actual_file_base_name}` but its primary definition is `#{primary_definition.full_name}`; the file name should be the lower snake case of the primary class",
        "rename the file to `#{expected_file_base_name}#{File.extname(display_path)}`"
      )
    end

    def check_primary_definition_is_stored_under_its_namespace_folders
      primary_definition = primary_definition_of_this_file
      return if primary_definition.nil?

      namespace_segments = NameGrammar.namespace_segments(primary_definition.full_name)
      return if namespace_segments.empty?

      project_details = project_details_for_file
      return if project_details.nil?
      return unless project_name_matches_namespace?(project_details[:namespace], namespace_segments.first)

      feature_namespace_segments = namespace_segments.drop(1).map do |namespace_segment|
        NameGrammar.snake_case_of(namespace_segment)
      end
      return if feature_namespace_segments.empty?

      root_namespace_folder = NameGrammar.snake_case_of(namespace_segments.first)
      actual_folder_segments = folders_relative_to_source_root(project_details[:root])
      expected_folder_sequences = [feature_namespace_segments, [root_namespace_folder] + feature_namespace_segments]
      namespace_folders_are_present = expected_folder_sequences.any? do |expected_folder_sequence|
        actual_folder_segments.each_cons(expected_folder_sequence.length).any? do |folder_sequence|
          folder_sequence == expected_folder_sequence
        end
      end
      return if namespace_folders_are_present

      namespace_path = feature_namespace_segments.join("/")
      add_finding(
        "AED-N11", "info", primary_definition.line,
        "project definition `#{primary_definition.full_name}` is not stored under its feature namespace folder `#{namespace_path}`",
        "place the file beneath `#{namespace_path}/` to match its namespace"
      )
    end

    def project_details_for_file
      absolute_file_path = File.expand_path(display_path)
      current_directory = File.dirname(absolute_file_path)

      loop do
        project_namespace = namespace_from_project_manifest(current_directory)
        return { root: current_directory, namespace: project_namespace } unless project_namespace.nil?

        parent_directory = File.dirname(current_directory)
        break if parent_directory == current_directory

        current_directory = parent_directory
      end

      source_path_segments = absolute_file_path.tr("\\", "/").split("/")
      source_root_index = source_path_segments.rindex { |path_segment| %w[src lib].include?(path_segment) }
      return nil if source_root_index.nil? || source_root_index >= source_path_segments.length - 2

      {
        root: source_path_segments[0..source_root_index].join(File::SEPARATOR),
        namespace: source_path_segments[source_root_index + 1]
      }
    end

    def namespace_from_project_manifest(project_directory)
      case language
      when :crystal
        read_match_from_file(File.join(project_directory, "shard.yml"), /^\s*name:\s*["']?([^\s"'#]+)["']?\s*$/)
      when :elixir
        read_match_from_file(File.join(project_directory, "mix.exs"), /\bapp:\s*:([A-Za-z0-9_]+)/)
      when :ruby
        gemspec_path = Dir.glob(File.join(project_directory, "*.gemspec")).first
        read_match_from_file(gemspec_path, /\b(?:spec|s)\.name\s*=\s*["']([^"']+)["']/)
      end
    end

    def read_match_from_file(file_path, pattern)
      return nil if file_path.nil? || !File.file?(file_path)

      File.read(file_path)[pattern, 1]
    rescue SystemCallError
      nil
    end

    def project_name_matches_namespace?(project_name, namespace_segment)
      normalize_project_name(project_name) == normalize_project_name(NameGrammar.snake_case_of(namespace_segment))
    end

    def normalize_project_name(project_name)
      project_name.to_s.downcase.tr("-", "_").gsub(/_+/, "_")
    end

    def folders_relative_to_source_root(project_root)
      absolute_file_path = File.expand_path(display_path).tr("\\", "/")
      absolute_project_root = File.expand_path(project_root).tr("\\", "/").sub(%r{/+\z}, "")
      return [] unless absolute_file_path.start_with?("#{absolute_project_root}/")

      relative_path_segments = absolute_file_path[(absolute_project_root.length + 1)..].split("/")
      actual_folder_segments = relative_path_segments[0...-1]
      source_root_index = actual_folder_segments.rindex { |path_segment| %w[src lib].include?(path_segment) }
      source_root_index ? actual_folder_segments[(source_root_index + 1)..] : actual_folder_segments
    end

    def method_owner_uses_an_external_namespace?(line_number)
      owning_definition = innermost_definition_containing(line_number)
      return false if owning_definition.nil?

      namespace_segments = NameGrammar.namespace_segments(owning_definition.full_name)
      return false if namespace_segments.empty?

      project_details = project_details_for_file
      return false if project_details.nil?

      !project_name_matches_namespace?(project_details[:namespace], namespace_segments.first)
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

    def suggested_singular_data_class_name_for(candidate_definition)
      is_data_class = model_definitions_in_this_file.include?(candidate_definition) ||
                      data_class_definitions_in_this_file.include?(candidate_definition)
      return nil unless is_data_class

      NameGrammar.suggested_singular_data_class_name(candidate_definition.full_name)
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
      return acceptable_verdict if NameGrammar.collective_data_class_name?(final_segment)
      return acceptable_verdict if NameGrammar.all_caps_acronym?(final_segment)

      suggested_singular_name = NameGrammar.suggested_singular_data_class_name(final_segment)
      if suggested_singular_name
        return rename_verdict(
          "data class names have a singular head noun (AED-N9)",
          "e.g. `#{suggested_singular_name}`"
        )
      end
      return acceptable_verdict if NameGrammar.framework_class_name?(final_segment)
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
      return acceptable_verdict if NameGrammar.action_method_name?(@candidate_name)
      return acceptable_verdict if NameGrammar.snake_case_tokens(@candidate_name).length >= 2
      return acceptable_verdict unless NameGrammar.vague_single_word_method?(@candidate_name)

      rename_verdict(
        "method names are phrases or statements that explain the process taking place (AED-N10)",
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

    # Claude Code supplies a file_path. Codex supplies apply_patch text or a
    # Bash command, so work out the changed paths from each harness's payload.
    # Hook findings are always advisory and always use Codex's additionalContext
    # envelope, which Claude Code also accepts.
    def run_the_post_tool_use_hook
      hook_event = JSON.parse(@standard_input.read.to_s)
      return 0 unless hook_event.is_a?(Hash)

      if hook_event["hook_event_name"] == "SessionStart"
        record_session_start(hook_event)
        return 0
      end

      working_directory = working_directory_for(hook_event)
      list_of_edited_file_paths = extract_edited_file_paths(hook_event, working_directory)
      list_of_findings_by_path = findings_for_edited_paths(list_of_edited_file_paths, working_directory)
      return 0 if list_of_findings_by_path.empty?

      additional_context = additional_context_for(list_of_findings_by_path)
      @standard_output.puts(JSON.generate(hook_payload_for(additional_context)))
      0
    rescue StandardError
      0
    end

    def hook_payload_for(additional_context)
      {
        "hookSpecificOutput" => {
          "hookEventName" => "PostToolUse",
          "additionalContext" => additional_context
        }
      }
    end

    def extract_edited_file_paths(hook_event, working_directory)
      tool_input = hook_event["tool_input"]
      return [] unless tool_input.is_a?(Hash)

      candidate_path = tool_input["file_path"] || tool_input["filePath"] || tool_input["path"]
      return [File.expand_path(candidate_path, working_directory)] if candidate_path.is_a?(String) && !candidate_path.empty?

      case hook_event["tool_name"].to_s
      when "apply_patch"
        file_paths_in_apply_patch(tool_input["command"], working_directory)
      when "Bash"
        git_dirty_source_files_changed_during_session(hook_event, working_directory)
      else
        []
      end
    end

    def file_paths_in_apply_patch(patch_text, working_directory)
      patch_text.to_s.lines.each_with_object([]) do |patch_line, list_of_file_paths|
        path_match = PATCH_PATH_PATTERN.match(patch_line)
        next unless path_match

        list_of_file_paths << File.expand_path(path_match[1].strip, working_directory)
      end.uniq
    end

    def git_dirty_source_files_changed_during_session(hook_event, working_directory)
      repository_root = git_root_for(working_directory)
      return [] if repository_root.nil?

      session_stamp = session_start_stamp_path(hook_event, working_directory)
      session_started_at = File.file?(session_stamp) ? File.mtime(session_stamp) : Time.now - 600
      git_status, status = Open3.capture2(
        "git", "-C", repository_root, "status", "--porcelain=v1", "-z", "-uall",
        err: File::NULL
      )
      return [] unless status.success?

      git_status.split("\0").each_with_object([]) do |status_record, list_of_file_paths|
        relative_path = status_record[3..-1].to_s
        next if relative_path.empty?

        absolute_path = File.expand_path(relative_path, repository_root)
        next unless in_scope?(absolute_path)
        next unless File.file?(absolute_path) && File.mtime(absolute_path) > session_started_at

        list_of_file_paths << absolute_path
      end.uniq
    rescue StandardError
      []
    end

    def git_root_for(working_directory)
      output, status = Open3.capture2(
        "git", "-C", working_directory, "rev-parse", "--show-toplevel",
        err: File::NULL
      )
      status.success? ? output.strip : nil
    rescue StandardError
      nil
    end

    def record_session_start(hook_event)
      FileUtils.mkdir_p(HOOK_STAMP_DIRECTORY)
      FileUtils.touch(session_start_stamp_path(hook_event, working_directory_for(hook_event)))
    end

    def session_start_stamp_path(hook_event, working_directory)
      session_id = hook_event["session_id"].to_s.gsub(/[^A-Za-z0-9_-]/, "")
      if session_id.empty?
        working_directory_digest = Digest::SHA256.hexdigest(working_directory)[0, 12]
        session_id = "unknown-#{working_directory_digest}"
      end

      File.join(HOOK_STAMP_DIRECTORY, "#{session_id}.stamp")
    end

    def working_directory_for(hook_event)
      candidate_directory = hook_event["cwd"].to_s
      candidate_directory.empty? ? Dir.pwd : File.expand_path(candidate_directory)
    end

    def findings_for_edited_paths(list_of_edited_file_paths, working_directory)
      list_of_edited_file_paths.each_with_object([]) do |edited_file_path, list_of_findings_by_path|
        absolute_path = File.expand_path(edited_file_path, working_directory)
        next unless in_scope?(absolute_path)
        next unless File.file?(absolute_path) && File.readable?(absolute_path)

        relative_path = relative_display_path(absolute_path, working_directory)
        list_of_findings = AnalyzeSourceFileForNamingFindings.new(relative_path, File.read(absolute_path)).perform
        list_of_findings_by_path << [relative_path, list_of_findings] unless list_of_findings.empty?
      end
    end

    def additional_context_for(list_of_findings_by_path)
      context_lines = []
      list_of_findings_by_path.each do |relative_path, list_of_findings|
        context_lines << "AED naming check on #{relative_path}:"
        context_lines.concat(list_of_findings.map(&:as_text_line))
      end
      context_lines << "These are advisory — the AED canon is at #{CANON_URL}"
      context_lines.join("\n")
    end

    def relative_display_path(absolute_or_relative_path, working_directory)
      absolute_path = File.expand_path(absolute_or_relative_path, working_directory)
      working_directory_prefix = "#{File.expand_path(working_directory)}#{File::SEPARATOR}"
      return absolute_path[working_directory_prefix.length..-1] if absolute_path.start_with?(working_directory_prefix)

      absolute_path
    end
  end
end

exit(AedLint::LintCommandLineInvocation.new(ARGV).perform) if $PROGRAM_NAME == __FILE__
