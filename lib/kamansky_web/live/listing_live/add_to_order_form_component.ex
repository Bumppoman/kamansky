defmodule KamanskyWeb.ListingLive.AddToOrderFormComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Sales.{Listings, Orders}
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec update(map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{trigger_params: %{"listing-id" => listing_id}} = assigns, socket) do
    with listing <- Listings.get_listing!(listing_id) do
      {
        :ok,
        socket
        |> assign(assigns)
        |> assign(:changeset, Listings.change_listing(listing))
        |> assign(:listing, listing)
        |> assign(:pending_orders, Orders.list_pending_orders_to_add_listing())
      }
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"listing" => listing_params}, socket) do
    with changeset <-
      socket.assigns.listing
      |> Listings.change_listing(listing_params)
      |> Map.put(:action, :validate)
    do
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("submit", %{"listing" => listing_params}, socket) do
    case Listings.add_listing_to_order(socket.assigns.listing, listing_params) do
      {:ok, _order} ->
        send self(), {:listing_added_to_order, socket.assigns.listing.id}
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
