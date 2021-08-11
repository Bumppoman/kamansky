defmodule Kamansky.Operations.Dashboard do
  import Ecto.Query, warn: false
  import Kamansky.Helpers

  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps.Stamp

  def load_dashboard_data(timezone) do
    with date <- DateTime.now!(timezone),
      this_month <- date.month,
      previous_month <-
        date.day
        |> then(&(max(&1, Date.add(date, -&1))))
        |> Map.get(:day)
        |> then(&(Date.add(date, -&1)))
        |> Map.get(:month),
      stamp_totals <-
        from(s in "stamps")
        |> select(
          [s],
          %{
            collection_cost: fragment(
              "SUM(CASE WHEN ? = ? THEN ? END)",
              s.status,
              ^get_value_for_ecto_enum(Stamp, :status, :collection),
              s.cost + s.purchase_fees
            ),
            listed_cost: fragment(
              "SUM(CASE WHEN ? = ? THEN ? END)",
              s.status,
              ^get_value_for_ecto_enum(Stamp, :status, :listed),
              s.cost + s.purchase_fees
            ),
            stock_cost: fragment(
              "SUM(CASE WHEN ? = ? THEN ? END)",
              s.status,
              ^get_value_for_ecto_enum(Stamp, :status, :stock),
              s.cost + s.purchase_fees
            ),
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
        |> Repo.one()
    do
      Map.merge(stamp_totals, listing_totals)
    end
  end
end
