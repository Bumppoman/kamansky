defmodule KamanskyWeb.ListingLive.Bid do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {4, :asc}

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Listings with Bids")}

  @impl true
  @spec count_data(:index, String.t | nil) :: integer
  def count_data(_action, search), do: Listings.count_listings_with_bids(search)

  @impl true
  @spec load_data(:index, Kamansky.Paginate.params) :: [Expense.t]
  def load_data(_action, params), do: Listings.list_listings_with_bids(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.listing_bid_path(socket, :index, opts)
end
