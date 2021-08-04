defmodule Kamansky.Operations.Statistics do
  @spec get_statistics(integer, integer) :: map
  def get_statistics(month, year) do
    %{
      gross_sales: Orders.total_gross_profit(month, year)
    }
  end
end
