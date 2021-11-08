defmodule KamanskyWeb.StampLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec handle_event(String.t, any, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("move_to_stock", %{"stamp-id" => stamp_id}, socket) do
    case Stamps.move_stamp_to_stock(stamp_id) do
      {:ok, _stamp} ->
        send_update KamanskyWeb.Components.DataTable, id: "stamps-kamansky-data-table", options: []

        {
          :noreply,
          socket
          |> push_event("kamansky:closeConfirmationModal", %{})
          |> put_flash(:info, %{message: "You have successfully moved this stamp to stock.", timestamp: Time.utc_now()})
        }

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  @spec handle_info({atom, integer | Stamp.t}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:stamp_added, stamp}, socket) do
    {
      :noreply,
      socket
      |> push_event("kamansky:closeModal", %{})
      |> put_flash(:info, %{message: "You have successfully added this stamp", timestamp: Time.utc_now()})
      |> push_redirect(to: Routes.stamp_index_path(socket, stamp.status, go_to_record: stamp.id))
    }
  end

  def handle_info({:stamp_updated, stamp_id}, socket) do
    send_update KamanskyWeb.Components.DataTable, id: "stamps-kamansky-data-table", options: [go_to_record: stamp_id]

    {
      :noreply,
      socket
      |> push_event("kamansky:closeModal", %{})
      |> put_flash(:info, %{message: "You have successfully updated this stamp.", timestamp: Time.utc_now()})
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    with socket <- apply_action(socket, socket.assigns.live_action, params), do: {:noreply, load_stamps(socket)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, atom, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :collection_to_replace, params) do
    socket
    |> assign(:go_to_record, Map.get(params, "go_to_record"))
    |> assign(:page_title, "Collection Below XF")
  end

  defp apply_action(socket, action, params) do
    socket
    |> assign(:go_to_record, Map.get(params, "go_to_record"))
    |> assign(:page_title, String.capitalize(Atom.to_string(action)))
    |> assign(:status, socket.assigns.live_action)
  end

  @spec load_stamps(Phoenix.LiveView.Socket.t) :: Phoenix.LiveView.Socket.t
  defp load_stamps(%Phoenix.LiveView.Socket{assigns: %{live_action: :collection_to_replace}} = socket) do
    socket
    |> assign(:data_count, fn -> Stamps.count_stamps_in_collection_below_grade(85) end)
    |> assign(:data_locator, fn options -> Stamps.find_row_number_for_stamp_in_collection_below_grade(85, options) end)
    |> assign(:data_source, fn options -> Stamps.list_stamps_in_collection_below_grade(85, options) end)
  end
  defp load_stamps(%Phoenix.LiveView.Socket{assigns: %{stamp: %Stamp{status: status}}} = socket) when not is_nil(status), do: load_stamps(socket, status)
  defp load_stamps(socket), do: load_stamps(socket, socket.assigns.live_action)

  @spec load_stamps(Phoenix.LiveView.Socket.t, atom) :: Phoenix.LiveView.Socket.t
  defp load_stamps(socket, status) do
    socket
    |> assign(:data_count, fn -> Stamps.count_stamps(status) end)
    |> assign(:data_locator, fn options -> Stamps.find_row_number_for_stamp(status, options) end)
    |> assign(:data_source, fn options -> Stamps.list_stamps(status, options) end)
    |> assign(:status, status)
  end
end
