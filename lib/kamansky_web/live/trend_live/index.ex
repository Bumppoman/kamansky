defmodule KamanskyWeb.TrendLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Stamps.StampReferences

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {
      :noreply,
      socket
      |> apply_action(socket.assigns.live_action, params)
      |> load_stamps()
    }
  end

  defp apply_action(socket, :sold, params), do: assign(socket, :page_title, "Stamps Sold by Scott Number")

  defp load_stamps(socket) do
    socket
    |> assign(:data_count, StampReferences.count_stamp_references_with_sales())
    |> assign(:data_locator, fn options -> StampReferences.find_row_number_for_stamp_reference_sale(options) end)
    |> assign(:data_source, fn options -> StampReferences.list_stamp_references_with_sales(options) end)
  end
end
