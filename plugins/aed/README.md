# AED plugin for Claude Code and Codex

**Agent-Enhanced Development (AED)** conventions, packaged as a Claude Code and
Codex plugin: release-quality naming from the pseudocode stage onward, process
managers derived from When-statements, and an advisory naming linter for Ruby,
Crystal, and Elixir. This file is self-contained — it does not assume you have
the rest of the [aed-conventions](https://github.com/AgentC-Consulting/aed-conventions)
repository checked out.

Plugin version: `0.2.1`.

## Install

| Claude Code | Codex CLI |
|---|---|
| `/plugin marketplace add https://github.com/AgentC-Consulting/aed-conventions.git#plugin-v0.2.1`<br>`/plugin install aed@aed-conventions` | `codex plugin marketplace add AgentC-Consulting/aed-conventions --ref <release commit hash>`<br>`codex plugin add aed@aed-conventions` |

Claude Code users can also ask Claude to install it:

```
Install the AED conventions plugin:
1. Run: claude plugin marketplace add https://github.com/AgentC-Consulting/aed-conventions.git#plugin-v0.2.1
2. Run: claude plugin install aed@aed-conventions
3. Confirm the aed:naming, aed:planning, and aed:process-managers skills are available,
   then give me one example of a boolean attribute name that passes AED naming.
```

Codex CLI has no plugin slash commands. The three matching workflows are
available as the `aed:check`, `aed:scaffold`, and `aed:adopt` skills; provide
paths or a When-statement in the request when needed.

**Requirements:** a harness version with plugin support and `ruby` on PATH for
the linter and edit-time hook. Codex hook definitions must be reviewed and
trusted before they run. Without Ruby, the skills still work; the hook no-ops.

## What you get

| Component | Claude Code | Codex | What it does |
|---|---|---|---|
| Skill | `aed:naming` | `aed:naming` | Applies the AED naming doctrine — `list_of_` collections, boolean-as-question, statement-style attributes and class names — while planning or editing code. |
| Skill | `aed:planning` | `aed:planning` | Brings AED's planning-stage discipline (feature stories, personas, operations, authorization levels) into how work is scoped before code is written. |
| Skill | `aed:process-managers` | `aed:process-managers` | The "when" grammar for deriving a process manager's shape — `initialize` inputs, `perform` steps — from a single When-statement. |
| Check workflow | `/aed:check [paths]` | `aed:check` skill | Runs the naming linter on the given paths or the project's changed files, then triages clear renames and judgment calls. |
| Scaffold workflow | `/aed:scaffold <When-statement>` | `aed:scaffold` skill | Scaffolds a process manager from a When-statement and verifies derived names before writing the file. |
| Adopt workflow | `/aed:adopt` | `aed:adopt` skill | Adds or updates an AED section in `AGENTS.md` or `CLAUDE.md`, keeping one canonical section for projects using both harnesses. |
| Edit hook | `PostToolUse` (Edit/Write/MultiEdit) | `PostToolUse` (apply_patch/Bash) | Lints Ruby, Crystal, and Elixir edits and returns advisory context. It never blocks. |

Claude Code reads its hook configuration from `hooks/hooks.json`. Codex reads
inline hooks from `.codex-plugin/plugin.json`: `SessionStart` records the
session timestamp, and `PostToolUse` extracts apply-patch paths or checks
Git-dirty source files modified since that timestamp after Bash commands.

## The linter CLI

`scripts/aed_lint.rb` is a standalone Ruby script with no dependencies beyond
the Ruby standard library. Run it directly from a repository checkout:

```
# Lint one or more files or directories
ruby plugins/aed/scripts/aed_lint.rb [--format text|json] [--strict] <files-or-dirs>

# Check a candidate name before you use it
ruby plugins/aed/scripts/aed_lint.rb check-name --kind boolean|collection|attribute|class|method <name>

# Read a PostToolUse hook payload from stdin
ruby plugins/aed/scripts/aed_lint.rb --hook
```

Plural data-model and data-struct names are checked in Ruby, Crystal, and
Elixir. AED-N5 handles ORM/Ecto models. AED-N9 warns for non-ORM classes with
data evidence such as a struct, property/field declaration, or
`JSON::Serializable`; an unannotated primary class named `Orders` in `orders.rb`
also qualifies. Other plural class candidates are informational. It exempts
configuration and aggregate names such as `Settings`, `SMTPSettings`, `Options`,
`Params`, `Metrics`, `QueryStats`,
`Errors`, `Filters`, `Styles`, `SecurityHeaders`, `Connections`,
`BatchOperations`, `Credentials`, and `Preferences`; all-caps acronyms such as
`CORS` are not singularized. Singular words such as `Status`, `Address`,
`Business`, `Analysis`, `News`, and `Series` stay unflagged.

AED-N10 is conservative: it gives an informational finding for parameterized
`process`, `retry`, `handle`, or `manage` methods, while standard protocol,
collection, query, accessor, and framework-hook names keep their established
spelling. AED-N11 checks explicitly namespaced primary definitions only when the
root namespace matches the project name from `shard.yml`, `mix.exs`, a gemspec,
or a top-level folder under `src`/`lib`; reopened dependency namespaces such as
`HTTP::Request` are ignored. A Crystal project root segment can be omitted from
the source path, so `Grant::Adapter::Base` in `src/adapter/base.cr` is accepted.

In Claude Code's plugin command and hook context, the script path is
`${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb`. Codex hook commands receive
`${PLUGIN_ROOT}/scripts/aed_lint.rb`.

The `--hook` adapter accepts Claude Code's `tool_input.file_path`, Codex's
`tool_name: "apply_patch"` with patch paths in `tool_input.command`, and
Codex's `tool_name: "Bash"` with changed paths discovered from Git status. It
prints the Codex and Claude-compatible `hookSpecificOutput.additionalContext`
envelope and always exits 0. If Bash edits run outside a Git working tree, the
hook cannot infer their paths; apply-patch paths are available directly.

`--strict` turns advisory findings into failures for direct CLI use. Hook mode
always remains non-blocking. `--format json` gives machine-parseable findings.

## Advisory by design

Nothing in this plugin fails a build or blocks an edit. The hook, workflows,
and `check-name` report findings; applying them is a judgment call made by the
developer or agent. This mirrors the canon's own posture — AED is a convention
to reach for consistently, not a linter that can veto a commit.

## The canon behind this plugin

This plugin packages a slice of a larger, actively evolving set of written
conventions — the naming doctrine, process managers, feature stories, control
flow, and the reasoning behind all of it. Read the full canon, see what's
settled versus still a release candidate, and find every place it's published
(including a single-file bundle for pasting into any context window):

<https://github.com/AgentC-Consulting/aed-conventions>

## License

Prose and documentation in this plugin (this README, `SKILL.md` files,
command bodies, and workflow sources) are CC BY 4.0, matching the parent
repository. The linter script (`scripts/aed_lint.rb`) is MIT-licensed code.
See the parent repository's `LICENSE` and `LICENSE-EXAMPLES` for the full
terms.
