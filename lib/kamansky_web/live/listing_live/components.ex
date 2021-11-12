defmodule KamanskyWeb.ListingLive.Components do
  use Phoenix.Component

  alias KamanskyWeb.Router.Helpers, as: Routes

  @spec tabs(map) :: Phoenix.LiveView.Rendered.t
  def tabs(assigns) do
    ~H"""
    <nav class="flex font-medium justify-center leading-6 mt-4">
      <%= live_patch "Active",
        to: Routes.listing_active_path(@socket, :index),
        class: "block mr-1.5 px-4 py-2 text-gray-500" <> (
          if @socket.view == KamanskyWeb.ListingLive.Active do
            " bg-blue-100 rounded-md text-blue-600"
          else
            " text-opacity-70"
          end
        )
      %>
      <%= live_patch "With Bids",
        to: Routes.listing_bid_path(@socket, :index),
        class: "block mr-1.5 px-4 py-2 text-gray-500" <> (
          if @socket.view == KamanskyWeb.ListingLive.Bid do
            " bg-blue-100 rounded-md text-blue-600"
          else
            " text-opacity-70"
          end
        )
      %>
      <%= live_patch "Sold",
        to: Routes.listing_sold_path(@socket, :index),
        class: "block ml-1.5 px-4 py-2 text-gray-500" <> (
          if @socket.view === KamanskyWeb.ListingLive.Sold do
            " bg-blue-100 rounded-md text-blue-600"
          else
            " text-opacity-70"
          end
        )
      %>
    </nav>
    """
  end
end
