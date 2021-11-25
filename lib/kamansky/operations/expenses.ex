defmodule Kamansky.Operations.Expenses do
  @sort_columns [:date]
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Operations.Expenses.Expense
  alias Kamansky.Repo

  @spec change_expense(Expense.t, map) :: Ecto.Changeset.t
  def change_expense(%Expense{} = expense, attrs \\ %{}), do: Expense.changeset(expense, attrs)

  @spec count_expenses(String.t | nil) :: integer
  def count_expenses(search \\ nil) do
    Expense
    |> maybe_search(search)
    |> Repo.aggregate(:count, :id)
  end

  @spec create_expense(map) :: {:ok, Expense.t} | {:error, Ecto.Changeset.t}
  def create_expense(attrs) do
    %Expense{}
    |> Expense.changeset(attrs)
    |> Repo.insert()
  end

  @spec find_row_number_for_expense(pos_integer, integer, Paginate.sort_direction) :: integer | nil
  def find_row_number_for_expense(expense_id, sort, direction), do: Paginate.find_row_number(Expense, expense_id, Expense.display_column_for_sorting(sort), direction)

  @spec get_expense!(pos_integer) :: Expense.t
  def get_expense!(id), do: Repo.get!(Expense, id)

  @spec get_or_initialize_expense(String.t) :: Expense.t
  def get_or_initialize_expense(""), do: %Expense{}
  def get_or_initialize_expense(id), do: get_expense!(String.to_integer(id))

  @spec list_expenses(Paginate.params) :: [Expense.t]
  def list_expenses(params) do
    Expense
    |> maybe_search(params.search)
    |> then(&Paginate.list(Expenses, &1, params))
  end

  @spec update_expense(Expense.t, map) :: {:ok, Expense.t} | {:error, Ecto.Changeset.t}
  def update_expense(%Expense{} = expense, attrs) do
    expense
    |> Expense.changeset(attrs)
    |> Repo.update()
  end

  @spec maybe_search(Ecto.Queryable.t, String.t | nil) :: Ecto.Queryable.t
  defp maybe_search(query, nil), do: query
  defp maybe_search(query, search), do: where(query, [e], ilike(e.description, ^"%#{search}%"))
end
