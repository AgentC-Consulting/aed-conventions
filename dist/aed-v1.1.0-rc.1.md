# AED Conventions — the complete canon (v1.1.0-rc.1)

> **This file is generated.** It is every chapter of
> [AED Conventions](https://github.com/AgentC-Consulting/aed-conventions)
> concatenated in reading order, so the whole thing can be fetched with one
> request or pasted into one context window. The repository is canonical; if
> this file and the repository disagree, the repository wins.
>
> Fetch the newest copy:
> `https://raw.githubusercontent.com/AgentC-Consulting/aed-conventions/v1.1.0-rc.1/dist/aed-v1.1.0-rc.1.md`
>
> Chapters 01–04, 07 and the quick reference are the author's original notes,
> published verbatim — including his own work-in-progress markers. Chapter 05
> (`CONVENTIONS.md`) and chapter 06 are later work.
>
> Licensed CC BY 4.0 (prose) and MIT (code examples) — AgentC Consulting,
> https://agentc.consulting

## Contents

- 01 · Why Models Need This — `01_why_models_need_this.md`
- Naming Conventions Overview for Agent Enhanced Development (AED or AE-dev) — `02_naming_conventions.md`
- Process Manager Conventions — `03_process_managers.md`
- Agent Enhanced Development - The Whole Process — `04_feature_stories.md`
- AED Conventions — Code That Reads Like Statements — `CONVENTIONS.md`
- 06 · Control Flow (CF-1 … CF-11) — `06_control_flow.md`
- How Agent Enhanced Development Work Flows - Local Models — `07_how_the_workflow_runs.md`
- Quick Reference - AED Cheat Sheet — `quick_reference.md`


---

<!-- source: 01_why_models_need_this.md -->

## 01 · Why Models Need This

*Excerpted **verbatim** from the author's `naming_conventions.md`, lifted to the
front of the reading order because it explains why every later rule exists.
The complete original — with this passage in place — is
[02_naming_conventions.md](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/02_naming_conventions.md).*

---

Naming conventions are one of the ways that drive the agent enhanced development workflow. The reason for this is that AI models use token windows to understand the context of things.&#x20;

### Basic Explanation of Tokens & Token Window

AI models, specifically LLMs, use tokens to represent groups of text. For example the statement:

`I want to create a new user and assign them to an account.`

For this example I’ll use Llama 3 to tokenize this prompt. When we tokenize this prompt, it turns into these tokens:

\`

```
'I'
' want'
' to'
' create'
' a'
' new'
' user'
' and'
' assign'
' them'
' to'
' an'
' account'
'.'
```

The extra spaces inside of the single quotes here is to highlight that spaces can be part of a token. Now when the AI model is scanning through the prompt, it’s going to read a group of tokens at a time, shifting down as it processes. For this example I’ll use a 8 token window, shifting 4 tokens at a time so there is some overlap.

Starting token window `’I want to create a new user and’`

Next token window `’ a new user and assign them to an’`

Final token window `‘ assign them to an account.’`

This window is typically larger than this, but for this example it illustrates how as the window shifts and the LLM model associates groups of tokens. This association is how the relationship of a flow of words is established and influences the direction that the model computes. This is why a naming convention needs to be very consistent.

---

*Chapter 01 of the AED canon · continue to
[02 · Naming Conventions](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/02_naming_conventions.md) ·
[reading order](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/README.md#reading-order)*


---

<!-- source: 02_naming_conventions.md -->

## Naming Conventions Overview for Agent Enhanced Development (AED or AE-dev)

`_This is a work in progress_`

Naming conventions are one of the ways that drive the agent enhanced development workflow. The reason for this is that AI models use token windows to understand the context of things.&#x20;

### Basic Explanation of Tokens & Token Window

AI models, specifically LLMs, use tokens to represent groups of text. For example the statement:

`I want to create a new user and assign them to an account.`

For this example I’ll use Llama 3 to tokenize this prompt. When we tokenize this prompt, it turns into these tokens:

\`

```
'I'
' want'
' to'
' create'
' a'
' new'
' user'
' and'
' assign'
' them'
' to'
' an'
' account'
'.'
```

The extra spaces inside of the single quotes here is to highlight that spaces can be part of a token. Now when the AI model is scanning through the prompt, it’s going to read a group of tokens at a time, shifting down as it processes. For this example I’ll use a 8 token window, shifting 4 tokens at a time so there is some overlap.

Starting token window `’I want to create a new user and’`

Next token window `’ a new user and assign them to an’`

Final token window `‘ assign them to an account.’`

This window is typically larger than this, but for this example it illustrates how as the window shifts and the LLM model associates groups of tokens. This association is how the relationship of a flow of words is established and influences the direction that the model computes. This is why a naming convention needs to be very consistent.

### Patterns For Naming Conventions

For this section I’m going to use the example of implementing the feature story from above:

\`I want to create a new user and assign them to an account.

#### The Rails Way - Conventions That Have Stood The Test of Time

The Rails framework has lead the way with “convention over configuration” for well over a decade now. You can really feel the difference this makes in your productivity when getting started. However, once you deviate from the normal Rails conventions you’ll find that Rails can become very painful to work with. This typically happens with non-RESTful business logic being intermingled into what should only be a RESTful end-point.

The Rails conventions would typically establish the following flow:

1. Assuming that the `UsersController` already exists, with the standard `create` action inside of it to handle a `POST` request
2. You (the dev) would update the allowed params to add an `account_id` parameter that would be used to allow the user to be associated to the account.

This works perfectly for a one-to-one relationship, where one user belongs to one account. What happens if we want to make a many-to-one relationship where the user can have multiple accounts it has access to? This is where the Rails conventions can start to become murky and developers get creative in their solutions.

You may do one of the following:

1. You create a service object or PORO to handle the logic from the request and neatly organize the process into 1 or more classes to handle the job.
2. You update the allowed params to make the `account_id` into an `account_ids` array that manages a join table that represents the association for the user.
3. You split the association into 2 end-points, and you have your UI perform multiple successive requests in order to create/update all of the relationships.
4. You stuff a bunch of logic into your controller to determine if/when updates to the joining records need to happen (most common rapid development approach).

Depending on the maturity of your app, you may start at option 3 and move up in sophistication or simplicity. There’s no real wrong answer here, just a lot of opinions.

Rails doesn’t have one way of handling increasingly complexity. It’s up to the developer who is writing the start of the feature to hopefully do it in a way that works right for the maturity level of the project at that time.

However, when we introduce an AI agent into the mix the story begins to change.

#### The Agent Enhanced Way

Working with an AI agent can be a powerful multiplier for your efficiency as a dev, especially as the app grows in complexity. This is highly dependent on how clear the patterns are that you choose.

The pattern that you choose is critical because it heavily influences the models train of thought. Since AI models don’t have mental models like you or I do, they become heavily influenced by the way a prompt is written. You can effectively ask the same question, word it in various ways and get the AI to provide a varying answer. This is both good and bad. It means the AI can be articulate with some level of complexity, but it creates less certainty in the consistency required for coding. We can overcome this, mostly, by using a more strict and consistent naming convention.

Let’s start by looking at something that would generally be acceptable as “good code”.

```crystal
class Customer
  property name : String
  property email : String

  def initialize(@name, @email)
  end

end
```

Here we have the barest of minimums that represent a Customer for our new SaaS product. After all, this entire method is around building and maintaining products as they grow in complexity.

I am intentionally skipping persistence methods because this explanation is about naming conventions.

Our first job is going to be setting up subscriptions for Customers. A Customer can have many Subscriptions.

So now we have a setup like this:

```crystal
class Subscription
  property name : String
  property rate : Int16
  property quantity : Int16

  def initialize(@name, @rate, @quantity)
  end

end

class Customer
  property name : String
  property email : String
  property subscriptions : Array(Subscription) = [] of Subscription

  
  def initialize(@name, @email)
  end

end
```

At this point the relationship between the two objects is clear and the names are simple and imply their intended meaning. Our minds have mental models of what a Customer is and what a Subscription is because of our life experience. We can fill in the implications of what the property and its type mean. The `name` property is relatively clear.

However, to an AI this kind of naming is less than ideal. It will probably still work, but will progressively become less and less useful as the classes grow in complexity.

Instead if we change to a more verbose naming convention that adds in contextual meaning, the AI is better able to understand what we are trying to do.

Let’s focus on the Customer class first and you’ll see what I mean.

```crystal
class Customer
  property first_name : String
  property last_name : String
  property email_address : String
  property list_of_all_active_subscriptions : Array(Subscription) = [] of Subscription

  def initialize(@name, @email)
  end

end
```

You may have noticed that a lot has changed and at the same time, we changed very little.

Notice how explicit the name attributes are now? The name before could have been first, last, middle initial or full name. Who knows? We certainly didn’t have those details before. A more senior developer reading this probably picked up on that quickly!

We’ve now expanded our `email` to `email_address` because now it’s 100% clear that we intend to store an email address there and some kind of flag that says the email subscription list that the Customer belongs to. It was implied that the value was intended to be an email address, but it’s entirely possible its intended use was not that.

The changes to our old `subscriptions` property are a bit shocking! Did you have any idea that all you needed to track were the active subscriptions? Maybe during the conversation with a product owner, but the AI would have no idea. By updating the naming we now have a clear purpose given to that property with a contextually significant meaning.

So far all of the examples are fairly simple and straight forward. In fact, this is already pretty close to what would be considered “good” naming practices. So let’s take this to the next level where there’s a lot more complexity. This is where real business logic becomes messy and far less non-obvious.

Well the good news is that our little SaaS is growing up and now has more products and all new licensing. The sales team has been getting enterprise customer inquiries and the deal size is so big that the product team is now being told we need to adapt our one Customer to many Subscriptions model to allow for Customers who aggregate into a single billable entity, and prevents these users from adding any subscription items.

By the way, you have a super short window to implement so there’s no way to take time to architect this thoroughly and perform any data migrations.

That’s alright, this type of feature request is the Achilles Heel of many code bases. Typically in this kind of scenario we start seeing naming becoming a challenge. Let’s see how we can do it so that it benefits our AI agent assistant, or how our agent would be implementing this feature if we let it drive for us.

```crystal
class Customer
  property first_name : String
  property last_name : String
  property email_address : String
  property list_of_all_active_subscriptions : Array(Subscription) = [] of Subscription
  property is_this_an_enterprise_customer : Bool

  def initialize(@first_name, @last_name, @email_address, @is_this_an_enterprise_customer = false)
  end

end

  

class EnterpriseCustomerBillingEntity
  property full_legal_entity_name : String
  property payment_terms_in_number_of_days : Int8
  property billing_cycle_frequency : Int8
  property billing_cycle_time_period : String
  property maximum_customers_according_to_the_contract_limit : Int16
  property current_count_of_customer_accounts : UInt16

  def initialize(@full_legal_entity_name, @payment_terms_in_number_of_days, @billing_cycle_frequency, @billing_cycle_time_period, @maximum_customers_according_to_the_contract_limit, @current_count_of_customer_accounts)
  end

end
```

We now have this new class mixed in that handles the enterprise details. This isn’t about programming the full workflow, it’s about the naming convention used here. A pattern is beginning to emerge.

Now depending on your level of seniority as a dev, you may read those class attributes and think “yeah that’s basically what I would do, except I’d simplify the names a bit”. And this is when I can begin outlining the general rules to follow when writing code you want an AI assistant to flourish with:

1. Object attributes with primitive types should be short statements or phrases
2. Object attributes that are booleans should be phrased as a “yes/no” question or statement
3. Object attributes that are collections, Arrays or enumerable in some way. Usually it’s good to start the name like “list\_of\_” or “array\_of\_” with a descriptive name of the object types it’s holding.

Following these guidelines will help keep your naming conventions consistent which helps provide clarity and contextual understanding for your AI agent. It’s also good for you, because you may come back to this code many months or years later and you will not remember the product meeting details but you can clearly read your code.

#### Method & Variable Naming

Next let’s discuss method and variable naming. This is the most common area where devs can help themselves greatly, but typically fall short. Clever naming can make short variable names for easier readability but the context of what and why quickly disappears into your editors background.

We left some of the business logic that was in our new feature requirement that we can use for this part. The part we are going to focus on is going to be:

`prevents these users from adding any subscription items`

This is something that we can use a process manager to handle while exercising good naming conventions.

This is a process manager, but it does not use “process” or “manager” in the name. It is acceptable with or without including those details.&#x20;

```crystal
class AddSubscriptionToCustomer
  property customer_to_add_subscription_to : Customer
  property subscription_to_add_to_customer : Subscription

  def initialize(@customer_to_add_subscription_to, @subscription_to_add_to_customer)
  end

  def add_subscription_to_customer
    return if @customer_to_add_subscription_to.is_this_an_enterprise_customer

    @customer_to_add_subscription_to.list_of_all_active_subscriptions << subscription_to_add_to_customer
  end
end
```

1. The class name for the process manager clearly states what the entire process is attempting to do in a short statement.
2. The initialize method accepts all of the initial data required to perform the process
3. The name of the method to start the process is clear and obvious.&#x20;

This reads very plainly now. The logic in the `return` line reads almost like a complete sentence. This makes the intent very clear for both you the developer and your AI agent assistant.

The variable names clearly state what the contents are, and the intended use.

The method name clearly states the action that is being performed. It does not take any parameters because the intended purpose of a process manager is to be initialized with all of the data it needs in order to perform the process it is managing.

Do you come across code this plainly and clearly written? Maybe. It’s more than likely that it’s plain on that it uses simpler wording and phrasing that is less robust, but still clear. You may have seen `customer_to_update` and considered that good over just `customer`. Maybe you consider the one word better. But your AI agent is going to have less and less of a clear intent by using such simplified wording.

### The Compounding Rewards of Enhanced Naming

You are rewarded for clearer naming practices as your files get larger. In fact, you may start implementing these naming conventions and notice something strange. At first, your code completion suggestions from typical AI coding assistants will usually be pretty bad. Only at first, but it’s distinctly noticeable.

Github Copilot tends to be the worst offender by offering up code snippets that are close but make silly naming mistakes when re-using existing variables. Mistakes such as pluralizing when the variable should be phrased singularly and vice-versa.

I use Cursor, which has a Copilot++ in editor code suggestion tool and it tends to work much better. It still has lower quality suggestions initially, but as your files grow in size, the suggestions and understanding of what you are trying to do become increasingly more accurate. This includes across files when you’re using Copilot++.

---

*Chapter 02 of the AED canon · published **verbatim** from the author's original; the work-in-progress marker at the top is his own, kept as written · continue to [03 · Process Managers](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/03_process_managers.md) · [reading order](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/README.md#reading-order)*


---

<!-- source: 03_process_managers.md -->

## Process Manager Conventions

`_This is a work in progress_`. Updated on 11/24/2025

Process managers are a convention that AI agents need to organize an unRESTful process. This is commonly domain specific business logic or workflows.

A process manager name is a statement or phrase that describes what is being done.

Let’s use an example of building a report. We are just going to describe the feature story that defines this process, and the triggering event. For this example our app has Customers:&#x20;

`When a list of Customer ID’s is provided, then lock each customers account.`

Processes start with a “when” keyword, always. Because a process is “when” something happens!

The second statement “a list of Customer ID’s is provided” tells us the qualifying information we need before this process can be performed. Here were are referencing a “list” aka an Array of IDs which is the attribute type from the Customer model. This could be integers, ULID, UUID’s etc.

The second half “lock each customers account” is using jargon that represents an operation we define for the business. “Locking” an account for this means: changing an attribute in the Customer model that requires an additional input from the user to confirm their identity and reset their password.

A process manager can perform many operations at a time, and typically will. The more complicated the process, the more likely to require human intervention to write the complete the process writing.

If we expand our process statement, it looks like the following:

`When an array of Integers that represent Customer IDs is provided then loop through each Customer account using the ID to find the correct record and update the necessary attribute that will prevent the Customer from accessing their account.`

The AI is going to analyze this and ultimately make the determination if any jargon was used, and will ask questions if it can’t understand your intent. It will generally phrase it like I explained above, and may provide more details.

---

*Chapter 03 of the AED canon · published **verbatim** from the author's original (last revised 2025-11-24); the work-in-progress marker at the top is his own, kept as written · continue to [04 · Feature Stories](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/04_feature_stories.md) · [reading order](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/README.md#reading-order)*


---

<!-- source: 04_feature_stories.md -->

## Agent Enhanced Development - The Whole Process

### Introduction To What A Feature Request Is
The idea of “operating” an AI means we need to be able to define it’s “operations” to begin with.

An operation is essentially the work flow for performing a task. This should encompass multiple steps and possibly “tasks” depending on how you want to define a task.

To operate an AI agent successfully, we have to shift our mindset on a few topics, such as:

1. How we define the work that we want to perform
2. The expected patterns or overall flexibility we have in our code base
3. Our definition of naming conventions and what "clear" means for us
4. How we perform development work
5. The relationship between the code we write and how it reflects the business

To begin with, we are going to start by more clearly defining what a `feature request` really is. If you've been a developer for any period of time, you've most likely already worked with scrum or agile and been exposed to User Stories. The idea here is pretty similar, however instead of managing the details of the story from a 3rd party tool such as Jira, we are going to manage the details directly with our AI agent that works from our code base.

Let's define some critical terminology before we move forward.

**Operation**: the interaction with the AI agent and ensuring it has the correct knowledge and understanding to perform.


### Our First Feature Request
Let’s describe some default operations that should come with the framework. I have notes about user stories and I think that operating an AI development agent should mean using Feature Stories to control the behavior of the agent and the outcome.

First a simple user story:

`As an **Admin** user, I want to _create_ a new **user** **_and_** _assign_ them to an **account**`

This story is pretty simple and would mean operations that are required use the typical MVC concepts, which makes things easy to start with.  

The `As an Admin` establishes our persona, scoping the following **action** to be performed. When there is a persona we have chosen, we also know the feature request requires a view and a controller action at a minimum. Our agent knows which views belong to which controller actions, and if we need to create that controller, action, view etc.

The action is the full statement. It should be a clear summary of what would complete a request/response cycle. If it triggers or enqueues a background job, that should be stated. The action description should also include references to any data models that require a relationship. In the example that’s User and Account. The plurality of the data models dictates the relationships between them, and should use the same Active Record pattern expressions as in Rails.

The “I want to” part is provided as part of the story builder. The action verb needs to be an HTTP verb of GET POST PUTS PATCH or DELETE followed by the primary data model that is effected.

A unique verb of “perform” can be used to trigger a workflow that is not RESTful. This is the keyword you primarily use for our unique business logic, aka your special sauce.

The specially called out “and” in the action is because we follow up a simple RESTful action with a secondary action, and it’s establishing a relationship with an additional record. In this case I highlighted “assign” because it’s an example of company jargon that can alias an Active Record relationship of “belongs to”. These kinds of aliases can be configured with restrictions/conditions before creating a feature story. This story implies it is limited to linking the newly created user to an existing account, and that it does not create a new account.

A feature story with a persona breaks down it’s structure like this:

`As a (specify persona), I want to (RESTful verb, or “perform”) (“a” or “multiple”) (data model name of an existing data model) and (AR relationship name/type or “perform”) (data model name or Process Manager name if performing a process)`

A “persona” is a specialized alias of a User data model type that includes an indication of the “authorization” (ie permissions) level of that model type. For example, an Admin persona could be an alias of a Super Administrator type that has unrestricted permissions, which means they would be using controllers/routes that are scoped to this kind of user.

Authorization levels work in several ways together to create a robust authorization system.

- Model type: the model name should represent the general permission level of that group. This is resource based, so an Administrator user type may have its own API and all administrators would generally be considered to use those end-points.
- Action specific: RESTful verbs have a matching permission level two on the actual model as an attribute. Your app configuration should define if by default the user of that group is allowed or disallowed, and if the flag necessary to perform the action needs to be specified on the models record.
- Individual resource: individual resources can restrict behavior to model type or record ID’s.

For unRESTful end-points, the permissions are based on if the model type or specific records of models are allowed to execute an action.


### Breakdown of The Anatomy of A Feature Request

TBD

---

*Chapter 04 of the AED canon · published **verbatim** from the author's original. The closing `TBD` is the author's own — the anatomy breakdown is genuinely unwritten, and this release candidate marks it rather than papering over it · continue to [05 · Edit-Level Style](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/05_edit_level_style.md) · [reading order](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/README.md#reading-order)*


---

<!-- source: CONVENTIONS.md -->

## AED Conventions — Code That Reads Like Statements

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

### The rules (with Crystal examples)

<a id="rule-1"></a>
#### 1. Branch on type with an explicit `if … is_a?`, not a clever `case`

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
#### 2. Name the thing; don't make the reader decode a chain

```crystal
# ✅ AED
expected_state = session["oauth_state"]?
return unless expected_state && constant_time_equal?(expected_state, state)

# 🚫 terse, but the reader has to hold three operations in their head
return unless session["oauth_state"]?.try { |s| constant_time_equal?(s, state) }
```

<a id="rule-3"></a>
#### 3. Prefer explicit guard clauses to nested ternaries / one-liners

```crystal
# ✅ AED
return nil if password_digest.empty?
return nil unless Crypto::Bcrypt::Password.new(password_digest).verify(password)
self

# 🚫 dense
password_digest.empty? ? nil : (Crypto::Bcrypt::Password.new(password_digest).verify(password) ? self : nil)
```

<a id="rule-4"></a>
#### 4. Use full, intention-revealing names

Methods and locals are sentences-in-miniature: `establish_session`,
`invalidate_all_sessions`, `find_or_create_from_oauth`, `expected_state`. Avoid
`do_it`, `tmp`, `x`, `res2`. A good name removes the need for a comment.

<a id="rule-5"></a>
#### 5. Say *why* in a comment, let the code say *what*

Comments earn their place by explaining intent, security rationale, or a
non-obvious constraint — not by restating the line. The house style: a
session-establishing method carries a comment stating the fixation attack it
prevents; an encrypted column carries a comment stating what the encryption
protects and why. If a comment could be deleted with no loss because the code
already says it, delete it.

<a id="rule-6"></a>
#### 6. One statement per line; let the formatter own the layout

Run `crystal tool format` (or your language's canonical formatter) as part of
every edit. Canonical formatting means every reader and every diff sees the
same shape.

---

<a id="shorthand-boundary"></a>
### When shorthand IS the clearer form

AED is "clarity first," not "verbose always." Idioms that are *more* readable are
encouraged: `arr.map(&.name)`, `value.try(&.to_i64?)`, a `?`-suffixed predicate,
a single well-named guard expression. The test is always: **does a reader who has
never seen this code understand the intent on first pass?** If yes, keep it. If
they have to mentally execute it, expand it.

---

<a id="checklist"></a>
### Checklist before you finish an edit

- [ ] Type branches use explicit `if … is_a?` (not `case … in` against Grant types).
- [ ] No one-liner hides more than one operation from the reader.
- [ ] Names state intent; no `tmp`/`x`/`res2`.
- [ ] Comments explain *why*, never restate *what*.
- [ ] `crystal tool format` is clean.
- [ ] The edit-time type check passed (no `case is not exhaustive`, no undefined methods).

---

### Status and versioning

This document is the public canon of the AED conventions, versioned by signed
git tags. Rules covering control flow (loops, guards, rescues, fibers, macros)
are drafted and under internal review; they will land here as a tagged minor
version. The [ADOPTION.md](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/ADOPTION.md) log records, with dates, when each rule
entered practice and when it was published.


---

<!-- source: 06_control_flow.md -->

## 06 · Control Flow (CF-1 … CF-11)

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

### 0. Census — what actually occurs in our Crystal

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

### The core insight: mechanism syntax vs statement syntax

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

### Rule CF-1. `case` is a menu — every branch one bite

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

### Rule CF-2. Loops state their finish line

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

### Rule CF-3. Guards are the bouncer — they stand at the door

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

### Rule CF-4. `unless` carries one positive idea

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

### Rule CF-5. Ternary picks between two spellings of one value

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

### Rule CF-6. Chains read like a sentence or get named waypoints

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

### Rule CF-7. Errors are vocabulary; rescues say what they forgive

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

### Rule CF-8. Three ands make a question method

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

### Rule CF-9. Every fiber gets a job title

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

### Rule CF-10. `?` asks, `!` warns — and the suffix is a promise

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

### Rule CF-11. Macros write code; they don't hide flow

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

### How these rules feed documentation generation

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

### Implementation sketch (if adopted)

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

### Open questions before v1.1.0 final

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
rather than theory · back to the [reading order](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/README.md#reading-order)*


---

<!-- source: 07_how_the_workflow_runs.md -->

## How Agent Enhanced Development Work Flows - Local Models

Typical development processes are that you focus on small steps at a time to scaffold out an idea and then focus on the logic flow. This usually means a lot of saving and rapid iteration. This is actually the least productive way to work with an agent enhanced development process.

When you are first starting out using an AI agent to assist with developing your app, the temptation is to continue using it for the quick iterative feedback like we currently get from a “write, save, retry” development process. However, with an AI agent enhancing our development process, we are rewarded for planning in detail, and using our natural language. By that I mean, writing and building feature requests in large batches and letting the AI run over many features.  

The agent should be driving the majority of the development, and you should be able to walk away and do something else. It’s a great way to end a day of planning, and then let your laptop sit for a time while the agent runs. It’ll spend the time it needs until it succeeds at building a thorough feature, including your tests.

This means you can plan your time so that your agent is building your app while you’re typically away from your computer, this way you’re maximizing your local hardware availability while getting the benefits.

---

*Chapter 07 of the AED canon · published **verbatim** from the author's original · back to the [reading order](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/README.md#reading-order)*


---

<!-- source: quick_reference.md -->

## Quick Reference - AED Cheat Sheet

This is a quick reference, please read the entire guide for more details.

**This is the bare minimum to improve the performance of untrained coding assistants**

If you're a Rails developer, or come from a similarly structured framework, you'll find a lot of this inspired by the Rails conventions.


## Naming Conventions


### General Principles & Guidelines

- Avoid unnecessary jargon or slang.
- Never create a whole new lexicon for your code base by applying a theme.
	- Code names for code bases are entirely acceptable and expected.
- Names that read like plain English are preferred


### Object & Attribute Naming Conventions

- Data models should be singular, and only concerned with their own individual behavior.
	- Good: `Customer`
	- Bad: `Customers`
- Classes should be name spaced according to the feature that is being implemented.
	- Good: `Billing::ActivateNewCustomerSubscription`
	- Bad: `NewCustomerSubscription`
- Class names should be short statements or phrases that clearly express the process being performed.
	- Good: `PerformCustomerAccountLocking`
	- Bad: `LockCustomers`
- Class attributes of non-enumerable primitive types should be phrased as short statements for what the intended purpose of the attribute is.
	- Example class `Customer`
	- Well named attribute:  `first_name` or `full_name`
	- Poorly named attribute: `name`
- Class attributes of enumerable (Array or Array-like) objects or types should be phrased with `list_of_` or `collection_of_` or `array_of_`
	- Example class `Customer` has many `Order`s
	- Well named attribute: `list_of_previous_orders` or `collection_of_previous_orders` or `array_of_previous_orders`
	- Poorly named attribute: `orders` or `previous_orders`
	- **Suggestion**: in dynamically typed languages, adding the object type to the end of the name can be very helpful by using the `_as_` phrasing in your naming
		- Example: `list_of_previous_orders_as_hashes`
- Class attributes of non-primitive types should be named using short statements or phrases that accurately and clearly express how that attribute is to be used
	- Example class: `Customer` with a `Subscription`
	- Ideal: `currently_active_subscription`
	- Acceptable: `active_subscription`
	- Bad: `subscription`
- Class attributes for boolean types should be named as if the expression is a question beginning with `if`
	- Example class: `Customer`
	- Good: `has_a_valid_payment_method`
	- Bad: `payment_method_present`


### Method Naming Conventions

- Method names should be phrases or statements that explain the process thats taking place
	- When possible, include wording to describe the expected return type
- Method parameters should be named when possible
	- Ideally as if reading a plain statement


### File & Folder Naming Conventions

These primarily apply to domain/business logic. Use your appropriate framework folder structure where necessary. These conventions are primarily if you are using an agent helper that is trained to work with more than 1 file at a time or perform file edits/updates autonomously.

- The file name should be a lower snake case of the primary class from the file.
	- Class name `ProcessCustomersWithExpiredSubscriptions`
	- Filename: `process_customers_with_expired_subscriptions.cr`
- Classes that are name spaced should be in folders named for that namespace
	- Class name `Billing::ProcessCustomersWithExpiredSubscriptions`
	- Filename: `billing/process_customers_with_expired_subscriptions.cr`
- Data models rarely need to be name spaced. 
	- Reserve this kind of naming for single-table inheritance or other very specific situations where you need a data model to be name spaced.



Example
```crystal
# File found under `billing/process_customers_with_expired_payment_methods`
class Billing::ProcessCustomersWithExpiredPaymentMethods
  property collection_of_customers_that_have_expired_payment_methods : Array(Customer) = [] of Customer
  property collection_of_customers_that_were_retried_and_failed : Array(Customer) = [] of Customer
  property all_of_the_customers_have_been_processed : Bool = false

  def initialize(@collection_of_customers_that_have_expired_payment_methods)
  end

  def perform
    retry_customers_who_failed_payment_processing_with_an_expired_card
    mark_customer_accounts_as_delinquent_and_prevent_further_use
  end

  private def retry_customers_who_failed_payment_processing_with_an_expired_card
    # Your business logic goes here
  end

  private def mark_customer_accounts_as_delinquent_and_prevent_further_use
    # Your business logic goes here
  end

end
```

### Process Manager Conventions

Process managers are the starting point of your businesses internal domain-specific language (DSL).

These objects are _typically_ just a plain class that is not part of a specific framework. Many frameworks have some utilities that bleed out of the framework and into your business logic for common usecase tasks.

A more formal definition that encompasses what the spirit of the process manager is:

`Process Manager: a starting point in a business process where a workflow of one or more steps begins and ends, with the final product being the end of the computational process for the business.`

Process managers conform to the following:
	- The `initialize` method receives all of the necessary information possible to perform the process
		- Any necessary data organization should happen during the objects initialization step
		- Prefer to use named parameters when initializing objects
	- The entry point method `perform` is defined, and performs all of the methods necessary for the business task to be completed in a single method call
		- A well written `perform` method will read almost like psuedo code when outlining each step that's being performed.
	- Use read-only public accessor methods if the object is going to be used for anything other than returning a single result
	- Use "middle managers" if your business process requires a secondary layer of business logic.

### Process "Middle" Manager Conventions

Just like process managers, these are objects that are in your codebase and represent your business process. As a middle manager, they typically are responsible for small parts of a larger process that has complex logic.

- Middle managers _should be named spaced to the process manager_. These are not meant to be re-used across the code base, just as an organization tool in a large process.
- Middle managers _do not_ use any other managers.

## Framework Conventions

These conventions have (amber)[https://amberframework.org] and (Ruby on Rails)[https://rubyonrails.org] in mind, but any RESTful routing app will tend to follow these well.

- The standard `Create`, `Edit`, `Update` and `Destroy` will only effect a single resource object.
- The typical `CRUD` actions should maintain the bare minimum logic to do the following:
	- a single resource:
		- Recieve whitelisted parameters
		- update and validate the target object
		- Render a response (successful or otherwise)
	- multiple resources:
		- Render a response with 0 or more of the desired resource (more commonly known as an index route)
- Any non-RESTful routes should do the following:
	- Recieve and validate any incoming parameters or request body
	- Use a process manager to perform any logic required for the response
	- Render a response (successful or otherwise)

A well written Rails controller would look like the following:
```ruby
# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  def create
    @customer = Customer.new(customer_params)
    if @customer.save
      render json: @customer, status: :created
    else
      render json: @customer.errors, status: :unprocessable_entity
    end
  end

	def update_payment_and_subscription
    customer = Customer.find(params[:id])
    new_payment_method = params[:payment_method]

    if customer && new_payment_method
      process_manager = Billing::UpdateCustomerPaymentAndSubscription.new(
        customer: customer, 
        new_payment_method: new_payment_method
      )
      if process_manager.perform
        render json: { message: 'Customer payment method and subscription updated successfully' }, status: :ok
      else
        render json: { error: 'Failed to update payment method and subscription' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Invalid parameters' }, status: :bad_request
    end
  end

  private def customer_params
    params.require(:customer).permit(:first_name, :last_name, :email)
  end
end
```

Here's the accompanying process manager:

```ruby
module Billing
  class UpdateCustomerPaymentAndSubscription
    attr_reader :customer, :new_payment_method

    def initialize(customer:, new_payment_method:)
      @customer = customer
      @new_payment_method = new_payment_method
    end

    def perform
      update_payment_method && update_subscription_status
    end

    private def update_payment_method
      # Implement the logic to update the customer's payment method
      customer.update(payment_method: new_payment_method)
    end

    private def update_subscription_status
      # Implement the logic to update the customer's subscription status based on the new payment method
      if customer.payment_method_valid?
        customer.update(subscription_status: 'active')
      else
        customer.update(subscription_status: 'inactive')
      end
    end
  end
end
```


---

*The AED cheat sheet · published **verbatim** from the author's original · back to the [reading order](https://github.com/AgentC-Consulting/aed-conventions/blob/v1.1.0-rc.1/README.md#reading-order)*
