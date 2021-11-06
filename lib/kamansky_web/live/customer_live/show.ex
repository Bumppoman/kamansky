defmodule KamanskyWeb.CustomerLive.Show do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1, formatted_date: 1]

  alias Kamansky.Sales.{Customers, Orders}
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec mount(%{required(String.t) => String.t}, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(%{"id" => id}, _session, socket) do
    with customer <- Customers.get_customer_detail(id) do
      {
        :ok,
        socket
        |> assign(:customer, customer)
        |> assign(:order_count, fn -> Orders.count_orders_for_customer(customer.id) end)
        |> assign(:order_source, fn options -> Orders.list_orders_for_customer(customer.id, options) end)
        |> assign(:page_title, "Information for #{customer.name}")
      }
    end
  end
end
