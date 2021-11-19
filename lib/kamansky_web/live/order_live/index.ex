defmodule KamanskyWeb.OrderLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.{Ebay, Hipstamp}

  @data_table "orders-kamansky-data-table"

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("load_new_orders", _value, socket) do
    with _orders <- Hipstamp.Order.load_new_orders(),
      _orders <- Ebay.Order.load_new_orders(),
      {:phoenix, :send_update, _update} <- refresh_datatable(@data_table)
    do
      {:noreply, socket}
    end
  end

  def handle_event("mark_all_processed_shipped", _value, socket) do
    with orders <- Orders.list_orders(status: :processed),
      :ok <- Enum.each(orders, &Kamansky.Services.Order.mark_order_shipped/1)
    do
      close_modal_with_success_and_refresh_datatable(
        socket,
        @data_table,
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
      {:ok, _order} -> advance_order(socket, "completed")
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
    close_modal_with_success_and_refresh_datatable(
      socket,
      @data_table,
      "kamansky:closeModal",
      "You have successfully added this order.",
      order_id
    )
  end

  def handle_info({:order_updated, order_id}, socket) do
    close_modal_with_success_and_refresh_datatable(
      socket,
      @data_table,
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
  def handle_params(params, _uri, socket) do
    {
      :noreply,
      socket
      |> assign(:data_count, fn -> Orders.count_orders(status: socket.assigns.live_action) end)
      |> assign(:data_locator, fn options -> Orders.find_row_number_for_order(socket.assigns.live_action, options) end)
      |> assign(:data_source, fn options -> Orders.list_orders(:display, socket.assigns.live_action, options) end)
      |> assign(:go_to_record, Map.get(params, "go_to_record"))
      |> assign(:page_title, String.capitalize(Atom.to_string(socket.assigns.live_action)) <> " Orders")
    }
  end

  @spec advance_order(Phoenix.LiveView.Socket.t, String.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def advance_order(socket, action) do
    close_modal_with_success_and_refresh_datatable(
      socket,
      @data_table,
      "kamansky:closeConfirmationModal",
      "You have successfully marked this order as #{action}."
    )
  end
end
