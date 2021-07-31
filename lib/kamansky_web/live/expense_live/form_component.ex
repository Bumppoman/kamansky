defmodule KamanskyWeb.ExpenseLive.FormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Operations.Expenses
  alias Kamansky.Operations.Expenses.Expense

  @impl true
  @spec update(%{required(:expense) => Expense.t}, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{expense: expense} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, Expenses.change_expense(expense))
    }
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"expense" => expense_params}, socket) do
    with(
      changeset <-
        socket.assigns.expense
        |> Expenses.change_expense(expense_params)
        |> Map.put(:action, :validate)
    ) do
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("submit", %{"expense" => expense_params}, socket) do
    save_expense(socket, socket.assigns.action, expense_params)
  end

  @spec save_expense(Phoenix.LiveView.Socket.t, :edit | :new, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_expense(socket, :edit, expense_params) do
    case Expenses.update_expense(socket.assigns.expense, expense_params) do
      {:ok, _expense} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "You have successfully updated this expense.")
          |> push_redirect(to: socket.assigns.return_to)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_expense(socket, :new, expense_params) do
    case Expenses.create_expense(expense_params) do
      {:ok, %{id: id}} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "You have successfully added this expense.")
          |> push_redirect(to: Routes.expense_index_path(socket, :index, go_to_record: id))
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
