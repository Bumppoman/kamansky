defmodule KamanskyWeb.ComponentLive.ModalComponent do
  use KamanskyWeb, :live_component

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("close", _, socket), do: {:noreply, push_patch(socket, to: socket.assigns.return_to)}

  @spec size_for_type(atom) :: String.t
  defp size_for_type(:confirmation), do: "modal-sm"
  defp size_for_type(:confirmation_large), do: ""
  defp size_for_type(_), do: "modal-lg"
end
