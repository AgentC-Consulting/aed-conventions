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
(see the public key attached to the repository; verify with `gpg --verify`)
and pushed with `--follow-tags`.

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
- **Hugging Face org card** — blocked on the same missing `AgentC-Consulting`
  HF organization noted above.
- **dev.to posts A and B** — drafts exist in `drafts/` and await the owner's
  voice review before either is scheduled; nothing has been published to
  dev.to.
