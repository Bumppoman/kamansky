defmodule Kamansky.Operations.Statistics do
  alias Kamansky.Sales.Orders

  @spec get_statistics(integer, integer) :: map
  def get_statistics(month, year) do
    %{
      gross_sales: Orders.total_gross_profit(month: month, year: year)
    }
  end
end
