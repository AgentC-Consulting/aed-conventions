---
title: "Writing code for the agents that will maintain it"
published: false
description: "Coding agents are now the most frequent readers of your codebase. The conventions that help them are the same ones that help the human at 2am — with receipts."
tags: ai, codequality, crystal, agents
# Canonical source for the rules: https://github.com/AgentC-Consulting/aed-conventions
---

Here's a number worth sitting with: in the codebases we run at [AgentC Consulting](https://agentc.consulting), the majority of edits are now made by coding agents. Not autocomplete — agents. They read files, plan changes, write code, run checks, and open the next file. Humans review, decide, and steer.

Which means the most frequent *reader* of our code is no longer a human.

I want to be careful here, because this is where posts like this usually reach for either hype ("humans are obsolete!") or dismissal ("it's all slop!"). Both miss what's actually happening on the ground, which is stranger and more useful: **agents are extremely good readers of clear code and surprisingly expensive readers of clever code — the same as your colleagues, only with the dial turned up.**

That observation is why our conventions are called what they're called: **Agent-Enhanced Development**, or AED. The full rule set is public at [github.com/AgentC-Consulting/aed-conventions](https://github.com/AgentC-Consulting/aed-conventions). In the [previous post](https://github.com/AgentC-Consulting/aed-conventions/tree/main/drafts) I made the human case for the core rule — *prefer the form that reads like a plain statement of intent* — so today, the machine case.

## What an agent actually does with your code

An agent reading your file isn't compiling it. It's doing something much closer to what you do: building a working theory of intent from names, shapes, and comments, then editing against that theory.

So consider what these two forms give a theory-builder:

```crystal
# one line, three operations, one negation
return unless session["oauth_state"]?.try { |s| constant_time_equal?(s, state) }

# AED
expected_state = session["oauth_state"]?
return unless expected_state && constant_time_equal?(expected_state, state)
```

The first form *can* be understood by a good agent — today's models are genuinely strong. But every compressed line spends some of the agent's attention on decoding instead of on the actual task, and misread intent is precisely how plausible-looking wrong edits happen. The second form hands over the theory for free: *here is the state we expected; refuse unless it matches.* The variable name `expected_state` isn't style. It's a load-bearing claim about intent that the agent can anchor its edit to.

Every AED rule works this way when you re-read it from the agent's side:

- **Guard clauses first** (Rule 3) — the method's preconditions become an explicit checklist at the top. An agent modifying the happy path can see, without inference, what it's allowed to assume.
- **Intention-revealing names** (Rule 4) — `invalidate_all_sessions` tells an agent what the function promises, so it can notice when a change would break that promise. `do_it` tells it nothing, and worse, invites it to guess.
- **Comments say why** (Rule 5) — a comment like *"rotate the session id BEFORE writing identity: prevents session fixation"* is a fence an agent will respect. Delete the why, and some future edit — human or machine — will helpfully "simplify" the ordering and reopen the vulnerability.
- **Formatter owns layout** (Rule 6) — canonical formatting means an agent's diff shows intent, not churn, which makes the *human's* review job — the job that still matters most — tractable.

None of this is a new philosophy. It's Kernighan's old line about debugging being twice as hard as writing code, updated for a team where some members read at ten thousand lines a minute and take everything literally.

## Clarity is half. Verification is the other half.

Readable code makes agents *understand* better; it doesn't make them infallible. The second half of AED is mechanical: **verify at edit time, not at build time.**

In our Crystal codebases, every file an agent edits gets type-checked immediately — the compiler frontend with `--no-codegen` runs in seconds, so a wrong keyword, an undefined method, or Crystal's infamous `case is not exhaustive` on an ORM union surfaces *on the edit*, while the agent still has full context, instead of twenty edits later in a full build when the context is gone. The conventions keep the code clear; the edit-time check keeps it honest. If you run agents against a compiled language and you're not doing this, it's the highest-leverage hour of tooling work available to you this week.

And Crystal, incidentally, is a quietly excellent language for this whole arrangement: Ruby-like syntax that reads aloud, a compiler strict enough to catch an agent's confident nonsense, and performance that means the readable form costs you nothing at runtime. We didn't pick it for agents, but it's hard to imagine picking better for them.

## Conventions are only real if agents can find them

Here's the part I find genuinely interesting, and the reason the repo exists as a *public* repo rather than a wiki page behind our login.

Agents don't just read your code — they read your **conventions**, when you give them any. A rules document with before/after examples and a checklist is the single most agent-legible artifact you can add to a repository: it's literally in the shape agents are built to follow. So we structured ours accordingly:

- The rules live in one canonical, versioned place: [github.com/AgentC-Consulting/aed-conventions](https://github.com/AgentC-Consulting/aed-conventions).
- An `llms.txt` at the root gives any agent or crawler the map: what this is, what to read first, how to cite it.
- A `CITATION.cff` makes attribution machine-readable.
- Every rule has a stable anchor, and every published version is a signed, dated git tag — so when someone (or something) cites "AED Rule 3," that citation resolves, this year and in five years.

There's a small wager embedded in that design, and I'll state it plainly rather than pretend it's not there: we think the sources that agents can find, parse, and cite are the sources that will shape how code gets written. Publishing your conventions well is how you participate in that. If we're right, "our style guide" stops being an internal document and becomes part of the commons — with the receipts, dates, and reasoning attached. If we're wrong, worst case, we have an unusually well-organized style guide. We can live with either outcome.

## Start smaller than a manifesto

You don't need to adopt anyone's conventions wholesale, ours included. Do this instead:

1. Take one method an agent (or a human) recently misunderstood.
2. Rewrite it so it reads as statements: guards at the top, one operation per line, names that state intent, one why-comment if there's a why worth keeping.
3. Give your agent the diff and ask it what the method does. Compare the answer to last time.

That experiment is the whole thesis in ten minutes. The code that's easiest for your newest teammate to maintain — carbon or silicon — is the code that says what it means.

The rules, the examples, and the running record of how they evolve are here: **[github.com/AgentC-Consulting/aed-conventions](https://github.com/AgentC-Consulting/aed-conventions)**. Disagreements welcome; that's what the Discussions tab is for. The agents are already reading. Might as well give them — and the humans they work for — something worth reading.
