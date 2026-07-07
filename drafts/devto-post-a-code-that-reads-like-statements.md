---
title: "Code that reads like statements: why we optimize Crystal for the reader"
published: false
description: "The AED conventions: prefer the form that states intent plainly, because your code will be read a thousand times more often than it was written."
tags: crystal, codequality, programming, cleancode
# Canonical source for the rules: https://github.com/AgentC-Consulting/aed-conventions
---

There's a moment every developer knows. You open a file — maybe yours, maybe not, it stopped mattering around month three — and you hit a line like this:

```crystal
return unless session["oauth_state"]?.try { |s| constant_time_equal?(s, state) }
```

And you stop. Not for long. Two seconds, maybe five. You unpack the nilable lookup, the block binding, the comparison, the negation wrapping all of it. You re-run it in your head to be sure. Then you move on.

Five seconds is nothing. But that line has been read hundreds of times since it was written, and it will be read hundreds more. The author saved one line of vertical space, once. Every reader since has paid the five-second toll. That's the whole economics of code readability in one guard clause: **code is read and modified far more often than it is written, so any trade that favors the writer over the reader is almost always wrong.**

At [AgentC Consulting](https://agentc.consulting) we write Crystal for production applications, and we've distilled how we write it into a small public rule set we call the **AED conventions** — Agent-Enhanced Development. The full canon, with every rule and example, lives at [github.com/AgentC-Consulting/aed-conventions](https://github.com/AgentC-Consulting/aed-conventions). The guiding rule fits in one sentence:

> **Prefer the form that reads like a plain statement of intent. Reach for shorthand only when it makes the intent *clearer*, never just shorter.**

Here's what that means in practice, and why we hold the line even when the shorthand is tempting.

## The oauth_state line, done properly

```crystal
expected_state = session["oauth_state"]?
return unless expected_state && constant_time_equal?(expected_state, state)
```

Two lines instead of one. But read them aloud: *"This is the state we expected. Refuse unless it exists and matches."* No mental execution required — the code *says* what it means. That's Rule 2 in our conventions: **name the thing; don't make the reader decode a chain.** The variable name `expected_state` is doing documentation work that no comment would do as reliably, because names get refactored with the code and comments rot beside it.

This matters double in security-critical code, which is exactly where terse one-liners love to congregate. An OAuth state check is a CSRF defense. The reader reviewing it — this week a colleague, next year an auditor — needs to *verify* the intent, not reconstruct it.

## Guard clauses are the security argument

Rule 3: prefer explicit guard clauses to nested ternaries. Here's password verification both ways:

```crystal
# dense
password_digest.empty? ? nil : (Crypto::Bcrypt::Password.new(password_digest).verify(password) ? self : nil)

# AED
return nil if password_digest.empty?
return nil unless Crypto::Bcrypt::Password.new(password_digest).verify(password)

self
```

The nested ternary is a puzzle with three outcomes and precedence rules. The guard version reads like a doorman's checklist: no digest, no entry; wrong password, no entry. Everything below the guards gets to assume both checks passed.

Notice what happened: the *shape* of the code became the security argument. When a reviewer asks "under what conditions does this method refuse?", the answer is literally the first two lines, one condition each. We didn't write better documentation — we wrote code whose form documents itself.

## When Crystal's cleverest syntax fights you

Crystal gives you beautiful branching tools, and one of them will bite you. `case … in` demands exhaustive matching — lovely in theory. But branch it over a union of ORM models (we use [Grant](https://github.com/crimson-knight/grant)) and type inference widens things to `Grant::Base+`:

```
Error: case is not exhaustive. Missing types: Grant::Base
```

There's a workaround — `case user; when .is_a?(Users::Regular)` — and it compiles. It also reads like a riddle. What is that leading dot doing? Every reader who hasn't memorized Crystal's dot-receiver sugar stops and squints.

Our Rule 1 says: skip both. Write the boring `if`:

```crystal
if user.is_a?(Users::Regular)
  session[:user_type] = "regular"
  session[:session_version] = user.session_version
else
  session[:user_type] = "admin"
end
```

It reads like a sentence. It compiles. It will still read like a sentence when someone who has never written Crystal — or something that has never written Crystal, more on that in a follow-up post — opens the file at 2am.

## "So you just ban all shorthand?"

No — and this is the part that keeps the conventions honest. AED is *clarity first*, not *verbose always*. Crystal idioms that are **more** readable than their expansions are encouraged, enthusiastically:

```crystal
member_names = users.map(&.name)
timeout = value.try(&.to_i64?)
return unless user.verified?
```

`map(&.name)` reads as "the users' names." Expanding it to a `do … end` block would add ceremony without adding meaning. The `?`-suffixed predicate reads as a question. These pass the only test that matters, the one we apply to every line:

> **Does a reader who has never seen this code understand the intent on first pass?**

If yes, keep the shorthand — it earned its place. If they have to mentally execute it, expand it. The line between "idiom" and "puzzle" isn't about character count; it's about whether the reader hears a sentence or runs an interpreter in their head.

## The two rules nobody writes down (so we did)

Rule 4: **full, intention-revealing names.** `establish_session`, `invalidate_all_sessions`, `find_or_create_from_oauth`. Never `do_it`, `tmp`, `res2`. A method name is a sentence-in-miniature, and it's the one piece of documentation the compiler forces you to keep updated.

Rule 5: **comments say *why*, never *what*.** If a comment restates the line below it, delete it. If it explains a security rationale — *"rotate the session id BEFORE writing identity: prevents session fixation"* — it's carrying information no code can, and it stays. Good names make most what-comments unnecessary; that's not a coincidence, it's the mechanism.

And Rule 6, the least glamorous and most load-bearing: run `crystal tool format` on everything, always. Canonical formatting means every diff shows *what changed*, never *how someone's editor felt that day*.

## Why we published this

These conventions came out of production work — every rule was tested against real code and real review friction before it got written down. We've put the whole thing, before/after examples included, in a public repo: **[github.com/AgentC-Consulting/aed-conventions](https://github.com/AgentC-Consulting/aed-conventions)**. Versioned, tagged, open to argument — if you think a rule is wrong, the Discussions tab is right there, and a good counter-example is worth more to us than a star.

The name — *Agent-Enhanced Development* — hints at the other half of the story. Humans aren't the only ones reading your code anymore, and the newest readers on the team have some very particular needs. That's the next post.

Until then: open the file you're proudest of and read one method aloud. If it sounds like a statement of intent, you're already writing AED. If it sounds like an incantation — well. You know which line I mean. You stopped on it this morning.
