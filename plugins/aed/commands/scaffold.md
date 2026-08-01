---
description: Scaffold a process manager from a When-statement
---

Scaffold a process manager from a When-statement, using the `aed:process-managers` skill.

1. If `$ARGUMENTS` is non-empty, treat it as the When-statement. Otherwise ask
   the user for one before doing anything else — a process manager cannot be
   scaffolded without it. A well-formed statement always starts with "when"
   (see chapter 03 of the AED canon): it names the qualifying information the
   process needs, and the operation(s) it performs once that information is
   available.

2. Invoke the `aed:process-managers` skill and follow it to derive the
   process manager's shape from the When-statement: the class name (a short
   statement or phrase describing the process, namespaced to its feature),
   the `initialize` parameters (the qualifying information from the
   "when" clause, named and typed), and the `perform` method's steps (the
   operations from the "then" clause, each broken into a private method
   read like pseudocode).

3. Infer the target language from the project (check for a `Gemfile` →
   Ruby, `shard.yml` → Crystal, `mix.exs` → Elixir; ask if none of these are
   present) and write the process manager in that language's idiom, following
   the file/folder conventions at
   https://github.com/AgentC-Consulting/aed-conventions/blob/main/quick_reference.md
   (snake_case filename matching the class name, namespaced classes live in a
   folder named for the namespace).

4. Before writing the file, verify every derived name — the class name, the
   `initialize` parameters, the private method names — against the linter:
   ```
   ruby "${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb" check-name --kind class <ClassName>
   ruby "${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb" check-name --kind attribute <param_name>
   ruby "${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb" check-name --kind method <method_name>
   ```
   (use `--kind boolean` or `--kind collection` where the name is a boolean
   or a list/array attribute). Revise any name the linter flags before it
   ever lands in the file — verify, then write, never the other way round.

5. Write the file at its snake_case path and report what you created: the
   file path, the class name, and a one-line summary of what `perform` does.

If `ruby` is not on PATH, say so, skip the `check-name` verification step,
and flag in your summary that names were not linter-verified.
