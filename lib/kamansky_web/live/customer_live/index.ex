defmodule KamanskyWeb.CustomerLive.Index do
  use KamanskyWeb, :live_view

  alias Kamansky.Sales.Customers
  alias Kamansky.Sales.Customers.Customer

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> assign([
        data_count: Customers.count_customers(),
        data_locator: fn options -> Customers.find_row_number_for_customer(options) end,
        data_source: fn options -> Customers.list_customers(options) end
      ])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Customer")
    |> assign(:customer, Customers.get_customer!(id))
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:go_to_record, Map.get(params, "go_to_record"))
    |> assign(page_title: "Customer List")
  end
end
