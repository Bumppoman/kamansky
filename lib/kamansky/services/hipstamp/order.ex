defmodule Kamansky.Services.Hipstamp.Order do
  import Kamansky.Helpers, only: [humanize_and_capitalize: 1]

  alias Kamansky.Sales.{Customers, Listings, Orders}
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
      |> Enum.each(
        fn(hipstamp_order) ->
          with order <- Orders.get_or_initialize_order(hipstamp_id: String.to_integer(hipstamp_order["id"])),
            ordered_at <- parse_ordered_at(hipstamp_order["created_at"]),
            customer_name <-
              normalize_name(
                hipstamp_order["ShippingAddress"]["name_first"],
                hipstamp_order["ShippingAddress"]["name_last"]
              ),
            {:ok, %{id: customer_id}} <-
              Customers.insert_or_update_hipstamp_customer(
                %{
                  hipstamp_id: hipstamp_order["buyer_id"],
                  name: customer_name,
                  street_address: humanize_and_capitalize(String.downcase(hipstamp_order["ShippingAddress"]["address"])),
                  city: humanize_and_capitalize(String.downcase(hipstamp_order["ShippingAddress"]["city"])),
                  state: String.upcase(hipstamp_order["ShippingAddress"]["state_abbreviation"]),
                  zip: hipstamp_order["ShippingAddress"]["postal_code"],
                  email: String.downcase(hipstamp_order["buyer_email"])
                }
              ),
            item_price <- Decimal.from_float(hipstamp_order["sales_listings_amount"] / 1),
            shipping_price <- Decimal.from_float(hipstamp_order["postage_amount"] / 1),
            selling_fees <- calculate_selling_fees(item_price, shipping_price),
            {:ok, order} <-
              Orders.insert_or_update_hipstamp_order(
                order,
                %{
                  customer_id: customer_id,
                  ordered_at: ordered_at,
                  item_price: item_price,
                  shipping_price: shipping_price,
                }
              ),
            listings <- update_order_listings(hipstamp_order["SaleListings"], order.id)
          do
            Orders.update_order_fees(
              order,
              selling_fees: selling_fees,
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

  defp calculate_selling_fees(item_price, shipping_price) do
    with hipstamp_coefficient <- Decimal.from_float(0.0895),
      paypal_coefficient <- Decimal.from_float(0.029),
      paypal_flat_fee <- Decimal.from_float(0.3),
      item_fees <-
        item_price
        |> Decimal.mult(hipstamp_coefficient)
        |> Decimal.add(Decimal.mult(item_price, paypal_coefficient))
        |> Decimal.add(paypal_flat_fee),
      shipping_fees <-
        shipping_price
        |> Decimal.mult(hipstamp_coefficient)
        |> Decimal.add(Decimal.mult(shipping_price, paypal_coefficient))
    do
      item_fees
      |> Decimal.add(shipping_fees)
      |> Decimal.round(2)
    end
  end

  defp hipstamp_username, do: Application.get_env(:kamansky, :hipstamp_username)

  @spec normalize_name(String.t, String.t) :: String.t
  defp normalize_name(first_name, last_name) do
    with(
      first_name <-
        first_name
        |> String.downcase()
        |> humanize_and_capitalize(),
      last_name <-
        last_name
        |> String.downcase()
        |> humanize_and_capitalize()
    ) do
      "#{first_name} #{last_name}"
    end
  end

  defp parse_ordered_at(ordered_at) do
    ordered_at
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!("America/New_York")
    |> DateTime.shift_zone!("Etc/UTC")
  end

  defp update_order_listings(sale_listings, order_id) do
    Enum.map(
      sale_listings,
      fn sale_listing ->
        with(
          %Stamp{listing: listing} = stamp <-
            Stamps.get_stamp_by_inventory_key(sale_listing["private_id"], with_listing: true),
          {:ok, _stamp} <- Stamps.mark_stamp_as_sold(stamp),
          {:ok, listing} <-
            Listings.mark_listing_sold(
              listing,
              order_id: order_id,
              sale_price: Decimal.new(sale_listing["price"]), # comes in as a string instead of float
            )
        ) do
          listing
        end
      end
    )
  end
end
