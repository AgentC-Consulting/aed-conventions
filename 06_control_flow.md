# 06 · Control Flow (CF-1 … CF-11)

> **Status**: RELEASE CANDIDATE. These eleven rules ship in `v1.1.0-rc.1` as a
> candidate, not as settled canon. The numbered questions at the end are still
> open, and the answers may change individual thresholds before `v1.1.0` final.
> Adopt them if they help; expect the edges to move.
>
> **Scope question answered here**: how should AED handle control-flow code
> whose *syntax* does not naturally align with the reads-like-statements rule?
> A `while` loop, a `rescue` ladder, or a `spawn` block has no name of its own
> — the syntax is pure mechanism. AED's answer, developed rule by rule below:
> **when the syntax can't read like a statement, the *names around it* must
> say what the syntax is doing.**

---

## 0. Census — what actually occurs in our Crystal

Rules should target real frequency, not theory. Counted with `grep -rE`
across the two live codebases (regex counts are ceilings — e.g. the ternary
pattern also matches nilable type signatures; noted where it matters):

| Pattern | premium template `src/` (107 files, 12,250 lines) | agentc_website `src/` (22 files, 2,163 lines) |
|---|---:|---:|
| Leading `if` | 154 | 23 |
| `if … is_a?` (existing Rule 1) | 6 | 0 |
| `case` statements | 28 | 3 |
| `when` branches | 124 | 6 |
| `case … in` | **0** | **0** |
| Leading `unless` | 25 | 5 |
| Any ` unless ` (incl. postfix) | 150 | 24 |
| `while` | 4 | 8 |
| `until` | **0** | **0** |
| `loop do` | 2 | 0 |
| `break` | 3 | 12 |
| `next` | 15 | 3 |
| `return` (all) | 127 | 43 |
| Guard `return … if` | 36 | 19 |
| Guard `return … unless` | 58 | 7 |
| Ternary `? … :` (regex ceiling; true ternaries ≈ half) | 61 | 16 |
| `begin` | 14 | 2 |
| `rescue` | 57 | 8 |
| `ensure` | 13 | 0 |
| `retry` | **0** | **0** |
| `raise` | 156 (138 typed error, 14 bare string) | 1 |
| `spawn` | 4 (2 real code sites) | 0 |
| `Channel` | 1 | 0 |
| Concurrency `select` | **0** | **0** |
| `.each` | 16 | 7 |
| `.map` | 30 | 5 |
| `.select`/`.reject` | 13 | 4 |
| `.try` | 98 | 3 |
| `&.` shorthand | 116 | 7 |
| `macro` definitions | 3 | 0 |
| `{% if %}` compile-time branches | 2 | 0 |
| `def …?` predicate methods | 195 | 26 |
| `def …!` bang methods | 10 | 0 |

**What the census says:**

- The codebase already leans AED: guard returns (120 across both repos) far
  outnumber loops (14); typed raises outnumber string raises 10:1; there are
  195 `?` predicates in the template — the "name the question" culture exists.
- `case … in`, `until`, `retry`, and concurrency `select` occur **zero**
  times. We can codify their status cheaply — banning what nobody uses costs
  nothing and stops an agent from introducing them.
- The high-frequency gaps that need real rules: `case/when` menus (28+3
  sites), guard ordering (120 guard returns with no stated ordering rule),
  `unless` (175 total uses, some compound), `.try` (98 uses — the single
  biggest "decode a chain" risk), and bare `rescue` (a large share of the 65
  rescues carry no error name).
- The website's markdown parser is a legitimate **cursor-loop** cluster
  (8 `while` + 12 `break` in one file family) — the loop rule must bless that
  shape, not fight it.

---

## The core insight: mechanism syntax vs statement syntax

The existing skill's rule — *prefer the form that reads like a plain statement
of intent* — works effortlessly for **expressions**: you pick the spelling
that reads best. Control flow is different. `while`, `rescue`, `spawn`,
`{% if %}` are **mechanism keywords**: they say *how* execution moves, never
*why*. No amount of re-spelling makes `while @i < @lines.size` state an
intent.

So for control flow, AED shifts from "pick the readable spelling" to three
compensating moves, in priority order:

1. **Name the intent next to the mechanism** — the condition is a named
   predicate, the body is a named method, the error is a named type, the
   fiber does a named job.
2. **Keep the mechanism in one canonical shape** — one blessed way to write
   each construct, so a reader (or a linting hook) recognizes it instantly.
3. **Ban the shapes that only ever obscure** — the census shows we already
   live without them.

Every rule below is one of those three moves. Format per rule: (a) why the
raw syntax fights the reading rule, (b) the proposed rule with a crisp name,
(c) before/after in the skill's voice, (d) the honest cost, (e) the
mechanical check an agent, linter, or hook can apply.

---

## Rule CF-1. `case` is a menu — every branch one bite

**(a) Why the syntax fights the rule.** A `case` on a *value* (`case action`,
`case fmt`, `case status_code`) is actually the closest control flow gets to
a plain statement — *"depending on the action: …"*. It stops reading like a
statement in exactly two ways: when a branch body grows into a paragraph (the
reader loses the menu and falls into one dish), and when the subject is an
expression the reader must evaluate first (`case ENV["AI_DEFAULT_PROVIDER"]?.to_s.downcase`).

