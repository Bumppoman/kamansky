defmodule KamanskyWeb.TrendLive.Sold do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {1, :asc}

  import Kamansky.Helpers

  alias Kamansky.Stamps.StampReferences

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Stamps Sold by Scott Number")}

  @impl true
  @spec count_data(:index, String.t | nil) :: integer
  def count_data(_action, search), do: StampReferences.count_stamp_references_with_sales(search)

  @impl true
  @spec load_data(:index, Kamansky.Paginate.params) :: [Order.t]
  def load_data(_action, params), do: StampReferences.list_stamp_references_with_sales(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.trend_sold_path(socket, :index, opts)
end
