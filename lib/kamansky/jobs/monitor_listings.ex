require Logger

defmodule Kamansky.Jobs.MonitorListings do
  use GenServer

  alias Kamansky.Sales.Listings.Platforms
  alias Kamansky.Services.{Ebay, Hipstamp}

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  @spec init(any) :: {:ok, any}
  def init(state) do
    schedule()
    {:ok, state}
  end

  @impl true
  @spec handle_info(:work, any) :: {:noreply, any}
  def handle_info(:work, state) do
    load_new_ebay_bids()
    relist_ebay_listings()
    schedule()
    {:noreply, state}
  end

  @spec schedule :: reference
  defp schedule do
    Process.send_after(self(), :work, 120000)
  end

  defp load_new_ebay_bids do
    Enum.each(
      Ebay.Listing.list_active_listings_with_bids(),
      fn ebay_listing ->
        listing = Platforms.get_ebay_listing(ebay_listing.ebay_id)

        if listing.bid_count == 0 do
          listing
          |> Platforms.update_external_listing(ebay_listing)
          |> case do
            {:ok, _listing} -> Logger.info("Kamansky.Jobs.MonitorListings: new eBay bid received for listing #{listing.listing_id}")
            {:error, _changeset} -> Logger.error("Kamansky.Jobs.MonitorListings: error loading eBay bid")
          end

          Hipstamp.Listing.maybe_remove_listing(listing.listing)
        end
      end
    )
  end

  defp relist_ebay_listings do
    case Platforms.list_expired_ebay_listings() do
      [] -> Logger.info("#{__MODULE__}:  no eBay listings to relist")
      listings ->
        Enum.each(listings, fn listing ->
          listing
          |> Ebay.Listing.relist()
          |> case do
            {:ok, ebay_listing} -> Logger.info("#{__MODULE__}: relisted eBay listing #{ebay_listing.ebay_id}")
            {:error, error} -> Logger.error("#{__MODULE__}: error relisting eBay listing (#{error.dump})")
          end
        end)
    end
  end
end
