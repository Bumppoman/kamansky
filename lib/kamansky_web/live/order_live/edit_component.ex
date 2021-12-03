defmodule KamanskyWeb.OrderLive.EditComponent do
  use KamanskyWeb, :live_component
  use KamanskyWeb.Modal

  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec handle_event(String.t, %{required(String.t) => map}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("submit", %{"order" => order_params}, socket) do
    case Orders.update_order(socket.assigns.order, order_params) do
      {:ok, %Order{id: order_id}} ->
        send self(), {:order_updated, order_id}
        noreply(socket)
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"order" => order_params}, socket) do
    socket.assigns.order
    |> Orders.change_new_order(order_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  @impl true
  @spec open_assigns(Phoenix.LiveView.Socket.t, map) :: Phoenix.LiveView.Socket.t
  def open_assigns(socket, %{"order-id" => id}) do
    with order <- Orders.get_order_with_customer!(id),
      changeset <- Orders.change_new_order(order)
    do
      socket
      |> assign(:changeset, changeset)
      |> assign(:customer, order.customer)
      |> assign(:order, order)
    end
  end
end
