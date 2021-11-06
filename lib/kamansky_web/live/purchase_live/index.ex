defmodule KamanskyWeb.PurchaseLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Operations.Purchases
  alias Kamansky.Operations.Purchases.Purchase

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:data_count, &Purchases.count_purchases/0)
      |> assign(:data_locator, fn options -> Purchases.find_row_number_for_purchase(options) end)
      |> assign(:data_source, fn options -> Purchases.list_purchases(options) end)
    }
  end

  @impl true
  @spec handle_info({:purchase_added | :purchase_updated, pos_integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:purchase_added, purchase_id}, socket), do: update_datatable(socket, "You have successfully added this purchase.", purchase_id)
  def handle_info({:purchase_updated, purchase_id}, socket), do: update_datatable(socket, "You have successfully updated this purchase.", purchase_id)

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Purchases")}

  @spec update_datatable(Phoenix.LiveView.Socket.t, String.t, pos_integer) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp update_datatable(socket, message, purchase_id) do
    send_update KamanskyWeb.Components.DataTable, id: "purchases-kamansky-data-table", options: [go_to_record: purchase_id]

    {
      :noreply,
      socket
      |> push_event("kamansky:closeModal", %{})
      |> put_flash(:info, %{message: message, timestamp: Time.utc_now()})
    }
  end
end
