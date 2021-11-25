defmodule KamanskyWeb.OrderLive.Index do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {0, :desc}

  import Kamansky.Helpers

  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.{Ebay, Hipstamp}

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("load_new_orders", _value, socket) do
    with _orders <- Hipstamp.Order.load_new_orders(),
      _orders <- Ebay.Order.load_new_orders()
    do
      {:noreply, push_patch(socket, to: self_path(socket, :pending, %{}))}
    end
  end

  def handle_event("mark_all_processed_shipped", _value, socket) do
    with orders <- Orders.list_orders(status: :processed),
      :ok <- Enum.each(orders, &Kamansky.Services.Order.mark_order_shipped/1)
    do
      close_modal_with_success_and_reload_data(
        socket,
        "kamansky:closeConfirmationModal",
        "You have successfully marked these orders as shipped."
      )
    end
  end

  def handle_event("mark_completed", %{"order-id" => order_id}, socket) do
    order_id
    |> Orders.get_order!()
    |> Orders.mark_order_as_completed()
    |> case do
      {:ok, _order} -> advance_order(socket, "completed")
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("mark_processed", %{"order-id" => order_id}, socket) do
    order_id
    |> Orders.get_order!()
    |> Orders.mark_order_as_processed()
    |> case do
      {:ok, _order} -> advance_order(socket, "processed")
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("mark_shipped", %{"order-id" => order_id}, socket) do
    with order <- Orders.get_order!(order_id),
      {:ok, _order} <- Kamansky.Services.Order.mark_order_shipped(order)
    do
      advance_order(socket, "shipped")
    end
  end

  @impl true
  @spec handle_info({atom, any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:order_added, order_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully added this order.",
      order_id
    )
  end

  def handle_info({:order_updated, order_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully updated this order.",
      order_id
    )
  end

  def handle_info({:update_new_order_step, %{step: 2, customer: customer}}, socket) do
    {
      :noreply,
      socket
      |> assign(:button_text, "Create Order")
      |> assign(:customer, customer)
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, String.capitalize(Atom.to_string(socket.assigns.live_action)) <> " Orders")}

  @spec advance_order(Phoenix.LiveView.Socket.t, String.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def advance_order(socket, action) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeConfirmationModal",
      "You have successfully marked this order as #{action}."
    )
  end

  @impl true
  @spec count_data(:completed | :pending | :processed | :shipped, String.t | nil) :: integer
  def count_data(status, search), do: Orders.count_orders(status, search)

  @impl true
  @spec find_item_in_data(:completed | :pending | :processed | :shipped, pos_integer, integer, Kamansky.Paginate.sort_direction) :: integer
  def find_item_in_data(status, item_id, sort, direction), do: Orders.find_row_number_for_order(status, item_id, sort, direction)

  @impl true
  @spec load_data(:completed | :pending | :processed | :shipped, Kamansky.Paginate.params) :: [Order.t]
  def load_data(status, params), do: Orders.list_orders(:display, status, params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :completed | :pending | :processed | :shipped, map) :: String.t
  def self_path(socket, action, opts), do: Routes.order_index_path(socket, action, opts)
end
