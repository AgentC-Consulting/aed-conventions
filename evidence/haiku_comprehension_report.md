# AED vs Conventional Crystal — Small-Model Comprehension Benchmark

**Date**: 2026-07-07
**Answering model**: Claude Haiku
**Raw data**: [`evidence/benchmark_data.json`](./benchmark_data.json) (full source of every pair variant + per-probe scores)
**Conventions under test**: `.claude/skills/aed-conventions/SKILL.md` ("reads like statements")

---

## Verdict (read this first, including the caveats)

In this run, AED-style Crystal scored **60/60** and conventional compressed
style scored **54/60** when Claude Haiku answered comprehension probes blind
and a blind grader scored the answers. AED never lost a probe; conventional
lost points on 3 of 10 pairs, concentrated in **defect-finding** (16/20) and
**intent** (18/20) probes, while **modification** probes tied (20/20 each).

What this run **does** establish: on these 10 snippet-scale pairs, one small
Claude model, one attempt each, the AED variant never performed worse and
performed better exactly where the hypothesis predicts — understanding *why*
code exists and spotting subtle behavioral edges, not mechanical edits.

What this run **does not** establish: that AED helps at codebase scale, that
the effect survives repeated sampling (single run, no variance estimate), that
it generalizes beyond Haiku or beyond the Claude family, that a human grader
would agree with the model grader, or that the gain comes from AED's *syntax
rules* specifically rather than the whole AED bundle (expanded control flow +
intent-bearing names + intent comments travel together in the AED variants).
A 6-point gap on n=10 with 7 ceiling ties is a **directional signal
consistent with the hypothesis, not proof of it**.

---

## Hypothesis

AED-style Crystal ("reads like statements", per the premium template's
`aed-conventions` skill) lets **smaller** models reason about and understand
code intent better than conventional compressed style. The theory: compressed
syntax (dense `case … in` ladders, ternaries inside `when` arms, single-letter
locals, chained expressions) forces a re-parse that big models absorb but
small models pay for.

## Method

- **10 pairs** of Crystal snippets (15–45 lines each), one AED variant and one
  conventional variant per pair, covering auth, scoring, state machines,
  storage, rate limiting, retries, validation, RBAC, rendering, and queue
  triage (full list in the appendix).
- **Semantic equivalence enforced**: both variants of each pair were run
  through a differential-test harness (shared checks, outputs diffed) so the
  probes measure *style*, not behavior differences.
- **3 probes per variant**, same probes for both variants of a pair:
  1. **Intent** — explain what the code does and why (business intent).
  2. **Modification** — describe how to make a specified behavior change.
  3. **Defect** — a subtle edge-case/behavioral question.
- **Blind answering**: Claude Haiku saw one variant at a time and was never
  told a style comparison was happening.
- **Blind grading**: a model grader scored each answer 0/1/2 (wrong / partial /
  fully correct) without seeing which style produced the code or the answer.
  Max 6 points per variant per pair, 60 per style overall.

**Honest limits of the method, stated up front**: n=10 pairs; **one** small
model; **single run** per probe (no repeats, so no variance estimate); the
grader is **also a model**, so grader error or grader style-affinity is
uncorrected; and the pairs were authored by the same party that authored the
conventions.

## Results

### Aggregate

| Style | Total | Max |
|---|---:|---:|
| **AED** | **60** | 60 |
| Conventional | 54 | 60 |

### Per probe type (computed from the per-run data)

| Probe type | AED | Conventional | Gap |
|---|---:|---:|---:|
| Intent | 20/20 | 18/20 | +2 |
| Modification | 20/20 | 20/20 | 0 |
| Defect | 20/20 | 16/20 | **+4** |

The gap lives almost entirely in **defect probes** (two outright zeros for
conventional) and partially in **intent probes** (two partial credits).
**Modification probes showed no difference at all** — when Haiku is told
exactly what change to make, compressed style did not slow it down. The style
seems to matter when the model must *infer* purpose or *notice* an edge case,
not when it is executing instructions. That is precisely the split the
hypothesis predicts, which is encouraging — and also exactly what a
motivated benchmark author would produce, which is why replication matters.

### Per pair

