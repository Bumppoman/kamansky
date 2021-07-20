defmodule KamanskyWeb.SessionController do
  use KamanskyWeb, :controller

  def create(conn, %{"login" => %{"username" => username, "password" => password}}) do
    if username == Application.get_env(:kamansky, :username) && password == Application.get_env(:kamansky, :password) do
      conn
      |> KamanskyWeb.Auth.login
      |> redirect(to: "/dashboard")
    end
  end

  def delete(conn, _) do
    conn
    |> KamanskyWeb.Auth.logout()
    |> redirect(to: "/")
  end
end
