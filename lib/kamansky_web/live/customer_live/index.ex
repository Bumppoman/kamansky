defmodule KamanskyWeb.CustomerLive.Index do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {0, :asc}

  import Kamansky.Helpers

  alias Kamansky.Sales.Customers
  alias Kamansky.Sales.Customers.Customer

  @impl true
  @spec handle_info({:customer_updated, integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:customer_updated, customer_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully updated this customer.",
      customer_id
    )
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Customer List")}

  @impl true
  @spec count_data(Phoenix.LiveView.Socket.t, String.t | nil) :: integer
  def count_data(_socket, search), do: Customers.count_customers(search)

  @impl true
  @spec find_item_in_data(Phoenix.LiveView.Socket.t, pos_integer, integer, Kamansky.Paginate.sort_direction) :: integer
  def find_item_in_data(_socket, customer_id, sort, direction), do: Customers.find_row_number_for_customer(customer_id, sort, direction)

  @impl true
  @spec load_data(Phoenix.LiveView.Socket.t, Kamansky.Paginate.params) :: [Customer.t]
  def load_data(_socket, params), do: Customers.list_customers(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.customer_index_path(socket, :index, opts)
end
