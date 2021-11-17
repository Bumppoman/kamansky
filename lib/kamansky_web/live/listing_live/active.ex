defmodule KamanskyWeb.ListingLive.Active do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Services.{Ebay, Hipstamp}
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:data_count, fn -> Listings.count_listings(:active) end)
      |> assign(:data_locator, fn options -> Listings.find_row_number_for_listing(:active, options) end)
      |> assign(:data_source, fn options -> Listings.list_active_listings(options) end)
    }
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("list_on_ebay", %{"listing-id" => listing_id}, socket) do
    with listing <- Listings.get_listing_to_list(listing_id),
      {:ok, ebay_listing} <- Ebay.Listing.list(listing)
    do
      refresh_datatable("listings-kamansky-data-table", [])
      {:noreply, put_flash(socket, :info, %{message: "You have successfully listed this listing on eBay.", timestamp: Time.utc_now()})}
    end
  end

  def handle_event("list_on_hipstamp", %{"listing-id" => listing_id}, socket) do
    with listing <- Listings.get_listing_to_list(listing_id),
      {:ok, hipstamp_listing} <- Hipstamp.Listing.list(listing)
    do
      refresh_datatable("listings-kamansky-data-table", [])
      {:noreply, put_flash(socket, :info, %{message: "You have successfully listed this listing on Hipstamp.", timestamp: Time.utc_now()})}
    end
  end

  @impl true
  @spec handle_info({:listing_added_to_order, pos_integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:listing_added_to_order, _listing_id}, socket) do
    refresh_datatable("listings-kamansky-data-table", [])
    {:noreply, put_flash(socket, :info, %{message: "You have successfully added this listing to an order.", timestamp: Time.utc_now()})}
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {
      :noreply,
      socket
      |> assign(:go_to_record, Map.get(params, "go_to_record"))
      |> assign(:page_title, "Listings")
    }
  end
end
