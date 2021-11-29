require Logger

defmodule Kamansky.Jobs.MonitorOrders do
  use GenServer

  alias Kamansky.Operations.Notifications
  alias Kamansky.Operations.Notifications.Notification
  alias Kamansky.Sales.Orders
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

  @spec notification_topic(Order.t) :: atom
  defp notification_topic(%Order{ebay_id: ebay_id}) when not is_nil(ebay_id), do: :ebay_new_order
  defp notification_topic(%Order{hipstamp_id: hipstamp_id}) when not is_nil(hipstamp_id), do: :hipstamp_new_order

  @spec schedule :: reference
  defp schedule, do: Process.send_after(self(), :work, 120000)

  @spec work :: :ok
  defp work do
    case Ebay.Order.load_new_orders() ++ Hipstamp.Order.load_new_orders() do
      [] -> Logger.info("Kamansky.Jobs.MonitorOrders:  no new eBay or Hipstamp orders to load")
      orders ->
        Enum.each(
          orders,
          fn order ->
            Orders.maybe_delist_listings(order)
            {:ok, notification} =
              Notifications.send_notification(
                notification_topic(order),
                order.id
              )
            Logger.info("Kamansky.Jobs.MonitorOrders: " <> Notification.body(notification, order))
          end
        )
    end
  end
end