**(b) Proposed rule — "Case is a menu, not a novel."**
Use `case … when` when branching a **single named value** across **three or
more** outcomes. Two outcomes is an `if/else` (a menu of two is just a
choice). Each `when` body is at most ~3 lines or a single named method call —
if a branch needs a paragraph, extract it to a method whose name is the
branch's intent. The `case` subject must be a **named local or a plain
method call**, never an inline expression chain. Always write an explicit
`else` that states the fallback (`false`, `raise`, or a named default) —
Crystal's `when` is not exhaustive, so the `else` is where you *say* what
happens to the unlisted world. `case … in` stays banned per existing Rule 1
(census: zero uses — nothing to migrate).

**(c) Before/after.**

```crystal
# ✅ AED — a menu: named subject, one bite per branch, spoken fallback
default_provider = ENV["AI_DEFAULT_PROVIDER"]?.to_s.downcase
case default_provider
when "anthropic" then Anthropic::Client.new
when "openai"    then OpenAI::Client.new
else                  raise "Unknown AI_DEFAULT_PROVIDER: #{default_provider}"
end

# 🚫 subject is a puzzle the reader must evaluate before the menu even starts
case ENV["AI_DEFAULT_PROVIDER"]?.to_s.downcase
when "anthropic" then ...
end

# 🚫 a two-item "menu" — this is just an if wearing a costume
case backend
when :smtp then deliver_smtp(message)
else            deliver_log(message)
end
# ✅ instead:
if backend == :smtp
  deliver_smtp(message)
else
  deliver_log(message)
end
```

The policy classes are the house exemplar already
(`src/policies/team_policy.cr`): `case action` with one-line branches
composed of `?` predicates (`team_lead? || admin_access?`) and `else false`.
That file reads like an access-control table — which is the point.

**(d) Cost.** Extracting fat branches adds methods; a reader who wants the
details takes one hop. Two-branch `case` fans will find the if/else rule
fussy. Accepted: the menu shape is only worth its visual weight when there is
an actual menu.

**(e) Mechanical check.** Flag: `case` whose subject line contains `.` more
than once or any `?.`/`ENV[`; any `when` body exceeding 3 lines; any `case`
with fewer than 3 `when` branches; any `case` without `else`; any `case … in`
(already caught by the compile hook on Grant types — extend to a grep ban).

---

## Rule CF-2. Loops state their finish line

