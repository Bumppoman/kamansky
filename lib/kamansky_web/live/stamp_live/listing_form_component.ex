defmodule KamanskyWeb.StampLive.ListingFormComponent do
  use KamanskyWeb, :live_component
  use KamanskyWeb.Modal

  import Kamansky.Helpers

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Services
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"listing" => listing_params}, socket) do
    socket.assigns.listing
    |> Listings.change_listing(listing_params)
    |> Map.put(:action, :validate)
    |> maybe_put_ebay_suggested_values(socket)
    |> maybe_put_hipstamp_suggested_values(socket)
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

  @impl true
  @spec open_assigns(Phoenix.LiveView.Socket.t, map) :: Phoenix.LiveView.Socket.t
  def open_assigns(socket, %{"stamp-id" => stamp_id}) do
    with stamp <- Stamps.get_stamp_with_reference(stamp_id),
      listing <- %Listing{},
      socket <-
        socket
        |> assign(:suggested_ebay_description, Services.Ebay.Listing.suggested_description(stamp))
        |> assign(:suggested_ebay_title, Services.Ebay.Listing.suggested_title(stamp))
        |> assign(:suggested_hipstamp_description, Services.Hipstamp.Listing.suggested_description(stamp))
        |> assign(:suggested_hipstamp_title, Services.Hipstamp.Listing.suggested_title(stamp))
    do
      socket
      |> assign(:changeset,
        listing
        |> Listings.change_listing()
        |> maybe_put_ebay_suggested_values(socket)
        |> maybe_put_hipstamp_suggested_values(socket)
      )
      |> assign(:listing, listing)
      |> assign(:stamp, stamp)
    end
  end

  @spec maybe_put_ebay_suggested_values(Ecto.Changeset.t, Phoenix.LiveView.Socket.t) :: Ecto.Changeset.t
  defp maybe_put_ebay_suggested_values(changeset, socket) do
    if Ecto.Changeset.get_field(changeset, :ebay) == true and is_nil(Ecto.Changeset.get_field(changeset, :ebay_title)) do
      changeset
      |> Ecto.Changeset.put_change(:ebay_description, socket.assigns.suggested_ebay_description)
      |> Ecto.Changeset.put_change(:ebay_title, socket.assigns.suggested_ebay_title)
    else
      changeset
    end
  end

  @spec maybe_put_hipstamp_suggested_values(Ecto.Changeset.t, Phoenix.LiveView.Socket.t) :: Ecto.Changeset.t
  defp maybe_put_hipstamp_suggested_values(changeset, socket) do
    if Ecto.Changeset.get_field(changeset, :hipstamp) == true and is_nil(Ecto.Changeset.get_field(changeset, :hipstamp_title)) do
      changeset
      |> Ecto.Changeset.put_change(:hipstamp_description, socket.assigns.suggested_hipstamp_description)
      |> Ecto.Changeset.put_change(:hipstamp_title, socket.assigns.suggested_hipstamp_title)
    else
      changeset
    end
  end
end
