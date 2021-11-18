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
      {
        :ok,
        socket
        |> assign(assigns)
        |> assign(
          :changeset,
          Platforms.change_external_listing(
            %EbayListing{},
            %{
              auction_price: Ebay.Listing.suggested_auction_price(listing),
              buy_it_now_price: Ebay.Listing.suggested_buy_it_now_price(listing),
              title: Ebay.Listing.title(listing.stamp)
            }
          )
        )
        |> assign(:listing, listing)
      }
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"ebay_listing" => ebay_listing_params}, socket) do
    with changeset <-
      %EbayListing{}
      |> Platforms.change_external_listing(ebay_listing_params)
      |> Map.put(:action, :validate)
    do
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("submit", %{"ebay_listing" => ebay_listing_params}, socket) do
    :ebay
    |> Platforms.create_external_listing(socket.assigns.listing, ebay_listing_params)
    |> case do
      {:ok, %EbayListing{listing_id: listing_id}} ->
        close_modal_with_success_and_refresh_datatable(
          socket,
          "listings-kamansky-data-table",
          "kamansky:closeModal",
          "You have successfully listed this stamp on eBay.",
          listing_id
        )
      {:error, %Ecto.Changeset{} = changeset} -> assign(socket, :changeset, changeset)
    end
  end
end
