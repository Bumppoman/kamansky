defmodule KamanskyWeb.CustomerLive.FormComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Sales.Customers
  alias Kamansky.Sales.Customers.Customer

  @impl true
  @spec update(%{required(:customer) => Customer.t, optional(any) => any}, Phoenix.LiveView.Socket.t)
    :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{trigger_params: %{"customer-id" => customer_id}} = assigns, socket) do
    with customer <- Customers.get_customer!(customer_id),
    changeset <- Customers.change_customer(customer),
      socket <-
        socket
        |> assign(assigns)
        |> assign(:customer, customer)
        |> assign(:changeset, changeset)
    do
      {:ok, socket}
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"customer" => customer_params}, socket) do
    changeset =
      socket.assigns.customer
      |> Customers.change_customer(customer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("submit", %{"customer" => customer_params}, socket) do
    save_customer(socket, customer_params)
  end

  @spec save_customer(Phoenix.LiveView.Socket.t, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_customer(socket, customer_params) do
    case Customers.update_customer(socket.assigns.customer, customer_params) do
      {:ok, %Customer{id: id}} ->
        send self(), {:customer_updated, id}
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
