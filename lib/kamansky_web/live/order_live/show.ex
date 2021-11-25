defmodule KamanskyWeb.OrderLive.Show do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec mount(%{required(String.t) => String.t}, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(%{"id" => id}, _session, socket) do
    with order <- Orders.get_order_detail(id) do
      socket
      |> assign(:order, order)
      |> assign(:page_title, "Order ##{Order.order_number(order)}")
      |> ok()
    end
  end

  @spec order_status_width(Order.t) :: String.t
  defp order_status_width(%Order{status: :pending}), do: "w-[2.5%]"
  defp order_status_width(%Order{status: :processed}), do: "w-[37.5%]"
  defp order_status_width(%Order{status: :shipped}), do: "w-[62.5%]"
  defp order_status_width(%Order{status: :completed}), do: "w-full"
end
