defmodule KamanskyWeb.ListingLive.Active do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {0, :asc}

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Listings")}

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
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully added this listing to an order."
    )
  end

  def handle_info({:listing_listed_on_ebay, listing_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully listed this listing on eBay.",
      listing_id
    )
  end

  def handle_info({:listing_listed_on_hipstamp, listing_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully listed this listing on Hipstamp.",
      listing_id
    )
  end

  @impl true
  @spec count_data(:index, String.t | nil) :: integer
  def count_data(_action, search), do: Listings.count_listings(:active, search)

  @impl true
  @spec find_item_in_data(:index, pos_integer, integer, Kamansky.Paginate.sort_direction) :: integer
  def find_item_in_data(_action, item_id, sort, direction), do: Listings.find_row_number_for_listing(:active, item_id, sort, direction)

  @impl true
  @spec load_data(:index, Kamansky.Paginate.params) :: [Listing.t]
  def load_data(_action, params), do: Listings.list_active_listings(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.listing_active_path(socket, :index, opts)

  @spec sort_action(Phoenix.LiveView.Socket.t) :: :active
  def sort_action(_socket), do: :active
end
