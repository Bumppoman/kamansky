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
    work()
    schedule()
    {:ok, state}
  end

  @impl true
  @spec handle_info(:work, any) :: {:noreply, any}
  def handle_info(:work, state) do
    work()
    {:noreply, state}
  end

  @spec schedule :: reference
  defp schedule do
    Process.send_after(self(), :work, 300000)
  end

  defp work do
    Enum.each(
      Ebay.Listing.list_active_listings_with_bids(),
      fn ebay_listing ->
        listing = Platforms.get_ebay_listing(ebay_listing.ebay_id)

        if listing.bid_count == 0 do
          listing
          |> Platforms.update_external_listing(ebay_listing)
          |> case do
            {:ok, _listing} -> Logger.info("Kamansky.Jobs.MonitorListings: new eBay bid received for listing #{listing.id}")
            {:error, _changeset} -> Logger.error("Kamansky.Jobs.MonitorListings: error with eBay bid")
          end

          Hipstamp.Listing.maybe_remove_listing(listing.listing)
        end
    end)
  end
end
