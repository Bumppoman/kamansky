defmodule Kamansky.Operations.Expenses do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Operations.Expenses.Expense
  alias Kamansky.Repo

  @spec change_expense(Expense.t, map) :: Ecto.Changeset.t
  def change_expense(%Expense{} = expense, attrs \\ %{}), do: Expense.changeset(expense, attrs)

  @spec count_expenses :: integer
  def count_expenses, do: Repo.aggregate(Expense, :count)

  @spec create_expense(map) :: {:ok, Expense.t} | {:error, Ecto.Changeset.t}
  def create_expense(attrs) do
    %Expense{}
    |> Expense.changeset(attrs)
    |> Repo.insert()
  end

  @spec find_row_number_for_expense(map) :: integer
  def find_row_number_for_expense(options) do
    Paginate.find_row_number(Expense, Expense.display_column_for_sorting(options[:sort][:column]), options)
  end

  @spec list_expenses(Paginate.params) :: [Expense.t]
  def list_expenses(params), do: Paginate.list(Expenses, Expense, params)

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search), do: where(query, [e], ilike(e.description, ^"%#{search}%"))

  @impl true
  @spec sort(Ecto.Queryable.t, Paginate.sort) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :date})

  @spec update_expense(Expense.t, map) :: {:ok, Expense.t} | {:error, Ecto.Changeset.t}
  def update_expense(%Expense{} = expense, attrs) do
    expense
    |> Expense.changeset(attrs)
    |> Repo.update()
  end
end
