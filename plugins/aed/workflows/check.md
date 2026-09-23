Run the AED naming linter on explicit paths or the project's changed source
files, then triage its findings. This is advisory; the linter never blocks and
neither should you.

1. If command arguments or the user's request include paths, lint those paths.
   Otherwise, in the project root, union the paths from `git status
   --porcelain --untracked-files=all`, `git diff --name-only`, and `git diff
   --cached --name-only`. If Git is unavailable or no paths changed, say so and
   stop.

2. Run the installed plugin's `scripts/aed_lint.rb` with Ruby on the resolved
   paths. In Claude Code, use
   `ruby "${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb" <paths>`. In Codex,
   resolve the installed plugin copy, then run it:

   ```bash
   aed_lint_script="$(find "${CODEX_HOME:-$HOME/.codex}/plugins/cache" -type f -path '*/aed/*/scripts/aed_lint.rb' -print -quit)"
   ruby "$aed_lint_script" <paths>
   ```

   Use `--format json` only when you need to parse the results programmatically.

3. Triage every finding:
   - **Clear renames:** If the AED-preferred name is unambiguous, such as a
     boolean that does not read as a question or a collection missing its
     prefix, apply the rename and update every reference in the same pass.
   - **Judgment calls:** If several AED-consistent names are plausible, or a
     rename would affect a public API or many files, do not rename it
     automatically. Report the current name, finding, and recommended name.

4. Report how many files were linted, how many findings were returned, how
   many names were renamed, and how many findings remain as judgment calls.

If Ruby is unavailable, say so and stop. Do not reimplement the linter's rules
by hand.
