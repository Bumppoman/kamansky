defmodule KamanskyWeb.PurchaseLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Operations.Purchases
  alias Kamansky.Operations.Purchases.Purchase

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket) do
    {
      :ok,
      socket
      |> assign_defaults(session)
      |> assign([
        data_count: Purchases.count_purchases(),
        data_locator: fn options -> Purchases.find_row_number_for_purchase(options) end,
        data_source: fn options -> Purchases.list_purchases(options) end
      ])
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, atom, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:purchase, Purchases.get_purchase!(id))
    |> assign(:page_title, "Add New Purchase")
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Purchases")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:purchase, %Purchase{})
    |> assign(:page_title, "Add New Purchase")
  end
end
