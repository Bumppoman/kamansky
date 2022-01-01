defmodule Kamansky.Services.Listing do
  import Kamansky.Sales.Orders.Order, only: [is_ebay: 1, is_hipstamp: 1]

  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.{Listing, Platforms}
  alias Kamansky.Sales.Listings.Platforms.{EbayListing, HipstampListing}
  alias Kamansky.Services.{Ebay, Hipstamp}

  @spec delist_any_external_listings(Listing.t) :: :ok
  def delist_any_external_listings(%Listing{} = listing) do
    with listing <- Repo.preload(listing, [:ebay_listing, :hipstamp_listing, :order]) do
      maybe_delist_ebay_listing(listing)
      maybe_delist_hipstamp_listing(listing)
      :ok
    end
  end

  @spec maybe_delist_ebay_listing(Listing.t) :: {:ebay_removed | :noop, Listing.t} | {:ok, EbayListing.t} | :noop
  defp maybe_delist_ebay_listing(%Listing{ebay_listing: %EbayListing{}, order: order} = listing) when not is_ebay(order) do
    Ebay.Listing.maybe_remove_listing(listing)
  end
  defp maybe_delist_ebay_listing(%Listing{ebay_listing: %EbayListing{} = ebay_listing}), do: Platforms.delete_external_listing(ebay_listing)
  defp maybe_delist_ebay_listing(_), do: :noop

  @spec maybe_delist_hipstamp_listing(Listing.t) :: {:hipstamp_removed | :noop, Listing.t} | {:ok, HipstampListing.t} | :noop
  defp maybe_delist_hipstamp_listing(%Listing{hipstamp_listing: %HipstampListing{}, order: order} = listing) when not is_hipstamp(order) do
    Hipstamp.Listing.maybe_remove_listing(listing)
  end
  defp maybe_delist_hipstamp_listing(%Listing{hipstamp_listing: %HipstampListing{} = hipstamp_listing}), do: Platforms.delete_external_listing(hipstamp_listing)
  defp maybe_delist_hipstamp_listing(_), do: :noop
end
