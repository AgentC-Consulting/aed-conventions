---
description: Scaffold AED (Agent-Enhanced Development) process managers from "When … then …" statements — a class named for the whole process, an `initialize` taking all needed data, a no-argument `perform` that reads like pseudocode, and namespaced middle managers, plus Crystal, Ruby, and Elixir templates. Use when adding non-RESTful business logic, workflows, or service objects in projects that adopt AED (AED named in CLAUDE.md or README), or when the user asks for an AED process manager.
---

# AED Process Managers

The public canon: <https://github.com/AgentC-Consulting/aed-conventions> —
chapter 03 and the cheat sheet in that repository.

Process managers are the starting point of your business's internal
domain-specific language (DSL). They are *typically* just a plain class that is
not part of a specific framework.

## Definition (canon, verbatim)

> `Process Manager: a starting point in a business process where a workflow of one or more steps begins and ends, with the final product being the end of the computational process for the business.`

## When you need one

Any non-RESTful work. The canon's framework rule: CRUD actions carry the bare
minimum logic (receive whitelisted params, update and validate the target object,
render a response). Anything else — multi-step business logic, "our special
sauce" — is a process manager the controller calls.

## Conformance rules

- The canon: "The `initialize` method receives all of the necessary information possible to perform the process".
  Any necessary data organization happens during initialization. **Prefer named
  parameters.**
- The canon: "The entry point method `perform` is defined, and performs all of the methods necessary for the business task to be completed in a single method call".
  `perform` takes no arguments — everything it needs arrived at `initialize`.
- The canon: "A well written `perform` method will read almost like psuedo code when outlining each step that's being performed."
  If `perform` contains branching, looping, or inline logic, that logic belongs in
  a named step method.
- Use **read-only public accessor methods** if the object is going to be used for
  anything other than returning a single result.
- Use **"middle managers"** if the process requires a secondary layer of business
  logic.

### Middle managers

- Middle managers **should be namespaced to the process manager**. They are not
  meant to be re-used across the code base — they are an organization tool inside
  one large process.
- Middle managers **do not use any other managers**.

So `Billing::ProcessCustomersWithExpiredPaymentMethods` may own
`Billing::ProcessCustomersWithExpiredPaymentMethods::RetryASingleExpiredCard`,
and that middle manager calls no other manager. If you feel the urge to reuse a
middle manager elsewhere, it is not a middle manager — promote it to its own
process manager.

## Naming

The class name is a short statement or phrase that states **the whole process**:
`Billing::ProcessCustomersWithExpiredPaymentMethods`,
`Billing::UpdateCustomerPaymentAndSubscription`, `AddSubscriptionToCustomer`.
Namespace it by the feature.

On the words "process" and "manager" in the name, the canon is explicit:

> This is a process manager, but it does not use “process” or “manager” in the name. It is acceptable with or without including those details.

Either is fine. Be consistent within a code base.

File path: lower snake_case of the class, in a folder named for the namespace —
`billing/process_customers_with_expired_payment_methods.cr`.

## Scaffold procedure

Given a When-statement:

`When a list of Customer ID’s is provided, then lock each customers account.`

1. **Class name** — state the whole process, namespaced by feature. From the
   "then" clause plus its subject: `Billing::PerformCustomerAccountLocking`.
2. **`initialize` parameters** — from the **when** clause. "a list of Customer
   ID’s is provided" → one collection parameter,
   `array_of_customer_ids_to_lock`. Add a parameter for every qualifying fact the
   process needs; if the process must fetch it instead, fetching is data
   organization and belongs in `initialize`.
3. **Step methods** — from the **verbs in the then clause**, one private method
   each, named as the statement of the step:
   `find_each_customer_record_by_the_provided_id`,
   `update_the_attribute_that_prevents_the_customer_from_accessing_their_account`.
4. **`perform`** — call the step methods in order, nothing else.
5. **Accessors** — expose read-only results the caller needs
   (`collection_of_customers_that_were_locked`,
   `all_of_the_customers_have_been_processed`).
