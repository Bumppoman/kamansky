defmodule Kamansky.Operations.Expenses.Expense do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @type t :: Ecto.Schema.t | %Expense{
    category: integer,
    description: String.t,
    date: DateTime.t,
    amount: Decimal.t
  }

  schema "expenses" do
    field :category, Ecto.Enum, values: [:equipment]
    field :description, :string
    field :date, :utc_datetime
    field :amount, :decimal
  end

  @spec categories :: [{String.t, atom}]
  def categories do
    [
      {"Equipment", :equipment}
    ]
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(%Expense{} = expense, attrs) do
    expense
    |> cast(attrs, [])
  end

  @spec display_column_for_sorting(integer) :: atom
  def display_column_for_sorting(column) do
    [:date]
    |> Enum.at(column)
  end

  @spec formatted_category(t) :: String.t
  def formatted_category(%Expense{category: category}) do
    categories()
    |> Enum.find(fn _name, key -> key == category end)
    |> elem(0)
  end
end
