---
description: Name and review code with AED (Agent-Enhanced Development) conventions from AgentC Consulting — singular models, feature-namespaced classes, statement-shaped class and method names, `first_name` not `name`, `list_of_` collections, booleans phrased as questions, snake_case files matching the class. Use when writing, naming, renaming, or reviewing classes, attributes, methods, or files in projects that adopt AED (AED named in CLAUDE.md or README), or when the user asks for AED naming.
---

# AED Naming Conventions

The public canon: <https://github.com/AgentC-Consulting/aed-conventions> —
chapters 01–06, plus the cheat sheet and the edit-level style rules in that
repository. This skill is the working distillation; everything you need to apply
the conventions is embedded here.

## The guiding rule

> **Prefer the form that reads like a plain statement of intent. Reach for
> shorthand only when it makes the intent _clearer_, never just shorter.**

Clever, compressed syntax saves the author a few keystrokes and costs every later
reader — human or agent — a re-parse. Code is read and modified far more often
than it is written. Optimize for the reader.

## Why verbose naming helps a model (the token-window rationale)

LLMs read text as overlapping windows of tokens, and meaning comes from which
tokens keep company with which — "This association is how the relationship of a
flow of words is established and influences the direction that the model
computes." A name like `list_of_all_active_subscriptions` puts the container
type, the scope, and the purpose inside a single window; `subscriptions` puts
almost nothing there, so the model has to guess from surrounding code that may be
thousands of tokens away. That is why the canon's next line is:
"This is why a naming convention needs to be very consistent."

The payoff compounds: as files grow, verbose consistent names make completions
*more* accurate, not less.

## The rule table

| Thing | Rule | Good | Bad |
|---|---|---|---|
| Data model | Singular; concerned only with its own individual behavior | `Customer` | `Customers` |
| Class | Namespaced by the **feature** being implemented | `Billing::ActivateNewCustomerSubscription` | `NewCustomerSubscription` |
| Class name | A short statement or phrase clearly expressing the process performed | `PerformCustomerAccountLocking` | `LockCustomers` |
| Primitive attribute | A short statement of the attribute's intended purpose | `first_name`, `full_name`, `email_address` | `name`, `email` |
| Enumerable attribute | Prefix `list_of_` / `collection_of_` / `array_of_` + what it holds | `list_of_previous_orders` | `orders`, `previous_orders` |
| Enumerable, dynamic language | Optionally append the element type with `_as_` | `list_of_previous_orders_as_hashes` | `orders` |
| Non-primitive attribute | A phrase expressing how the attribute is to be **used** | `currently_active_subscription` (acceptable: `active_subscription`) | `subscription` |
| Boolean attribute | Phrased as a yes/no question, as if the expression began with `if` | `has_a_valid_payment_method`, `is_this_an_enterprise_customer` | `payment_method_present` |
| Method | A phrase or statement explaining the process taking place; include wording for the expected return type when possible | `retry_customers_who_failed_payment_processing_with_an_expired_card` | `retry` |
| Method parameters | Named when possible, ideally reading as a plain statement | `perform(for_customer:, using_payment_method:)` | `perform(c, pm)` |
| File name | Lower snake_case of the primary class in the file | `process_customers_with_expired_subscriptions.cr` | `pcwes.cr` |
| Namespaced class | Lives in a folder named for the namespace | `billing/process_customers_with_expired_subscriptions.cr` | `services/pcwes.cr` |
| Data models | Rarely namespaced — reserve for STI or similarly specific cases | `Customer` | `Billing::Customer` |

General principles: avoid unnecessary jargon or slang; names that read like plain
English are preferred.

**Never create a whole new lexicon for your code base by applying a theme.** No
Star Wars class names, no weather metaphors, no house vocabulary invented to feel
clever. (A *code name* for the code base itself is entirely acceptable and
expected — that is not a lexicon.)

## The canon's own before/after

```crystal
# 🚫 "good code" by ordinary standards — and nearly meaningless to a model
class Customer
  property name : String
  property email : String
  property subscriptions : Array(Subscription) = [] of Subscription
end

# ✅ AED — every name carries its own context
class Customer
  property first_name : String
  property last_name : String
  property email_address : String
  property list_of_all_active_subscriptions : Array(Subscription) = [] of Subscription
  property is_this_an_enterprise_customer : Bool
end
```

