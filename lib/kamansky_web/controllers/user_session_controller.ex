defmodule KamanskyWeb.UserSessionController do
  use KamanskyWeb, :controller

  alias Kamansky.Operations.Accounts
  alias KamanskyWeb.UserAuth

  @spec new(Plug.Conn.t, map) :: Plug.Conn.t
  def new(conn, _params) do
    render(conn, "new.html", page_title: "Sign in")
  end

  @spec create(Plug.Conn.t, map) :: Plug.Conn.t
  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:info, %{type: :error, message: "Invalid email or password", timestamp: DateTime.utc_now()})
      |> render("new.html", page_title: "Sign in")
    end
  end

  @spec delete(Plug.Conn.t, map) :: Plug.Conn.t
  def delete(conn, _params) do
    conn
    |> put_flash(:info, %{type: :success, message: "Logged out successfully.", timestamp: DateTime.utc_now()})
    |> UserAuth.log_out_user()
  end
end
