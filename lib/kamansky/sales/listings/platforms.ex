defmodule Kamansky.Sales.Listings.Platforms do
  import Ecto.Query, warn: false

  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Listings.Platforms.{EbayListing, HipstampListing}

  @spec change_external_listing(EbayListing.t | HipstampListing.t, map) :: Ecto.Changeset.t
  def change_external_listing(%EbayListing{} = ebay_listing, attrs), do: EbayListing.changeset(ebay_listing, attrs)
  def change_external_listing(%HipstampListing{} = hipstamp_listing, attrs), do: HipstampListing.changeset(hipstamp_listing, attrs)

  @spec create_external_listing(:ebay | :hipstamp, Listing.t, map) :: {:ok, EbayListing.t | HipstampListing.t} | {:error, Ecto.Changeset.t}
  def create_external_listing(service, %Listing{id: listing_id}, attrs) do
    service
    |> external_listing_struct()
    |> change_external_listing(attrs)
    |> Ecto.Changeset.put_change(:listing_id, listing_id)
    |> Repo.insert()
  end

  defp external_listing_struct(:ebay), do: %EbayListing{}
  defp external_listing_struct(:hipstamp), do: %HipstampListing{}
end
