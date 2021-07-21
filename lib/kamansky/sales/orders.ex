defmodule Kamansky.Sales.Orders do
  use Kamansky.Paginate

  import Ecto.Query, warn: false
  import Kamansky.Helpers

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Services.Hipstamp

  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def count_orders(:all) do
    Repo.aggregate(Order, :count, :id)
  end

  def count_orders(month: month) do
    Order
    |> where([o], fragment("DATE_PART('month', ?)", o.ordered_at) == ^month)
    |> Repo.aggregate(:count, :id)
  end

  def count_orders(status) do
    Order
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def find_row_number_for_order(status, options) do
    Order
    |> where(status: ^status)
    |> select([o], {o.id, row_number() |> over(order_by: [{:asc, o.id}])})
    |> Repo.all
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

  def get_or_initialize_order(params) do
    Order
    |> where(^params)
    |> limit(1)
    |> Repo.one()
    |> case do
      %Order{} = order ->
        order
      nil ->
        struct(Order, params)
    end
  end

  def get_order_detail(id) do
    listings_query =
      Listing
      |> join(:left, [l], s in assoc(l, :stamp))
      |> join(:left, [l, s], sr in assoc(s, :stamp_reference))
      |> preload([l, s, sr], [stamp: {s, [stamp_reference: sr]}])

    Order
    |> where(id: ^id)
    |> preload(listings: ^listings_query)
    |> Repo.one()
  end

  def list_orders(status, params) do
    orders =
      Order
      |> where(status: ^status)
      |> preload([o], [listings: :stamp])

    Paginate.list(Orders, orders, params)
  end

  def load_new_orders do
    with %Order{ordered_at: from_date} <- most_recent_order(),
      new_orders <- Hipstamp.Order.all_pending(from_date)
    do
      new_orders
      |> Enum.reverse()
      |> List.first()
      |> List.wrap()
      |> Enum.each(
        fn(hipstamp_order) ->

          # Create the order
          with order <- get_or_initialize_order(hipstamp_id: String.to_integer(hipstamp_order["id"])),
            ordered_at <-
              hipstamp_order["created_at"]
              |> NaiveDateTime.from_iso8601()
              |> elem(1)
              |> DateTime.from_naive("America/New_York")
              |> elem(1)
              |> DateTime.shift_zone("Etc/UTC")
              |> elem(1)
          do
            order =
              order
              |> Ecto.Changeset.change(
                [
                  ordered_at: ordered_at,
                  item_price: Decimal.from_float(hipstamp_order["sales_listings_amount"] / 1),
                  shipping_price: Decimal.from_float(hipstamp_order["postage_amount"] / 1),
                  supply_cost: Decimal.from_float(0.1),
                  name: "#{String.capitalize(String.downcase(hipstamp_order["ShippingAddress"]["name_first"]))} #{humanize_and_capitalize(String.downcase(hipstamp_order["ShippingAddress"]["name_last"]))}",
                  street_address: humanize_and_capitalize(String.downcase(hipstamp_order["ShippingAddress"]["address"])),
                  city: humanize_and_capitalize(String.downcase(hipstamp_order["ShippingAddress"]["city"])),
                  state: String.upcase(hipstamp_order["ShippingAddress"]["state_abbreviation"]),
                  zip: hipstamp_order["ShippingAddress"]["postal_code"],
                  email: String.downcase(hipstamp_order["buyer_email"])
                ]
              )
              |> Repo.insert_or_update()
              |> elem(1)

            # Add all of the listings to the order and mark the stamps as sold
            listings =
              hipstamp_order["SaleListings"]
              |> Enum.map(
                fn sale_listing ->

                  # Find stamp
                  stamp =
                    Stamp
                    |> where(inventory_key: ^sale_listing["private_id"])
                    |> join(:left, [s], l in assoc(s, :listing))
                    |> preload([s, l], [listing: l])
                    |> Repo.one()

                  # Update stamp
                  stamp
                  |> Ecto.Changeset.change(status: :sold)
                  |> Repo.update()

                  # Update the listing and add it to the order
                  stamp.listing
                  |> Ecto.Changeset.change(
                    [
                      order_id: order.id,
                      sale_price: Decimal.new(sale_listing["price"]),
                      status: :sold
                    ]
                  )
                  |> Repo.update()
                  |> elem(1)
                end
              )

            # Calculate the selling fees for each listing
            total_selling_fees =
              listings
              |> Enum.map(
                fn listing ->
                  selling_fees =
                    [
                      Decimal.mult(
                        listing.sale_price,
                        Decimal.from_float(0.0895)
                      ),
                      Decimal.div(
                        Decimal.mult(
                          order.shipping_price,
                          Decimal.from_float(0.0895)
                        ),
                        Decimal.new(
                          Enum.count(listings)
                        )
                      ),
                      Decimal.mult(
                        listing.sale_price,
                        Decimal.from_float(0.029)
                      ),
                      Decimal.div(
                        Decimal.mult(
                          order.shipping_price,
                          Decimal.from_float(0.029)
                        ),
                        Decimal.new(
                          Enum.count(listings)
                        )
                      ),
                      Decimal.from_float(0.3 / Enum.count(listings))
                    ]
                    |> Enum.reduce(Decimal.new(0), &(Decimal.add(&1, &2)))
                    |> Decimal.round(2)

                  # Update listing
                  listing
                  |> Ecto.Changeset.change(selling_fees: selling_fees)
                  |> Repo.update()

                  # Return the selling fees
                  selling_fees
                end
              )
              |> Enum.reduce(Decimal.new(0), &(Decimal.add(&1, &2)))
              |> Decimal.round(2)

            # Calculate the total order selling fees and shipping fee
            order
            |> Ecto.Changeset.change(
              [
                selling_fees: total_selling_fees,
                shipping_cost: Decimal.add(
                  Decimal.from_float(0.55),
                  Decimal.from_float(0.2 * (Float.floor(Enum.count(listings) / 4) - 1))
                )
              ]
            )
            |> Repo.update()
          end
        end
      )
    end
  end

  def most_recent_order do
    Order
    |> order_by(desc: :ordered_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search) do
    where(query, [o], ilike(fragment("CAST(id AS text)"), ^"%#{search}%"))
  end

  @impl true
  @spec sort(Ecto.Query.t, %{column: integer, direction: :asc | :desc}) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :id})
  def sort(query, %{column: 1, direction: direction}), do: order_by(query, {^direction, :ordered_at})

  def total_gross_profit(:all) do
    Order
    |> select(sum(fragment("item_price + shipping_price")))
    |> Repo.one()
  end

  def total_net_profit(:all), do: total_net_profit_query(Order)

  def total_net_profit(month: month) do
    Order
    |> where([s], fragment("DATE_PART('month', ?)", s.ordered_at) == ^month)
    |> total_net_profit_query()
  end

  def total_stamps_in_orders(:all), do: stamps_in_orders_query(Order)

  def total_stamps_in_orders(month: month) do
    Order
    |> where([s], fragment("DATE_PART('month', ?)", s.ordered_at) == ^month)
    |> stamps_in_orders_query()
  end

  defp stamps_in_orders_query(query) do
    query
    |> with_stamps_query()
    |> select([o, ..., s], count(s.id))
    |> Repo.one()
  end

  defp total_net_profit_query(query) do
    query
    |> with_stamps_query()
    |> preload([o, l, s], listings: {l, [stamp: s]})
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &(Decimal.add(Order.net_profit(&1), &2)))
  end

  defp with_stamps_query(query) do
    query
    |> join(:left, [o], l in assoc(o, :listings))
    |> join(:left, [o, l], s in assoc(l, :stamp))
  end
end
