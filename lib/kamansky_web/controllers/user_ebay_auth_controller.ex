defmodule KamanskyWeb.UserEbayAuthController do
  use KamanskyWeb, :controller

  alias Kamansky.Operations.Accounts

  @spec auth_code(Plug.Conn.t, map) :: Plug.Conn.t
  def auth_code(conn, %{"code" => code}) do
    with response <-
      Tesla.post!(
        "https://api.ebay.com/identity/v1/oauth2/token",
        URI.encode_query(
          %{
            grant_type: "authorization_code",
            code: code,
            redirect_uri: Application.get_env(:kamansky, :ebay_redirect_uri)
          }
        ),
        headers: [
          {"Content-Type", "application/x-www-form-urlencoded"},
          {"Authorization", "Basic #{Base.encode64("#{Application.get_env(:kamansky, :ebay_client_id)}:#{Application.get_env(:kamansky, :ebay_client_secret)}")}"}
        ]
      )
      |> Map.get(:body)
      |> Jason.decode!()
    do
      Accounts.set_ebay_token(conn.assigns.current_user, response["refresh_token"])
      redirect(conn, to: Routes.dashboard_index_path(conn, :index))
    end
  end

  @spec new(Plug.Conn.t, map) :: Plug.Conn.t
  def new(conn, _params) do
    "https://auth.ebay.com/oauth2/authorize"
    |> URI.parse()
    |> Map.put(
      :query,
      URI.encode_query(
        client_id: Application.get_env(:kamansky, :ebay_client_id),
        redirect_uri: Application.get_env(:kamansky, :ebay_redirect_uri),
        response_type: "code"
      )
    )
    |> URI.to_string()
    |> then(&redirect(conn, external: &1))
  end
end
