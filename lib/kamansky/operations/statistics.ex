defmodule Kamansky.Operations.Statistics do
  import Ecto.Query, warn: false

  alias Kamansky.Repo
  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order

  @spec get_base_statistics(integer, integer) :: map
  def get_base_statistics(month, year) do
    %{
      ebay_selling_fees: orders_total_ebay_selling_fees(month, year),
      gross_profit: Orders.total_gross_profit(month: month, year: year),
      hipstamp_selling_fees: orders_total_hipstamp_selling_fees(month, year),
      selling_fees: orders_total_selling_fees(month, year),
      shipping_cost: orders_total_shipping_cost(month, year)
    }
  end

  @spec list_orders_for_month_and_year(integer, integer) :: [Order.t]
  def list_orders_for_month_and_year(month, year) do
    order_for_month_and_year_query(month, year)
    |> select_merge([o], %{gross_profit: fragment("item_price + shipping_price")})
    |> order_by(:id)
    |> Repo.all()
  end

  defp order_for_month_and_year_query(month, year) do
    where(
      Order,
      [o],
      fragment("DATE_PART('month', ?)", o.ordered_at) == ^month
        and fragment("DATE_PART('year', ?)", o.ordered_at) == ^year
    )
  end

  defp orders_total_ebay_selling_fees(month, year) do
    month
    |> order_for_month_and_year_query(year)
    |> where([o], not is_nil(o.ebay_id))
    |> Repo.aggregate(:sum, :selling_fees)
  end

  defp orders_total_hipstamp_selling_fees(month, year) do
    month
    |> order_for_month_and_year_query(year)
    |> where([o], not is_nil(o.hipstamp_id))
    |> Repo.aggregate(:sum, :selling_fees)
  end

  defp orders_total_selling_fees(month, year) do
    month
    |> order_for_month_and_year_query(year)
    |> Repo.aggregate(:sum, :selling_fees)
  end

  defp orders_total_shipping_cost(month, year) do
    month
    |> order_for_month_and_year_query(year)
    |> Repo.aggregate(:sum, :shipping_cost)
  end
end
