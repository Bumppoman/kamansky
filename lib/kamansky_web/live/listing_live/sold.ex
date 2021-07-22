defmodule KamanskyWeb.ListingLive.Sold do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps.Stamp

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> assign([
        data_count: Listings.count_listings(:sold),
        data_locator: fn options -> Listings.find_row_number_for_listing(:sold, options) end,
        data_source: fn options -> Listings.list_sold_listings(options) end
      ])
      |> assign(:page_title, "Sold Listings")

    {:ok, socket}
  end
end
