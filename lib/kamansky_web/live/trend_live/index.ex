defmodule KamanskyWeb.TrendLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1]

  alias Kamansky.Sales.Listings
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    with stamps <- Stamps.list_sold_stamps_raw(),
      total_sold_stamps <- Enum.count(stamps),
      sold_stamps_by_grade <- Enum.frequencies_by(stamps, &Stamp.letter_grade/1),
      %{false: never_hinged, true: hinged} <- Enum.frequencies_by(stamps, &Stamp.hinged?/1)
    do
      {
        :ok,
        socket
        |> assign(:era_sold_listing_data, Listings.sold_listing_data_by_era())
        |> assign(:hinged, (hinged / total_sold_stamps) * 100)
        |> assign(:letter_grade_data, letter_grade_data(sold_stamps_by_grade, total_sold_stamps))
        |> assign(:median_sold_price_data, Listings.median_price_data_for_sold_listings())
        |> assign(:never_hinged, (never_hinged / total_sold_stamps) * 100)
        |> assign(:page_title, "Sales Trends")
      }
    end
  end

  defp letter_grade_data(sold_stamps_by_grade, total_stamps) do
    [
      Map.get(sold_stamps_by_grade, "---", 0),
      Map.get(sold_stamps_by_grade, "F", 0),
      Map.get(sold_stamps_by_grade, "F/VF", 0),
      Map.get(sold_stamps_by_grade, "VF", 0),
      Map.get(sold_stamps_by_grade, "VF/XF", 0),
      Map.get(sold_stamps_by_grade, "XF", 0),
      Map.get(sold_stamps_by_grade, "XF/Superb", 0),
      Map.get(sold_stamps_by_grade, "Superb", 0),
      Map.get(sold_stamps_by_grade, "Gem", 0),
    ]
    |> Enum.map_join(",", &(round((&1 / total_stamps) * 100)))
    |> then(&("[#{&1}]"))
  end
end