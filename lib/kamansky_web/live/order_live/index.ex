defmodule KamanskyWeb.OrderLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Hipstamp

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("load_new_orders", _value, socket) do
    with :ok <- Hipstamp.Order.load_new_orders() do
      send_update KamanskyWeb.Components.DataTable, id: "orders-kamansky-data-table", options: []
      {:noreply, socket}
    end
  end

  def handle_event("mark_completed", %{"order-id" => order_id}, socket) do
    order_id
    |> Orders.get_order!()
    |> Orders.mark_order_as_completed()
    |> case do
      {:ok, _order} -> order_successfully_advanced(socket, "You have successfully marked this order as completed.")
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("mark_processed", %{"order-id" => order_id}, socket) do
    order_id
    |> Orders.get_order!()
    |> Orders.mark_order_as_processed()
    |> case do
      {:ok, _order} -> order_successfully_advanced(socket, "You have successfully marked this order as processsed.")
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("mark_shipped", %{"order-id" => order_id}, socket) do
    with(
      order <- Orders.get_order!(order_id),
      {:ok, _order} <-
        case order do
          o when not is_nil(o.hipstamp_id) -> Hipstamp.Order.mark_shipped(order)
          _ -> Orders.mark_order_as_shipped(order)
        end
    ) do
      order_successfully_advanced(socket, "You have successfully marked this order as shipped.")
    end
  end

  @impl true
  @spec handle_info({atom, any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:order_added, order_id}, socket), do: update_datatable(socket, "You have successfully added this order.", order_id)
  def handle_info({:order_updated, order_id}, socket), do: update_datatable(socket, "You have successfully updated this order.", order_id)
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

  @spec order_successfully_advanced(Phoenix.LiveView.Socket.t, String.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp order_successfully_advanced(socket, message) do
    send_update KamanskyWeb.Components.DataTable, id: "orders-kamansky-data-table", options: [go_to_record: nil]

    {
      :noreply,
      socket
      |> push_event("kamansky:closeConfirmationModal", %{})
      |> put_flash(:info, %{message: message, timestamp: Time.utc_now()})
    }
  end

  @spec update_datatable(Phoenix.LiveView.Socket.t, String.t, pos_integer) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp update_datatable(socket, message, order_id) do
    send_update KamanskyWeb.Components.DataTable, id: "orders-kamansky-data-table", options: [go_to_record: order_id]

    {
      :noreply,
      socket
      |> push_event("kamansky:closeModal", %{})
      |> put_flash(:info, %{message: message, timestamp: Time.utc_now()})
    }
  end
end
