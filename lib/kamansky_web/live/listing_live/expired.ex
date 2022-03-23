defmodule KamanskyWeb.ListingLive.Expired do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {2, :asc}

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Platforms
  alias Kamansky.Services

  @impl true
  @spec handle_event(String.t, any, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("relist", %{"listing-id" => listing_id}, socket) do
    listing_id
    |> Platforms.get_ebay_listing_for_listing()
    |> Services.Ebay.Listing.relist()
    |> case do
      {:ok, _stamp} ->
        close_modal_with_success_and_reload_data(
          socket,
          "kamansky:closeConfirmationModal",
          "You have relisted this stamp."
        )
      {:error, %{code: :ebay_relist_listing_error, dump: _response}} -> {:noreply, socket}
    end
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Expired Auction Listings")}

  @impl true
  @spec count_data(Phoenix.LiveView.Socket.t, String.t | nil) :: integer
  def count_data(_socket, search), do: Listings.count_expired_listings(search)

  @impl true
  @spec load_data(Phoenix.LiveView.Socket.t, Kamansky.Paginate.params) :: [Expense.t]
  def load_data(_socket, params), do: Listings.list_expired_listings(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.listing_expired_path(socket, :index, opts)

  @spec sort_action(Phoenix.LiveView.Socket.t) :: :expired
  def sort_action(_socket), do: :expired
end
