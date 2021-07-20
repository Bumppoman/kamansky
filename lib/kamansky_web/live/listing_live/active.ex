defmodule KamanskyWeb.ListingLive.Active do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Stamps.Stamp

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> assign([
        data_count: Listings.count_listings(:active),
        data_locator: fn options -> Listings.find_row_number_for_listing(:active, options) end,
        data_source: fn options -> Listings.list_listings(:active, options) end,
        page_title: "Listings"
      ])

    {:ok, socket}
  end
end
