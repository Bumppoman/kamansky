defmodule KamanskyWeb.ReportsLive.Index do
  use KamanskyWeb, :live_view

  alias Kamansky.Operations.Reports

  @impl true
  def mount(_params, session, socket) do
    {
      :ok,
      assign_defaults(socket, session)
    }
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {
      :noreply,
      assign(socket, :months, Reports.list_report_months())
    }
  end
end
