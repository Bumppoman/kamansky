defmodule KamanskyWeb.StampReferenceLive.Index do
  use KamanskyWeb, :live_view

  alias Kamansky.Stamps.StampReferences
  alias Kamansky.Stamps.StampReferences.StampReference

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

  @spec apply_action(Phoenix.LiveView.Socket.t, :edit | :index | :new, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Stamp Reference")
    |> assign(:stamp_reference, StampReferences.get_stamp_reference!(id))
  end

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

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add New Stamp Reference")
    |> assign(:stamp_reference, %StampReference{})
  end

  @spec load_stamps(Phoenix.LiveView.Socket.t) :: Phoenix.LiveView.Socket.t
  defp load_stamps(%Phoenix.LiveView.Socket{assigns: %{live_action: :missing_from_collection}} = socket) do
    socket
    |> assign(:data_count, StampReferences.count_stamp_references_missing_from_collection())
    |> assign(
      :data_locator,
      fn options -> StampReferences.find_row_number_for_stamp_reference_missing_from_collection(options) end
    )
    |> assign(:data_source, fn options -> StampReferences.list_stamp_references_missing_from_collection(options) end)
  end

  defp load_stamps(socket) do
    socket
    |> assign(:data_count, StampReferences.count_stamp_references())
    |> assign(:data_locator, fn options -> StampReferences.find_row_number_for_stamp_reference(options) end)
    |> assign(:data_source, fn options -> StampReferences.list_stamp_references(options) end)
  end
end
