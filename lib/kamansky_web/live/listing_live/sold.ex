defmodule KamanskyWeb.ListingLive.Sold do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {1, :desc}

  import Kamansky.Helpers
  import KamanskyWeb.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Sold Listings")}

  @impl true
  @spec count_data(Phoenix.LiveView.Socket.t, String.t | nil) :: integer
  def count_data(_socket, search), do: Listings.count_listings(:sold, search)

  @impl true
  @spec find_item_in_data(Phoenix.LiveView.Socket.t, pos_integer, integer, Kamansky.Paginate.sort_direction) :: integer
  def find_item_in_data(_socket, item_id, sort, direction), do: Listings.find_row_number_for_listing(:sold, item_id, sort, direction)

  @impl true
  @spec load_data(Phoenix.LiveView.Socket.t, Kamansky.Paginate.params) :: [Listing.t]
  def load_data(_socket, params), do: Listings.list_sold_listings(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.listing_sold_path(socket, :index, opts)

  @spec sort_action(Phoenix.LiveView.Socket.t) :: :sold
  def sort_action(_socket), do: :sold
end
