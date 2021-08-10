defmodule Kamansky.Operations.Purchases.Purchase do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @type t :: Ecto.Schema.t | %Purchase{
    date: DateTime.t,
    description: String.t,
    quantity: integer,
    cost: Decimal.t,
    purchase_fees: Decimal.t
  }

  schema "purchases" do
    field :date, :utc_datetime
    field :description, :string
    field :quantity, :integer
    field :cost, :decimal
    field :purchase_fees, :decimal
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(%Purchase{} = purchase, attrs) do
    purchase
    |> cast(attrs, [:cost, :date, :description, :purchase_fees, :quantity])
  end

  @spec display_column_for_sorting(integer) :: atom
  def display_column_for_sorting(column) do
    [:date]
    |> Enum.at(column)
  end
end
