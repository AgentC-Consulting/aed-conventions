Scaffold a process manager from a "When … then …" statement, using the AED
process-manager workflow.

1. Treat the When-statement supplied in the command arguments or user request
   as the input. If none is present, ask for one before continuing. A
   well-formed statement starts with "when" and names the qualifying
   information and the operation or operations that follow.

2. Derive the process manager's shape from that statement:
   - Name the class for the whole process, within its feature namespace.
   - Put all qualifying information from the "when" clause in the initializer,
     with named and typed parameters.
   - Turn each operation in the "then" clause into a private method named as a
     clear statement.
   - Make `perform` take no arguments and call the step methods in order,
     reading like pseudocode.

3. Infer the language from the project (`Gemfile` for Ruby, `shard.yml` for
   Crystal, or `mix.exs` for Elixir). Ask which language to use if the project
   does not make it clear. Follow the host language's style and the AED file
   rules: a snake_case filename matching the class, with namespaced classes in
   a folder named for the namespace.

4. Before writing the file, verify the class name, initializer parameters,
   and private method names with the installed plugin's
   `scripts/aed_lint.rb check-name`. Check boolean and collection names with
   their matching linter kinds. In Claude Code, run the script through
   `${CLAUDE_PLUGIN_ROOT}`. In Codex, resolve and run the installed copy:

   ```bash
   aed_lint_script="$(find "${CODEX_HOME:-$HOME/.codex}/plugins/cache" -type f -path '*/aed/*/scripts/aed_lint.rb' -print -quit)"
   ruby "$aed_lint_script" check-name --kind class <ClassName>
   ```

   Revise every rejected name before it lands in the file.

5. Write the file at its derived path and report the path, class name, and a
   one-line summary of what `perform` does.

If Ruby is unavailable, say so, skip linter verification, and state that the
names were not linter-verified.
