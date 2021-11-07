defmodule Kamansky.Operations.Dashboard do
  import Ecto.Query, warn: false
  import Kamansky.Helpers

  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Stamps.Stamp

  @spec list_pending_orders :: [Order.t]
  def list_pending_orders do
    Order
    |> where(status: :pending)
    |> join(:left, [o], c in assoc(o, :customer))
    |> preload([o, c], customer: c)
    |> order_by(desc: :ordered_at)
    |> Repo.all()
  end

  @spec load_dashboard_data(String.t) :: %{atom: any}
  def load_dashboard_data(_timezone) do
    #with date <- DateTime.now!(timezone),
      #this_month <- date.month,
      #previous_month <-
      #  date.day
      #  |> then(&(max(&1, Date.add(date, -&1))))
      #  |> Map.get(:day)
      #  |> then(&(Date.add(date, -&1)))
      #  |> Map.get(:month),
    with stamp_totals <-
        from(s in "stamps")
        |> select(
          [s],
          %{
            collection_stamp_cost: fragment(
              "SUM(CASE WHEN ? = ? THEN ? END)",
              s.status,
              ^get_value_for_ecto_enum(Stamp, :status, :collection),
              s.cost + s.purchase_fees
            ),
            listed_stamp_cost: fragment(
              "SUM(CASE WHEN ? = ? THEN ? END)",
              s.status,
              ^get_value_for_ecto_enum(Stamp, :status, :listed),
              s.cost + s.purchase_fees
            ),
            sold_stamp_cost: fragment(
              "SUM(CASE WHEN ? = ? THEN ? END)",
              s.status,
              ^get_value_for_ecto_enum(Stamp, :status, :sold),
              s.cost + s.purchase_fees
            ),
            stock_stamp_cost: fragment(
              "SUM(CASE WHEN ? = ? THEN ? END)",
              s.status,
              ^get_value_for_ecto_enum(Stamp, :status, :stock),
              s.cost + s.purchase_fees
            ),
            total_stamps_sold: fragment(
              "COUNT(CASE WHEN ? = ? THEN ? END)",
              s.status,
              ^get_value_for_ecto_enum(Stamp, :status, :sold),
              s.id
            )
          }
        )
        |> Repo.one(),
      listing_totals <-
        from(l in "listings")
        |> select(
          [l],
          %{
            total_listing_price: fragment(
              "SUM(CASE WHEN ? = ? THEN ? END)",
              l.status,
              ^get_value_for_ecto_enum(Listing, :status, :active),
              l.listing_price
            )
          }
        )
        |> Repo.one(),
      order_totals <-
        from(o in "orders")
        |> select(
          [o],
          %{
            total_gross_profit: sum(o.item_price + o.shipping_price),
            total_orders: count(o.id)
          }
        )
        |> Repo.one()
    do
      stamp_totals
      |> Map.merge(listing_totals)
      |> Map.merge(order_totals)
    end
  end
end
