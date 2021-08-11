defmodule KamanskyWeb.StampReferenceLive.Index do
  use KamanskyWeb, :live_view

  alias Kamansky.Stamps.StampReferences
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket) do
    {
      :ok,
      socket
      |> assign_defaults(session)
      |> assign([
        data_count: StampReferences.count_stamp_references(),
        data_locator: fn options -> StampReferences.find_row_number_for_stamp_reference(options) end,
        data_source: fn options -> StampReferences.list_stamp_references(options) end
      ])
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add New Stamp Reference")
    |> assign(:stamp_reference, %StampReference{})
  end
end
