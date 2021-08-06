defmodule Kamansky.Operations.Reports do
  import Ecto.Query, warn: false

  alias Kamansky.Repo
  alias Kamansky.Stamps.Stamp

  @spec get_expense_data(integer, integer) :: map
  def get_expense_data(year, month) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month),
      stamp_cost <-
        from(s in "stamps")
        |> where([s], fragment("? BETWEEN ? AND ?", s.inserted_at, ^begin_date, ^end_date))
        |> select([s], sum(s.cost + s.purchase_fees))
        |> Repo.one()
    do
      %{
        stamp_cost: stamp_cost
      }
    end
  end

  @spec get_order_data(integer, integer) :: map
  def get_order_data(year, month) do
    with(
      stamps_query <-
        Stamp
        |> join(:left, [s], l in assoc(s, :listing))
        |> where([s, l], parent_as(:order).id == l.order_id)
        |> select([s], %{stamp_cost: sum(s.cost + s.purchase_fees)}),
      base_data <-
        from(o in "orders", as: :order)
        |> order_for_year_and_month_query(year, month)
        |> join(:left_lateral, [o], ss in subquery(stamps_query))
        |> select(
          [o, ss],
          %{
            ebay_gross_sales: fragment(
              "SUM(CASE WHEN ? IS NOT NULL THEN (? + ?) ELSE 0 END)",
              o.ebay_id,
              o.item_price,
              o.shipping_price
            ),
            ebay_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.ebay_id, o.selling_fees),
            hipstamp_gross_sales: fragment(
              "SUM(CASE WHEN ? IS NOT NULL THEN (? + ?) ELSE 0 END)",
              o.hipstamp_id,
              o.item_price,
              o.shipping_price
            ),
            hipstamp_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.hipstamp_id, o.selling_fees),
            gross_sales: sum(fragment("? + ?", o.item_price, o.shipping_price)),
            net_sales: sum(
              fragment(
                "(? + ?) - ? - ? - ?",
                o.item_price,
                o.shipping_price,
                o.selling_fees,
                o.shipping_cost,
                ss.stamp_cost
              )
            ),
            selling_fees: sum(o.selling_fees),
            shipping_cost: sum(o.shipping_cost),
            stamp_cost: sum(ss.stamp_cost)
          }
        )
        |> Repo.one(),
      calculated_data <-
        %{
          ebay_sales_percentage: calculate_percentage(base_data.ebay_gross_sales, base_data.gross_sales),
          ebay_selling_fees_percentage_of_gross:
            calculate_percentage(base_data.ebay_selling_fees, base_data.ebay_gross_sales),
          hipstamp_sales_percentage: calculate_percentage(base_data.hipstamp_gross_sales, base_data.gross_sales),
          hipstamp_selling_fees_percentage_of_gross:
            calculate_percentage(base_data.hipstamp_selling_fees, base_data.hipstamp_gross_sales),
          net_sales_percentage: calculate_percentage(base_data.net_sales, base_data.gross_sales),
          selling_fees_percentage: calculate_percentage(base_data.selling_fees, base_data.gross_sales),
          shipping_cost_percentage: calculate_percentage(base_data.shipping_cost, base_data.gross_sales),
          stamp_cost_percentage: calculate_percentage(base_data.stamp_cost, base_data.gross_sales)
        }
    ) do
      Map.merge(base_data, calculated_data)
    end
  end

  @spec begin_and_end_date_for_year_and_month(integer, integer) :: {DateTime.t, DateTime.t}
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

  @spec calculate_percentage(Decimal.t, Decimal.t) :: integer
  defp calculate_percentage(numerator, denominator) do
    numerator
    |> Decimal.div(denominator)
    |> Decimal.to_float()
    |> Kernel.*(100)
    |> Kernel.round()
  end

  @spec order_for_year_and_month_query(Ecto.Queryable.t, integer, integer) :: Ecto.Query.t
  defp order_for_year_and_month_query(query, year, month) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month) do
      where(
        query,
        [o],
        fragment("? BETWEEN ? AND ?", o.ordered_at, ^begin_date, ^end_date)
      )
    end
  end
end
