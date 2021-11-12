defmodule KamanskyWeb.ListingLive.Bid do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:data_count, fn -> Listings.count_listings(:bid) end)
      |> assign(:data_locator, fn options -> Listings.find_row_number_for_listing(:bid, options) end)
      |> assign(:data_source, fn options -> Listings.list_listings(:bid, options) end)
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {
      :noreply,
      socket
      |> assign(:go_to_record, Map.get(params, "go_to_record"))
      |> assign(:page_title, "Listings with eBay Bids")
    }
  end
end
