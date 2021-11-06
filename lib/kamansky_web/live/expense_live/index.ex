defmodule KamanskyWeb.ExpenseLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Operations.Expenses
  alias Kamansky.Operations.Expenses.Expense

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:data_count, fn -> Expenses.count_expenses() end)
      |> assign(:data_locator, fn options -> Expenses.find_row_number_for_expense(options) end)
      |> assign(:data_source, fn options -> Expenses.list_expenses(options) end)
    }
  end

  @impl true
  @spec handle_info({:expense_added | :expense_updated, pos_integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:expense_added, expense_id}, socket), do: update_datatable(socket, "You have successfully added this expense.", expense_id)
  def handle_info({:expense_updated, expense_id}, socket), do: update_datatable(socket, "You have successfully updated this expense.", expense_id)

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Expenses")}

  @spec update_datatable(Phoenix.LiveView.Socket.t, String.t, pos_integer) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp update_datatable(socket, message, expense_id) do
    send_update KamanskyWeb.Components.DataTable, id: "expense-kamansky-data-table", options: [go_to_record: expense_id]

    {
      :noreply,
      socket
      |> push_event("kamansky:closeModal", %{})
      |> put_flash(:info, %{message: message, timestamp: Time.utc_now()})
    }
  end
end
