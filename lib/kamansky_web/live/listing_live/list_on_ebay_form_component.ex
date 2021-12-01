defmodule KamanskyWeb.ListingLive.ListOnEbayFormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Platforms
  alias Kamansky.Sales.Listings.Platforms.EbayListing
  alias Kamansky.Services.Ebay

  @impl true
  @spec update(map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{trigger_params: %{"listing-id" => listing_id}} = assigns, socket) do
    with listing <- Listings.get_listing_to_list(listing_id) do
      socket
      |> assign(assigns)
      |> assign(
        :changeset,
        Platforms.change_external_listing(
          %EbayListing{},
          %{
            auction_price: Ebay.Listing.suggested_auction_price(listing),
            buy_it_now_price: Ebay.Listing.suggested_buy_it_now_price(listing),
            ebay_description: Ebay.Listing.suggested_description(listing.stamp),
            ebay_title: Ebay.Listing.suggested_title(listing.stamp)
          }
        )
      )
      |> assign(:listing, listing)
      |> ok()
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"ebay_listing" => ebay_listing_params}, socket) do
    %EbayListing{}
    |> Platforms.change_external_listing(ebay_listing_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  def handle_event("submit", %{"ebay_listing" => ebay_listing_params}, socket) do
    socket.assigns.listing
    |> Kamansky.Services.Stamp.create_new_external_listing_for_existing_listing(:ebay, ebay_listing_params)
    |> case do
      {:ok, %EbayListing{listing_id: listing_id}} -> send self(), {:listing_listed_on_ebay, listing_id}
      {:error, error} -> send self(), {:error, error}
    end

    noreply(socket)
  end
end
