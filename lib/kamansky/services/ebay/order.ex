require Logger

defmodule Kamansky.Services.Ebay.Order do
  import SweetXml
  import Kamansky.Helpers, only: [humanize_and_capitalize: 1]

  alias Kamansky.Operations.Administration
  alias Kamansky.Sales.{Customers, Listings, Orders}
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Ebay
  alias Kamansky.Stamps

  @spec all_pending(DateTime.t) :: list
  def all_pending(%DateTime{} = from_time) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <GetOrdersRequest xmlns="urn:ebay:apis:eBLBaseComponents">
      #{Ebay.requester_credentials()}
      <CreateTimeFrom>#{DateTime.to_iso8601(from_time)}</CreateTimeFrom>
      <CreateTimeTo>#{DateTime.to_iso8601(DateTime.utc_now())}</CreateTimeTo>
      <IncludeFinalValueFee>true</IncludeFinalValueFee>
    </GetOrdersRequest>
    """
    |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "GetOrders"}]))
    |> Map.get(:body)
    |> parse(dtd: :none)
    |> xpath(~x"//Order"l,
      ebay_order_id: ~x"./OrderID/text()"s,
      ordered_at: ~x"CreatedTime/text()"s,
      customer: [
        ~x".",
        ebay_user_id: ~x"./BuyerUserID/text()"s,
        name: ~x"./ShippingAddress/Name/text()"s,
        street_address_1: ~x"./ShippingAddress/Street1/text()"s,
        street_address_2: ~x"./ShippingAddress/Street2/text()"s,
        city: ~x"./ShippingAddress/CityName/text()"s,
        state: ~x"./ShippingAddress/StateOrProvince/text()"s,
        zip: ~x"./ShippingAddress/PostalCode/text()"s,
        country: ~x"./ShippingAddress/Country/text()"s
      ],
      transactions: [
        ~x".//Transaction"l,
        ebay_item_id: ~x".//Item/ItemID/text()"s,
        item_price: ~x"./TransactionPrice/text()"s,
        selling_fees: ~x"./FinalValueFee/text()"s,
        shipping_price: ~x"./ActualShippingCost/text()"s
      ]
    )
  end

  @spec load_new_orders :: [Order.t]
  def load_new_orders do
    with %Order{ordered_at: from_date} <- Orders.most_recent_order(:ebay),
      new_orders <- all_pending(from_date)
    do
      new_orders
      |> Enum.reverse()
      |> Enum.flat_map(
        fn(ebay_order) ->
          with order <- Orders.get_or_initialize_order(ebay_id: ebay_order.ebay_order_id),
            ordered_at <- parse_ordered_at(ebay_order.ordered_at),
            customer_name <- normalize_name(ebay_order.customer.name),
            country <- determine_country(ebay_order.customer.country),
            {:ok, %{id: customer_id}} <-
              Customers.insert_or_update_ebay_customer(
                %{
                  ebay_id: ebay_order.customer.ebay_user_id,
                  name: customer_name,
                  street_address:
                    Enum.map_join(
                      Enum.reject([ebay_order.customer.street_address_1, ebay_order.customer.street_address_2], &(&1 == "")),
                      ", ",
                      &(humanize_and_capitalize(String.downcase(&1)))
                    ),
                  city:
                    ebay_order.customer.city
                    |> String.downcase()
                    |> humanize_and_capitalize(),
                  state: ebay_order.customer.state,
                  zip: ebay_order.customer.zip,
                  country: country
                }
              ),
            {:ok, order} <-
              Orders.insert_or_update_order(
                order,
                %{
                  customer_id: customer_id,
                  ordered_at: ordered_at,
                  item_price: Enum.reduce(ebay_order.transactions, 0, &Decimal.add(Decimal.new(&1.item_price), &2)),
                  shipping_price: Enum.reduce(ebay_order.transactions, 0, &Decimal.add(Decimal.new(&1.shipping_price), &2))
                }
              ),
            listings <- update_order_listings(ebay_order.transactions, order.id)
          do
            order
            |> Orders.update_order_fees(
              selling_fees: Decimal.add(Decimal.new("0.30"), Enum.reduce(ebay_order.transactions, 0, &Decimal.add(Decimal.new(&1.selling_fees), &2))),
              shipping_cost: Decimal.add(
                Administration.get_setting!(:shipping_cost),
                Decimal.from_float(Decimal.to_float(Administration.get_setting!(:additional_ounce)) * Float.floor(Enum.count(listings) / 6))
              )
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

  @spec mark_shipped(Order.t) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def mark_shipped(order) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <CompleteSaleRequest xmlns="urn:ebay:apis:eBLBaseComponents">
      #{Ebay.requester_credentials()}
      <OrderID>#{order.ebay_id}</OrderID>
      <Shipped>true</Shipped>
    </CompleteSaleRequest>
    """
    |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "CompleteSale"}]))
    |> Map.get(:body)
    |> parse(dtd: :none)
    |> xpath(~x"//CompleteSaleResponse",
      errors: ~x".//Errors"l,
      timestamp: ~x".//Timestamp/text()"s
    )
    |> case do
      %{errors: []} -> Orders.mark_order_as_shipped(order)
      %{errors: errors} -> {:error, errors}
    end
  end

  @spec determine_country(String.t) :: String.t | nil
  defp determine_country("US"), do: nil
  defp determine_country(country_name), do: country_name

  @spec normalize_name(String.t) :: String.t
  defp normalize_name(name) do
    name
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @spec parse_ordered_at(String.t) :: DateTime.t
  defp parse_ordered_at(ordered_at) do
    ordered_at
    |> DateTime.from_iso8601()
    |> elem(1)
    |> DateTime.truncate(:second)
  end

  @spec update_order_listings([map], integer) :: [Kamansky.Sales.Listings.Listing.t]
  defp update_order_listings(sale_listings, order_id) do
    Enum.map(
      sale_listings,
      fn sale_listing ->
        with(
          %Listing{stamp: stamp} = listing <- Listings.get_listing_by_ebay_id(sale_listing.ebay_item_id),
          {:ok, _stamp} <- Stamps.mark_stamp_as_sold(stamp),
          {:ok, listing} <-
            Listings.mark_listing_sold(
              listing,
              order_id: order_id,
              sale_price: Decimal.new(sale_listing.item_price)
            )
        ) do
          listing
        end
      end
    )
  end
end
