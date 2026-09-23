Add or update the project's AED conventions section in its agent instructions.
Keep one canonical section when the project uses both Codex and Claude Code.

1. Identify the project root and check for `AGENTS.md` and `CLAUDE.md`. Choose
   `AGENTS.md` as the canonical file when Codex is active, when `AGENTS.md`
   already exists, or when `CLAUDE.md` imports `AGENTS.md`. Otherwise, use
   `CLAUDE.md` for a Claude Code-only project.

2. Make the chosen file available to both harnesses:
   - If `AGENTS.md` is canonical and Claude Code is in use or `CLAUDE.md`
     exists, make sure `CLAUDE.md` contains the import line `@AGENTS.md`.
     Create `CLAUDE.md` with a short heading and that import line if needed.
   - If `AGENTS.md` is canonical and `CLAUDE.md` has its own AED conventions
     section, remove that duplicate section so the shared text lives only in
     `AGENTS.md`.
   - If `CLAUDE.md` is canonical, create it with a `# CLAUDE.md` heading if
     needed.

3. In the canonical file, find a heading matching `## AED conventions`,
   case-insensitively. Replace that section through the next `##` heading or
   end of file. If no section exists, append the text below. Preserve the rest
   of each instructions file.

   ```markdown
   ## AED conventions

   This project follows Agent-Enhanced Development (AED) conventions —
   canon: https://github.com/AgentC-Consulting/aed-conventions

   Name rules summary:
   - Attributes of primitive types are short statements of intent
     (`first_name`, not `name`).
   - Collection attributes are prefixed `list_of_` / `collection_of_` /
     `array_of_` (`list_of_previous_orders`, not `orders`).
   - Boolean attributes read as a question (`has_a_valid_payment_method`,
     not `payment_method_present`).
   - Class names are short statements or phrases describing the process
     performed, namespaced to their feature
     (`Billing::LockDelinquentCustomerAccounts`).
   - Process managers are named from a "when"-statement and expose a single
     `perform` entry point that reads like pseudocode.

   Check candidate names with the AED `check` workflow, or run the bundled
   `aed_lint.rb check-name` command with Ruby. The `naming` and `planning`
   workflows apply these rules while planning and editing; use `scaffold` for
   process-manager scaffolding.
   ```

4. Report whether the section was added or updated, which file is canonical,
   and whether Claude Code imports `AGENTS.md`.
