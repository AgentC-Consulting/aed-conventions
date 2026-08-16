# The pet-tracker build-off — AED at codebase scale (2026-08-11)

The [Haiku comprehension benchmark](../haiku_comprehension_report.md) ended with an
honest gap: snippet-scale results say nothing about codebase scale. This experiment is
that missing piece, sized as a demonstration, published so you can rerun it.

## Question

Does a small, fast model (Claude Haiku) do better real work in a codebase that has
adopted AED (statement-shaped names + the conventions in CLAUDE.md + the advisory
naming hook) than in the same codebase without it?

## Method

- **Codebase:** [premium-agentc-app-template](https://github.com/AgentC-Consulting/premium-agentc-app-template),
  our open-source Crystal/Amber template.
  - **Arm "before":** branch [`aed-before`](https://github.com/AgentC-Consulting/premium-agentc-app-template/tree/aed-before)
    (commit `5eef172`) — the template before AED adoption. Terse names, no AED section
    in CLAUDE.md, AED plugin disabled.
  - **Arm "after":** `main` at `699a528` — identical code after the renames-only AED
    burn-down (PR #25: 243 warns → 0, specs 1021/1021 green and byte-identical to the
    pre-rename baseline), plus the CLAUDE.md AED section and the advisory naming hook
    (aed plugin v0.1.2). **The arms differ by the whole AED bundle, not names alone.**
- **Task** (identical, [pet_tracker_task.md](pet_tracker_task.md)): build a pet tracker — Grant
  model, migration file, 7-action RESTful controller, routes, component-based index +
  form views, no auth — following the codebase's existing patterns, finishing with the
  whole app type-checking clean.
- **Agents:** fresh headless Claude Haiku (`claude -p`), no prior context, full
  autonomy, two independent runs per arm, one machine, same day.
  Runner: [run_experiment_arm.rb](run_experiment_arm.rb).
- **Grading:** every run's uncommitted diff was scored by an adversarial reviewer (a
  larger model, identical rubric, harsh, with framework behavior claims verified
  against the framework source — e.g. it proved this Amber ignores `_method` fields
  by reading the router). Full verdicts: [judge_report.md](judge_report.md).

## Results

| | before #1 | before #2 | after #1 | after #2 |
|---|---|---|---|---|
| Agent cost (USD) | 0.50 | 0.38 | 0.61 | 0.64 |
| Agent turns | 41 | 33 | 59 | 52 |
| Output tokens | 13,951 | 12,777 | 13,003 | 16,026 |
| Cache-read tokens | 2.84M | 1.92M | 3.84M | 4.00M |
| Final type-check | green | green | green | green |
| **Working user journeys (of 5)** | **0** | **0** | **2** | **4** |
| Index lists pets | silently empty | 500s | works | works |
| JSON serialization correct | no | no | yes | yes |
| Flash convention correct | no | no | yes | yes |
| Real design-system CSS classes | no | no | no | yes |
| Judge: completeness / conformance | 5 / 5 | 4 / 4 | 6 / 6 | 8 / 8 |
| Major defects | 4 | 2 | 3 | 2 |

Exact per-run detail is in the `exp_*.metrics.json` files. Note the shape of the cost
difference: output tokens are nearly flat across arms (after #1 wrote fewer tokens
than before #1); the after arm's extra cost is context re-reading across more turns,
part of which is the advisory hook feeding naming feedback after every edit.

**The terse arm was cheaper and shipped nothing that worked, twice.** Both before-runs
independently wrote the same data-corrupting serialization
(`pets.map(&.to_json).to_json`), omitted CSRF from every form, and styled pages with
CSS classes that do not exist in the repo. Neither after-run made the serialization
mistake; after #2 was the only run of four whose forms carried CSRF and whose markup
used the design system that actually ships in the repo.

**What did not improve:** both after-runs assumed Rails-style `_method` form
tunneling, which this Amber does not implement — an unwritten framework fact no
naming convention can carry. It is now written
(premium-agentc-app-template PR #26), which is the loop working as intended.

**The invariant across all four runs:** no agent executed a single write path; all
shipped on the compiler's word. Conventions narrowed the gap between "type-checks"
and "works"; only running the software closes it.

## Caveats (read these as part of the result)

Two runs per arm, one task, one codebase, one model, one machine: a demonstration,
not a study. Arms bundle names + instructions + tooling. Wall-clock times are not
comparable (one run was inflated by API latency). Token counts favor the terse arm
and are published unspun. To rerun: check out either branch, install the plugin (or
don't), and pipe `pet_tracker_task.md` through the runner.
