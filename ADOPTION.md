# Adoption log — the dated record of intents

Every rule change, publication, and license event gets a dated entry here at
the time it happens, and every published version is a **signed git tag**
mirrored to independently-operated hosts. Forward from first publication, this
log plus the tag history is the public, timestamped record of when each idea
entered the canon.

Entries marked *(reconstructed)* describe practice that predates this public
repository; they are honest reconstructions, not contemporaneous records — the
contemporaneous private evidence exists and is referenced where it may later be
published.

---

## 2026-08-01 — Claude Code plugin packaging added

**Practiced same day.** The AED conventions are now installable as a Claude
Code plugin, packaged on the `v1.1` line alongside the canon rather than as
a separate line of doctrine:

- `.claude-plugin/marketplace.json` and
  `plugins/aed/.claude-plugin/plugin.json` — a marketplace shipping one
  plugin, `aed`. Install with
  `/plugin marketplace add AgentC-Consulting/aed-conventions` then
  `/plugin install aed@aed-conventions`.
- Three skills — `aed:naming`, `aed:planning`, `aed:process-managers` —
  that carry the naming doctrine, planning-stage discipline, and
  process-manager "when" grammar from chapters 02–04 into an agent's
  planning and edits.
- Three commands — `/aed:check` (lint names on demand), `/aed:scaffold`
  (build a process manager from a When-statement), and `/aed:adopt` (write
  an "AED conventions" section into a project's `CLAUDE.md`).
- `plugins/aed/scripts/aed_lint.rb`, an advisory naming linter for Ruby,
  Crystal, and Elixir, wired into a `PostToolUse` hook that runs after
  every edit.

**Enforcement is advisory only, by design** — the same posture as the
written canon. The linter always exits 0, the hook never blocks an edit,
and every finding is a suggestion for an agent or human to accept or
reject, never a gate.

**Plugin versioning is separate from the canon's.** The plugin ships as
`0.1.0` and versions independently of the `v1.x` doctrine tags; a plugin
release carries no claim about the state of the canon, and a canon release
carries no claim about the plugin.

`scripts/validate_plugin.sh` is the executable rubric for this packaging —
manifest schema, hook wiring, skill/command frontmatter, the linter's own
test suite, and a hook smoke test.

---

## 2026-07-29 — v1.1.0-rc.1: the original canon published, control flow added

**Practiced since 2024; first published here 2026-07-29.**

v1.0.0 published six edit-level style rules and nothing else. Readers — and
the maintainer — noted that the repository did not contain the doctrine AED
is actually named for: the token-window rationale, the verbose-naming
conventions, process managers, and feature stories all existed as private
notes dating to 2024-06-03 and had never been published. `v1.1.0-rc.1`
publishes them.

**Restored, verbatim from the author's originals** (authored 2024-06-03,
`process_manager_conventions.md` last revised 2025-11-24). These are published
as written, including the author's own work-in-progress markers and one
unfinished section marked `TBD`; nothing was rewritten or smoothed:

- `01_why_models_need_this.md` — the token-window explanation (excerpt of 02,
  lifted to the front of the reading order)
- `02_naming_conventions.md` — `list_of_` naming, boolean-as-question naming,
  attributes as short statements, and the compounding argument
- `03_process_managers.md` — the "when" grammar
- `04_feature_stories.md` — personas, operations, authorization levels
- `07_how_the_workflow_runs.md` — the batch-plan-and-walk-away rhythm
- `quick_reference.md` — the cheat sheet

**Added:**

- `06_control_flow.md` — CF-1 through CF-11, developed 2026-07-07 against a
  census of two live production codebases. Ships as a **release candidate**:
  the rules hold, the exact thresholds are still open, and the open questions
  are listed at the end of the file.
- `evidence/` — the small-model comprehension benchmark (AED 60/60 vs
  conventional 54/60, Claude Haiku, blind-answered and blind-graded) and its
  raw per-probe data, with the method's limits stated up front. Run
  2026-07-07.

**Kept, repositioned:** the six v1.0.0 rules remain at `CONVENTIONS.md` with
their `#rule-1` … `#rule-6` anchors untouched, indexed as chapter 05 of the
canon. The anchors were published in v1.0.0 and are cited externally;
renumbering them into a new filename would have broken those links to no
reader's benefit.

**Known conflict, tracked not hidden:** `CONVENTIONS.md` rule 4 offers
`expected_state` as an improved name; by `02_naming_conventions.md` that name
is still under-specified. Chapter 02 is the authority. Reconciling the
example is tracked for v1.1.0 final.

**Why a release candidate:** the CF thresholds and that naming conflict are
genuinely unsettled. Publishing as `-rc.1` puts the material where it can be
fetched and argued with, without asserting that the edges are final.

