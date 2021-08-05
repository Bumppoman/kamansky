defmodule KamanskyWeb.ReportsLive.Show do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1]

  alias Kamansky.Operations.Reports

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
      data <- Reports.get_order_data(year, month),
      socket <-
        socket
        |> assign(:month, month)
        |> assign(:page_title, "Report for #{month_name} #{year}")
        |> assign(:data, data)
        |> assign(:year, year)
    do
      {:noreply, socket}
    end
  end
end
