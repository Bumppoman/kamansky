defmodule KamanskyWeb.ReportLive.Show do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1]

  alias Kamansky.Operations.Reports

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
        |> assign(:expense_data, Reports.get_expense_data(year, month))
        |> assign(:month, month)
        |> assign(:page_title, "Report for #{month_name} #{year}")
        |> assign(:order_data, Reports.get_order_data(year, month))
        |> assign(:year, year)
    do
      {:noreply, socket}
    end
  end
end
