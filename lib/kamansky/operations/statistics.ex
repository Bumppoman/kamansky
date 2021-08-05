defmodule Kamansky.Operations.Statistics do
  import Ecto.Query, warn: false

  alias Kamansky.Repo
  alias Kamansky.Sales.Orders.Order

  @spec get_order_statistics(integer, integer) :: {[Order.t], map}
  def get_order_statistics(year, month) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month),
      orders <- list_orders_for_year_and_month(year, month),
      base_statistics <-
        from(o in "orders")
        |> where([o], fragment("? BETWEEN ? AND ?", o.ordered_at, ^begin_date, ^end_date))
        |> select(
          [o],
          %{
            ebay_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.ebay_id, o.selling_fees),
            hipstamp_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.hipstamp_id, o.selling_fees),
            gross_profit: sum(fragment("? + ?", o.item_price, o.shipping_price)),
            selling_fees: sum(o.selling_fees),
            shipping_cost: sum(o.shipping_cost),
          }
        )
        |> Repo.one(),
      stamp_cost <- total_stamp_cost(orders),
      net_profit <- total_net_profit(orders),
      calculated_statistics <-
        %{
          net_profit: net_profit,
          net_profit_percentage: calculate_percentage(net_profit, base_statistics.gross_profit),
          selling_fees_percentage: calculate_percentage(base_statistics.selling_fees, base_statistics.gross_profit),
          shipping_cost_percentage: calculate_percentage(base_statistics.shipping_cost, base_statistics.gross_profit),
          stamp_cost: stamp_cost,
          stamp_cost_percentage: calculate_percentage(stamp_cost, base_statistics.gross_profit)
        }
    do
      {orders, Map.merge(base_statistics, calculated_statistics)}
    end
  end

  @spec list_orders_for_year_and_month(integer, integer) :: [Order.t]
  def list_orders_for_year_and_month(year, month) do
    order_for_year_and_month_query(year, month)
    |> join(:left, [o], l in assoc(o, :listings))
    |> join(:left, [o, l], s in assoc(l, :stamp))
    |> select_merge(
      [o, ..., s],
      %{
        gross_profit: fragment("? + ?", o.item_price, o.shipping_price),
        net_profit:
          fragment(
            "(? + ?) - (? + ? + ? + ?)",
            o.item_price,
            o.shipping_price,
            o.shipping_cost,
            o.selling_fees,
            s.cost,
            s.purchase_fees
          ),
        stamp_cost: sum(fragment("? + ?", s.cost, s.purchase_fees))
      }
    )
    |> group_by([o], o.id)
    |> order_by(:id)
    |> Repo.all()
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

  defp order_for_year_and_month_query(year, month) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month) do
      where(
        Order,
        [o],
        fragment("? BETWEEN ? AND ?", o.ordered_at, ^begin_date, ^end_date)
      )
    end
  end

  defp total_net_profit(orders) do
    Enum.reduce(orders, Decimal.new(0), &(Decimal.add(&1.net_profit, &2)))
  end

  defp total_stamp_cost(orders) do
    Enum.reduce(orders, Decimal.new(0), &(Decimal.add(&1.stamp_cost, &2)))
  end
end
