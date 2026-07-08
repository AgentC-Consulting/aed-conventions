# AED Conventions — Code That Reads Like Statements

**Agent-Enhanced Development (AED)** is how [AgentC Consulting](https://agentc.consulting)
writes code that both humans and coding agents can read, change, and review
with the least friction. The guiding rule is simple:

> **Prefer the form that reads like a plain statement of intent. Reach for
> shorthand only when it makes the intent _clearer_, never just shorter.**

Clever, compressed syntax saves the author a few keystrokes and costs every later
reader (human or agent) a re-parse. In an agent-driven codebase, that trade is
almost always wrong: the code is read and modified far more often than it is
written. Optimize for the reader.

These conventions are the *readability* half of the practice. Their
*correctness* companion is edit-time verification: run the compiler's type
check (for Crystal, the compiler frontend with `--no-codegen`) on every edited
file so mistakes surface immediately, not minutes later in a full build. AED
keeps the code clear; the edit-time check keeps it compiling. In our own
tooling this runs automatically after every agent edit — wire the equivalent
into whatever harness your agents use.

The examples below are Crystal, because that is what we build with. The rules
are about reading, not syntax.

---

## The rules (with Crystal examples)

<a id="rule-1"></a>
### 1. Branch on type with an explicit `if … is_a?`, not a clever `case`

`case … in` demands *exhaustive* matching, and in codebases using the Grant ORM
it trips over Grant's `Grant::Base+` type inference (`Error: case is not
exhaustive. Missing types: Grant::Base`). `case … when .is_a?(T)` (the
dot-receiver sugar) compiles but reads like a puzzle. An ordinary `if` reads
like a sentence.

```crystal
# ✅ AED — reads like a statement
if user.is_a?(Users::Regular)
  session[:user_type] = "regular"
  session[:session_version] = user.session_version
else
  session[:user_type] = "admin"
end

# 🚫 trips Grant inference AND hides intent
case user
in Users::Regular then ...
in Users::Admin   then ...
end

# 🚫 compiles, but the leading dot is a riddle
case user
when .is_a?(Users::Regular) then ...
end
```

<a id="rule-2"></a>
### 2. Name the thing; don't make the reader decode a chain

```crystal
# ✅ AED
expected_state = session["oauth_state"]?
return unless expected_state && constant_time_equal?(expected_state, state)

# 🚫 terse, but the reader has to hold three operations in their head
return unless session["oauth_state"]?.try { |s| constant_time_equal?(s, state) }
```

<a id="rule-3"></a>
### 3. Prefer explicit guard clauses to nested ternaries / one-liners

```crystal
# ✅ AED
return nil if password_digest.empty?
return nil unless Crypto::Bcrypt::Password.new(password_digest).verify(password)
self

# 🚫 dense
password_digest.empty? ? nil : (Crypto::Bcrypt::Password.new(password_digest).verify(password) ? self : nil)
```

<a id="rule-4"></a>
### 4. Use full, intention-revealing names

Methods and locals are sentences-in-miniature: `establish_session`,
`invalidate_all_sessions`, `find_or_create_from_oauth`, `expected_state`. Avoid
`do_it`, `tmp`, `x`, `res2`. A good name removes the need for a comment.

<a id="rule-5"></a>
### 5. Say *why* in a comment, let the code say *what*

Comments earn their place by explaining intent, security rationale, or a
non-obvious constraint — not by restating the line. The house style: a
session-establishing method carries a comment stating the fixation attack it
prevents; an encrypted column carries a comment stating what the encryption
protects and why. If a comment could be deleted with no loss because the code
already says it, delete it.

<a id="rule-6"></a>
### 6. One statement per line; let the formatter own the layout

Run `crystal tool format` (or your language's canonical formatter) as part of
every edit. Canonical formatting means every reader and every diff sees the
same shape.

---

<a id="shorthand-boundary"></a>
## When shorthand IS the clearer form

AED is "clarity first," not "verbose always." Idioms that are *more* readable are
encouraged: `arr.map(&.name)`, `value.try(&.to_i64?)`, a `?`-suffixed predicate,
a single well-named guard expression. The test is always: **does a reader who has
never seen this code understand the intent on first pass?** If yes, keep it. If
they have to mentally execute it, expand it.

---

<a id="checklist"></a>
## Checklist before you finish an edit

- [ ] Type branches use explicit `if … is_a?` (not `case … in` against Grant types).
- [ ] No one-liner hides more than one operation from the reader.
- [ ] Names state intent; no `tmp`/`x`/`res2`.
- [ ] Comments explain *why*, never restate *what*.
- [ ] `crystal tool format` is clean.
- [ ] The edit-time type check passed (no `case is not exhaustive`, no undefined methods).

---

## Status and versioning

This document is the public canon of the AED conventions, versioned by signed
git tags. Rules covering control flow (loops, guards, rescues, fibers, macros)
are drafted and under internal review; they will land here as a tagged minor
version. The [ADOPTION.md](ADOPTION.md) log records, with dates, when each rule
entered practice and when it was published.