**(a) Why the syntax fights the rule.** `while` states a *continuation
condition*, but a reader thinks in terms of a *finish line* ("keep going
until the lines run out"). Worse, `loop do … break` scatters the finish line
into the body, and an index cursor (`@i`) makes progress invisible — the
reader must verify the loop advances or they can't trust it terminates.

**(b) Proposed rule — "Every loop names its finish line and shows its
step."** Three blessed loop shapes, nothing else:

1. **Collection walk** — `items.each do |item|` (default; covers most needs).
2. **Cursor loop** — `while cursor_has_more?` over an explicit cursor, where
   (i) the condition is a plain comparison or a named `?` predicate, (ii)
   every `break` inside is a one-line guard whose condition is a named
   predicate or plain comparison, and (iii) the cursor visibly advances in
   the body (an `@i += n` a reader can point at). This blesses the website's
   markdown parser shape (`while @i < @lines.size` … `break unless row?(s)` —
   `article_markdown.cr` already complies, its break conditions are named
   predicates like `ordered_item?`, `task_item?`, `row?`).
3. **Forever loop** — `loop do` only for intentionally unbounded work (the
   SSE heartbeat in `mcp_sse_controller.cr`), and it must sit inside a method
   whose **name says it loops** (`run_heartbeat_loop`, `pump_stdout`), with
   its exit spelled as a guard (`break if client_disconnected?`).

If a loop body exceeds ~8 lines, extract the body to a method named for one
iteration's intent (`consume_blockquote`, `emit_table_row`) — the loop line
then reads *"while there are lines, consume the next block."*
`until` is **banned** (census: zero uses): `until done?` forces the reader to
negate in their head; write `while more?`.

**(c) Before/after.**

```crystal
# ✅ AED — cursor loop: named finish line, named break, visible step
while @i < @lines.size
  line = @lines[@i].strip
  break unless ordered_item?(line)
  emit_ordered_item(line)
  @i += 1
end

# 🚫 the finish line is a negation the reader must invert
until @i >= @lines.size
  ...
end

# 🚫 forever-loop with an anonymous job and a buried exit
loop do
  sleep 15.seconds
  begin
    send_event(response, "ping", {time: Time.utc.to_unix})
  rescue
    break
  end
end
# ✅ instead: the method name carries the loop's intent
private def run_heartbeat_loop(response) : Nil
  loop do
    sleep 15.seconds
    break unless send_ping(response) # returns false when the client is gone
  end
end
```

**(d) Cost.** Extraction adds one hop per fat loop; the "visible step" rule
occasionally forces an `@i += 1` where a cleverer restructure could avoid the
cursor entirely. Accepted: termination you can point at beats elegance you
must simulate.

**(e) Mechanical check.** Flag: any `until`; any `loop do` in a method whose
name lacks `loop`/`pump`/`watch`/`poll`; any `while` body > 8 lines; any
`break` followed by a compound condition (`&&`/`||` on the same line); a
`while i <`-style loop whose body never reassigns the cursor variable.

---

## Rule CF-3. Guards are the bouncer — they stand at the door

**(a) Why the syntax fights the rule.** An early `return` is invisible in
prose: a non-technical reader scanning top-to-bottom doesn't naturally know
that `return nil unless key` means *everything below assumes a key exists*.
Guards scattered mid-method are worse — the story keeps getting interrupted
by exits the reader has to fold into their mental state.

**(b) Proposed rule — "Guards first, story second."** Guard clauses (already
the house majority style — 120 guard returns across both repos, and existing
Rule 3 prefers them) get an *ordering and shape* contract:

- All precondition guards sit in a **contiguous block at the top** of the
  method, before the first line of the happy path. A reader — technical or
  not — reads them as a doorman's checklist: *"no ticket, no entry; wrong
  tag, no entry."* Everything after the blank line is the story with all
  assumptions established.
- One guard per line, one idea per guard. A guard's condition is a plain
  comparison, a named predicate, or a single nil-check — never a compound
  needing parentheses (extract to a `?` method, see CF-8).
- A `return` *after* the story has started is allowed only when it is the
  method's **answer** (the natural end of a branch), not a late-discovered
  precondition. If you discover a precondition mid-story, either hoist it or
  extract the remainder into a method with its own door.
- Guards that reject for a *reason worth documenting* say why on the line
  above (`# CSRF: state must match what we issued`), per existing Rule 5.

`src/wire/cose.cr` is the exemplar: five `return nil unless …` guards in a
row, then the single decrypt statement — the shape *is* the security
argument.

**(c) Before/after.**

```crystal
# ✅ AED — the bouncer's checklist, then the story
def verify_password(password : String) : self?
  return nil if password_digest.empty?
  return nil unless Crypto::Bcrypt::Password.new(password_digest).verify(password)

  self
end

# 🚫 nested ifs — the reader carries open questions to the last line
def verify_password(password : String) : self?
  unless password_digest.empty?
    if Crypto::Bcrypt::Password.new(password_digest).verify(password)
      self
    end
  end
end

# 🚫 a precondition ambushing the reader mid-story
def publish(article)
  html = render(article)
  return if article.draft?   # ← this belonged at the door
  upload(html)
end
```

**(d) Cost.** Hoisting sometimes evaluates a guard slightly earlier than
strictly needed (rarely matters; note it when it does). Multiple exit points
still bother single-exit purists — AED sides with the checklist reader.

**(e) Mechanical check.** Flag: a `return … if/unless` guard appearing after
the first non-guard, non-comment statement of a method (heuristic: guard
lines must be a prefix of the method body); any guard condition containing
`&&`/`||` (send to CF-8); nesting depth > 2 inside a method that has no
guards (suggests inversion is available).

---

## Rule CF-4. `unless` carries one positive idea

**(a) Why the syntax fights the rule.** `unless` reads beautifully as an
English exception — *"return nil unless the state matches"* — right up until
the condition contains logic. `unless a && b` requires De Morgan in the
reader's head ("so it runs when… a is false, OR b is false…"). The census
shows 175 total `unless` uses; most are clean guards, but sites like
`unless key.algorithm == ES256 && key.curve == P256` (`webauthn/verifier.cr`)
cross the line.

**(b) Proposed rule — "`unless` takes one idea."**
`unless` (postfix or block) may wrap **one positive condition**: a single
predicate call, a single comparison, or a single presence check. Never
`unless` with `&&`, `||`, or `!`; never `unless … else` (Crystal allows it;
AED bans it outright — an inverted two-branch is an `if` written backwards).
Compound conditions get a named `?` predicate first, then `unless` may carry
the name. `until` is covered (banned) by CF-2 — same negation tax.

**(c) Before/after.**

```crystal
# ✅ AED — name the compound, then the exception reads like English
def es256_key?(key) : Bool
  key.algorithm == COSE::Algorithm::ES256 && key.curve == COSE::EC2Curve::P256
end
raise Error.new("expected an ES256 key") unless es256_key?(key)

# 🚫 the reader must run De Morgan to know when this fires
unless key.algorithm == COSE::Algorithm::ES256 && key.curve == COSE::EC2Curve::P256
  raise Error.new("expected an ES256 key")
end

# 🚫 unless/else — an if, written in a mirror
unless info.email_verified
  reject_signup
else
  create_account
end
```

**(d) Cost.** One extra tiny method per compound; occasionally a predicate
used exactly once. Accepted: the predicate name doubles as documentation and
as a doc heading (see §Docs).

**(e) Mechanical check.** Flag: `unless` on a line containing `&&`, `||`, or
` !`; any `unless … else`; any `until`. All three are plain greps — ideal
hook material.

---

## Rule CF-5. Ternary picks between two spellings of one value

**(a) Why the syntax fights the rule.** A ternary compresses a branch into a
breath. That's fine when both arms are *values of the same idea*
(`success ? "info" : "warning"`), because the reader parses it as one noun
with two spellings. It fights the rule the moment an arm contains a call
with effects, another `?`, or the arms are different *actions* — then the
reader is executing code inside a noun slot.

**(b) Proposed rule — "Ternary is a value with two spellings, and it gets a
name."** A ternary is allowed only when **all** hold: both arms are simple
values (literal, variable, or a single pure call); no nesting; no side
effects; and the result is immediately **named** — assigned to a variable or
passed as a named/keyword argument whose name states what it is. Choosing
between two *actions* is always an `if/else`. Existing Rule 3's ban on
nested ternaries is subsumed here.

**(c) Before/after.**

```crystal
# ✅ AED — one noun, two spellings, and the noun is named at the call site
severity: success ? "info" : "warning",

# ✅ AED — named result
byte_length = curve == OKPCurve::Ed25519 ? 32 : 57

# 🚫 two different actions crammed into a noun slot
logged_in? ? render_dashboard : redirect_to_login

# 🚫 arms with their own lookups and fallbacks (real shape from icon_component.cr)
path = name ? (ICONS[name]? || "") : (@attributes["path"]? || "")
# ✅ instead: the branch is a decision — write it as one
if name
  path = ICONS[name]? || ""
else
  path = @attributes["path"]? || ""
end
```

**(d) Cost.** Some three-line `if`s where a one-liner "worked". Accepted:
the one-liner worked for the author; the `if` works for the reader.

**(e) Mechanical check.** Flag: a line matching the ternary shape that also
contains a second `?`-operator (nesting), a `!`-suffixed call, `<<`, `=`
inside an arm, or arms containing `(…)` with further calls; ternaries whose
result is not assigned or passed as an argument.

---

## Rule CF-6. Chains read like a sentence or get named waypoints

**(a) Why the syntax fights the rule.** `users.select(&.active?).map(&.email)`
*is* a sentence — "take the active users' emails." The syntax stops
cooperating when a link needs a multi-line block, when a `.try` hides a nil
branch mid-chain, or when link three depends on remembering what link one
produced. At that point the chain is a pipeline the reader must trace, not a
sentence they can hear. The census makes `.try` the sharpest instance: 98
uses in the template, many nested (`data["mail"]?.try(&.as_s) || …`), versus
only ~50 collection-chain links total.

**(b) Proposed rule — "Two links spoken, three links named."**

- A chain may have up to **two transformation links**, each in `&.method`
  shorthand, when it reads aloud as one sentence.
- Three or more links, or **any** multi-line `do … end` block mid-chain, or
  any link whose output type isn't obvious from its name → break the chain
  with **named waypoints**: intermediate variables named for *what the data
  is at that point* (`active_users`, `member_emails`), not for the operation
  (`filtered`, `mapped`, `result2`).
- `.each` (side effects) never follows transformation links in the same
  chain — name the collection first, then iterate it. A reader distinguishes
  "computing" from "doing" by the line break.
- `.try` chains: **one `.try` maximum per expression**, and only the
  `&.method` shorthand form. Two `.try`s, a `.try` with a block containing
  logic, or `.try` feeding `||` feeding `.try` → rewrite as an explicit
  nil-check guard or an `if value = expr` assignment-condition. (This
  restates existing Rule 2 with a hard threshold.)

**(c) Before/after.**

```crystal
# ✅ AED — two links, one sentence
member_emails = users.select(&.active?).map(&.email)

# ✅ AED — waypoints named for what the data IS
oauth_accounts   = accounts.select(&.oauth?)
verified_emails  = oauth_accounts.map(&.email).select(&.verified?)
verified_emails.each { |email| enqueue_welcome(email) }

# 🚫 the reader holds three intermediate shapes in their head, then side-effects
accounts.select(&.oauth?).map(&.email).select(&.verified?).each { |e| enqueue_welcome(e) }

# 🚫 nested try-fallback — three nil-branches hidden in one line (real shape, microsoft.cr)
email = data["mail"]?.try(&.as_s) || data["userPrincipalName"]?.try(&.as_s) || ""
# ✅ instead: each source named, the preference order visible as lines
primary_email  = data["mail"]?.try(&.as_s)
fallback_email = data["userPrincipalName"]?.try(&.as_s)
email = primary_email || fallback_email || ""
```

**(d) Cost.** More lines and more locals; hot paths allocate an intermediate
array per waypoint (if profiling ever shows it matters, note the exception
with a *why* comment per existing Rule 5). Accepted: this codebase reads far
more than it iterates.

**(e) Mechanical check.** Flag: ≥3 `.method(` / `&.` links on one expression;
`.each` preceded by `.map`/`.select`/`.reject` in the same statement; ≥2
`.try` in one expression; `.try do` block form; waypoint variables named
`result`, `tmp`, `filtered`, `x2` (existing Rule 4's list, extended).

---

## Rule CF-7. Errors are vocabulary; rescues say what they forgive

**(a) Why the syntax fights the rule.** `begin/rescue` reads like nothing at
all: a bare `rescue` is the statement *"if anything whatsoever goes wrong,
do this"* — which is almost never what the author meant and never what the
reader can verify. Exception flow is invisible control flow: the jump happens
on a line the reader can't see. The only way it reads like a statement is if
the **error type carries the sentence**. The census shows the raising side
already speaks: 138 typed raises vs 14 string raises, and a real error
vocabulary exists (`WebAuthn::Registration::UnsupportedAttestation`,
`Storage::FileNotFoundError`, `Authorization::…`). The rescuing side lags:
a large share of the 65 rescues are bare.

**(b) Proposed rule — "Raise nouns, rescue by name."**

- **Raising**: always a typed error from the domain vocabulary; new failure
  modes mint a new subclass under the module's base `Error` (the house
  pattern: `class Error < Exception` per module, specific subclasses under
  it). A bare `raise "string"` is allowed only for
  configuration-impossible states at boot (`"ANTHROPIC_API_KEY required"`).
- **Rescuing**: `rescue ex : SpecificError` naming the narrowest type that
  states what you forgive. A broad `rescue ex` is permitted only at
  **boundaries** — the outermost edge of a request, a fiber, a mailer
  delivery, a worker — and must (i) bind `ex`, (ii) log or report it, and
  (iii) carry a *why* comment stating the boundary ("mailer must never take
  the request down with it"). A bare `rescue` with no binding and no comment
  is banned.
- **Postfix `rescue nil`** only around a *single parse/convert expression*
  where nil is the honest answer (`Time.parse_rfc2822(date) rescue nil` —
  the two existing uses both qualify). Never around a call with side effects.
- **`ensure`** is for cleanup only (close, unlink, reset) — never business
  logic; if an `ensure` grows past ~3 lines, extract it to a named cleanup
  method (`ensure … close_worker_pipes`).
- **`retry`** (census: zero) is banned in its raw form; retrying is a policy,
  so it must live in a method named for it (`with_retries(attempts: 3) do`)
  that owns the counter and backoff — a raw `retry` is an unbounded loop
  wearing an exception costume.

**(c) Before/after.**

```crystal
# ✅ AED — the rescue states exactly what it forgives, and why
def find_verified(token : String) : Users::Regular?
  payload = decode_session_token(token)
  Users::Regular.find(payload.user_id)
rescue JWT::ExpiredSignatureError
  # Expired session is a normal event, not an error: the caller re-authenticates.
  nil
end

# 🚫 forgives everything — a typo in decode_session_token now returns nil forever
def find_verified(token : String) : Users::Regular?
  Users::Regular.find(decode_session_token(token).user_id)
rescue
  nil
end

# ✅ AED — broad rescue earns its breadth at a boundary, with the why on record
spawn do
  run_heartbeat_loop(response)
rescue ex
  # Boundary: a dead client must never crash the server fiber pool.
  Log.warn(exception: ex) { "SSE heartbeat fiber exited" }
end
```

**(d) Cost.** Naming narrow error types takes real thought (what *can* this
raise?), and Crystal won't tell you — there are no checked exceptions.
Sometimes you'll name two types where a bare rescue was one word. Accepted:
that thought is precisely the documentation the next agent needs; a bare
rescue is a claim of omniscience.

**(e) Mechanical check.** Flag: `rescue` at end-of-line or `rescue$` with no
type and no `ex` binding; `rescue ex` (untyped) with no comment within 2
lines; `raise "` outside `config/`/boot files; any `retry` keyword; `ensure`
blocks > 3 lines; postfix `rescue nil` on a line containing `save`/`create`/
`delete`/`<<`/`=` (side-effect heuristic).

---

## Rule CF-8. Three ands make a question method

**(a) Why the syntax fights the rule.** Boolean operators are the one place
where "statement-like" degrades *gradually*: `a && b` still reads, `a && b || c && !d`
is a logic puzzle. The reader shouldn't need parentheses skills to know when
a branch fires. The template's 195 `?` methods prove the extraction habit
exists — this rule just fixes the threshold.

**(b) Proposed rule — "Two operators is a sentence; three is a method."**
A condition (in `if`, `unless`, `while`, a guard, or a ternary) may contain
at most **two** boolean operators, and never a *mix* of `&&` and `||`
without extraction — a mix means precedence, and precedence means the
reader is parsing, not reading. Beyond that, extract either a **`?` question
method** (when the concept recurs or belongs to the object:
`team_lead?`, `es256_key?`) or a **named `Bool` local** (when it's one-off
and built from locals: `state_matches = …`). The name must be the *positive*
form of the question — no `not_invalid?`.

**(c) Before/after.**

```crystal
# ✅ AED — the condition IS the sentence
if oauth_callback_valid?(provider, expected_state, state, code)
  ...

private def oauth_callback_valid?(provider, expected_state, state, code) : Bool
  return false unless provider && expected_state && state && code
  constant_time_equal?(expected_state, state)
end

# 🚫 four conditions and a continuation line — a parser test, not a sentence
unless provider && expected_state && state && code &&
       constant_time_equal?(expected_state, state)
  ...

# ✅ AED — mixed operators earn a named local even at only three terms
signature_acceptable = algorithm.rs? || algorithm.ps?
return unless signature_acceptable && key_present?
```

**(d) Cost.** Method count grows; a hostile reviewer can call `?` methods
"indirection". Accepted — with one honest caveat: the extracted name must
truly summarize, or you've hidden the puzzle behind a label. Bad name = worse
than inline. Naming quality falls to existing Rule 4.

**(e) Mechanical check.** Flag: any condition line with ≥3 of (`&&`, `||`);
any condition mixing `&&` and `||`; any `if`/`unless`/`while` condition
spilling to a continuation line; predicate names starting `not_`/`no_`.

---

## Rule CF-9. Every fiber gets a job title

**(a) Why the syntax fights the rule.** Concurrency breaks the deepest
assumption of statement-reading: that the next line happens next. `spawn do`
means "meanwhile, elsewhere" — and an anonymous block gives the reader no
noun to hold on to while the main story continues. Channels are worse:
`ch.receive` is a sentence missing its subject (*receive what, from whom?*).
The census says our exposure is small (4 spawns, 1 channel, 0 `select`) but
the two real sites (`isolated_worker.cr`, `mcp_sse_controller.cr`) are
exactly the hardest code in the template — small count, maximal reader risk.

**(b) Proposed rule — "Meanwhile, the *named* worker does its *named* job."**

- Every `spawn` body is a **single call to a named method** whose name is
  the fiber's job (`spawn { pump_input_to_child(in_writer, input, writer_done) }`,
  `spawn { run_heartbeat_loop(response) }`). Never an inline multi-line
  block: the reader should meet a fiber the way they meet an employee — by
  title — and only read the job description if they choose to. Crystal's
  `spawn(name: "heartbeat")` is encouraged in addition (it labels runtime
  diagnostics) but the method name is the load-bearing part.
- Every `Channel` variable is named for its **cargo and direction**
  (`writer_done`, `parsed_events`, `shutdown_requested`) — the existing
  `writer_done = Channel(Exception?).new(1)` is the exemplar. Bare `ch`
  banned.
- A `.receive` reads as *"wait for the writer to be done"* only if the line
  says so: `writer_error = writer_done.receive`.
- Concurrency `select` (census: zero): when it arrives, each branch must be
  a one-line guard-style clause calling a named method — same menu
  discipline as CF-1.
- Every fiber body's outermost layer is a boundary rescue per CF-7 — a fiber
  that dies silently is control flow the reader can never follow.

*How a statement-reader follows concurrent flow under this rule:* the main
story reads linearly and each `spawn` line reads as a one-sentence aside —
"meanwhile, pump input to the child" — and each `receive` reads as
"wait here for X." The reader never has to interleave two instruction
streams; they follow one story with named waypoints where the streams touch.

**(c) Before/after.**

```crystal
# ✅ AED — the aside has a title; the join point says what it waits for
writer_done = Channel(Exception?).new(1)
spawn { pump_input_to_child(in_writer, input, writer_done) }
output = drain_child_output(out_reader)
writer_error = writer_done.receive

# 🚫 an anonymous ten-line meanwhile — the reader must simulate two timelines at once
writer_done = Channel(Exception?).new(1)
spawn do
  begin
    in_writer.write(input) unless input.empty?
    err = nil
  rescue ex
    err = ex
  ensure
    in_writer.close
    writer_done.send(err)
  end
end
```

**(d) Cost.** Method extraction can force explicit parameter passing where a
closure captured silently — that's several extra tokens per fiber, and
occasionally a small struct to carry them. Accepted eagerly: silent capture
is precisely what makes concurrent code unreadable (and, per the `gc_arena`
warnings, unsafe — a named method's parameter list *is* the audit of what
the fiber touches).

**(e) Mechanical check.** Flag: `spawn do`/`spawn {` whose body exceeds 1
statement; channel locals named `ch`/`chan`/`c`; a `spawn` whose body lacks
a rescue and whose called method lacks one (approximate: warn on every spawn,
require the boundary-rescue comment to silence); any `select` branch longer
than one line.

---

## Rule CF-10. `?` asks, `!` warns — and the suffix is a promise

**(a) Why the syntax fights the rule.** The suffixes are Crystal's built-in
statement-reading aid — `verified?` reads as a question, `save!` as a
warning — but only if they're *reliable*. A `?` method returning a `String?`
"sometimes-value" instead of a `Bool`, or a `!` method that's merely "the
other version", breaks the reader's trained reflex and silently poisons
every future read. Census: 195 `?` defs and 10 `!` defs in the template —
the reflex is trainable; the contract just needs writing down.

**(b) Proposed rule — "The suffix is a promise."**

- `def foo?` returns `Bool` — full stop — with one blessed exception: the
  Crystal-stdlib **maybe-lookup** convention (`session["oauth_state"]?`,
  `ENV["KEY"]?`, `find_by?`) where `?` means *nil instead of raising*. Both
  are questions ("is it?" / "is it there?"); nothing else earns the mark.
- `def foo!` means **raises where `foo` returns nil, or mutates the
  receiver** — the two Ruby/Crystal senses — and every `!` method's doc
  comment states *which* danger it warns about, in one line.
- In conditions, prefer the `?` form over comparison chains
  (`user.verified?` not `user.verified_at != nil`).
- Chaining: a `!` call never appears mid-chain (`fetch!.parse.render` hides
  the raise in the middle of a sentence — the raise belongs on its own
  line, where a guard or rescue can be seen next to it). A `?` predicate
  never has its result chained onward (`valid?.to_s` is a smell: a question
  answers, it doesn't pipeline).

**(c) Before/after.**

```crystal
# ✅ AED — the question mark tells the truth
def team_member? : Bool
  @context.try(&.team_membership) != nil
end

# 🚫 a "question" that answers with a maybe-string — the reflex is now poisoned
def admin_role?
  membership.role if membership.admin?
end

# ✅ AED — the raise stands on its own line where the reader can see it
document = Document.find!(document_id) # raises Grant::Querying::NotFound
render(document)

# 🚫 the raise hides mid-sentence
render(Document.find!(document_id).with_sections)
```

**(d) Cost.** The maybe-lookup exception means `?` is *two* promises, not
one — genuinely a wart, but it's stdlib-load-bearing (98 `.try`s and every
`[]?` depend on it), so we document it rather than fight it. Some `!`
doc-comment ceremony.

**(e) Mechanical check.** Flag: `def …?` with a declared return type other
than `Bool` outside index/find/lookup names; `def …!` with no doc comment;
`!`-suffixed call followed by `.` on the same line; `?`-suffixed predicate
call followed by `.` (excluding `[]?`/`find_by?`-style lookups).

---

## Rule CF-11. Macros write code; they don't hide flow

**(a) Why the syntax fights the rule.** `{% if flag?(:preview_mt) %}` is
control flow the runtime reader *cannot see executing at all* — the branch
was taken at compile time, and half the file's text is a ghost. `macro
included` generates methods that exist nowhere in the source a reader greps.
Both defeat statement-reading not by being dense but by being **invisible**.
Census: 3 macro defs, 2 compile-time ifs — rare, so the rule is a fence, not
a renovation.

**(b) Proposed rule — "Compile-time branches speak for both worlds."**

- `{% if %}` / `{% else %}` is allowed only for **platform/flag gating**
  (`flag?(:preview_mt)`, `flag?(:gc_agentc)`), placed at the **top level of
  a method or file section** — never interleaved inside a runtime `if`
  ladder. Each branch's first line is a comment stating which world this is
  and what the other world does (`# MT builds: forking is unsupported —
  raise; single-thread builds take the fork path below`). The existing
  `isolated_worker.cr` / `gc_arena.cr` sites already approximate this.
- `macro` definitions live only in **concerns and infrastructure**
  (`src/models/concerns/`, `src/runtime/`), never in controllers/views/
  business logic. Every `macro included` carries a comment block listing,
  by name, the methods/columns it generates (`soft_deletable.cr`'s
  `column deleted_at` style is halfway there — add the roster comment), so
  grep-for-definition finds a mention even though the def is generated.
- No macro-generated *runtime branching* whose shape depends on macro logic
  (a macro that emits different `if` ladders per include is a puzzle box).
  Generate declarations and delegations; keep decisions in visible code.
- `{% for %}` (census: zero) — same fence: declaration generation only.

**(c) Before/after.**

```crystal
# ✅ AED — the ghost branch is narrated for the reader of either world
def self.run(&block : -> Bytes) : Bytes
  {% if flag?(:preview_mt) %}
    # MT builds: fork() after threads exist inherits poisoned locks — refuse loudly.
    raise UnsupportedError.new("IsolatedWorker.run requires the single-threaded runtime")
  {% else %}
    # Single-threaded builds: fork, run the block in the child, reap the bytes.
    run_in_forked_child(block)
  {% end %}
end

# 🚫 compile-time and runtime conditions braided together — nobody can trace this
{% if flag?(:gc_agentc) %} if ENABLED && {% if flag?(:preview_mt) %} false {% else %} arena_ready? {% end %} ... {% end %}
```

**(d) Cost.** The roster comment can drift from what the macro actually
generates (comments always can); the "concerns only" fence occasionally
forces a small concern file where an inline macro felt convenient. Accepted:
invisible code is the single most expensive thing to hand a coding agent.

**(e) Mechanical check.** Flag: `{% if` on a line that also contains runtime
`if`/`unless`; `macro ` definitions outside `src/models/concerns/` and
`src/runtime/`; `macro included` without a comment containing `generates`
within 3 lines; nested `{%` inside a method body deeper than one level.

---

## How these rules feed documentation generation

AED's premise for docs: **the names are the source of headings.** Prose docs
rot; names are re-verified by every compile and every review. Control flow is
where this pays off most, because control flow *is* the behavior readers ask
about ("when does it refuse?", "what can go wrong?", "what runs in the
background?"). Each rule above was written so its mandatory names map onto a
doc section mechanically:

| Rule | Named artifact | Doc surface it generates |
|---|---|---|
| CF-3 Guards first | The guard block of each public method | **"Refuses when…"** bullet list per operation — each guard line becomes one bullet, its *why*-comment becomes the bullet's explanation. The wire/cose.cr guard stack *is* its security doc. |
| CF-8 Question methods | `?` predicates referenced by guards & branches | **Glossary of business rules** — `team_lead?`, `oauth_callback_valid?` become glossary entries; the predicate body is the definition. Policy classes' `can?` menus render directly as **permission tables** (action × predicate). |
| CF-1 Case menus | `case` subject + `when` labels + extracted branch methods | **Decision tables** — "depending on `default_provider`: …" — subject is the table title, when-labels are rows, extracted method names are the outcome column. The mandatory `else` becomes the documented fallback row. |
| CF-2 Loop finish lines | Loop-extracted body methods, `loop`-named methods | **"Process steps"** — `consume_blockquote`, `emit_table_row` list as the pipeline's stages; `run_heartbeat_loop` names itself in ops docs. |
| CF-7 Error vocabulary | Typed error classes; typed rescues | **"What can go wrong"** section per module — the error subclass tree renders as the failure catalogue; each typed `rescue` site documents which layer absorbs which failure. This is also compliance evidence (SOC2 loves an error taxonomy). |
| CF-9 Fiber job titles | Spawn-target method names; channel names | **"Background work"** section — every `spawn`-called method is a row: job title, what it waits on (channel names), its boundary rescue. Ops runbooks can be generated from exactly this. |
| CF-11 Macro rosters | The `generates:` comment roster | **"Generated API"** appendix per concern — the roster is the contract; docs list it verbatim so generated methods are findable. |
| CF-10 Suffix promises | `!` doc comments | **Danger callouts** — every `!` method's one-line warning surfaces as a ⚠️ note wherever the method is documented. |

**What does *not* surface:** ternary values, waypoint locals (CF-6), named
`Bool` locals (CF-8's one-off form), and cursor predicates — these are
paragraph-level names for the human reading the file, below the doc
altitude. The doc generator's selection rule is mechanical: **a control-flow
name surfaces to docs iff it is a method name** (predicates, branch
extractions, loop bodies, fiber jobs, error classes). Locals stay local.

A future `docs/` generator (or a doc-writing agent) therefore needs only:
method names + `?`/`!` suffixes + guard blocks + case labels + error class
tree + spawn targets — all extractable with the same grep-grade tooling as
the mechanical checks in (e). That symmetry is deliberate: **the linter's
tokens and the doc generator's tokens are the same tokens.**

---

## Implementation sketch (if adopted)

1. Add the accepted rules to `.claude/skills/aed-conventions/SKILL.md` as a
   "Control flow" section, keeping the existing 6 rules and voice; extend
   the end-of-edit checklist with one line per rule.
2. Extend `.claude/hooks/crystal_check.sh` (or a sibling `aed_lint.sh`) with
   the grep-grade checks from each rule's (e) — start **warn-only**, promote
   to blocking per-rule once the existing codebase is swept. Candidates for
   custom Ameba rules later; greps first (same engine, zero deps).
3. Sweep order by census-weighted payoff: (1) bare rescues → typed/commented
   (~40 sites), (2) nested `.try` fallbacks (~a dozen sites), (3) compound
   `unless` (+ the two `spawn do` bodies), (4) case menus without `else`.
   The website's markdown parser needs no changes — it already conforms to
   CF-2's cursor-loop shape.

---

## Open questions before v1.1.0 final

These are the thresholds still under review. Each rule above is usable today;
what is unsettled is exactly where the line falls, not whether the rule holds.
Opinions are welcome in
[Discussions](https://github.com/AgentC-Consulting/aed-conventions/discussions).


1. **Case threshold (CF-1):** Adopt "3+ branches or use if/else", every
   `when` body ≤ 3 lines, mandatory `else`? Or allow 2-branch `case` when
   the subject name carries weight?
2. **Ban `until` outright (CF-2/CF-4)?** Census shows zero uses, so it's
   free today — but it's idiomatic Crystal and some readers find
   `until done?` natural. Ban, or allow with single-predicate conditions?
3. **Guard contiguity (CF-3):** Enforce "all guards before the first story
   statement" as a hard rule, or as a default with a *why*-comment escape
   hatch for genuinely late preconditions?
4. **Bare `rescue ex` at boundaries (CF-7):** Is comment-plus-log sufficient
   license, or do you want a named helper (`swallowing_errors(context) do`)
   so boundaries are greppable as one idiom?
5. **`.try` hard cap (CF-6):** One `.try` per expression is aggressive given
   98 existing uses — adopt as blocking for new code and sweep old, or
   warn-only permanently?
6. **Spawn body = single named call (CF-9):** Apply retroactively to the two
   existing spawn sites (`isolated_worker.cr`, `mcp_sse_controller.cr`) in
   the sweep, or grandfather them with comments?
7. **Enforcement vehicle:** extend `crystal_check.sh` with warn-only greps,
   write custom Ameba rules, or both (greps now, Ameba when stable)?
8. **Docs pipeline:** is the "method names surface, locals don't" selection
   rule right for the doc generator, and which doc surface should be built
   first — permission tables from policies (cheapest, highest compliance
   value) or "What can go wrong" from the error tree?
9. **Ternary strictness (CF-5):** the `success ? "info" : "warning"`
   argument-position form is blessed; do you also want to allow simple
   ternaries inside string interpolation (common in view components), or
   force extraction there too?
10. **Where does this land?** Fold into the existing SKILL.md as one
    "Control flow" section (one skill, longer), or a sibling
    `aed-control-flow` skill file referenced from the main one (two hops,
    shorter files)?

---

*Chapter 06 of the AED canon · the census and code shapes above are drawn from
AgentC Consulting's own production Crystal, so the rules target real frequency
rather than theory · back to the [reading order](README.md#reading-order)*
