defmodule KamanskyWeb.ListingLive.Sold do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket) do
    {
      :ok,
      socket
      |> assign_defaults(session)
      |> assign([
        data_count: Listings.count_listings(:sold),
        data_locator: fn options -> Listings.find_row_number_for_listing(:sold, options) end,
        data_source: fn options -> Listings.list_sold_listings(options) end
      ])
      |> assign(:page_title, "Sold Listings")
    }
  end
end
