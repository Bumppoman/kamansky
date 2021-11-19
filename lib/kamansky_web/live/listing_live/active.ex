defmodule KamanskyWeb.ListingLive.Active do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
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

  def handle_event("error", _, socket), do: {:noreply, put_flash(socket, :info, %{type: :error, message: "Lorem ipsum dolor sit amet.", timestamp: DateTime.utc_now()})}
  def handle_event("success", _, socket), do: {:noreply, put_flash(socket, :info, %{type: :success, message: "Lorem ipsum dolor sit amet.", timestamp: DateTime.utc_now()})}

  @impl true
  @spec handle_info({atom, pos_integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:error, _error}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, %{type: :error, message: "An error occurred while attempting to list this listing on eBay.", timestamp: DateTime.utc_now()})
      |> push_event("kamansky:closeModal", %{})
    }
  end

  def handle_info({:listing_added_to_order, _listing_id}, socket) do
    close_modal_with_success_and_refresh_datatable(
      socket,
      "listings-kamansky-data-table",
      "kamansky:closeModal",
      "You have successfully added this listing to an order."
    )
  end

  def handle_info({:listing_listed_on_ebay, listing_id}, socket) do
    close_modal_with_success_and_refresh_datatable(
      socket,
      "listings-kamansky-data-table",
      "kamansky:closeModal",
      "You have successfully listed this listing on eBay.",
      listing_id
    )
  end

  def handle_info({:listing_listed_on_hipstamp, listing_id}, socket) do
    close_modal_with_success_and_refresh_datatable(
      socket,
      "listings-kamansky-data-table",
      "kamansky:closeModal",
      "You have successfully listed this listing on Hipstamp.",
      listing_id
    )
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
