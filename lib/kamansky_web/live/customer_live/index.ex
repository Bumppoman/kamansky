defmodule KamanskyWeb.CustomerLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.Customers
  alias Kamansky.Sales.Customers.Customer

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:data_count, &Customers.count_customers/0)
      |> assign(:data_locator, fn options -> Customers.find_row_number_for_customer(options) end)
      |> assign(:data_source, fn options -> Customers.list_customers(options) end)
    }
  end

  @impl true
  @spec handle_info({:customer_updated, integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:customer_updated, customer_id}, socket) do
    close_modal_with_success_and_refresh_datatable(
      socket,
      "customers-kamansky-data-table",
      "kamansky:closeModal",
      "You have successfully updated this customer.",
      customer_id
    )
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {
      :noreply,
      socket
      |> assign(:go_to_record, Map.get(params, "go_to_record"))
      |> assign(:page_title, "Customer List")
    }
  end
end
