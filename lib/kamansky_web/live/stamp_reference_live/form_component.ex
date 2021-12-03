defmodule KamanskyWeb.StampReferenceLive.FormComponent do
  use KamanskyWeb, :live_component
  use KamanskyWeb.Modal

  alias Kamansky.Stamps.StampReferences
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("submit", %{"stamp_reference" => stamp_reference_params}, socket), do: save_stamp_reference(socket, socket.assigns.action, stamp_reference_params)
  def handle_event("validate", %{"stamp_reference" => stamp_reference_params}, socket) do
    socket.assigns.stamp_reference
    |> StampReferences.change_stamp_reference(stamp_reference_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  @impl true
  @spec open_assigns(Phoenix.LiveView.Socket.t, map) :: Phoenix.LiveView.Socket.t
  def open_assigns(socket, %{"action" => action, "stamp-reference-id" => stamp_reference_id}) do
    with stamp_reference <- StampReferences.get_or_initialize_stamp_reference(stamp_reference_id) do
      socket
      |> assign(:action, String.to_existing_atom(action))
      |> assign(:changeset, StampReferences.change_stamp_reference(stamp_reference))
      |> assign(:stamp_reference, stamp_reference)
      |> assign(:title, (if action == "new", do: "Add New Stamp Reference", else: "Update Stamp Reference"))
    end
  end

  @spec save_stamp_reference(Phoenix.LiveView.Socket.t, :edit | :new, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_stamp_reference(socket, :edit, stamp_reference_params) do
    case StampReferences.update_stamp_reference(socket.assigns.stamp_reference, stamp_reference_params) do
      {:ok, %StampReference{id: id}} ->
        send self(), {:stamp_reference_updated, id}
        noreply(socket)

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_stamp_reference(socket, :new, stamp_reference_params) do
    case StampReferences.create_stamp_reference(stamp_reference_params) do
      {:ok, %StampReference{id: id}} ->
        send self(), {:stamp_reference_added, id}
        noreply(socket)

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
