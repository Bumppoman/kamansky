defmodule KamanskyWeb.StampLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket) do
    {:ok, assign_defaults(socket, session)}
  end

  @impl true
  @spec handle_event(String.t, any, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("move_to_stock", _value, socket) do
    case Stamps.move_stamp_to_stock(socket.assigns.stamp) do
      {:ok, _stamp} ->
        {:noreply,
          socket
          |> put_flash(:info, "You have successfully moved this stamp to stock.")
          |> push_redirect(to: Routes.stamp_index_path(socket, socket.assigns.status))
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    with socket <- apply_action(socket, socket.assigns.live_action, params) do
      {:noreply, load_stamps(socket)}
    end
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, atom, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Stamp")
    |> assign(:stamp, Stamps.get_stamp!(id))
  end

  defp apply_action(socket, :move_to_stock, %{"id" => id}) do
    socket
    |> assign(:page_title, "Move Stamp to Stock")
    |> assign(:stamp, Stamps.get_stamp!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add New Stamp")
    |> assign(:stamp, %Stamp{})
  end

  defp apply_action(socket, :sell, %{"id" => id}) do
    socket
    |> assign(:page_title, "List Stamp for Sale")
    |> assign(:stamp, Stamps.get_stamp!(id))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:go_to_record, id)
    |> assign(:stamp, Stamps.get_stamp_detail!(id))
  end

  defp apply_action(socket, action, params) do
    socket
    |> assign(:go_to_record, Map.get(params, "go_to_record"))
    |> assign(:page_title, String.capitalize(Atom.to_string(action)))
  end

  @spec load_stamps(Phoenix.LiveView.Socket.t) :: Phoenix.LiveView.Socket.t
  defp load_stamps(%Phoenix.LiveView.Socket{assigns: %{stamp: %Stamp{status: status}}} = socket) when not is_nil(status) do
    load_stamps(socket, status)
  end
  defp load_stamps(socket), do: load_stamps(socket, socket.assigns.live_action)

  @spec load_stamps(Phoenix.LiveView.Socket.t, atom) :: Phoenix.LiveView.Socket.t
  defp load_stamps(socket, status) do
    socket
    |> assign(
      [
        data_count: Stamps.count_stamps(status),
        data_locator: fn options -> Stamps.find_row_number_for_stamp(status, options) end,
        data_source: fn options -> Stamps.list_stamps(status, options) end,
        status: status
      ]
    )
  end
end
