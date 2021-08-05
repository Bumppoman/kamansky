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
        |> Repo.one()
        |> Map.put(:stamp_cost, total_stamp_cost(orders))
    do
      {orders, base_statistics}
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

  defp order_for_year_and_month_query(year, month) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month) do
      where(
        Order,
        [o],
        fragment("? BETWEEN ? AND ?", o.ordered_at, ^begin_date, ^end_date)
      )
    end
  end

  defp total_stamp_cost(orders) do
    Enum.reduce(orders, Decimal.new(0), &(Decimal.add(&1.stamp_cost, &2)))
  end
end
