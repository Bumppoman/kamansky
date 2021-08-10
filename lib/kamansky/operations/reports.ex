defmodule Kamansky.Operations.Reports do
  import Ecto.Query, warn: false
  import Kamansky.Helpers

  alias Kamansky.Operations.Expenses.Expense
  alias Kamansky.Repo
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Stamps.Stamp

  @spec get_expense_data(pos_integer, pos_integer) :: map
  def get_expense_data(year, month) do
    with(
      stamp_cost <-
        Stamp
        |> filter_query_for_year_and_month(year, month)
        |> where([s], s.status != ^:collection)
        |> select([s], sum(s.cost + s.purchase_fees))
        |> Repo.one(),
      base_data <-
        from(e in "expenses")
        |> filter_query_for_year_and_month_as_date(year, month)
        |> select(
          [e],
          %{
            platform_fees: fragment(
              "SUM(CASE WHEN ? = ? THEN ? ELSE 0 END)",
              e.category,
              ^get_value_for_ecto_enum(Expense, :category, :platform_fee),
              e.amount
            )
          }
        )
        |> Repo.one(),
      calculated_data <- %{
        stamp_cost: stamp_cost
      }
    ) do
      Map.merge(base_data, calculated_data)
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
        |> filter_query_for_year_and_month(year, month, :ordered_at)
        |> join(:left_lateral, [o], ss in subquery(stamps_query))
        |> select(
          [o, ss],
          %{
            ebay_gross_sales: fragment(
              "SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)",
              o.ebay_id,
              o.item_price + o.shipping_price
            ),
            ebay_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.ebay_id, o.selling_fees),
            hipstamp_gross_sales: fragment(
              "SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)",
              o.hipstamp_id,
              o.item_price + o.shipping_price
            ),
            hipstamp_selling_fees: fragment("SUM(CASE WHEN ? IS NOT NULL THEN ? ELSE 0 END)", o.hipstamp_id, o.selling_fees),
            gross_sales: sum(o.item_price + o.shipping_price),
            net_sales: sum((o.item_price + o.shipping_price) - o.selling_fees - o.shipping_cost - ss.stamp_cost),
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

  @spec list_report_months :: %{required(integer) => [{integer, map}]}
  def list_report_months do
    with(
      report_years <-
        Order
        |> select([o], fragment("DISTINCT(DATE_PART('year', ?), DATE_PART('month', ?))", o.ordered_at, o.ordered_at))
        |> Repo.all()
        |> Enum.group_by(
          fn {year, _month} -> trunc(year) end,
          fn {year, month} ->
            with year <- trunc(year),
              month <- trunc(month),
              order_data <-
                from(o in "orders")
                |> filter_query_for_year_and_month(year, month, :ordered_at)
                |> select(
                  [o],
                  %{
                    gross_sales: sum(o.item_price + o.shipping_price)
                  }
                )
                |> Repo.one(),
              expense_data <-
                from(e in "expenses")
                |> filter_query_for_year_and_month_as_date(year, month)
                |> select(
                  [e],
                  %{
                    total_expenses: sum(e.amount)
                  }
                )
                |> Repo.one(),
              calculated_data <-
                %{
                  net_profit: Decimal.sub(order_data.gross_sales || 0, expense_data.total_expenses || 0)
                }
            do
              {
                month,
                order_data
                |> Map.merge(expense_data)
                |> Map.merge(calculated_data)
              }
            end
          end
        )
    ) do
      for {year, months} <- report_years, into: %{} do
        with(
          totals <-
            Enum.reduce(
              months,
              {:total, %{gross_sales: 0, net_profit: 0, total_expenses: 0}},
              fn
                {_month, %{gross_sales: gross_sales, net_profit: net_profit, total_expenses: total_expenses}},
                {:total, data}
              ->
                {
                  :total,
                  %{
                    gross_sales: Decimal.add(data.gross_sales, gross_sales || 0),
                    net_profit: Decimal.add(data.net_profit, net_profit || 0),
                    total_expenses: Decimal.add(data.total_expenses, total_expenses || 0)
                  }
                }
              end
            )
        ) do
          {
            year,
            [totals | months]
          }
        end
      end
    end
  end

  @spec total_expenses_for_year_and_month(pos_integer, pos_integer) :: Decimal.t
  def total_expenses_for_year_and_month(year, month) do
    Expense
    |> filter_query_for_year_and_month_as_date(year, month)
    |> Repo.aggregate(:sum, :amount)
  end

  @spec calculate_percentage(Decimal.t, Decimal.t) :: integer
  defp calculate_percentage(_numerator, %Decimal{coef: 0}), do: 0
  defp calculate_percentage(numerator, denominator) do
    numerator
    |> Decimal.div(denominator)
    |> Decimal.to_float()
    |> Kernel.*(100)
    |> Kernel.round()
  end
end
