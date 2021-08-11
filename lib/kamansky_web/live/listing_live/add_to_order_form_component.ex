defmodule KamanskyWeb.ListingLive.AddToOrderFormComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec update(%{required(:listing) => Kamansky.Sales.Listings.Listing.t, optional(any) => any}, Phoenix.LiveView.Socket.t)
    :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{listing: listing} = assigns, socket) do
    with changeset <- Listings.change_listing(listing),
      socket <-
        socket
        |> assign(assigns)
        |> assign(:changeset, changeset)
    do
      {:ok, socket}
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"listing" => listing_params}, socket) do
    changeset =
      socket.assigns.listing
      |> Listings.change_listing(listing_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("submit", %{"listing" => listing_params}, socket) do
    case Listings.add_listing_to_order(socket.assigns.listing, listing_params) do
      {:ok, _order} ->
        {:noreply,
          socket
            |> put_flash(:info, "You have successfully added this listing to an order.")
            |> push_redirect(to: Routes.listing_active_path(socket, :index))
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
