defmodule KamanskyWeb.Auth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    logged_in = get_session(conn, :logged_in)

    assign(conn, :logged_in, logged_in)
  end

  def login(conn) do
    conn
    |> assign(:logged_in, true)
    |> put_session(:logged_in, true)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end
end
