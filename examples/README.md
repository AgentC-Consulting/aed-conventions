# Examples — before/after, one rule cluster per file

Each file shows the shorthand form (BEFORE, commented out — some deliberately
do not compile, that is part of the point) and the AED form (AFTER, live code)
for one rule from [../CONVENTIONS.md](../CONVENTIONS.md).

| File | Rule | The move |
|---|---|---|
| [01_branch_on_type.cr](01_branch_on_type.cr) | Rule 1 | `case … in` / dot-riddle `case` → explicit `if … is_a?` |
| [02_name_the_thing.cr](02_name_the_thing.cr) | Rule 2 | decoded chain → named intermediate |
| [03_guard_clauses.cr](03_guard_clauses.cr) | Rule 3 | nested ternary → guard clauses |
| [04_reader_first_names_and_comments.cr](04_reader_first_names_and_comments.cr) | Rules 4 + 5 | cryptic names / what-comments → intention-revealing names / why-comments |

The test applied throughout: **does a reader who has never seen this code
understand the intent on first pass?** If they must mentally execute it, expand it.
