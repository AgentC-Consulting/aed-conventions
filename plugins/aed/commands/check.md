---
description: Run the AED naming linter on given paths (or changed files) and triage findings
---

Run the AED naming linter and triage what it finds. This is advisory, not a
gate — the linter never blocks, and neither should you.

1. Determine the target paths:
   - If `$ARGUMENTS` is non-empty, use it as the list of paths to lint.
   - Otherwise, derive the target files from the current git state: run
     `git status --porcelain` and `git diff --name-only` (and
     `git diff --cached --name-only`) in the project root, union the results,
     and lint those paths. If there is no git repo or nothing has changed,
     say so and stop.

2. Run the linter against the resolved paths:
   ```
   ruby "${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb" <paths>
   ```
   Use `--format json` if you need to parse results programmatically;
   otherwise the default text output is fine to read directly.

3. Triage every finding:
   - **Clear renames** — cases where the AED-preferred name is unambiguous
     (e.g. a boolean attribute not phrased as a question, a collection
     missing its `list_of_`/`collection_of_`/`array_of_` prefix) — apply the
     rename directly with Edit, updating every reference to the old name in
     the same pass so nothing is left broken.
   - **Judgment calls** — anything where more than one AED-consistent name is
     plausible, or where renaming would touch a public API / cross many
     files — do not rename automatically. List each one with the current
     name, the finding, and your recommended name, and let the user decide.

4. Report a short summary: how many files were linted, how many findings,
   how many renamed automatically, how many left as judgment calls.

If `ruby` is not on PATH, say so plainly and stop — do not attempt to
reimplement the linter's rules by hand.
