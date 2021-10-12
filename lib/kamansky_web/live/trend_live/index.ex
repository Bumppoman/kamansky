defmodule KamanskyWeb.TrendLive.Index do
  use KamanskyWeb, :live_view

  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    with stamps <- Stamps.list_sold_stamps_raw(),
      total_sold_stamps <- Enum.count(stamps),
      %{false: never_hinged, true: hinged} <- Enum.frequencies_by(stamps, &Stamp.hinged?/1)
    do
      {
        :ok,
        socket
        |> assign(:hinged, (hinged / total_sold_stamps) * 100)
        |> assign(:never_hinged, (never_hinged / total_sold_stamps) * 100)
        |> assign(:page_title, "Sales Trends")
      }
    end
  end
end
