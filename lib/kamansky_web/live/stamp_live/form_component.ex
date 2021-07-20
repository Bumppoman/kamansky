defmodule KamanskyWeb.StampLive.FormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Attachments
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  def mount(socket) do
    socket =
      socket
      |> allow_upload(:front_photo, accept: :any, auto_upload: true)
      |> allow_upload(:rear_photo, accept: :any, auto_upload: true)

    {:ok, socket}
  end

  @impl true
  def update(%{stamp: stamp} = assigns, socket) do
    changeset = Stamps.change_stamp(stamp)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
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
          {:noreply,
          socket
          |> put_flash(:info, "You have successfully updated this stamp.")
          |> push_redirect(to: Routes.stamp_index_path(socket, socket.assigns.status, go_to_record: id))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :changeset, changeset)}
      end
    end
  end

  defp save_stamp(socket, :new, stamp_params) do
    with {:ok, front_photo} <- manage_photo(socket, :front_photo),
      {:ok, rear_photo} <- manage_photo(socket, :rear_photo)
    do
      case Stamps.create_stamp(stamp_params, front_photo, rear_photo, socket.assigns.status) do
        {:ok, %{id: id}} ->
          {:noreply,
          socket
          |> put_flash(:info, "You have successfully added this stamp.")
          |> push_redirect(to: Routes.stamp_index_path(socket, socket.assigns.status, go_to_record: id))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end
end
