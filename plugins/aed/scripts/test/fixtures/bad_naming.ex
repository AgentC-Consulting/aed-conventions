# AED linter fixture — Elixir naming the canon would push back on.
# Every rule that applies to Elixir fires somewhere in this file.
defmodule AedFixtures.Customers do
  use Ecto.Schema

  schema "customers" do
    field :name, :string
    field :data, :string
    field :locked, :boolean
    field :orders, {:array, :integer}
    field :lookup, :map
  end

  def lock_it(x) do
    tmp = x
    Enum.map([tmp], fn c -> c end)
  end
end
