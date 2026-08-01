# AED linter fixture — Elixir naming the canon would accept.
# Expectation: zero findings of any severity.
defmodule AedFixtures.GoodNaming do
  use Ecto.Schema

  schema "customers" do
    field :first_name, :string
    field :last_name, :string
    field :email_address, :string
    field :has_a_valid_payment_method, :boolean
    field :list_of_previous_order_ids, {:array, :integer}
    field :subscription_totals_by_billing_period, :map
  end

  def lock_every_customer_account_in(list_of_customer_records_to_lock) do
    list_of_locked_customer_records =
      Enum.map(list_of_customer_records_to_lock, fn customer_record -> lock_one_customer_record(customer_record) end)

    list_of_locked_customer_records
  end

  defp lock_one_customer_record(customer_record_to_lock) do
    %{customer_record_to_lock | has_this_account_been_locked: true}
  end
end
