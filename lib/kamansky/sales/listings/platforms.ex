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

  @spec get_ebay_listing(String.t) :: EbayListing.t | nil
  def get_ebay_listing(ebay_id) do
    EbayListing
    |> where(ebay_id: ^ebay_id)
    |> join(:left, [el], l in assoc(el, :listing))
    |> preload([el, l], listing: l)
    |> Repo.one()
  end

  @spec get_ebay_listing_for_listing(Listing.t) :: EbayListing.t | nil
  def get_ebay_listing_for_listing(%Listing{id: listing_id}) do
    EbayListing
    |> where(listing_id: ^listing_id)
    |> Repo.one()
  end

  @spec get_hipstamp_listing(pos_integer) :: HipstampListing.t | nil
  def get_hipstamp_listing(hipstamp_id) do
    HipstampListing
    |> where(hipstamp_id: ^hipstamp_id)
    |> join(:left, [el], l in assoc(el, :listing))
    |> preload([el, l], listing: l)
    |> Repo.one()
  end

  @spec get_hipstamp_listing_for_listing(Listing.t) :: HipstampListing.t | nil
  def get_hipstamp_listing_for_listing(%Listing{id: listing_id}) do
    HipstampListing
    |> where(listing_id: ^listing_id)
    |> Repo.one()
  end

  @spec update_external_listing(external_listing, map) :: {:ok, external_listing} | {:error, Ecto.Changeset.t} when external_listing: EbayListing.t | HipstampListing.t
  def update_external_listing(external_listing, attrs) do
    external_listing
    |> change_external_listing(attrs)
    |> Repo.update()
  end

  defp external_listing_struct(:ebay), do: %EbayListing{}
  defp external_listing_struct(:hipstamp), do: %HipstampListing{}
end
