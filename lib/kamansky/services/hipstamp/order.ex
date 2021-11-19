defmodule Kamansky.Services.Hipstamp.Order do
  import Kamansky.Helpers, only: [humanize_and_capitalize: 1]

  alias Kamansky.Operations.Administration
  alias Kamansky.Sales.{Customers, Listings, Orders}
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Hipstamp
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @spec all_paid :: %{required(String.t) => any}
  def all_paid do
    with {:ok, response} <- Hipstamp.get("/stores/#{hipstamp_username()}/sales/paid") do
      response.body["results"]
    end
  end

  @spec all_pending(DateTime.t) :: %{required(String.t) => any}
  def all_pending(%DateTime{} = from_time) do
    with(
      from_time <-
        from_time
        |> DateTime.shift_zone!("America/New_York")
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

  @spec load_new_orders :: [Order.t]
  def load_new_orders do
    with %Order{ordered_at: from_date} <- Orders.most_recent_order(:hipstamp),
      new_orders <- all_pending(from_date)
    do
      new_orders
      |> Enum.reverse()
      |> Enum.flat_map(
        fn(hipstamp_order) ->
          with %Order{} = order <- Orders.initialize_order(hipstamp_id: String.to_integer(hipstamp_order["id"])),
            ordered_at <- parse_ordered_at(hipstamp_order["created_at"]),
            customer_name <-
              normalize_name(
                hipstamp_order["ShippingAddress"]["name_first"],
                hipstamp_order["ShippingAddress"]["name_last"]
              ),
            state <- determine_state(hipstamp_order["ShippingAddress"]),
            country <- determine_country(hipstamp_order["ShippingAddress"]["country_name"]),
            {:ok, %{id: customer_id}} <-
              Customers.insert_or_update_hipstamp_customer(
                %{
                  hipstamp_id: hipstamp_order["buyer_id"],
                  name: customer_name,
                  street_address: humanize_and_capitalize(String.downcase(hipstamp_order["ShippingAddress"]["address"])),
                  city: humanize_and_capitalize(String.downcase(hipstamp_order["ShippingAddress"]["city"])),
                  state: state,
                  zip: hipstamp_order["ShippingAddress"]["postal_code"],
                  country: country,
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
            order
            |> Orders.update_order_fees(
              selling_fees: selling_fees,
              shipping_cost: tentative_shipping_cost(listings)
            )
            |> elem(1)
            |> List.wrap()
          else
            _ -> []
          end
        end
      )
    end
  end

  @spec mark_shipped(Kamansky.Sales.Orders.Order.t) :: {:ok, Kamansky.Sales.Orders.Order.t} | {:error, Ecto.Changeset.t}
  def mark_shipped(%Order{hipstamp_id: id} = order) do
    Hipstamp.put(
      "/stores/#{hipstamp_username()}/sales/#{id}",
      %{ flag_shipping: 1 }
    )

    Orders.mark_order_as_shipped(order)
  end

  @spec calculate_selling_fees(Decimal.t, Decimal.t) :: Decimal.t
  defp calculate_selling_fees(item_price, shipping_price) do
    with hipstamp_coefficient <- Administration.get_setting!(:hipstamp_percentage_fee),
      paypal_coefficient <- Administration.get_setting!(:paypal_percentage_fee),
      paypal_flat_fee <- Administration.get_setting!(:paypal_flat_fee),
      hipstamp_fees <-
        item_price
        |> Decimal.add(shipping_price)
        |> Decimal.mult(hipstamp_coefficient),
      paypal_fees <-
        item_price
        |> Decimal.add(shipping_price)
        |> Decimal.mult(paypal_coefficient)
        |> Decimal.add(paypal_flat_fee)
    do
      hipstamp_fees
      |> Decimal.add(paypal_fees)
      |> Decimal.round(2)
    end
  end

  @spec determine_country(String.t) :: String.t | nil
  defp determine_country("United States"), do: nil
  defp determine_country(country_name), do: country_name

  @spec determine_state(%{required(String.t) => String.t}) :: String.t
  defp determine_state(%{"state_abbreviation" => state}), do: String.upcase(state)
  defp determine_state(%{"state_name" => state}), do: state

  @spec hipstamp_username :: String.t
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

  @spec tentative_shipping_cost([Listing.t]) :: Decimal.t
  defp tentative_shipping_cost(listings) do
    listings
    |> Enum.count()
    |> Kernel./(6)
    |> Float.floor()
    |> Decimal.from_float()
    |> Decimal.mult(Administration.get_setting!(:additional_ounce))
    |> Decimal.add(Administration.get_setting!(:shipping_cost))
    |> Decimal.round(2)
  end

  @spec parse_ordered_at(String.t) :: DateTime.t
  defp parse_ordered_at(ordered_at) do
    ordered_at
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!("America/New_York")
    |> DateTime.shift_zone!("Etc/UTC")
  end

  @spec update_order_listings([map], integer) :: [Kamansky.Sales.Listings.Listing.t]
  defp update_order_listings(sale_listings, order_id) do
    Enum.map(
      sale_listings,
      fn sale_listing ->
        with(
          %Stamp{listing: listing} = stamp <- Stamps.get_stamp_by_inventory_key(sale_listing["private_id"], with_listing: true),
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
