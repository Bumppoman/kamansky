require Logger

defmodule Kamansky.Jobs.MonitorListings do
  use GenServer

  alias Kamansky.Sales.Listings
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
        listing = Listings.get_listing_by_ebay_id(ebay_listing.item_id)

        if listing.status != :bid do
          listing
          |> Listings.mark_listing_bid()
          |> case do
            {:ok, _listing} -> Logger.info("Kamansky.Jobs.MonitorListings: new eBay bid received for listing #{listing.id}")
            {:error, _changeset} -> Logger.error("Kamansky.Jobs.MonitorListings: error with eBay bid")
          end

          listing
          |> Hipstamp.Listing.maybe_remove_listing()
          |> case do
            {:ok, listing} -> Logger.info("Kamansky.Jobs.MonitorListings: removed Hipstamp listing for listing #{listing.id}")
            :ok -> :ok
          end
        end
    end)
  end
end
