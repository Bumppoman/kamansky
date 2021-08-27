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
      |> assign(:data_count, Customers.count_customers())
      |> assign(:data_locator, fn options -> Customers.find_row_number_for_customer(options) end)
      |> assign(:data_source, fn options -> Customers.list_customers(options) end)
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, :edit | :index, %{required(String.t) => any}) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Customer")
    |> assign(:customer, Customers.get_customer!(id))
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:go_to_record, Map.get(params, "go_to_record"))
    |> assign(:page_title, "Customer List")
  end
end
