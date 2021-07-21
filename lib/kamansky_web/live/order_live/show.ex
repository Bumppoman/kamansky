defmodule KamanskyWeb.OrderLive.Show do
  use KamanskyWeb, :live_view

  alias Kamansky.Sales.Orders
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  def mount(%{id: id}, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> assign(:order, Orders.get_order_detail(id))

    {:ok, socket}
  end
end
