---
description: Plan features and write pseudocode that already carries release-quality AED (Agent-Enhanced Development) names, so no renaming refactor is needed later — feature story to nouns and verbs, "When … then …" process statements, every name checked before code exists. Use when planning, designing, or writing pseudocode or a code skeleton in projects that adopt AED (AED named in CLAUDE.md or README), or when the user asks for AED planning.
---

# AED Planning — decide the names at pseudocode time

The public canon: <https://github.com/AgentC-Consulting/aed-conventions> —
chapter 04 covers feature stories, chapter 03 covers the "when" grammar.

This is the stage the whole practice is aimed at. Naming is not a cleanup task
you do before release — it is a **planning** task you do before the first line of
code exists.

## The law

**Pseudocode and plans use release names. Never placeholders.**

A plan that says `process the data` becomes code that says `process the data`.
A plan that says `handle_user`, `doStuff`, `TODO: helper here`, `data`, `result`,
or `Manager` becomes exactly those names in the shipped file, because the model
writing the implementation reads the plan and follows it. Placeholder names in a
plan are not neutral — they are instructions.

So the plan's `then lock each customer's account` step is written as
`prevent_each_customer_from_accessing_their_account`, and that is the method name
that lands in the file.

## Step 1 — the feature story

Start from a plain statement of what someone wants:

`I want to create a new user and assign them to an account.`

With a persona attached, the canon's story form is:

`As an **Admin** user, I want to _create_ a new **user** **_and_** _assign_ them to an **account**`

and its anatomy is:

`As a (specify persona), I want to (RESTful verb, or “perform”) (“a” or “multiple”) (data model name of an existing data model) and (AR relationship name/type or “perform”) (data model name or Process Manager name if performing a process)`

Read the story like a grammar exercise:

- **Nouns → data models and attributes.** "user", "account" are models; the
  details you had to ask about ("their legal entity name", "their payment terms")
  are attributes.
- **Verbs → process managers and methods.** "create", "assign" are the
  operations. A RESTful verb (GET/POST/PUT/PATCH/DELETE) maps to framework CRUD.
- **The persona** tells you a view and a controller action are in scope, and which
  authorization surface the route belongs to.
- **`perform`** is the special verb. The canon:

  > A unique verb of “perform” can be used to trigger a workflow that is not RESTful. This is the keyword you primarily use for our unique business logic, aka your special sauce.

  A `perform` story means you are writing a **process manager**, not a controller
  action.
- **Jargon is a flag.** "assign" aliases a `belongs_to`. If a word in the story is
  company jargon, define it in the plan before deriving names from it; ask the
  user if you cannot.

## Step 2 — write each process as a When-statement

> Processes start with a “when” keyword, always. Because a process is “when” something happens!

The canon's example:

`When a list of Customer ID’s is provided, then lock each customers account.`

- The **when** clause names the qualifying information the process needs before it
  can run. Those become the **`initialize` parameters**. Here, "a list" is an
  Array of IDs — Integer, ULID, UUID, whatever the Customer model uses.
- The **then** clause names the operations. Those become the **methods** called by
  `perform`.

Expand until no jargon is left. The canon's own expansion of the same statement:

`When an array of Integers that represent Customer IDs is provided then loop through each Customer account using the ID to find the correct record and update the necessary attribute that will prevent the Customer from accessing their account.`

That expanded sentence is nearly the pseudocode. That is the point.

## Step 3–6 — the planning procedure

1. **Write the feature story** as a plain statement (persona form if there is a
   persona).
2. **Write each process as a When-statement**, then expand it until every piece of
   jargon is spelled out in terms of models, attributes, and operations.
3. **Derive every name**: nouns → models + attributes (typed: primitive,
   enumerable, boolean, non-primitive); verbs → process-manager class names and
   method names. Apply the AED naming rules — singular models, feature-namespaced
   classes, `list_of_`/`collection_of_`/`array_of_`, boolean-as-question,
   usage-phrase non-primitives.
4. **Batch-check the names before writing anything**:
   ```bash
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind class Billing::AggregateEnterpriseCustomersUnderOneBillingEntity
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind collection array_of_customer_ids_to_aggregate list_of_all_active_subscriptions
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind boolean is_this_an_enterprise_customer
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind attribute full_legal_entity_name payment_terms_in_number_of_days
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind method attach_each_customer_to_the_enterprise_billing_entity
   ```
   `--kind` is one of `boolean | collection | attribute | class | method`. Fix
   every warn **now**, while the name exists in one place: the plan.
5. **Emit the plan / pseudocode skeleton using ONLY approved names.** No
   placeholders survive into the artifact the implementer reads.
6. **Note per file where each class lives** — the file is the lower snake_case of
   its primary class, and a namespaced class lives in a folder named for the
   namespace. State the path next to every class in the plan.

## Worked example

Storyline from the canon: the SaaS has `Customer` and `Subscription`; enterprise
deals now require Customers to aggregate into a single billable entity, and those
Customers must be prevented from adding subscription items.

**1. Feature story**

`As an **Admin** user, I want to _perform_ an aggregation of multiple **Customers** under one **EnterpriseCustomerBillingEntity** and prevent those Customers from adding subscription items.`

**2. When-statement**

`When an EnterpriseCustomerBillingEntity and an array of Integers that represent Customer IDs are provided, then attach each Customer record to that billing entity, flag each Customer as an enterprise customer, and prevent each Customer from adding any subscription items.`

**3. Names derived**

| From the story | Kind | Name |
|---|---|---|
| the process | class | `Billing::AggregateEnterpriseCustomersUnderOneBillingEntity` |
| "an EnterpriseCustomerBillingEntity is provided" | init param | `enterprise_customer_billing_entity` |
| "an array of Integers that represent Customer IDs" | init param (collection) | `array_of_customer_ids_to_aggregate` |
| "attach each Customer record" | method | `attach_each_customer_to_the_enterprise_billing_entity` |
| "flag each Customer as an enterprise customer" | method | `flag_each_customer_as_an_enterprise_customer` |
| "prevent … adding any subscription items" | method | `prevent_each_customer_from_adding_subscription_items` |
| Customer's enterprise flag | boolean attribute | `is_this_an_enterprise_customer` |
| Customer's subscriptions | enumerable attribute | `list_of_all_active_subscriptions` |
| entity's legal name / terms | primitive attributes | `full_legal_entity_name`, `payment_terms_in_number_of_days` |
| customers already handled | enumerable attribute | `collection_of_customers_that_were_aggregated` |

**4. Pseudocode skeleton** — file `billing/aggregate_enterprise_customers_under_one_billing_entity.cr`

```crystal
# File found under `billing/aggregate_enterprise_customers_under_one_billing_entity`
class Billing::AggregateEnterpriseCustomersUnderOneBillingEntity
  property enterprise_customer_billing_entity : EnterpriseCustomerBillingEntity
  property array_of_customer_ids_to_aggregate : Array(Int32) = [] of Int32
  property collection_of_customers_that_were_aggregated : Array(Customer) = [] of Customer
  property all_of_the_customers_have_been_aggregated : Bool = false

  def initialize(@enterprise_customer_billing_entity, @array_of_customer_ids_to_aggregate)
  end

  def perform
    attach_each_customer_to_the_enterprise_billing_entity
    flag_each_customer_as_an_enterprise_customer
    prevent_each_customer_from_adding_subscription_items
  end

  private def attach_each_customer_to_the_enterprise_billing_entity
    # Your business logic goes here
  end

  private def flag_each_customer_as_an_enterprise_customer
    # Your business logic goes here
  end

  private def prevent_each_customer_from_adding_subscription_items
    # Your business logic goes here
  end
end
```

Supporting model changes stated in the same plan:

- `customer.cr` → `Customer` gains `property is_this_an_enterprise_customer : Bool`
  and renames `subscriptions` to `list_of_all_active_subscriptions`.
- `enterprise_customer_billing_entity.cr` → new model with
  `full_legal_entity_name`, `payment_terms_in_number_of_days`,
  `billing_cycle_frequency`, `billing_cycle_time_period`,
  `maximum_customers_according_to_the_contract_limit`,
  `current_count_of_customer_accounts`.

Note what the skeleton already is: `perform` reads as the When-statement's "then"
clause, in order. Nothing in it needs renaming.

## The payoff

The shell written from this plan is already on track. Because the names were
decided and checked while they existed in exactly one place — the plan — the
refactor/rename pass at the end of the feature shrinks toward zero. There is no
"we'll clean up the names before merge" step, because there is nothing left to
clean.

If you find yourself about to write a placeholder name "just for the skeleton",
that is the signal that step 2 is not finished: expand the When-statement until
the real name is obvious, then write it.
