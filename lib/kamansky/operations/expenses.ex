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

  @spec find_row_number_for_expense(map) :: integer
  def find_row_number_for_expense(options) do
    Expense
    |> select(
      [e],
      {
        e.id,
        row_number()
        |> over(
          order_by:
            [
              {
                ^options[:sort][:direction],
                field(e, ^Expense.display_column_for_sorting(options[:sort][:column]))
              }
            ]
          )
      }
    )
    |> Repo.all()
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

  @spec list_expenses(Paginate.params) :: [Expense.t]
  def list_expenses(params) do
    Paginate.list(Expenses, from(Expense), params)
  end

  @impl true
  @spec sort(Ecto.Query.t, Paginate.sort) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :date})
end
