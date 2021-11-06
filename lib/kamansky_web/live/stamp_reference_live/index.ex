defmodule KamanskyWeb.StampReferenceLive.Index do
  use KamanskyWeb, :live_view

  alias Kamansky.Stamps.StampReferences
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec handle_info({atom, pos_integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:stamp_reference_added, stamp_reference_id}, socket) do
    refresh_data_table(socket, stamp_reference_id, "You have successfully added this stamp reference.")
  end

  def handle_info({:stamp_reference_updated, stamp_reference_id}, socket) do
    refresh_data_table(socket, stamp_reference_id, "You have successfully updated this stamp reference.")
  end

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

  @spec apply_action(Phoenix.LiveView.Socket.t, :index | :missing_from_collection, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :index, params) do
    socket
    |> assign(:go_to_record, Map.get(params, "go_to_record"))
    |> assign(:page_title, "Stamp References")
  end

  defp apply_action(socket, :missing_from_collection, params) do
    socket
    |> assign(:go_to_record, Map.get(params, "go_to_record"))
    |> assign(:page_title, "Stamps Missing From Collection")
    |> assign(:parent_index, nil)
  end

  @spec load_stamps(Phoenix.LiveView.Socket.t) :: Phoenix.LiveView.Socket.t
  defp load_stamps(%Phoenix.LiveView.Socket{assigns: %{live_action: :missing_from_collection}} = socket) do
    socket
    |> assign(:data_count, &StampReferences.count_stamp_references_missing_from_collection/0)
    |> assign(:data_locator, fn options -> StampReferences.find_row_number_for_stamp_reference_missing_from_collection(options) end)
    |> assign(:data_source, fn options -> StampReferences.list_stamp_references_missing_from_collection(options) end)
  end

  defp load_stamps(socket) do
    socket
    |> assign(:data_count, &StampReferences.count_stamp_references/0)
    |> assign(:data_locator, fn options -> StampReferences.find_row_number_for_stamp_reference(options) end)
    |> assign(:data_source, fn options -> StampReferences.list_stamp_references(options) end)
  end

  @spec refresh_data_table(Phoenix.LiveView.Socket.t, pos_integer, String.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp refresh_data_table(socket, id, message) do
    send_update KamanskyWeb.Components.DataTable, id: "stamp_references-kamansky-data-table", options: [go_to_record: id]

    {
      :noreply,
      socket
      |> push_event("kamansky:closeModal", %{})
      |> put_flash(:info, %{message: message, timestamp: Time.utc_now()})
    }
  end
end
