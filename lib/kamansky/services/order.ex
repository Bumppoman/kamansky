defmodule Kamansky.Services.Order do
  import Kamansky.Sales.Orders.Order, only: [is_ebay: 1, is_hipstamp: 1]

  alias Kamansky.Sales.{Listings, Orders}
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Ebay
  alias Kamansky.Services.Hipstamp

  @spec mark_order_shipped(Kamansky.Sales.Orders.Order.t) :: {:ok, Order.t}
  def mark_order_shipped(%Kamansky.Sales.Orders.Order{} = order) when is_ebay(order), do: Ebay.Order.mark_shipped(order)
  def mark_order_shipped(%Kamansky.Sales.Orders.Order{} = order) when is_hipstamp(order), do: Hipstamp.Order.mark_shipped(order)
  def mark_order_shipped(%Kamansky.Sales.Orders.Order{} = order), do: Orders.mark_order_as_shipped(order)

  @spec maybe_delist_competing_listings(Order.t) :: [{:ebay_removed | :hipstamp_removed | :noop, Listing.t}]
  def maybe_delist_competing_listings(%Order{id: order_id} = order) when is_ebay(order) do
    order_id
    |> Listings.list_listings_for_order()
    |> Enum.map(&Hipstamp.Listing.maybe_remove_listing/1)
  end

  def maybe_delist_competing_listings(%Order{id: order_id} = order) when is_hipstamp(order) do
    order_id
    |> Listings.list_listings_for_order()
    |> Enum.map(&Ebay.Listing.maybe_remove_listing/1)
  end
end
