require Logger

defmodule Kamansky.Jobs.MonitorOrders do
  use GenServer

  import Kamansky.Sales.Orders.Order, only: [is_ebay: 1, is_hipstamp: 1]

  alias Kamansky.Operations.Notifications
  alias Kamansky.Operations.Notifications.Notification
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.{Ebay, Hipstamp}

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state), do: GenServer.start_link(__MODULE__, state, name: __MODULE__)

  @impl true
  @spec init(any) :: {:ok, any}
  def init(state) do
    schedule()

    {:ok, state}
  end

  @impl true
  @spec handle_info(:work, any) :: {:noreply, any}
  def handle_info(:work, state) do
    work()
    schedule()

    {:noreply, state}
  end

  @spec log_delisting_action({:ebay_removed | :hipstamp_removed | :noop, Listing.t}) :: :ok
  defp log_delisting_action({:ebay_removed, %Listing{id: listing_id, order_id: order_id}}) do
    Logger.info("Kamansky.Jobs.MonitorOrders: delisted eBay listing for listing #{listing_id} (order #{order_id})")
  end

  defp log_delisting_action({:hipstamp_removed, %Listing{id: listing_id, order_id: order_id}}) do
    Logger.info("Kamansky.Jobs.MonitorOrders: delisted Hipstamp listing for listing #{listing_id} (order #{order_id})")
  end

  defp log_delisting_action({:noop, %Listing{id: listing_id, order_id: order_id}}) do
    Logger.info("Kamansky.Jobs.MonitorOrders: no listings to delist for listing #{listing_id} (order #{order_id})")
  end

  @spec process_order(Order.t) :: :ok
  defp process_order(%Order{} = order) do
    with {:ok, notification} <- Notifications.send_notification(notification_topic(order), order.id) do
      Logger.info("Kamansky.Jobs.MonitorOrders: " <> Notification.body(notification, order))

      order
      |> Kamansky.Services.Order.maybe_delist_competing_listings()
      |> Enum.each(&log_delisting_action/1)
    end
  end

  @spec notification_topic(Order.t) :: atom
  defp notification_topic(%Order{} = order) when is_ebay(order), do: :ebay_new_order
  defp notification_topic(%Order{} = order) when is_hipstamp(order), do: :hipstamp_new_order

  @spec schedule :: reference
  defp schedule, do: Process.send_after(self(), :work, 120000)

  @spec work :: :ok
  defp work do
    case Ebay.Order.load_new_orders() ++ Hipstamp.Order.load_new_orders() do
      [] -> Logger.info("Kamansky.Jobs.MonitorOrders:  no new eBay or Hipstamp orders to load")
      orders -> Enum.each(orders, &process_order/1)
    end
  end
end
