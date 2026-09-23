defmodule AedFixtures.GoodFrameworkProcessOverrides do
  defmodule RequestProcessor do
    @impl true
    def process(input_value), do: input_value
  end
  defmodule ProcessReceipt do
  end
end
