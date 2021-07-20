defmodule KamanskyWeb.StampLive.ListingFormComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  def update(assigns, socket) do
    listing = %Listing{}
    changeset = Listings.change_listing(listing)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:listing, listing)}
  end

  @impl true
  def handle_event("validate", %{"listing" => listing_params}, socket) do
    changeset =
      socket.assigns.listing
      |> Listings.change_listing(listing_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("submit", %{"listing" => listing_params}, socket) do
    case Stamps.sell_stamp(socket.assigns.stamp, listing_params) do
      {:ok, _stamp, listing_id} ->
        {:noreply,
          socket
          |> put_flash(:info, "You have successfully listed this stamp for sale.")
          |> push_redirect(to: Routes.listing_active_path(socket, :index, go_to_record: listing_id))
        }
    end
  end
end