6. **Emit the file** at the snake_case path for the class.
7. **Check the names** before you write them:
   ```bash
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind class Billing::PerformCustomerAccountLocking
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind collection array_of_customer_ids_to_lock
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb check-name --kind method find_each_customer_record_by_the_provided_id
   ```
   and lint the file after writing it:
   ```bash
   ruby ${CLAUDE_PLUGIN_ROOT}/scripts/aed_lint.rb billing/perform_customer_account_locking.cr
   ```

## Reference output (canon example)

This is the shape every scaffold should match.

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

## Template — Crystal (canonical)

```crystal
# File found under `<namespace>/<snake_case_class_name>`
class <Feature>::<StatementOfTheWholeProcess>
  # data the process was given
  getter <named_input_from_the_when_clause> : <Type>
  # results the caller may read
  getter <collection_of_records_that_were_processed> : Array(<Model>) = [] of <Model>
  getter <all_of_the_records_have_been_processed> : Bool = false

  def initialize(@<named_input_from_the_when_clause>)
  end

  def perform
    <first_step_named_as_a_statement>
    <second_step_named_as_a_statement>
  end

  private def <first_step_named_as_a_statement>
    # Your business logic goes here
  end

  private def <second_step_named_as_a_statement>
    # Your business logic goes here
  end
end
```

## Template — Ruby

Module-namespaced, `attr_reader` for read-only accessors, keyword arguments for
the named parameters. Rails framework surface stays idiomatic; AED governs this
class.

```ruby
# app/services/billing/update_customer_payment_and_subscription.rb
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

Called from a non-RESTful controller action that only validates input, delegates,
and renders:

```ruby
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
```

## Template — Elixir

**Be honest about this one: the canon is object-oriented.** There is no published
AED chapter for functional languages; this is the adaptation, and it keeps the
*semantics* (all data supplied up front, one no-decision entry point, steps named
as statements) rather than the class syntax. Say so if a user asks whether it is
canon.

The struct holds the named data that `initialize` would have received;
`perform/1` takes the struct and is the single entry point.

```elixir
# lib/billing/process_customers_with_expired_payment_methods.ex
defmodule Billing.ProcessCustomersWithExpiredPaymentMethods do
  @moduledoc """
  When a collection of Customers with expired payment methods is provided, then
  retry each failed payment and mark the remaining accounts as delinquent.
  """

  defstruct collection_of_customers_that_have_expired_payment_methods: [],
            collection_of_customers_that_were_retried_and_failed: [],
            all_of_the_customers_have_been_processed: false

  @type t :: %__MODULE__{}

  @spec new(keyword()) :: t()
  def new(collection_of_customers_that_have_expired_payment_methods: customers) do
    %__MODULE__{
      collection_of_customers_that_have_expired_payment_methods: customers
    }
  end

  @spec perform(t()) :: t()
  def perform(%__MODULE__{} = process) do
    process
    |> retry_customers_who_failed_payment_processing_with_an_expired_card()
    |> mark_customer_accounts_as_delinquent_and_prevent_further_use()
  end

  defp retry_customers_who_failed_payment_processing_with_an_expired_card(process) do
    # Your business logic goes here
    process
  end

  defp mark_customer_accounts_as_delinquent_and_prevent_further_use(process) do
    # Your business logic goes here
    %{process | all_of_the_customers_have_been_processed: true}
  end
end
```

The returned struct is the read-only accessor surface: the caller reads
`process.collection_of_customers_that_were_retried_and_failed` instead of calling
a getter. Middle managers become modules nested under the parent
(`Billing.ProcessCustomersWithExpiredPaymentMethods.RetryASingleExpiredCard`) and
still call no other manager.

## Before you finish

- [ ] `perform` takes no arguments and reads like the "then" clause of the When-statement.
- [ ] `initialize` received everything; no step method fetches a missing input mid-process.
- [ ] Every step method name is a statement, not a verb fragment.
- [ ] Public accessors are read-only.
- [ ] Any middle manager is namespaced under this class and calls no other manager.
- [ ] File path is the snake_case of the class under its namespace folder.
- [ ] `aed_lint.rb` is clean on the new file.
