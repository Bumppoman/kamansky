defmodule KamanskyWeb.TrendLive.Sold do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Stamps.StampReferences

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket) do
    {
      :noreply,
      socket
      |> assign(:page_title, "Stamps Sold by Scott Number")
      |> assign(:data_count, &StampReferences.count_stamp_references_with_sales/0)
      |> assign(:data_locator, fn options -> StampReferences.find_row_number_for_stamp_reference_with_sales(options) end)
      |> assign(:data_source, fn options -> StampReferences.list_stamp_references_with_sales(options) end)
    }
  end
end
