defmodule KamanskyWeb.PurchaseLive.Index do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {0, :asc}

  import Kamansky.Helpers

  alias Kamansky.Operations.Purchases
  alias Kamansky.Operations.Purchases.Purchase

  @impl true
  @spec handle_info({:purchase_added | :purchase_updated, pos_integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:purchase_added, purchase_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully added this purchase.",
      purchase_id
    )
  end

  def handle_info({:purchase_updated, purchase_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully updated this purchase.",
      purchase_id
    )
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Purchases")}

  @impl true
  @spec count_data(:index, String.t | nil) :: integer
  def count_data(_action, search), do: Purchases.count_purchases(search)

  @impl true
  @spec find_item_in_data(:index, pos_integer, integer, Kamansky.Paginate.sort_direction) :: integer
  def find_item_in_data(_action, item_id, sort, direction), do: Purchases.find_row_number_for_purchase(item_id, sort, direction)

  @impl true
  @spec load_data(:index, Kamansky.Paginate.params) :: [Order.t]
  def load_data(_action, params), do: Purchases.list_purchases(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.purchase_index_path(socket, :index, opts)
end
