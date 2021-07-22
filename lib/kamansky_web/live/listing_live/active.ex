defmodule KamanskyWeb.ListingLive.Active do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.{Listings, Orders}
  alias Kamansky.Stamps.Stamp

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> assign([
        data_count: Listings.count_listings(:active),
        data_locator: fn options -> Listings.find_row_number_for_listing(:active, options) end,
        data_source: fn options -> Listings.list_listings(:active, options) end
      ])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params), do: assign(socket, :page_title, "Listings")
  defp apply_action(socket, :add_to_order, %{"id" => id}) do
    socket
    |> assign(:listing, Listings.get_listing!(id))
    |> assign(:page_title, "Add Listing to Order")
    |> assign(:pending_orders, Orders.list_pending_orders_to_add_listing())
  end
end
