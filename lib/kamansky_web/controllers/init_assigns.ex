defmodule KamanskyWeb.InitAssigns do
  import Phoenix.LiveView

  @spec on_mount(:default, map, map, Phoenix.LiveView.Socket.t) :: {:cont, Phoenix.LiveView.Socket.t}
  def on_mount(:default, _params, session, socket) do
    with socket <-
      socket
      |> assign(:logged_in, Map.get(session, "logged_in", false))
      |> assign(:timezone, get_connect_params(socket)["timezone"] || "America/New_York")
    do
      {:cont, socket}
    end
  end
end
