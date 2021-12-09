defmodule KamanskyWeb.ListingLive.Components do
  use Phoenix.Component

  alias Kamansky.Stamps.Stamp
  alias KamanskyWeb.Router.Helpers, as: Routes

  @spec flaws(map) :: Phoenix.LiveView.Rendered.t
  def flaws(assigns) do
    ~H"""
    <div x-data="{showFlaws: false}" x-on:mouseleave="showFlaws = false">
      <sup class="text-xs">
        <a
          class="action-icon"
          tabindex="0"
          title="Flaws"
          x-on:mouseover="showFlaws = true"
        >*</a>
      </sup>
      <div
        class="absolute transition duration-150 ease-in-out mt-8 md:mt-0 -top-6 left-4 sm:ml-10 w-10/12 md:w-1/2"
        x-cloak
        x-show="showFlaws"
      >
        <div class="w-full bg-white rounded shadow-2xl">
          <div class="relative h-full p-4">
            <svg class="hidden md:block absolute -ml-5 left-0 bottom-3" width="30px" height="30px" viewBox="0 0 9 16" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
              <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
                <g id="Tooltips-" transform="translate(-874.000000, -1029.000000)" fill="#FFFFFF">
                  <g id="Group-3-Copy-16" transform="translate(850.000000, 975.000000)">
                    <g id="Group-2" transform="translate(24.000000, 0.000000)">
                      <polygon id="Triangle" transform="translate(4.500000, 62.000000) rotate(-90.000000) translate(-4.500000, -62.000000) " points="4.5 57.5 12.5 66.5 -3.5 66.5"></polygon>
                    </g>
                  </g>
                </g>
              </g>
            </svg>
            <%= Stamp.formatted_flaws(@stamp) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

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
