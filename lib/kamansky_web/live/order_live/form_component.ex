defmodule KamanskyWeb.OrderLive.FormComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Sales.{Customers, Orders}
  alias Kamansky.Sales.Orders.Order

  @impl true
  def update(%{customer: customer, order: order} = assigns, socket) do
    with order_changeset <- Orders.change_order(order),
      customer_changeset <- Customers.change_customer(customer),
      socket <-
        socket
        |> assign(assigns)
        |> assign(:customer_changeset, customer_changeset)
        |> assign(:order_changeset, order_changeset)
    do
      {:ok, socket}
    end
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
