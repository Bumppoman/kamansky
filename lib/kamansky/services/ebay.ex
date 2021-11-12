defmodule Kamansky.Services.Ebay do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.ebay.com/ws/api.dll"
  plug Tesla.Middleware.Headers, [
    {"X-EBAY-API-COMPATIBILITY-LEVEL", 1225},
    {"X-EBAY-API-SITEID", 0},
    {"Content-Type", "text/xml"}
  ]

  @spec requester_credentials :: String.t
  def requester_credentials do
    """
    <RequesterCredentials>
      <eBayAuthToken>#{Application.get_env(:kamansky, :ebay_authorization_token)}</eBayAuthToken>
    </RequesterCredentials>
    """
  end
end
