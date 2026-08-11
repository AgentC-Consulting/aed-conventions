---
description: Add or update an "AED conventions" section in this project's CLAUDE.md
---

Add an "AED conventions" section to this project's `CLAUDE.md`, creating the
file if it does not exist yet. This command is idempotent: if the section
already exists, update it in place rather than adding a duplicate.

1. Look for `CLAUDE.md` in the project root. If it doesn't exist, create it
   with a top-level `# CLAUDE.md` heading before adding the section below.

2. Search the file for a section heading matching `## AED conventions`
   (case-insensitive). If found, replace the full section (from that heading
   up to, but not including, the next `##` heading or end of file) with the
   text below. If not found, append the section text below to the end of the
   file.

3. Section text to write:

   ```
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
     performed, namespaced to their feature (`Billing::LockDelinquentCustomerAccounts`).
   - Process managers are named from a "when"-statement and expose a single
     `perform` entry point that reads like pseudocode.

   Check candidate names with the `aed` plugin's linter: run `/aed:check`,
   or `ruby <path-to-aed-plugin>/scripts/aed_lint.rb check-name --kind attribute first_name`.

   The `aed:naming` and `aed:planning` skills apply these rules automatically
   during planning and edits; the `aed:process-managers` skill is available
   for `/aed:scaffold`.
   ```

4. Report what changed: whether the section was added or updated, and the
   `CLAUDE.md` path.
