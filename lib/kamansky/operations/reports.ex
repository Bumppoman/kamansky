defmodule Kamansky.Operations.Reports do
  import Ecto.Query, warn: false

  alias Kamansky.Repo
  alias Kamansky.Sales.Orders.Order

  @spec get_order_data(integer, integer) :: map
  def get_order_data(year, month) do
    with(
      base_data <-
        from(o in "orders")
        |> order_for_year_and_month_query(year, month)
        |> select(
          [o],
          %{
            ebay_sales: fragment(
              "SUM(CASE WHEN ? IS NOT NULL THEN (? + ?) ELSE 0 END)",
              o.ebay_id,
              o.item_price,
              o.shipping_price
            ),
            ebay_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.ebay_id, o.selling_fees),
            hipstamp_sales: fragment(
              "SUM(CASE WHEN ? IS NOT NULL THEN (? + ?) ELSE 0 END)",
              o.hipstamp_id,
              o.item_price,
              o.shipping_price
            ),
            hipstamp_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.hipstamp_id, o.selling_fees),
            gross_sales: sum(fragment("? + ?", o.item_price, o.shipping_price)),
            selling_fees: sum(o.selling_fees),
            shipping_cost: sum(o.shipping_cost),
          }
        )
        |> Repo.one(),
      stamp_cost <- total_stamp_cost_for_year_and_month(year, month),
      net_sales <- total_net_sales(
        gross_sales: base_data.gross_sales,
        selling_fees: base_data.selling_fees,
        shipping_cost: base_data.shipping_cost,
        stamp_cost: stamp_cost
      ),
      calculated_data <-
        %{
          ebay_sales_percentage: calculate_percentage(base_data.ebay_sales, base_data.gross_sales),
          hipstamp_sales_percentage: calculate_percentage(base_data.hipstamp_sales, base_data.gross_sales),
          net_sales: net_sales,
          net_sales_percentage: calculate_percentage(net_sales, base_data.gross_sales),
          selling_fees_percentage: calculate_percentage(base_data.selling_fees, base_data.gross_sales),
          shipping_cost_percentage: calculate_percentage(base_data.shipping_cost, base_data.gross_sales),
          stamp_cost: stamp_cost,
          stamp_cost_percentage: calculate_percentage(stamp_cost, base_data.gross_sales)
        }
    ) do
      Map.merge(base_data, calculated_data)
    end
  end

  defp begin_and_end_date_for_year_and_month(year, month) do
    with(
      begin_date <-
        year
        |> Date.new!(month, 1)
        |> DateTime.new!(Time.new!(0, 0, 0), "America/New_York")
        |> DateTime.shift_zone!("Etc/UTC"),
      end_date <-
        year
        |> Date.new!(month, 1)
        |> Date.end_of_month()
        |> DateTime.new!(Time.new!(23, 59, 59), "America/New_York")
        |> DateTime.shift_zone!("Etc/UTC")
    ) do
      {begin_date, end_date}
    end
  end

  defp calculate_percentage(numerator, denominator) do
    numerator
    |> Decimal.div(denominator)
    |> Decimal.to_float()
    |> Kernel.*(100)
    |> Kernel.round()
  end

  defp order_for_year_and_month_query(query, year, month) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month) do
      where(
        query,
        [o],
        fragment("? BETWEEN ? AND ?", o.ordered_at, ^begin_date, ^end_date)
      )
    end
  end

  defp total_net_sales(
    gross_sales: gross_sales, selling_fees: selling_fees, shipping_cost: shipping_cost, stamp_cost: stamp_cost
  ) do
    Decimal.sub(gross_sales,
      Decimal.add(
        selling_fees,
        Decimal.add(shipping_cost, stamp_cost)
      )
    )
  end

  defp total_stamp_cost_for_year_and_month(year, month) do
    with(
      order_subquery <-
        Order
        |> order_for_year_and_month_query(year, month)
        |> select([o], o.id)
    ) do
      from(l in "listings")
      |> where([l], l.order_id in subquery(order_subquery))
      |> join(:left, [l], s in "stamps", on: l.stamp_id == s.id)
      |> select([l, s], sum(fragment("? + ?", s.cost, s.purchase_fees)))
      |> Repo.one()
    end
  end
end
