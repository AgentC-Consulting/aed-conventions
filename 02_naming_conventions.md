# Naming Conventions Overview for Agent Enhanced Development (AED or AE-dev)

`_This is a work in progress_`

Naming conventions are one of the ways that drive the agent enhanced development workflow. The reason for this is that AI models use token windows to understand the context of things.&#x20;

## Basic Explanation of Tokens & Token Window

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

## Patterns For Naming Conventions

For this section I’m going to use the example of implementing the feature story from above:

\`I want to create a new user and assign them to an account.

### The Rails Way - Conventions That Have Stood The Test of Time

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

### The Agent Enhanced Way

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

### Method & Variable Naming

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

## The Compounding Rewards of Enhanced Naming

You are rewarded for clearer naming practices as your files get larger. In fact, you may start implementing these naming conventions and notice something strange. At first, your code completion suggestions from typical AI coding assistants will usually be pretty bad. Only at first, but it’s distinctly noticeable.

Github Copilot tends to be the worst offender by offering up code snippets that are close but make silly naming mistakes when re-using existing variables. Mistakes such as pluralizing when the variable should be phrased singularly and vice-versa.

I use Cursor, which has a Copilot++ in editor code suggestion tool and it tends to work much better. It still has lower quality suggestions initially, but as your files grow in size, the suggestions and understanding of what you are trying to do become increasingly more accurate. This includes across files when you’re using Copilot++.

---

*Chapter 02 of the AED canon · published **verbatim** from the author's original; the work-in-progress marker at the top is his own, kept as written · continue to [03 · Process Managers](03_process_managers.md) · [reading order](README.md#reading-order)*
