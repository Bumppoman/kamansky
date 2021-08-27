defmodule KamanskyWeb.ListingLive.Active do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.{Listings, Orders}
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:data_count, Listings.count_listings(:active))
      |> assign(:data_locator, fn options -> Listings.find_row_number_for_listing(:active, options) end)
      |> assign(:data_source, fn options -> Listings.list_listings(:active, options) end)
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, :add_to_order | :index, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :index, params) do
    socket
    |> assign(:go_to_record, Map.get(params, "go_to_record"))
    |> assign(:page_title, "Listings")
  end


  defp apply_action(socket, :add_to_order, %{"id" => id}) do
    socket
    |> assign(:go_to_record, id)
    |> assign(:listing, Listings.get_listing!(id))
    |> assign(:page_title, "Add Listing to Order")
    |> assign(:pending_orders, Orders.list_pending_orders_to_add_listing())
  end
end
