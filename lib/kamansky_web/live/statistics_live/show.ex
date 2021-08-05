defmodule KamanskyWeb.StatisticsLive.Show do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1, formatted_date: 1]

  alias Kamansky.Operations.Statistics
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket) do
    with(
      socket <-
        socket
        |> assign_defaults(session)
    ) do
      {:ok, socket}
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => String.t}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("show", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  @spec handle_params(%{required(String.t) => String.t}, String.t, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(%{"month" => month, "year" => year}, _uri, socket) do
    with year <- String.to_integer(year),
      month <- String.to_integer(month),
      dummy_date <- Date.new!(year, month, 1),
      month_name <- Calendar.strftime(dummy_date, "%B"),
      socket <-
        socket
        |> assign(:month, month)
        |> assign(:orders, Statistics.list_orders_for_month_and_year(month, year))
        |> assign(:page_title, "Statistics for #{month_name} #{year}")
        |> assign(:statistics, Statistics.get_base_statistics(month, year))
        |> assign(:year, year)
    do
      {:noreply, socket}
    end
  end
end
