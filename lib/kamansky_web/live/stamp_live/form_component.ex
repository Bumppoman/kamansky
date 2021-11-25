defmodule KamanskyWeb.StampLive.FormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Attachments
  alias Kamansky.Attachments.Attachment
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec mount(Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(socket) do
    socket
    |> allow_upload(:front_photo, accept: :any, auto_upload: true)
    |> allow_upload(:rear_photo, accept: :any, auto_upload: true)
    |> ok()
  end

  @impl true
  @spec update(%{required(:stamp) => Stamp.t, required(:status) => atom, optional(atom) => any}, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{trigger_params: %{"action" => action, "stamp-id" => stamp_id, "status" => status}} = assigns, socket) do
    with stamp <- Stamps.get_or_initialize_stamp(stamp_id) do
      socket
      |> assign(assigns)
      |> assign(:action, action)
      |> assign(:changeset, Stamps.change_stamp(stamp, %{add_to: String.to_existing_atom(status)}))
      |> assign(:copy_in_collection, nil)
      |> assign(:stamp, stamp)
      |> assign(:title, (if action == "new", do: "Add New Stamp", else: "Edit Stamp"))
      |> ok()
    end
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("find_in_collection", %{"value" => scott_number}, socket) do
    with copy_in_collection <- Stamps.get_stamp_in_collection_by_scott_number(scott_number) do
      socket
      |> assign(:copy_in_collection, copy_in_collection)
      |> noreply()
    end
  end

  def handle_event("validate", %{"stamp" => stamp_params}, socket) do
    socket.assigns.stamp
    |> Stamps.change_stamp(stamp_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  def handle_event("submit", %{"stamp" => stamp_params}, socket), do: save_stamp(socket, stamp_params)

  @spec manage_photo(Phoenix.LiveView.Socket.t, atom) :: {:ok, Kamansky.Attachments.Attachment.t | nil}
  defp manage_photo(socket, photo_name) do
    socket
    |> consume_uploaded_entries(photo_name, &Attachments.create_attachment/2)
    |> case do
      [] -> {:ok, nil}
      [ok: {:ok, attached_photo}] -> {:ok, attached_photo}
    end
  end

  @spec save_stamp(Phoenix.LiveView.Socket.t, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_stamp(%Phoenix.LiveView.Socket{assigns: %{action: "edit"}} = socket, stamp_params) do
    with {:ok, front_photo} <- manage_photo(socket, :front_photo),
      {:ok, rear_photo} <- manage_photo(socket, :rear_photo)
    do
      case Stamps.update_stamp(socket.assigns.stamp, stamp_params, front_photo, rear_photo) do
        {:ok, %Stamp{id: id}} ->
          send self(), {:stamp_updated, id}
          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, :changeset, changeset)}
      end
    end
  end

  defp save_stamp(%Phoenix.LiveView.Socket{assigns: %{action: "new"}} = socket, %{"add_to" => add_to} = stamp_params) do
    with {:ok, front_photo} <- manage_photo(socket, :front_photo),
      {:ok, rear_photo} <- manage_photo(socket, :rear_photo)
    do
      stamp_params
      |> Map.put("status", add_to)
      |> Stamps.create_stamp(front_photo, rear_photo)
      |> case do
        {:ok, stamp} ->
          send self(), {:stamp_added, stamp}
          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end
end
