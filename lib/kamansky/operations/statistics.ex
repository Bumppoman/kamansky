defmodule Kamansky.Operations.Statistics do
  import Kamansky.Helpers, only: [format_decimal_as_currency: 1]

  alias Kamansky.Sales.Orders

  @spec get_statistics(integer, integer) :: map
  def get_statistics(month, year) do
    %{
      gross_profit: Orders.total_gross_profit(month: month, year: year)
    }
  end
end
