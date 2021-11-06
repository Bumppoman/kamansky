defmodule KamanskyWeb.Components.Modal do
  use KamanskyWeb, :live_component

  @impl true
  @spec mount(Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(socket), do: {:ok, assign(socket, :open, false)}

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("close", _, socket), do: {:noreply, assign(socket, :open, false)}
  def handle_event("open", params, socket) do
    {
      :noreply,
      socket
      |> assign(:open, true)
      |> assign(:opts, Keyword.put(socket.assigns.opts, :trigger_params, params))
    }
  end
end
