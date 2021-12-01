require Logger

defmodule Kamansky.Jobs.MonitorListings do
  use GenServer

  alias Kamansky.Sales.Listings.Platforms
  alias Kamansky.Sales.Listings.Platforms.EbayListing
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

  @spec load_new_ebay_bids :: :ok
  defp load_new_ebay_bids do
    Ebay.Listing.list_active_listings_with_bids()
    |> Enum.map(&process_ebay_bid/1)
    |> Enum.all?(&(&1 == :noop))
    |> if(do: Logger.info("Kamansky.Jobs.MonitorListings: no eBay listings with new bids"))
  end

  @spec process_ebay_bid(%{optional(:atom) => any, bid_count: integer, ebay_id: String.t}) :: :noop | :ok
  defp process_ebay_bid(%{bid_count: new_bid_count, ebay_id: ebay_id} = ebay_listing) do
    ebay_id
    |> Platforms.get_ebay_listing()
    |> case do
      nil -> :noop
      %EbayListing{bid_count: 0} = kamansky_ebay_listing when new_bid_count == 1 ->
        update_ebay_listing(kamansky_ebay_listing, ebay_listing)

        kamansky_ebay_listing.listing
        |> Hipstamp.Listing.maybe_remove_listing()
        |> case do
          {:hipstamp_removed, listing} -> Logger.info("Kamansky.Jobs.MonitorListings: removed Hipstamp listing for listing #{listing.id}")
          {:noop, listing} -> Logger.info("Kamansky.Jobs.MonitorListings: no Hipstamp listing to remove for listing #{listing.id}")
        end
      %EbayListing{bid_count: current_bid_count} = kamansky_ebay_listing when new_bid_count > current_bid_count ->
        update_ebay_listing(kamansky_ebay_listing, ebay_listing)
      _ -> :noop
    end
  end

  @spec relist_ebay_listings :: :ok
  defp relist_ebay_listings do
    case Platforms.list_expired_ebay_listings() do
      [] -> Logger.info("Kamansky.Jobs.MonitorListings: no eBay listings to relist")
      listings ->
        Enum.each(listings, fn listing ->
          listing
          |> Ebay.Listing.relist()
          |> case do
            {:ok, ebay_listing} -> Logger.info("Kamansky.Jobs.MonitorListings: relisted eBay listing #{ebay_listing.ebay_id}")
            {:error, error} -> Logger.error("Kamansky.Jobs.MonitorListings: error relisting eBay listing (#{error.dump})")
          end
        end)
    end
  end

  @spec update_ebay_listing(EbayListing.t, map) :: :ok
  defp update_ebay_listing(%EbayListing{} = kamansky_ebay_listing, ebay_listing) do
    kamansky_ebay_listing
    |> Platforms.update_external_listing(ebay_listing)
    |> case do
      {:ok, listing} -> Logger.info("Kamansky.Jobs.MonitorListings: new eBay bid received for listing #{listing.listing_id}")
      {:error, _changeset} -> Logger.error("Kamansky.Jobs.MonitorListings: error loading eBay bid")
    end
  end
end
