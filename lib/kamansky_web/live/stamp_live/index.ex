defmodule KamanskyWeb.StampLive.Index do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {0, :asc}

  import Kamansky.Helpers

  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec handle_event(String.t, any, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("move_to_stock", %{"stamp-id" => stamp_id}, socket) do
    case Stamps.move_stamp_to_stock(stamp_id) do
      {:ok, _stamp} ->
        close_modal_with_success_and_reload_data(
          socket,
          "kamansky:closeConfirmationModal",
          "You have successfully moved this stamp to stock."
        )
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  @spec handle_info({atom, integer | Stamp.t}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:stamp_added, stamp}, socket) do
    socket
    |> push_event("kamansky:closeModal", %{})
    |> put_flash(:info, %{type: :success, message: "You have successfully added this stamp", timestamp: Time.utc_now()})
    |> push_redirect(to: Routes.stamp_index_path(socket, stamp.status, show: stamp.id))
    |> noreply()
  end

  def handle_info({:stamp_updated, stamp_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully updated this stamp.",
      stamp_id
    )
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, apply_action(socket, socket.assigns.live_action)}

  @spec apply_action(Phoenix.LiveView.Socket.t, atom) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :collection_to_replace), do: assign(socket, :page_title, "Collection Below XF")
  defp apply_action(socket, action) do
    socket
    |> assign(:page_title, String.capitalize(Atom.to_string(action)))
    |> assign(:status, socket.assigns.live_action)
  end

  @impl true
  @spec count_data(Phoenix.LiveView.Socket.t, String.t | nil) :: integer
  def count_data(%Phoenix.LiveView.Socket{assigns: %{live_action: :collection_to_replace}}, search), do: Stamps.count_stamps_in_collection_below_grade(85, search)
  def count_data(%Phoenix.LiveView.Socket{assigns: %{live_action: status}}, search) when status in [:collection, :stock], do: Stamps.count_stamps(status, search)

  @impl true
  @spec find_item_in_data(Phoenix.LiveView.Socket.t, pos_integer, integer, Kamansky.Paginate.sort_direction) :: integer
  def find_item_in_data(%Phoenix.LiveView.Socket{assigns: %{live_action: status}}, item_id, sort, direction) when status in [:collection, :stock] do
    Stamps.find_row_number_for_stamp(status, item_id, sort, direction)
  end

  @impl true
  @spec load_data(Phoenix.LiveView.Socket.t, Kamansky.Paginate.params) :: [Stamp.t]
  def load_data(%Phoenix.LiveView.Socket{assigns: %{live_action: :collection_to_replace}}, params), do: Stamps.list_stamps_in_collection_below_grade(85, params)
  def load_data(%Phoenix.LiveView.Socket{assigns: %{live_action: status}}, params) when status in [:collection, :stock], do: Stamps.list_stamps(status, params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :collection | :collection_to_replace | :stock, map) :: String.t
  def self_path(socket, action, opts), do: Routes.stamp_index_path(socket, action, opts)
end
