defmodule KamanskyWeb.OrderLive.NewComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Sales.{Customers, Orders}
  alias Kamansky.Sales.Customers.Customer
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec update(map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(assigns, socket) do
    with socket <- assign_new(socket, :customer, fn -> %Customer{} end) do
      {
        :ok,
        socket
        |> assign(assigns)
        |> assign(:matching_customers, [])
        |> assign(:searched, false)
        |> assign_new(:button_text, fn -> "Next" end)
        |> assign_new(:changeset, fn -> Customers.change_customer(socket.assigns.customer) end)
        |> assign_new(:order_step, fn -> 1 end)
        |> assign_new(:submit, fn -> "submit_customer" end)
        |> assign_new(:validate, fn -> "validate_customer" end)
      }
    end
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("search_for_customers", %{"value" => name}, socket) when byte_size(name) == 0 do
    {
      :noreply,
      socket
      |> assign(:matching_customers, [])
      |> assign(:searched, false)
    }
  end

  def handle_event("search_for_customers", %{"value" => name}, socket) do
    {
      :noreply,
      socket
      |> assign(:matching_customers, Customers.search_customers_by_name(name))
      |> assign(:searched, true)
    }
  end

  def handle_event("select_customer", %{"customer-id" => customer_id}, socket) do
    with socket <-
      assign(socket, :customer, %Customer{Customers.get_customer!(customer_id) | existing: true}) do
      {
        :noreply,
        socket
        |> assign(:changeset, Customers.change_customer(socket.assigns.customer))
        |> assign(:matching_customers, [])
        |> assign(:searched, false)
      }
    end
  end

  def handle_event("submit_customer", %{"customer" => customer_params}, socket) do
    with {:ok, customer} <- Customers.insert_or_update_customer(socket.assigns.customer, customer_params),
      _map <- send(self(), {:update_new_order_step, %{step: 2, customer: customer}}),
      order <- %Order{customer: customer}
    do
      {
        :noreply,
        socket
        |> assign(:button_text, "Create Order")
        |> assign(:changeset, Orders.change_new_order(order))
        |> assign(:order, order)
        |> assign(:order_step, 2)
        |> assign(:submit, "submit_order")
        |> assign(:validate, "validate_order")
      }
    end
  end

  def handle_event("submit_order", %{"order" => order_params}, socket) do
    order_params
    |> Map.put("customer_id", socket.assigns.customer.id)
    |> Orders.create_order()
    |> case do
      {:ok, %{id: order_id}} -> send self(), {:order_added, order_id}
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate_customer", %{"customer" => customer_params}, socket) do
    with(
      changeset <-
        socket.assigns.customer
        |> Customers.change_customer(customer_params)
        |> Map.put(:action, :validate)
    ) do
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate_order", %{"order" => order_params}, socket) do
    with(
      changeset <-
        socket.assigns.order
        |> Orders.change_new_order(order_params)
        |> Map.put(:action, :validate)
    ) do
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @spec existing_customer(Ecto.Changeset.t) :: boolean
  def existing_customer(changeset), do: Ecto.Changeset.get_field(changeset, :existing)
end
