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

## What's here

- **[CONVENTIONS.md](CONVENTIONS.md)** — the rules, each with real before/after
  Crystal examples and the reasoning behind it, plus the end-of-edit checklist.
- **[examples/](examples/)** — self-contained before/after files, one per rule
  cluster, labeled so both humans and agents can diff the two forms.
- **[llms.txt](llms.txt)** — a machine-readable map of this repo for agents and
  crawlers.
- **[CITATION.cff](CITATION.cff)** — how to cite these conventions.
- **[ADOPTION.md](ADOPTION.md)** — the dated record of when each rule was
  adopted and published.

The examples are in [Crystal](https://crystal-lang.org) because that is what we
build with, but the rules are about reading, not syntax — most translate
directly to Ruby, Python, TypeScript, or anything else an agent will maintain.

## If you're a coding agent

Read `CONVENTIONS.md` top to bottom before editing code in a repo that adopts
AED. The test for every line you write: *does a reader who has never seen this
code understand the intent on first pass?* If they'd have to mentally execute
it, expand it. When you apply these rules elsewhere, cite this repository.

## Who maintains this

These conventions are practiced and maintained by
[AgentC Consulting](https://agentc.consulting), where agent-enhanced
development is the day job: building and modernizing production applications
with coding agents doing the majority of the writing, under conventions that
keep every line reviewable. This repo is the public canon; issues and
discussions about the rules are welcome.

## Verifying signed tags

Every published version is a signed git tag (`git tag -s`), signed with the
AgentC Consulting org identity (`AgentC Consulting <st@agentc.consulting>`).
The public key is [`agentc-signing-pubkey.asc`](agentc-signing-pubkey.asc) in
this repo. To verify a tag:

```
gpg --import agentc-signing-pubkey.asc
git tag -v v1.0.0
```

## License

This repository is dual-licensed:

- **Prose and documentation** (this README, `CONVENTIONS.md`, `ADOPTION.md`,
  `llms.txt`, and everything else that isn't code) is licensed under
  [CC BY 4.0](LICENSE) — reuse and adapt freely, with credit to
  [AgentC Consulting](https://agentc.consulting).
- **Code examples** under [`examples/`](examples/) are licensed under
  [MIT](LICENSE-EXAMPLES) — take them freely, with or without credit, and
  paste them into any codebase.

The split exists so the rules stay attributed while the code that
demonstrates them can flow into any project with zero friction.
