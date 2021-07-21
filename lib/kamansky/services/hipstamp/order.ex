defmodule Kamansky.Services.Hipstamp.Order do
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Hipstamp

  def all_paid do
    with {:ok, response} <-
      Hipstamp.get("/stores/#{hipstamp_username()}/sales/paid")
    do
      response.body["results"]
    end
  end

  def all_pending(%DateTime{} = from_time) do
    with(
      from_time <-
        from_time
        |> DateTime.shift_zone("America/New_York")
        |> elem(1)
        |> Calendar.strftime("%c"),
      {:ok, response} <-
        Hipstamp.get(
          "/stores/#{hipstamp_username()}/sales/paid",
          query: [created_time_from: from_time]
        )
    ) do
      response.body["results"]
    end
  end

  def mark_shipped(%Order{hipstamp_id: id}) do
    Hipstamp.put(
      "/stores/#{hipstamp_username()}/sales/#{id}",
      %{ flag_shipping: 1 }
    )
  end

  defp hipstamp_username, do: Application.get_env(:kamansky, :hipstamp_username)
end
