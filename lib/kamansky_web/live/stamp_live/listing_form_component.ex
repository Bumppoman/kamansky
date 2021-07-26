defmodule KamanskyWeb.StampLive.ListingFormComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Services
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec update(map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(assigns, socket) do
    with listing <- %Listing{},
      changeset <- Listings.change_listing(listing)
    do
      {
        :ok,
        socket
        |> assign(assigns)
        |> assign(:changeset, changeset)
        |> assign(:listing, listing)
      }
    end
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"listing" => listing_params}, socket) do
    with(
      changeset <-
        socket.assigns.listing
        |> Listings.change_listing(listing_params)
        |> Map.put(:action, :validate)
    ) do
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("submit", %{"listing" => listing_params}, socket) do
    case Stamps.sell_stamp(socket.assigns.stamp, listing_params) do
      {:ok, %Stamp{inventory_key: inventory_key}, listing_id} ->
        with :ok <- Services.Stamp.list_stamp_for_sale(listing_id, listing_params) do
          {
            :noreply,
            socket
              |> put_flash(:info, "You have successfully listed this stamp for sale (inventory key: ##{inventory_key}).")
              |> push_redirect(to: Routes.listing_active_path(socket, :index, go_to_record: listing_id))
          }
        end
    end
  end
end
