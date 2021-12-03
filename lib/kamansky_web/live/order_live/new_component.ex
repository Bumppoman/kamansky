defmodule KamanskyWeb.OrderLive.NewComponent do
  use KamanskyWeb, :live_component
  use KamanskyWeb.Modal

  alias Kamansky.Sales.{Customers, Orders}
  alias Kamansky.Sales.Customers.Customer
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("search_for_customers", %{"value" => name}, socket) when byte_size(name) == 0 do
    socket
    |> assign(:matching_customers, [])
    |> assign(:searched, false)
    |> noreply()
  end

  def handle_event("search_for_customers", %{"value" => name}, socket) do
    socket
    |> assign(:matching_customers, Customers.search_customers_by_name(name))
    |> assign(:searched, true)
    |> noreply()
  end

  def handle_event("select_customer", %{"customer-id" => customer_id}, socket) do
    with socket <- assign(socket, :customer, %Customer{Customers.get_customer!(customer_id) | existing: true}) do
      socket
      |> assign(:changeset, Customers.change_customer(socket.assigns.customer))
      |> assign(:matching_customers, [])
      |> assign(:searched, false)
      |> noreply()
    end
  end

  def handle_event("submit_customer", %{"customer" => customer_params}, socket) do
    with {:ok, customer} <- Customers.insert_or_update_customer(socket.assigns.customer, customer_params),
      _map <- send(self(), {:update_new_order_step, %{step: 2, customer: customer}}),
      order <- %Order{customer: customer}
    do
      socket
      |> assign(:button_text, "Create Order")
      |> assign(:customer, customer)
      |> assign(:changeset, Orders.change_new_order(order))
      |> assign(:order, order)
      |> assign(:order_step, 2)
      |> assign(:submit, "submit_order")
      |> assign(:validate, "validate_order")
      |> noreply()
    end
  end

  def handle_event("submit_order", %{"order" => order_params}, socket) do
    order_params
    |> Map.put("customer_id", socket.assigns.customer.id)
    |> Orders.create_order()
    |> case do
      {:ok, %{id: order_id}} ->
        send self(), {:order_added, order_id}
        noreply(socket)
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate_customer", %{"customer" => customer_params}, socket) do
    socket.assigns.customer
    |> Customers.change_customer(customer_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  def handle_event("validate_order", %{"order" => order_params}, socket) do
    socket.assigns.order
    |> Orders.change_new_order(order_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  @impl true
  @spec open_assigns(Phoenix.LiveView.Socket.t, map) :: Phoenix.LiveView.Socket.t
  def open_assigns(socket, _params) do
    with socket <- assign(socket, :customer, %Customer{}) do
      socket
      |> assign(:button_text, "Next")
      |> assign(:changeset, Customers.change_customer(socket.assigns.customer))
      |> assign(:matching_customers, [])
      |> assign(:order_step, 1)
      |> assign(:searched, false)
      |> assign(:submit, "submit_customer")
      |> assign(:validate, "validate_customer")
    end
  end

  @spec existing_customer(Ecto.Changeset.t) :: boolean
  defp existing_customer(changeset), do: Ecto.Changeset.get_field(changeset, :existing)
end
