defmodule KamanskyWeb.ListingLive.AddExternalListingFormComponent do
  use KamanskyWeb, :live_component
  use KamanskyWeb.Modal

  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Platforms
  alias Kamansky.Sales.Listings.Platforms.{EbayListing, HipstampListing}
  alias Kamansky.Services.{Ebay, Hipstamp}

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", params, socket) do
    with type <- socket.assigns.type do
      type
      |> empty_external_listing()
      |> Platforms.change_external_listing(external_listing_params(type, params))
      |> Map.put(:action, :validate)
      |> then(&assign(socket, :changeset, &1))
      |> noreply()
    end
  end

  def handle_event("submit", params, socket) do
    with type <- socket.assigns.type do
      socket.assigns.listing
      |> Kamansky.Services.Stamp.create_new_external_listing_for_existing_listing(type, external_listing_params(type, params))
      |> case do
        {:ok, %EbayListing{listing_id: listing_id}} -> send self(), {:listing_listed_on_ebay, listing_id}
        {:ok, %HipstampListing{listing_id: listing_id}} -> send self(), {:listing_listed_on_hipstamp, listing_id}
        {:error, error} -> send self(), {:error, error}
      end

      noreply(socket)
    end
  end

  @impl true
  @spec open_assigns(Phoenix.LiveView.Socket.t, map) :: Phoenix.LiveView.Socket.t
  def open_assigns(socket, %{"listing-id" => listing_id, "type" => type}) do
    with listing <- Listings.get_listing_to_list(listing_id),
      type <- String.to_existing_atom(type)
    do
      socket
      |> assign(:changeset, initialize_external_listing(type, listing))
      |> assign(:listing, listing)
      |> assign(:type, type)
    end
  end

  @spec empty_external_listing(atom) :: EbayListing.t | HipstampListing.t
  defp empty_external_listing(:ebay), do: %EbayListing{}
  defp empty_external_listing(:hipstamp), do: %HipstampListing{}

  @spec external_listing_params(atom, map) :: map
  defp external_listing_params(:ebay, %{"ebay_listing" => ebay_listing_params}), do: ebay_listing_params
  defp external_listing_params(:hipstamp, %{"hipstamp_listing" => hipstamp_listing_params}), do: hipstamp_listing_params

  @spec form_component(:ebay | :hipstamp) :: fun
  defp form_component(:ebay), do: &KamanskyWeb.ListingLive.Components.ebay_form/1
  defp form_component(:hipstamp), do: &KamanskyWeb.ListingLive.Components.hipstamp_form/1

  @spec initialize_external_listing(:ebay | :hipstamp, Listing.t) :: Ecto.Changeset.t
  defp initialize_external_listing(:ebay, listing) do
    Platforms.change_external_listing(
      %EbayListing{},
      %{
        auction_price: Ebay.Listing.suggested_auction_price(listing),
        buy_it_now_price: Ebay.Listing.suggested_buy_it_now_price(listing),
        ebay_description: Ebay.Listing.suggested_description(listing.stamp),
        ebay_title: Ebay.Listing.suggested_title(listing.stamp)
      }
    )
  end

  defp initialize_external_listing(:hipstamp, listing) do
    Platforms.change_external_listing(
      %HipstampListing{},
      %{
        hipstamp_description: Hipstamp.Listing.suggested_description(listing.stamp),
        hipstamp_title: Hipstamp.Listing.suggested_title(listing.stamp)
      }
    )
  end

  @spec listing_service(:ebay | :hipstamp) :: String.t
  defp listing_service(:ebay), do: "eBay"
  defp listing_service(:hipstamp), do: "Hipstamp"
end
