defmodule KamanskyWeb.ExpenseLive.FormComponent do
  use KamanskyWeb, :live_component
  use KamanskyWeb.Modal

  alias Kamansky.Operations.Expenses
  alias Kamansky.Operations.Expenses.Expense

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"expense" => expense_params}, socket) do
    socket.assigns.expense
    |> Expenses.change_expense(expense_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end
  def handle_event("submit", %{"expense" => expense_params}, socket), do: save_expense(socket, expense_params)

  @impl true
  def open_assigns(socket, %{"action" => action, "expense-id" => expense_id}) do
    with expense <- Expenses.get_or_initialize_expense(expense_id) do
      socket
      |> assign(:action, action)
      |> assign(:changeset, Expenses.change_expense(expense))
      |> assign(:expense, expense)
      |> assign(:title, (if action == "new", do: "Add Expense", else: "Update Expense"))
    end
  end

  @spec save_expense(Phoenix.LiveView.Socket.t, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_expense(%Phoenix.LiveView.Socket{assigns: %{action: "edit"}} = socket, expense_params) do
    case Expenses.update_expense(socket.assigns.expense, expense_params) do
      {:ok, %Expense{id: id}} ->
        send self(), {:expense_updated, id}
        noreply(socket)

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_expense(%Phoenix.LiveView.Socket{assigns: %{action: "new"}} = socket, expense_params) do
    case Expenses.create_expense(expense_params) do
      {:ok, %{id: id}} ->
        send self(), {:expense_added, id}
        noreply(socket)

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
