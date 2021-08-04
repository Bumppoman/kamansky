defmodule KamanskyWeb.StatisticsLive.Show do
  use KamanskyWeb, :live_view

  alias Kamansky.Operations.Statistics

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign_defaults(socket, session)}
  end

  @impl true
  def handle_params(%{"month" => month, "year" => year}, _uri, socket) do
    with year <- String.to_integer(year),
      month <- String.to_integer(month),
      dummy_date <- Date.new(year, month, 1),
      month_name <- Calendar.strftime("%B"),
      socket <-
        socket
        |> assign(:page_title, "Statistics for #{month_name} #{year}")
        |> assign(:statistics, Statistics.get_statistics(month, year))
    do
      {:noreply, socket}
    end
  end
end
