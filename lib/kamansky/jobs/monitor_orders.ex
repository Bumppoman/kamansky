require Logger

defmodule Kamansky.Jobs.MonitorOrders do
  use GenServer

  alias Kamansky.Sales.Orders
  alias Kamansky.Services.{Ebay, Hipstamp}

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state), do: GenServer.start_link(__MODULE__, state, name: __MODULE__)

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
  defp schedule, do: Process.send_after(self(), :work, 300000)

  defp work do
    Enum.each(Ebay.Order.load_new_orders(), &(Orders.maybe_delist_listings(&1)))
    Enum.each(Hipstamp.Order.load_new_orders(), &(Orders.maybe_delist_listings(&1)))
  end
end
