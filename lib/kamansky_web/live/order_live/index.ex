defmodule KamanskyWeb.OrderLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order

  @impl true
  def mount(params, session, socket) do
    socket =
      socket
      |> assign_defaults(session)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def marking_action(:mark_processed), do: "processed"

  defp apply_action(socket, :mark_processed, %{"id" => id}) do
    with order <- Orders.get_order!(id) do
      socket
      |> assign(:page_title, "Mark Order as Processed")
      |> assign(:order, order)
      |> assign(:marking_action, "processed")
      |> load_orders(order.status)
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create Order")
    |> assign(:order, %Order{})
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

  defp load_orders(%{assigns: %{live_action: live_action}} = socket, _params) when live_action == :new, do: load_orders(socket, :pending)
  defp load_orders(socket, %{"status" => status}), do: load_orders(socket, String.to_existing_atom(status))
  defp load_orders(socket, %{}), do: load_orders(socket, socket.assigns.live_action)
  defp load_orders(socket, status) when status in [:pending, :finalized, :processed, :shipped, :completed] do
    socket
    |> assign(
      [
        data_count: Orders.count_orders(status),
        data_locator: fn options -> Orders.find_row_number_for_order(status, options) end,
        data_source: fn options -> Orders.list_orders(status, options) end
      ]
    )
  end
end
