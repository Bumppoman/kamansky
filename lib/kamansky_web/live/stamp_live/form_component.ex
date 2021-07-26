defmodule KamanskyWeb.StampLive.FormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Attachments
  alias Kamansky.Attachments.Attachment
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  def mount(socket) do
    socket =
      socket
      |> allow_upload(:front_photo, accept: :any, auto_upload: true)
      |> allow_upload(:rear_photo, accept: :any, auto_upload: true)

    {:ok, socket}
  end

  @impl true
  def update(%{stamp: stamp, status: status} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, Stamps.change_stamp(stamp, %{add_to: status}))
      |> assign(:copy_in_collection, nil)
    }
  end

  @impl true
  def handle_event("find_in_collection", %{"value" => scott_number}, socket) do
    with copy_in_collection <- Stamps.get_stamp_in_collection_by_scott_number(scott_number) do
      {:noreply, assign(socket, :copy_in_collection, copy_in_collection)}
    end
  end

  def handle_event("validate", %{"stamp" => stamp_params}, socket) do
    changeset =
      socket.assigns.stamp
      |> Stamps.change_stamp(stamp_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("submit", %{"stamp" => stamp_params}, socket) do
    save_stamp(socket, socket.assigns.action, stamp_params)
  end

  defp manage_photo(socket, photo_name) do
    socket
    |> consume_uploaded_entries(photo_name, &Attachments.create_attachment/2)
    |> case do
      [] -> {:ok, nil}
      [ok: {:ok, attached_photo}] -> {:ok, attached_photo}
    end
  end

  defp save_stamp(socket, :edit, stamp_params) do
    with {:ok, front_photo} <- manage_photo(socket, :front_photo),
      {:ok, rear_photo} <- manage_photo(socket, :rear_photo)
    do
      case Stamps.update_stamp(socket.assigns.stamp, stamp_params, front_photo, rear_photo) do
        {:ok, %{id: id}} ->
          {
            :noreply,
            socket
            |> put_flash(:info, "You have successfully updated this stamp.")
            |> push_redirect(to: Routes.stamp_index_path(socket, socket.assigns.status, go_to_record: id))
          }

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :changeset, changeset)}
      end
    end
  end

  defp save_stamp(socket, :new, %{"add_to" => add_to} = stamp_params) do
    with {:ok, front_photo} <- manage_photo(socket, :front_photo),
      {:ok, rear_photo} <- manage_photo(socket, :rear_photo)
    do
      case Stamps.create_stamp(%{stamp_params | "status" => add_to}, front_photo, rear_photo) do
        {:ok, %Stamp{id: id, status: status}} ->
          {
            :noreply,
            socket
              |> put_flash(:info, "You have successfully added this stamp.")
              |> push_redirect(to: Routes.stamp_index_path(socket, status, go_to_record: id))
          }

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end
end
