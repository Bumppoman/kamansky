defmodule Kamansky.Operations.Statistics do
  import Ecto.Query, warn: false

  alias Kamansky.Repo
  alias Kamansky.Sales.Orders.Order

  @spec get_base_statistics(integer, integer) :: map
  def get_base_statistics(year, month) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month) do
      from(o in "orders")
      |> where([o], fragment("? BETWEEN ? AND ?", o.ordered_at, ^begin_date, ^end_date))
      |> join(:left, [o], l in "listings", on: l.order_id == o.id)
      |> join(:left, [o, l], s in "stamps", on: l.stamp_id == s.id)
      |> group_by([o], o.id)
      |> select(
        [o, ..., s],
        %{
          ebay_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.ebay_id, o.selling_fees),
          hipstamp_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.hipstamp_id, o.selling_fees),
          gross_profit: sum(fragment("? + ?", o.item_price, o.shipping_price)),
          selling_fees: sum(o.selling_fees),
          shipping_cost: sum(o.shipping_cost),
          stamp_cost: sum(fragment("? + ?", s.cost, s.purchase_fees))
        }
      )
      |> Repo.one()
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
      where(
        Order,
        [o],
        fragment("? BETWEEN ? AND ?", o.ordered_at, ^begin_date, ^end_date)
      )
    end
  end

  defp total_ebay_selling_fees(orders) do
    Enum.reduce(orders, Decimal.new(0), &(if Order.ebay?(&1), do: Decimal.add(&1.selling_fees, &2), else: &2))
  end

  defp total_gross_profit(orders) do
    Enum.reduce(orders, Decimal.new(0), &(Decimal.add(&1.gross_profit, &2)))
  end

  defp total_hipstamp_selling_fees(orders) do
    Enum.reduce(orders, Decimal.new(0), &(if Order.hipstamp?(&1), do: Decimal.add(&1.selling_fees, &2), else: &2))
  end

  defp total_selling_fees(orders) do
    Enum.reduce(orders, Decimal.new(0), &(Decimal.add(&1.selling_fees, &2)))
  end

  defp total_shipping_cost(orders) do
    Enum.reduce(orders, Decimal.new(0), &(Decimal.add(&1.shipping_cost, &2)))
  end

  defp total_stamp_cost(orders) do
    Enum.reduce(orders, Decimal.new(0), &(Decimal.add(&1.stamp_cost, &2)))
  end
end
