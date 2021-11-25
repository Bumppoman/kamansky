defmodule KamanskyWeb.CustomerLive.Show do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {1, :desc}

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1, formatted_date: 1]

  alias Kamansky.Sales.{Customers, Orders}
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(%{"id" => customer_id}, _session, socket) do
    with customer <- Customers.get_customer_detail(customer_id) do
      socket
      |> assign(:customer, customer)
      |> assign(:page_title, "Information for #{customer.name}")
      |> ok()
    end
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: noreply(socket)

  @impl true
  @spec count_data(Phoenix.LiveView.Socket.t, String.t | nil) :: integer
  def count_data(socket, search), do: Orders.count_orders_for_customer(socket.assigns.customer.id, search)

  @impl true
  @spec load_data(Phoenix.LiveView.Socket.t, Kamansky.Paginate.params) :: [Order.t]
  def load_data(socket, params), do: Orders.list_orders_for_customer(socket.assigns.customer.id, params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :show, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.customer_show_path(socket, :show, Map.put(opts, :id, socket.assigns.customer.id))
end
