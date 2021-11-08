defmodule KamanskyWeb.InitAssigns do
  import Phoenix.LiveView

  alias Kamansky.Operations.Accounts

  @spec on_mount(:default, map, map, Phoenix.LiveView.Socket.t) :: {:cont, Phoenix.LiveView.Socket.t}
  def on_mount(:default, _params, session, socket) do
    with user_token <- Map.get(session, "user_token"),
      user <- user_token && Accounts.get_user_by_session_token(user_token),
      false <- is_nil(user),
      socket <-
        socket
        |> assign(:current_user, user)
        |> assign(:timezone, get_connect_params(socket)["timezone"] || "America/New_York")
    do
      {:cont, socket}
    else
      _ -> {:halt, redirect(socket, to: "/users/login")}
    end
  end
end
