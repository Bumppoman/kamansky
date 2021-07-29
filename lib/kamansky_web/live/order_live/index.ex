defmodule KamanskyWeb.OrderLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Customers.Customer
  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Hipstamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket), do: {:ok, assign_defaults(socket, session)}

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("mark_completed", _value, socket) do
    with order <- socket.assigns.order do
      case Orders.mark_order_as_completed(order) do
        {:ok, _order} ->
          {:noreply,
          socket
          |> put_flash(:info, "You have successfully marked this order as completed.")
          |> push_redirect(to: Routes.order_index_path(socket, order.status))
        }

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

  def handle_event("mark_processed", _value, socket) do
    with order <- socket.assigns.order do
      case Orders.mark_order_as_processed(order) do
        {:ok, _order} ->
          {
            :noreply,
            socket
            |> put_flash(:info, "You have successfully marked this order as processed.")
            |> push_redirect(to: Routes.order_index_path(socket, order.status))
        }

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

  def handle_event("mark_shipped", _value, socket) do
    with order <- socket.assigns.order do
      case order do
        o when not is_nil(o.hipstamp_id) -> Hipstamp.Order.mark_shipped(order)
        _ -> Orders.mark_order_as_shipped(order)
      end

      {
        :noreply,
        socket
        |> put_flash(:info, "You have successfully marked this order as shipped.")
        |> push_redirect(to: Routes.order_index_path(socket, order.status))
      }
    end
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, atom, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :edit, %{"id" => id}) do
    with order <- Orders.get_order_with_customer!(id) do
      socket
      |> assign(:page_title, "Update Order")
      |> assign(:order, order)
      |> load_orders(order.status)
    end
  end

  defp apply_action(socket, :mark_completed, %{"id" => id}) do
    with order <- Orders.get_order!(id) do
      socket
      |> assign(:page_title, "Mark Order as Completed")
      |> assign(:order, order)
      |> assign(:marking_action, "completed")
      |> load_orders(order.status)
    end
  end

  defp apply_action(socket, :mark_processed, %{"id" => id}) do
    with order <- Orders.get_order!(id) do
      socket
      |> assign(:page_title, "Mark Order as Processed")
      |> assign(:order, order)
      |> assign(:marking_action, "processed")
      |> load_orders(order.status)
    end
  end

  defp apply_action(socket, :mark_shipped, %{"id" => id}) do
    with order <- Orders.get_order!(id) do
      socket
      |> assign(:page_title, "Mark Order as Shipped")
      |> assign(:order, order)
      |> assign(:marking_action, "shipped")
      |> load_orders(order.status)
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create Order")
    |> assign(:order, %Order{customer: %Customer{}})
    |> load_orders(:pending)
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  defp apply_action(socket, action, _params) do
    socket
    |> assign(:page_title, String.capitalize(Atom.to_string(action)) <> " Orders")
    |> load_orders(action)
  end

  @spec load_orders(Phoenix.LiveView.Socket.t, map | atom) :: Phoenix.LiveView.Socket.t
  defp load_orders(socket, %{"status" => status}), do: load_orders(socket, String.to_existing_atom(status))
  defp load_orders(socket, %{}), do: load_orders(socket, socket.assigns.live_action)
  defp load_orders(socket, status) when status in [:pending, :finalized, :processed, :shipped, :completed] do
    socket
    |> assign(
      [
        data_count: Orders.count_orders(status: status),
        data_locator: fn options -> Orders.find_row_number_for_order(status, options) end,
        data_source: fn options -> Orders.list_orders(:display, status, options) end
      ]
    )
  end
end
