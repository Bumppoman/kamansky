defmodule Kamansky.Services.Order do
  alias Kamansky.Sales.{Listings, Orders}
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Ebay
  alias Kamansky.Services.Hipstamp

  @spec mark_order_shipped(Kamansky.Sales.Orders.Order.t) :: {:ok, Order.t}
  def mark_order_shipped(%Kamansky.Sales.Orders.Order{ebay_id: ebay_id} = order) when not is_nil(ebay_id), do: Ebay.Order.mark_shipped(order)
  def mark_order_shipped(%Kamansky.Sales.Orders.Order{hipstamp_id: hipstamp_id} = order) when not is_nil(hipstamp_id), do: Hipstamp.Order.mark_shipped(order)
  def mark_order_shipped(%Kamansky.Sales.Orders.Order{} = order), do: Orders.mark_order_as_shipped(order)

  @spec maybe_delist_listings(Order.t) :: [{:ebay | :hipstamp, Listing.t}]
  def maybe_delist_listings(%Order{id: order_id, ebay_id: ebay_id, hipstamp_id: nil}) when not is_nil(ebay_id) do
    order_id
    |> Listings.list_listings_for_order()
    |> Enum.map(&Hipstamp.Listing.maybe_remove_listing/1)
  end

  def maybe_delist_listings(%Order{id: order_id, ebay_id: nil, hipstamp_id: hipstamp_id}) when not is_nil(hipstamp_id) do
    order_id
    |> Listings.list_listings_for_order()
    |> Enum.map(&Ebay.Listing.maybe_remove_listing/1)
  end
end
