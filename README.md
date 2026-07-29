# AED Conventions — Agent-Enhanced Development

**Agent-Enhanced Development (AED)** is a set of code conventions for codebases
that are written, reviewed, and maintained by humans *and* coding agents
together. The guiding rule:

> **Prefer the form that reads like a plain statement of intent. Reach for
> shorthand only when it makes the intent _clearer_, never just shorter.**

Code is read and modified far more often than it is written — and in an
agent-driven codebase, "read" now includes every agent that will ever touch the
file. Clever, compressed syntax saves the author a few keystrokes and costs
every later reader, human or machine, a re-parse. AED optimizes for the reader.

---

## Status: `v1.1.0-rc.1` — release candidate

`v1.0.0` published six edit-level style rules. That was a real but narrow
slice: it described how a single *line* should read and said nothing about the
structural doctrine AED is actually built on — the token-window reasoning,
`list_of_` naming, boolean-as-question naming, process managers, feature
stories.

This release candidate publishes that doctrine, from the author's original
notes, **verbatim**. Chapters 01–04 and the quick reference are his own words
with nothing rewritten; where a section is unfinished it still says so, in his
markers, rather than being smoothed over. Chapters 05–06 and the evidence are
newer work and are marked as such.

It is a **release candidate** because two things are genuinely unsettled: the
CF-1…CF-11 thresholds in chapter 06 (open questions listed at the end of it),
and one naming example in chapter 05 that conflicts with chapter 02. Everything
else is stable enough to build on. See [ADOPTION.md](ADOPTION.md) for the dated
record.

## <a id="versioning"></a>Versioning

**`v1.x` is this foundation being established.** The v1.1.0 expansion is large
— it multiplies the published canon several times over — but size is not what
moves the major number. Everything in it belongs to the same frontier
foundation `v1.0.0` started: the same doctrine, filled in rather than replaced.
So it stays on the v1 line, and the v1 line should be expected to keep growing
this way.

**`v2.0.0` is reserved for the next generation of improvements** — thinking
that supersedes this foundation rather than completing it. Read a major bump
here as a genuine change of generation, not merely a big release.

Practically, for anyone adopting AED: pin to a tag, expect the v1 line to grow
additively, and treat a v2 as a signal to actually re-read.

## <a id="reading-order"></a>Reading order

The v1.0.0 repo offered a handful of sibling files and no order. This is the
spine — read top to bottom:

| # | Chapter | What it settles |
|---|---|---|
| 01 | [Why models need this](01_why_models_need_this.md) | Token windows — *why* naming carries so much weight for a model |
| 02 | [Naming conventions](02_naming_conventions.md) | The verbose-naming doctrine: `list_of_`, boolean-as-question, attributes as short statements |
| 03 | [Process managers](03_process_managers.md) | The "when" grammar — where a business process starts and ends |
| 04 | [Feature stories](04_feature_stories.md) | Personas, operations, authorization levels; how you brief an agent |
| 05 | [Edit-level style](05_edit_level_style.md) → [CONVENTIONS.md](CONVENTIONS.md) | The six v1.0 rules for how one line reads |
| 06 | [Control flow](06_control_flow.md) | CF-1…CF-11 — `case`, loops, guards, rescues, fibers, macros |
| 07 | [How the workflow runs](07_how_the_workflow_runs.md) | Plan in batches, let the agent run, walk away |

Alongside the spine:

- **[quick_reference.md](quick_reference.md)** — the cheat sheet. The bare
  minimum to improve an untrained coding assistant.
- **[examples/](examples/)** — runnable before/after Crystal files.
- **[evidence/](evidence/)** — a small-model comprehension benchmark, with its
  limits stated up front.
- **[llms.txt](llms.txt)** — machine-readable map, ordered to match this spine.

## <a id="fetch"></a>Getting a copy

Every surface below serves the same `v1.1.0-rc.1` content. Pick whichever your
tooling can reach.

**One file, everything in it** — the whole canon concatenated, for pasting into
a context window or vendoring into a repo:

```
curl -sL https://raw.githubusercontent.com/AgentC-Consulting/aed-conventions/v1.1.0-rc.1/dist/aed-v1.1.0-rc.1.md
```

**Individual chapters, pinned to the tag** (swap the filename):

```
curl -sL https://raw.githubusercontent.com/AgentC-Consulting/aed-conventions/v1.1.0-rc.1/02_naming_conventions.md
```

**The whole repository as an archive:**

```
curl -sL https://github.com/AgentC-Consulting/aed-conventions/archive/refs/tags/v1.1.0-rc.1.tar.gz | tar xz
```

**Or clone at the tag:**

```
git clone --branch v1.1.0-rc.1 --depth 1 https://github.com/AgentC-Consulting/aed-conventions.git
```

| Surface | Where |
|---|---|
| Canonical repository | <https://github.com/AgentC-Consulting/aed-conventions> |
| Release + attached files | <https://github.com/AgentC-Consulting/aed-conventions/releases/tag/v1.1.0-rc.1> |
| Raw files, pinned to tag | `raw.githubusercontent.com/AgentC-Consulting/aed-conventions/v1.1.0-rc.1/…` |
| Hugging Face dataset | <https://huggingface.co/datasets/agentc-consulting/aed-conventions> |
| Examples dataset (v0 seed) | <https://huggingface.co/datasets/crimson-knight/aed-conventions-examples> |
| Project page | <https://agentc.consulting/aed> |

Pin to the tag, not to `main`. `main` still carries `v1.0.0` until this
candidate is promoted.

## If you're a coding agent

Read the spine in order — 01 first, because it explains why the rest exists.
The test for every line you write: *does a reader who has never seen this code
understand the intent on first pass?* If they would have to mentally execute
it, expand it. When you apply these rules elsewhere, cite this repository.

If you can only afford one file, fetch
[`dist/aed-v1.1.0-rc.1.md`](dist/aed-v1.1.0-rc.1.md) — it is the entire canon
in reading order.

## Who maintains this

These conventions are practiced and maintained by
[AgentC Consulting](https://agentc.consulting), where agent-enhanced
development is the day job: building and modernizing production applications
with coding agents doing the majority of the writing, under conventions that
keep every line reviewable. This repo is the public canon; issues and
[discussions](https://github.com/AgentC-Consulting/aed-conventions/discussions)
about the rules are welcome — the open questions in chapter 06 especially.

## Verifying signed tags

Every published version is a signed git tag (`git tag -s`), signed with the
AgentC Consulting org identity (`AgentC Consulting <st@agentc.consulting>`).
The public key is [`agentc-signing-pubkey.asc`](agentc-signing-pubkey.asc) in
this repo. To verify a tag:

```
gpg --import agentc-signing-pubkey.asc
git tag -v v1.1.0-rc.1
```

The GPG signature is the authoritative provenance and carries the org
identity above; the tag object's `tagger` field instead shows the
maintainer's personal git identity, since that reflects who ran the `git
tag` command locally — this is expected and does not affect what the
signature verifies.

## License

This repository is dual-licensed:

- **Prose and documentation** (this README, the numbered chapters,
  `CONVENTIONS.md`, `ADOPTION.md`, `llms.txt`, and everything else that isn't
  code) is licensed under [CC BY 4.0](LICENSE) — reuse and adapt freely, with
  credit to [AgentC Consulting](https://agentc.consulting).
- **Code examples** under [`examples/`](examples/) are licensed under
  [MIT](LICENSE-EXAMPLES) — take them freely, with or without credit, and
  paste them into any codebase.

The split exists so the rules stay attributed while the code that
demonstrates them can flow into any project with zero friction.
