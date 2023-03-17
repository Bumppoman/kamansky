defmodule KamanskyWeb.InitAssigns do
  import Phoenix.{Component, LiveView}

  alias Kamansky.Operations.Accounts

  @spec on_mount(:default, map, map, Phoenix.LiveView.Socket.t) :: {:cont, Phoenix.LiveView.Socket.t} | {:halt, Phoenix.LiveView.Socket.t}
  def on_mount(:default, _params, %{"user_token" => user_token}, socket) do
    with socket <- assign_new(socket, :current_user, fn -> Accounts.get_user_by_session_token(user_token) end) do
      if socket.assigns.current_user.id do
        {:cont, assign(socket, :timezone, get_connect_params(socket)["timezone"] || "America/New_York")}
      else
        {:halt, redirect(socket, to: "/users/login")}
      end
    end
  end
end
