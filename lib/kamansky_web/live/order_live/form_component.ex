defmodule KamanskyWeb.OrderLive.FormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order

  @impl true
  def update(%{order: order} = assigns, socket) do
    changeset = Orders.change_order(order)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"order" => order_params}, socket) do
    changeset =
      socket.assigns.order
      |> Orders.change_order(order_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("submit", %{"order" => order_params}, socket) do
    save_order(socket, socket.assigns.action, order_params)
  end

  defp save_order(socket, :new, order_params) do
    case Orders.create_order(order_params) do
      {:ok, %{id: id}} ->
        {:noreply,
        socket
        |> put_flash(:info, "You have successfully created this order.")
        |> push_redirect(to: Routes.order_index_path(socket, :pending, go_to_record: id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
