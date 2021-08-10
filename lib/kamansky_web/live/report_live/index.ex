defmodule KamanskyWeb.ReportLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1]

  alias Kamansky.Operations.Reports

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket) do
    {
      :ok,
      socket
      |> assign_defaults(session)
      |> assign(:year, DateTime.utc_now().year)
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket) do
    with socket <- assign(socket, :report_months, Reports.list_report_months()),
      reports <- Map.get(socket.assigns.report_months, socket.assigns.year),
      {{:totals, totals}, reports} <- List.pop_at(reports, 0)
    do
      {
        :noreply,
        socket
        |> assign(:reports, reports)
        |> assign(:totals, totals)
      }
    end
  end
end
