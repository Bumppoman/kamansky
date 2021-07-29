defmodule KamanskyWeb.StampReferenceLive.FormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Stamps.StampReferences
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec update(%{required(:stamp_reference) => StampReference.t}, Phoenix.LiveView.Socket.t)
    :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{stamp_reference: stamp_reference} = assigns, socket) do
    changeset = StampReferences.change_stamp_reference(stamp_reference)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"stamp_reference" => stamp_reference_params}, socket) do
    changeset =
      socket.assigns.stamp_reference
      |> StampReferences.change_stamp_reference(stamp_reference_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("submit", %{"stamp_reference" => stamp_reference_params}, socket) do
    save_stamp_reference(socket, socket.assigns.action, stamp_reference_params)
  end

  @spec save_stamp_reference(Phoenix.LiveView.Socket.t, :edit | :new, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_stamp_reference(socket, :edit, stamp_reference_params) do
    case StampReferences.update_stamp_reference(socket.assigns.stamp_reference, stamp_reference_params) do
      {:ok, _stamp_reference} ->
        {:noreply,
         socket
         |> put_flash(:info, "You have successfully updated this stamp reference.")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_stamp_reference(socket, :new, stamp_reference_params) do
    case StampReferences.create_stamp_reference(stamp_reference_params) do
      {:ok, %{id: id}} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "You have successfully added this stamp reference.")
          |> push_redirect(to: Routes.stamp_reference_index_path(socket, :index, go_to_record: id))
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
