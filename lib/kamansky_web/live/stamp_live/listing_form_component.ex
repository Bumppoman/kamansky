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
  def update(%{trigger_params: %{"stamp-id" => stamp_id}} = assigns, socket) do
    with stamp <- Stamps.get_stamp!(stamp_id),
      listing <- %Listing{}
    do
      socket
      |> assign(assigns)
      |> assign(:changeset, Listings.change_listing(listing))
      |> assign(:listing, listing)
      |> assign(:stamp, stamp)
      |> ok()
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"listing" => listing_params}, socket) do
    socket.assigns.listing
    |> Listings.change_listing(listing_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  def handle_event("submit", %{"listing" => listing_params}, socket) do
    case Stamps.sell_stamp(socket.assigns.stamp, listing_params) do
      {:ok, %Stamp{inventory_key: inventory_key}, listing_id} ->
        with :ok <- Services.Stamp.list_stamp_for_sale(listing_id, listing_params) do
          socket
          |> push_event("kamansky:closeModal", %{})
          |> put_flash(
            :info,
            %{type: :success, message: "You have successfully listed this stamp for sale (inventory key: ##{inventory_key}).", timestamp: Time.utc_now()}
          )
          |> push_redirect(to: Routes.listing_active_path(socket, :index, show: listing_id))
          |> noreply()
        end
    end
  end
end
