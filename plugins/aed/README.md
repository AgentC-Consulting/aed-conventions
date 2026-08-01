# AED plugin for Claude Code

**Agent-Enhanced Development (AED)** conventions, packaged as a Claude Code
plugin: release-quality naming from the pseudocode stage onward, process
managers derived from When-statements, and an advisory naming linter for
Ruby, Crystal, and Elixir. This file is self-contained — it does not assume
you have the rest of the [aed-conventions](https://github.com/AgentC-Consulting/aed-conventions)
repository checked out.

## Install the AED plugin (Claude Code)

In any Claude Code session:

```
/plugin marketplace add AgentC-Consulting/aed-conventions
/plugin install aed@aed-conventions
```

Or paste this into a session and let Claude drive the install:

```
Install the AED conventions plugin:
1. Run: claude plugin marketplace add AgentC-Consulting/aed-conventions
2. Run: claude plugin install aed@aed-conventions
3. Confirm the aed:naming, aed:planning, and aed:process-managers skills are available,
   then give me one example of a boolean attribute name that passes AED naming.
```

**Requirements:** Claude Code with plugin support; `ruby` on PATH for the
linter and the edit-time hook (macOS and most Linux distros have it out of
the box). Without `ruby`, the skills still work — only the linter-backed
command steps and the hook no-op.

## What you get

| Component | Name | What it does |
|---|---|---|
| Skill | `aed:naming` | Applies the AED naming doctrine — `list_of_` collections, boolean-as-question, statement-style attributes and class names — while planning or editing code. |
| Skill | `aed:planning` | Brings AED's planning-stage discipline (feature stories, personas, operations, authorization levels) into how work is scoped before code is written. |
| Skill | `aed:process-managers` | The "when" grammar for deriving a process manager's shape — `initialize` inputs, `perform` steps — from a single When-statement. |
| Command | `/aed:check [paths]` | Runs the naming linter on the given paths, or on your currently changed files if none are given, and triages findings: applies clear renames, lists judgment calls with recommendations. |
| Command | `/aed:scaffold <When-statement>` | Scaffolds a new process manager from a When-statement, verifying every derived name with the linter before writing the file. |
| Command | `/aed:adopt` | Adds (or updates) an "AED conventions" section in the current project's `CLAUDE.md`, idempotently. |
| Hook | `PostToolUse` (Edit/Write/MultiEdit) | Runs the linter in `--hook` mode after every edit to a Ruby, Crystal, or Elixir file and surfaces naming issues as advisory context. Never blocks; no-ops (exit 0) on any other file type or if `ruby` is missing. |

## The linter CLI

`scripts/aed_lint.rb` is a standalone Ruby script with no
dependencies beyond the Ruby standard library. The plugin's commands and hook
invoke it via `${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb`; you can also run it
directly:

```
# Lint one or more files/directories
ruby scripts/aed_lint.rb [--format text|json] [--strict] <files-or-dirs>

# Check a single candidate name before you use it
ruby scripts/aed_lint.rb check-name --kind boolean|collection|attribute|class|method <name>

# PostToolUse hook mode: reads a tool-call JSON payload on stdin,
# writes an advisory `additionalContext` JSON object to stdout, always exits 0
ruby scripts/aed_lint.rb --hook
```

`--strict` turns advisory findings into failures (useful for a CI gate);
without it, the linter always exits 0 — it informs, it does not block.
`--format json` gives you machine-parseable findings for scripting your own
checks around it.

## Advisory by design

Nothing in this plugin fails a build or blocks an edit. The hook, the
commands, and `check-name` all report findings; applying them is always a
judgment call made by you or by the agent acting on your behalf. This mirrors
the canon's own posture — AED is a convention to reach for consistently, not
a linter that can veto a commit.

## The canon behind this plugin

This plugin packages a slice of a larger, actively-evolving set of written
conventions — the naming doctrine, process managers, feature stories, control
flow, and the reasoning behind all of it. Read the full canon, see what's
settled versus still a release candidate, and find every place it's
published (including a single-file bundle for pasting into any context
window):

<https://github.com/AgentC-Consulting/aed-conventions>

## License

Prose and documentation in this plugin (this README, `SKILL.md` files,
command bodies) are CC BY 4.0, matching the parent repository. The linter
script (`scripts/aed_lint.rb`) is MIT-licensed code. See the parent
repository's `LICENSE` and `LICENSE-EXAMPLES` for the full terms.