**Version decision (2026-07-29): this stays on the v1 line.** The question was
raised at publication — an expansion this large arguably justifies an honest
`v2.0.0`, since it changes what the repository *is* rather than adding to it.
Settled by the maintainer the same day: no. It is a big expansion, but it is
still part of the same frontier foundation this project set out to establish,
so it belongs on the v1 line. `v2.0.0` is reserved for the **next generation of
improvements** — thinking that supersedes this foundation rather than filling
it in. The final tag on this work will therefore be `v1.1.0`. See
[Versioning](README.md#versioning).

**Published surfaces:**

- Signed tag `v1.1.0-rc.1`:
  <https://github.com/AgentC-Consulting/aed-conventions/releases/tag/v1.1.0-rc.1>
- Single-file bundle `dist/aed-v1.1.0-rc.1.md` — the whole canon in reading
  order, fetchable in one request, generated by `scripts/build_bundle.sh`
- Hugging Face dataset (org-owned):
  <https://huggingface.co/datasets/agentc-consulting/aed-conventions>

The tag lives on the `release/v1.1.0-rc.1` branch. `main` remains at `v1.0.0`
until this candidate is promoted, so anyone fetching the stable line is
unaffected.

---


## 2026-07-07 — Six core rules written down and licensed (pre-publication)

**Practiced since ~late 2025, first published 2026-07-07.** *(reconstructed)*
The six core rules (branch-on-type, name-the-thing, guard clauses,
intention-revealing names, why-comments, formatter-owned layout) were not
designed as a standalone document — they emerged from production
Agent-Enhanced Development on AgentC's own application and website
codebases (Crystal/Amber, Grant ORM) during 2025–2026, tested against real
agent edits before ever being written down. No contemporaneous public record
exists for that emergence period, so "late 2025" here is deliberately
approximate rather than implying more precision than the evidence supports;
the contemporaneous private evidence exists and whether/when to publish it
is a separate, later decision.

On 2026-07-07 the rules were written down in full for the first time as
`CONVENTIONS.md` in this repository, with four before/after example files
added under `examples/`, and licensed:

- **Prose and documentation** — [CC BY 4.0](LICENSE).
- **Code examples** (`examples/`) — [MIT](LICENSE-EXAMPLES).

Control-flow rules (loops, guard ordering, rescues, fibers, macros) were
drafted internally during the same period and are held back from this
publication; they are targeted for a signed `v1.1.0` after their own review
(see `CONVENTIONS.md` → Status and versioning).

*Note on "published": this entry records the rules being committed to this
repository's local history. The repository going live on GitHub, with a
signed `v1.0.0` tag and mirrors on GitLab and Codeberg, is a separate, later
step — a following entry will record that date and the resulting URLs once
it happens.*

---

## 2026-07-07 — Canonical repository goes public; v1.0.0 signed and tagged

The repository went live on GitHub as the canonical home of the AED
conventions, and `v1.0.0` was signed with the AgentC Consulting org key
and pushed with `--follow-tags`. The org public key is published in this
repo as [`agentc-signing-pubkey.asc`](agentc-signing-pubkey.asc); see
[README.md § Verifying signed tags](README.md#verifying-signed-tags) for the
verify command. Note: because that key is not (yet) registered to any
GitHub account, GitHub's own UI shows the tag/commits as "Unverified" —
this is a GitHub account-linking limitation, not a problem with the
signature itself; `gpg --verify` against the published key is the
authoritative check. The GPG signature is the authoritative provenance and
carries the org identity above; the tag object's `tagger` field instead
shows the maintainer's personal git identity, since that reflects who ran
the `git tag` command locally — this is expected. Also note: the tag
object's timestamp is 2026-07-08 UTC (18:51:51 PDT on 2026-07-07, the date
this entry is dated to), since the `-0700` offset carries it past midnight
UTC.

**Live URLs:**

- Canonical repository: <https://github.com/AgentC-Consulting/aed-conventions>
- Signed tag `v1.0.0`: <https://github.com/AgentC-Consulting/aed-conventions/releases/tag/v1.0.0>
- Discussions (enabled): <https://github.com/AgentC-Consulting/aed-conventions/discussions>
- Hugging Face seed dataset (v0): <https://huggingface.co/datasets/crimson-knight/aed-conventions-examples> —
  four before/after pairs drawn from `examples/`, dual-licensed matching this
  repo. Published under the maintainer's existing personal HF namespace
  (`crimson-knight`) rather than an `AgentC-Consulting` org, because that org
  does not yet exist on Hugging Face; an org card and an org-owned copy of
  this dataset are follow-up work once the org exists (owner action).

**Not yet live (tracked, not forgotten):**

- **GitLab and Codeberg mirrors** (`scripts/push_mirrors.sh`) — both hosts
  require credentials (an SSH key trusted by this machine, and, for
  Codeberg, an accepted host key) that are not present on the publishing
  machine. The script is inert until an owner configures the `gitlab` and
  `codeberg` git remotes; it will then push `main` and all tags with one
  command. Until the mirrors exist, GitHub is the sole host — the
  "independent corroboration" property described in the plan does not yet
  hold and should not be assumed.
- **Hugging Face org card** — *unblocked 2026-07-29*: the
  `agentc-consulting` organization now exists on Hugging Face, and the
  v1.1.0-rc.1 canon is published there as an org-owned dataset. The v0
  examples dataset still sits in the personal `crimson-knight` namespace;
  moving or duplicating it under the org is follow-up work.
- **dev.to posts A and B** — drafts exist in `drafts/` and await the owner's
  voice review before either is scheduled; nothing has been published to
  dev.to.
