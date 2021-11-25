defmodule KamanskyWeb.StampReferenceLive.Index do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {0, :asc}

  alias Kamansky.Stamps.StampReferences
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec handle_info({atom, pos_integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:stamp_reference_added, stamp_reference_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully added this stamp reference.",
      stamp_reference_id
    )
  end

  def handle_info({:stamp_reference_updated, stamp_reference_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully updated this stamp reference.",
      stamp_reference_id
    )
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, apply_action(socket, socket.assigns.live_action)}

  @spec apply_action(Phoenix.LiveView.Socket.t, :index | :missing_from_collection) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :index), do: assign(socket, :page_title, "Stamp References")
  defp apply_action(socket, :missing_from_collection) do
    socket
    |> assign(:page_title, "Stamps Missing From Collection")
    |> assign(:parent_index, nil)
  end

  @impl true
  @spec count_data(:index | :missing_from_collection, String.t | nil) :: integer
  def count_data(:index, search), do: StampReferences.count_stamp_references(search)
  def count_data(:missing_from_collection, search), do: StampReferences.count_stamp_references_missing_from_collection(search)

  @impl true
  @spec find_item_in_data(:index, pos_integer, integer, Kamansky.Paginate.sort_direction) :: integer
  def find_item_in_data(:index, item_id, sort, direction), do: StampReferences.find_row_number_for_stamp_reference(item_id, sort, direction)

  @impl true
  @spec load_data(:index | :missing_from_collection, Kamansky.Paginate.params) :: [Stamp.t]
  def load_data(:index, params), do: StampReferences.list_stamp_references(params)
  def load_data(:missing_from_collection, params), do: StampReferences.list_stamp_references_missing_from_collection(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index | :missing_from_collection, map) :: String.t
  def self_path(socket, action, opts), do: Routes.stamp_reference_index_path(socket, action, opts)
end
