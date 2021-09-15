defmodule KamanskyWeb.ListingLive.Sold do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:data_count, Listings.count_listings(:sold))
      |> assign(:data_locator, fn options -> Listings.find_row_number_for_listing(:sold, options) end)
      |> assign(:data_source, fn options -> Listings.list_sold_listings(options) end)
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, :index | :show, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :index, _params), do: assign(socket, :page_title, "Sold Listings")
  defp apply_action(socket, :show, %{"id" => id}) do
    with listing <- Listings.get_listing!(id) do
      socket
      |> assign(:page_title, "View Listing")
      |> assign(:stamp, Stamps.get_stamp_detail!(listing.stamp_id))
    end
  end
end