"Did you have any idea that all you needed to track were the active
subscriptions? Maybe during the conversation with a product owner, but the AI
would have no idea."

## Per-language adaptation

Crystal is the canonical language of the canon; the rules are about reading, not
syntax, so they port directly.

| Language | Adaptation |
|---|---|
| **Crystal** (canonical) | Rules as written. `property` / `getter` for accessors, `private def` step methods, `snake_case.cr` files, namespace folders. Run `crystal tool format`. |
| **Ruby** | Same rules, with two allowances: predicate methods **may** end in `?` (`has_a_valid_payment_method?`) — the `?` is the question mark the name is already asking; and **respect Rails framework conventions** for CRUD actions, association names, and generated scopes. AED governs your domain/business logic — process managers, POROs, service objects, domain attributes — **not the framework surface**. Do not rename `create`/`update`/`destroy`, `has_many :orders`, or route helpers to satisfy AED. |
| **Elixir** | Ecto schema fields follow the same boolean and collection rules (`has_a_valid_payment_method`, `list_of_previous_orders` for a loaded assoc field); modules are namespaced by feature (`Billing.ActivateNewCustomerSubscription`); files are snake_case under a folder per namespace. Function names are statements; use keyword-list or struct arguments where the canon says "named parameters". Framework surface (Phoenix controller actions, `changeset/2`) stays idiomatic. |

Any other language: keep the semantics, adopt the host language's casing (a
`PascalCase` class, a `camelCase` attribute) rather than importing snake_case
where it would fight the ecosystem.

## The shorthand boundary

AED is "clarity first," not "verbose always." Idioms that are *more* readable are
encouraged: `arr.map(&.name)`, `value.try(&.to_i64?)`, a `?`-suffixed predicate,
a single well-named guard expression.

**The test is always: does a reader who has never seen this code understand the
intent on first pass?** If yes, keep it. If they have to mentally execute it,
expand it.

## Workflow — check names, don't guess

Before introducing **any** new class, attribute, or method name:

```bash
ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind boolean has_a_valid_payment_method
ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind collection list_of_previous_orders
ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind attribute first_name email_address
ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind class Billing::ProcessCustomersWithExpiredPaymentMethods
ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind method retry_customers_who_failed_payment_processing
```

`--kind` is one of `boolean | collection | attribute | class | method`. Multiple
names can be checked in one call — batch them.

After editing files, run the linter over the files you touched:

```bash
ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb path/to/edited_file.cr path/to/other_file.rb
```

**Treat a warn as rename-now.** A name that survives one edit becomes a name
other code calls; renaming is cheapest in the minute you invented it. Never defer
a naming warn to "a cleanup pass later" — the entire point of AED is that the
cleanup pass shrinks toward zero.

## Reviewing existing code

When asked to review, report findings in this order: (1) names that mislead
(`subscriptions` that only ever holds active ones), (2) missing collection /
boolean prefixes, (3) single-word primitives that hide which value they store,
(4) classes not namespaced by feature, (5) files whose name does not match their
primary class. Propose the replacement name for every finding — a review that
only flags is half a review.

## Checklist before you finish an edit

- [ ] Type branches use explicit `if … is_a?` (not `case … in` against Grant types).
- [ ] No one-liner hides more than one operation from the reader.
- [ ] Names state intent; no `tmp`/`x`/`res2`.
- [ ] Comments explain *why*, never restate *what*.
- [ ] `crystal tool format` (or the language's canonical formatter) is clean.
- [ ] The edit-time type check passed (no `case is not exhaustive`, no undefined methods).
- [ ] Every new name was checked with `aed_lint.rb check-name`, and every warn was renamed, not deferred.

The six edit-level style rules behind that checklist — explicit `if … is_a?`,
name the thing instead of chaining, guard clauses over nested ternaries, full
intention-revealing names, comments that say *why*, one statement per line with
the formatter owning layout — are published in full at
<https://github.com/AgentC-Consulting/aed-conventions/blob/main/CONVENTIONS.md>.
