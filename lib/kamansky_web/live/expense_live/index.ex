defmodule KamanskyWeb.ExpenseLive.Index do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {0, :asc}

  import Kamansky.Helpers

  alias Kamansky.Operations.Expenses
  alias Kamansky.Operations.Expenses.Expense

  @impl true
  @spec handle_info({:expense_added | :expense_updated, pos_integer}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:expense_added, expense_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully added this expense.",
      expense_id
    )
  end

  def handle_info({:expense_updated, expense_id}, socket) do
    close_modal_with_success_and_reload_data(
      socket,
      "kamansky:closeModal",
      "You have successfully updated this expense.",
      expense_id
    )
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, :page_title, "Expenses")}

  @impl true
  @spec count_data(:index, String.t | nil) :: integer
  def count_data(_action, search), do: Expenses.count_expenses(search)

  @impl true
  @spec find_item_in_data(:index, pos_integer, integer, Kamansky.Paginate.sort_direction) :: integer
  def find_item_in_data(_action, expense_id, sort, direction), do: Expenses.find_row_number_for_expense(expense_id, sort, direction)

  @impl true
  @spec load_data(:index, Kamansky.Paginate.params) :: [Expense.t]
  def load_data(_action, params), do: Expenses.list_expenses(params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(socket, _action, opts), do: Routes.expense_index_path(socket, :index, opts)
end
