defmodule KamanskyWeb.ListingLive.Components do
  use Phoenix.Component

  import Phoenix.HTML.Form

  alias Kamansky.Stamps.Stamp
  alias KamanskyWeb.Router.Helpers, as: Routes

  @spec ebay_form(map) :: Phoenix.LiveView.Rendered.t
  def ebay_form(assigns) do
    ~H"""
    <h6 class="font-bold mb-2">eBay</h6>
    <div class="form-group" x-data="{count: 0}">
      <%= label @f, :ebay_title, "Title" %>
      <div class="form-input">
        <%= text_input @f,
          :ebay_title,
          maxlength: 80,
          "x-init": "count = $el.value.length",
          "x-on:change": "count = $el.value.length"
        %>
      </div>
      <div class="mt-2 text-xs" x-text="count + '/80 characters'" />
    </div>
    <div class="form-group">
      <%= label @f, :ebay_description, "Description" %>
      <div class="form-input">
        <%= textarea @f,
          :ebay_description,
          rows: 4,
          class: "shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
        %>
      </div>
    </div>
    <div class="grid grid-cols-2">
      <div class="form-group required">
        <%= label @f, :auction_price, "Auction Price" %>
        <div class="form-input">
          <div class="form-input-prepend">
            <span>$</span>
          </div>
          <%= text_input @f, :auction_price %>
        </div>
      </div>
      <div class="form-group required">
        <%= label @f, :buy_it_now_price, "Buy It Now Price" %>
        <div class="form-input">
          <div class="form-input-prepend">
            <span>$</span>
          </div>
          <%= text_input @f, :buy_it_now_price %>
        </div>
      </div>
    </div>
    """
  end

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
        class="absolute transition duration-150 ease-in-out mt-8 md:mt-0 -top-6 left-4 sm:ml-10 w-10/12 md:w-min"
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

  @spec hipstamp_form(map) :: Phoenix.LiveView.Rendered.t
  def hipstamp_form(assigns) do
    ~H"""
    <h6 class="font-bold mb-2">Hipstamp</h6>
    <div class="form-group" x-data="{count: 0}">
      <%= label @f, :hipstamp_title, "Title" %>
      <div class="form-input">
        <%= text_input @f,
          :hipstamp_title,
          maxlength: 80,
          "x-init": "count = $el.value.length",
          "x-on:change": "count = $el.value.length"
        %>
      </div>
      <div class="mt-2 text-xs" x-text="count + '/80 characters'" />
    </div>
    <div class="form-group">
      <%= label @f, :hipstamp_description, "Description" %>
      <div class="form-input">
        <%= textarea @f,
          :hipstamp_description,
          rows: 4,
          class: "shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
        %>
      </div>
    </div>
    <div class="form-group required">
      <%= label @f, :listing_price, "Listing Price" %>
      <div class="form-input">
        <div class="form-input-prepend">
          <span>$</span>
        </div>
        <%= text_input @f, :listing_price %>
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