| Pair | AED | Conventional | Δ |
|---|---:|---:|---:|
| p3 document-workflow (state machine) | 6 | 3 | **+3** |
| p10 mail-queue-triage (stale-lock reclaim) | 6 | 4 | **+2** |
| p7 inquiry-validation (collect-all-errors) | 6 | 5 | +1 |
| the other 7 pairs | 6 | 6 | 0 |

## The most instructive contrasts

**Where AED helped most — p3, the document review state machine (6 vs 3).**
The conventional variant expresses the whole workflow as a `case … in` ladder
with dot-shorthand predicates (`in .draft? then [Status::InReview]`) and no
comment. Haiku scored only partial credit on intent and **zero on the defect
probe**. The AED variant spells out the same transitions as an `if/elsif`
chain under a comment stating the review flow ("a rejected document returns
to draft… archived is terminal"). This is the single strongest data point for
the conventions' Rule 1 territory: compressed exhaustive-match syntax is
exactly where the small model lost the thread of *policy*.

**Where AED helped — p10, outbound-mail queue triage (6 vs 4).** The
conventional variant packs each `when` arm with a ternary
(`scheduled_at <= now ? :deliver : :not_due_yet`) and inlines the stale-lock
math; Haiku scored **zero on the defect probe**. The AED variant hoists the
same logic into named predicates (`due_for_delivery?`, `lock_gone_stale?`)
with a comment explaining that a stale lock means a crashed worker. Notably
this is the pattern the control-flow proposal targets (ternaries inside
branch arms; nil-guard ternaries like `locked_at ? … : false`).

**Where AED helped a little — p7, inquiry validation (6 vs 5).** Conventional
uses single-letter locals (`e` for the error array, `m` for message length)
and postfix conditionals; Haiku dropped to partial credit on the *intent*
probe only. Mild evidence that naming, not control flow, was the friction
here.

**Where AED did not help — the other seven pairs (ties at 6/6).** Auth/MFA
routing, lead scoring, safe delete, rate limiting, retry backoff, RBAC
policy, and badge rendering were all answered perfectly in both styles.
Reading those conventional variants, they are compressed but short and
single-purpose; Haiku handled them fine. **AED never hurt** in this run —
there is no pair where the AED variant scored lower — but on 70% of pairs it
also bought nothing measurable, because the test was too easy. The
discriminating pairs were the ones with *branchy policy logic* (state
machine, queue triage), which is consistent with the census in
`AED_CONTROL_FLOW_PROPOSAL.md` showing control flow is where the real
codebase's complexity lives.

## Threats to validity

1. **Small n, single run.** 10 pairs, 30 probes per style, one sample per
   probe. Model outputs are stochastic; a 6-point gap could shrink (or grow)
   under repeated sampling. No confidence interval is possible from one run.
2. **Ceiling effect.** 7 of 10 pairs tied at the maximum. The instrument was
   too easy for most pairs, so the aggregate compresses toward a tie and the
   signal rests on 3 pairs. Harder probes would give a more sensitive read.
3. **One model, one family.** Only Claude Haiku answered. Other small models
   (and non-Claude families) may parse compressed Crystal differently.
4. **Model-graded.** The grader is a model. It graded blind to style, but it
   can still systematically prefer answers that echo intent-comment phrasing
   — which AED variants contain and conventional variants do not.
5. **Style bundle confound.** The AED variants differ from conventional in
   *several* ways at once: expanded control flow, named predicates, AND
   intent-bearing comments (e.g. p3's workflow comment exists only in the AED
   variant). This run cannot attribute the gap to syntax rules specifically;
   the comments alone might explain the intent-probe gap. An ablation is
   needed.
6. **Length/token asymmetry.** AED variants are consistently longer (e.g.
   p10: 38 vs 21 lines). More tokens restating the logic may itself aid a
   small model, independent of *how* the code reads.
7. **Author bias.** Pairs, probes, and both variants were authored inside the
   AgentC ecosystem by the conventions' proponents. Even in good faith, pair
   selection and probe design can tilt toward AED's strengths.
8. **Snippet scale.** 15–45-line snippets are not a codebase. AED's costs
   (more lines to read per function, more scrolling) and benefits may both
   scale differently across files and call graphs.

## What to test next

1. **Larger n with repeats**: 30–50 pairs, 3–5 samples per probe, report
   variance and a paired significance test rather than a single tally.
2. **Harder probes**: calibrate so the conventional baseline lands near
   50–70%, eliminating the ceiling that muted 7 of 10 pairs.
3. **More models, including non-Claude**: at minimum another Claude tier plus
   two non-Claude small models, to separate "AED helps small models" from
   "AED helps Haiku".
4. **Human graders** on a subsample (or full set) to validate the model
   grader; report agreement.
5. **Ablations to break the bundle**: comments-only, naming-only, and
   control-flow-only variants, so the conventions' individual rules earn
   their keep separately.
6. **The control-flow proposal's new rules, once adopted**: p3 and p10 — the
   two biggest gaps — are precisely `case` ladders and ternary-in-branch
   patterns that `AED_CONTROL_FLOW_PROPOSAL.md` addresses. Re-run with pairs
   written to the new rules to test whether they capture the effect.
7. **Codebase-scale tasks**: multi-file comprehension and real modification
   tasks in the template itself, not snippets, to test the claim where it
   actually matters.

---

## Appendix A — Full scored table

Probe order: intent, modification, defect. Each probe scored 0–2.

| Pair | Topic | Variant | Intent | Modification | Defect | Total |
|---|---|---|---:|---:|---:|---:|
| p1-auth-mfa-routing | auth/session — post-password MFA routing and pending-challenge TTL | aed | 2 | 2 | 2 | 6 |
| p1-auth-mfa-routing | | conventional | 2 | 2 | 2 | 6 |
| p2-lead-scoring | lead scoring — email-domain classification plus message-effort bonus | aed | 2 | 2 | 2 | 6 |
| p2-lead-scoring | | conventional | 2 | 2 | 2 | 6 |
| p3-document-workflow | state transitions — document review workflow state machine | aed | 2 | 2 | 2 | 6 |
| p3-document-workflow | | conventional | 1 | 2 | 0 | 3 |
| p4-storage-safe-delete | file/storage — path-safe delete with metadata sidecar | aed | 2 | 2 | 2 | 6 |
| p4-storage-safe-delete | | conventional | 2 | 2 | 2 | 6 |
| p5-rate-limiter | rate limiting — sliding-window per-IP submission ceiling | aed | 2 | 2 | 2 | 6 |
| p5-rate-limiter | | conventional | 2 | 2 | 2 | 6 |
| p6-retry-backoff | background scheduling — exponential retry backoff with dead-letter cutoff | aed | 2 | 2 | 2 | 6 |
| p6-retry-backoff | | conventional | 2 | 2 | 2 | 6 |
| p7-inquiry-validation | validation — collect-all-errors form validation for inquiry submissions | aed | 2 | 2 | 2 | 6 |
| p7-inquiry-validation | | conventional | 1 | 2 | 2 | 5 |
| p8-rbac-document-policy | RBAC — admin/owner bypass plus org-role gated document actions | aed | 2 | 2 | 2 | 6 |
| p8-rbac-document-policy | | conventional | 2 | 2 | 2 | 6 |
| p9-lead-badge-rendering | ECR-adjacent rendering — score-tier badge HTML with escaping | aed | 2 | 2 | 2 | 6 |
| p9-lead-badge-rendering | | conventional | 2 | 2 | 2 | 6 |
| p10-mail-queue-triage | queue/status flow — outbound-mail worker triage with stale-lock reclaim | aed | 2 | 2 | 2 | 6 |
| p10-mail-queue-triage | | conventional | 2 | 2 | 0 | 4 |
| **Totals** | | **aed** | **20** | **20** | **20** | **60** |
| | | **conventional** | **18** | **20** | **16** | **54** |

## Appendix B — Reproducibility

`docs/aed_benchmark_data.json` contains the complete Crystal source of both
variants for all 10 pairs, the probe-type definitions, the grading rubric,
and every per-probe score. Haiku's raw answer transcripts and the grader's
rationales were **not** persisted from this run — a re-run should archive
them; the sources and probes in the JSON are sufficient to repeat the
experiment.
