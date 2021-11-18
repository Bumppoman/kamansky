defmodule Kamansky.Services.Stamp do
  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Listings.Platforms.{EbayListing, HipstampListing}
  alias Kamansky.Services.{Ebay, Hipstamp}

  @spec create_new_external_listing_for_existing_listing(Listing.t, :ebay | :hipstamp, map) :: {:ok, EbayListing.t | HipstampListing.t} | {:error, any}
  def create_new_external_listing_for_existing_listing(%Listing{} = listing, :ebay, opts \\ %{}), do: Ebay.Listing.list(listing, opts)

  @spec list_stamp_for_sale(pos_integer, %{required(String.t) => boolean, optional(any) => any}) :: :ok
  def list_stamp_for_sale(listing_id, %{"hipstamp" => hipstamp}) do
    with listing <- Listings.get_listing_to_list(listing_id) do
      if String.to_existing_atom(hipstamp), do: Hipstamp.Listing.list(listing)

      :ok
    end
  end
end
