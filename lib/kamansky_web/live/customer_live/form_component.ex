defmodule KamanskyWeb.CustomerLive.FormComponent do
  use KamanskyWeb, :live_component
  use KamanskyWeb.Modal

  import Kamansky.Helpers

  alias Kamansky.Sales.Customers
  alias Kamansky.Sales.Customers.Customer

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"customer" => customer_params}, socket) do
    socket.assigns.customer
    |> Customers.change_customer(customer_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  def handle_event("submit", %{"customer" => customer_params}, socket) do
    socket.assigns.customer
    |> Customers.update_customer(customer_params)
    |> case do
      {:ok, %Customer{id: id}} ->
        send self(), {:customer_updated, id}
        noreply(socket)

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  @spec open_assigns(Phoenix.LiveView.Socket.t, map) :: Phoenix.LiveView.Socket.t
  def open_assigns(socket, %{"customer-id" => customer_id}) do
    with customer <- Customers.get_customer!(customer_id),
      changeset <- Customers.change_customer(customer)
    do
      socket
      |> assign(:customer, customer)
      |> assign(:changeset, changeset)
    end
  end
end
