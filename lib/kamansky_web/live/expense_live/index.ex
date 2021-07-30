defmodule KamanskyWeb.ExpenseLive.Index do
  use KamanskyWeb, :live_view

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket) do
    {
      :ok,
      assign_defaults(socket, session)
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, atom, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Expenses")
  end
end
