defmodule Kamansky.Services.Hipstamp.Order do
  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Hipstamp
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  def all_paid do
    with {:ok, response} <-
      Hipstamp.get("/stores/#{hipstamp_username()}/sales/paid")
    do
      response.body["results"]
    end
  end

  def all_pending(%DateTime{} = from_time) do
    with(
      from_time <-
        from_time
        |> DateTime.shift_zone("America/New_York")
        |> elem(1)
        |> Calendar.strftime("%c"),
      {:ok, response} <-
        Hipstamp.get(
          "/stores/#{hipstamp_username()}/sales/paid",
          query: [created_time_from: from_time]
        )
    ) do
      response.body["results"]
    end
  end

  def load_new_orders do
    with %Order{ordered_at: from_date} <- Orders.most_recent_order(),
      new_orders <- all_pending(from_date)
    do
      new_orders
      |> Enum.reverse()
      |> tl()
      |> Enum.each(
        fn(hipstamp_order) ->
          with order <- Orders.get_or_initialize_order(hipstamp_id: String.to_integer(hipstamp_order["id"])),
            ordered_at <-
              hipstamp_order["created_at"]
              |> NaiveDateTime.from_iso8601!()
              |> DateTime.from_naive!("America/New_York")
              |> DateTime.shift_zone!("Etc/UTC"),
            {:ok, order} <-
              Orders.insert_or_update_hipstamp_order(order,
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
              ),
            listings <-
              hipstamp_order["SaleListings"]
              |> Enum.map(
                fn sale_listing ->
                  with(
                    %Stamp{listing: listing} = stamp <-
                      Stamps.get_stamp_by_inventory_key(sale_listing["private_id"], with_listing: true),
                    {:ok, _stamp} <- Stamps.mark_stamp_as_sold(stamp),
                    {:ok, listing} <-
                      Listings.mark_listing_sold(
                        listing,
                        order_id: order.id,
                        sale_price: Decimal.new(sale_listing["price"]), # comes in as a string instead of float
                      )
                  ) do
                    listing
                  end
                end
              ),
            total_selling_fees <-
              listings
              |> Enum.map(
                fn listing ->
                  with(
                    selling_fees <-
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
                      |> Decimal.round(2, :floor),
                    {:ok, _listing} <- Listings.update_listing_selling_fees(listing, selling_fees)
                  ) do
                    selling_fees
                  end
                end
              )
              |> Enum.reduce(Decimal.new(0), &(Decimal.add(&1, &2)))
              |> Decimal.round(2)
          do
            Orders.update_order_fees(
              order,
              selling_fees: total_selling_fees,
              shipping_cost: Decimal.add(
                Decimal.from_float(0.55),
                Decimal.from_float(0.2 * Float.floor(Enum.count(listings) / 4))
              )
            )
          end
        end
      )
    end
  end

  def mark_shipped(%Order{hipstamp_id: id} = order) do
    Hipstamp.put(
      "/stores/#{hipstamp_username()}/sales/#{id}",
      %{ flag_shipping: 1 }
    )

    Orders.mark_order_as_shipped(order)
  end

  defp hipstamp_username, do: Application.get_env(:kamansky, :hipstamp_username)
end
