defmodule KamanskyWeb.OrderLive.Show do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec mount(%{required(String.t) => String.t}, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(%{"id" => id}, session, socket) do
    {
      :ok,
      socket
      |> assign_defaults(session)
      |> assign(:order, Orders.get_order_detail(id))
    }
  end
end
