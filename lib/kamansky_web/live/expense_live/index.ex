defmodule KamanskyWeb.ExpenseLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Operations.Expenses
  alias Kamansky.Operations.Expenses.Expense

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, session, socket) do
    {
      :ok,
      socket
      |> assign_defaults(session)
      |> assign([
        data_count: Expenses.count_expenses(),
        data_locator: fn options -> Expenses.find_row_number_for_expense(options) end,
        data_source: fn options -> Expenses.list_expenses(options) end
      ])
    }
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t, atom, map) :: Phoenix.LiveView.Socket.t
  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:expense, Expenses.get_expense!(id))
    |> assign(:page_title, "Add New Expense")
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Expenses")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:expense, %Expense{})
    |> assign(:page_title, "Add New Expense")
  end
end
