# 05 · Edit-Level Style

Chapter 05 of the canon lives at **[CONVENTIONS.md](CONVENTIONS.md)** — six
rules for how a single line should read, each with before/after Crystal.

It keeps its original filename and its `#rule-1` … `#rule-6` anchors on
purpose. Those anchors were published in v1.0.0 and are cited from outside
this repository; moving them to renumber a chapter would break every one of
those links for no reader's benefit.

## Where it sits in the canon

Chapters 01–04 are the structural doctrine: why models need consistent naming,
what to name things, how to shape a process manager, how to write a feature
story. Chapter 05 is narrower and later — it governs the individual edit, once
the structure is already decided.

Read in that order it is a fair chapter. Read alone — which is all v1.0.0
offered — it reads as though AED were a six-item style guide, which it is not.
That was the gap this release closes.

- [CONVENTIONS.md#rule-1](CONVENTIONS.md#rule-1) — branch on type with an explicit `if … is_a?`
- [CONVENTIONS.md#rule-2](CONVENTIONS.md#rule-2) — name the thing; don't make the reader decode a chain
- [CONVENTIONS.md#rule-3](CONVENTIONS.md#rule-3) — prefer explicit guard clauses to nested ternaries
- [CONVENTIONS.md#rule-4](CONVENTIONS.md#rule-4) — use full, intention-revealing names
- [CONVENTIONS.md#rule-5](CONVENTIONS.md#rule-5) — say *why* in a comment, let the code say *what*
- [CONVENTIONS.md#rule-6](CONVENTIONS.md#rule-6) — one statement per line; let the formatter own the layout

Plus the [shorthand boundary](CONVENTIONS.md#shorthand-boundary) and the
[end-of-edit checklist](CONVENTIONS.md#checklist).

## One known conflict with chapter 02

CONVENTIONS.md rule 4 offers `expected_state` as an improved name. By
[chapter 02](02_naming_conventions.md) that name is still under-specified —
expected by whom, of what, in what units? Chapter 02 is the authority where
the two disagree. Reconciling the example is tracked for v1.1.0 final.

---

*Chapter 05 of the AED canon · continue to
[06 · Control Flow](06_control_flow.md) ·
[reading order](README.md#reading-order)*
