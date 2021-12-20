defmodule KamanskyWeb.TrendLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1]

  alias Kamansky.Operations.Trends
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    with stamps <- Stamps.list_sold_stamps_raw(),
      total_sold_stamps <- Enum.count(stamps),
      sold_stamps_by_format <- Enum.frequencies_by(stamps, &Stamp.format_code/1),
      sold_stamps_by_grade <- Enum.frequencies_by(stamps, &Stamp.letter_grade/1),
      %{false: never_hinged, true: hinged} <- Enum.frequencies_by(stamps, &Stamp.hinged?/1)
    do
      socket
      |> assign(:era_sold_listing_data, Trends.sold_listing_data_by_era())
      |> assign(:format_data, format_data(sold_stamps_by_format, total_sold_stamps))
      |> assign(:grade_listing_data, Trends.listing_data_by_grade())
      |> assign(:hinged, (hinged / total_sold_stamps) * 100)
      |> assign(:letter_grade_data, letter_grade_data(sold_stamps_by_grade, total_sold_stamps))
      |> assign(:never_hinged, (never_hinged / total_sold_stamps) * 100)
      |> assign(:page_title, "Sales Trends")
      |> ok()
    end
  end

  defp format_data(sold_stamps_by_format, total_stamps) do
    [
      Map.get(sold_stamps_by_format, "", 0),
      Map.get(sold_stamps_by_format, "P", 0),
      Map.get(sold_stamps_by_format, "ST", 0),
      Map.get(sold_stamps_by_format, "SS", 0),
      Map.get(sold_stamps_by_format, "B", 0),
      Map.get(sold_stamps_by_format, "PB", 0),
      Map.get(sold_stamps_by_format, "ZB", 0),
      Map.get(sold_stamps_by_format, "MB", 0),
      Map.get(sold_stamps_by_format, "FDC", 0),
    ]
    |> Enum.map_join(",", &(round((&1 / total_stamps) * 100)))
    |> then(&("[#{&1}]"))
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
