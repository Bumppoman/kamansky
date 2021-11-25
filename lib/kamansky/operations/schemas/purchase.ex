defmodule Kamansky.Operations.Purchases.Purchase do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @type t :: Ecto.Schema.t | %Purchase{
    date: Date.t,
    description: String.t,
    quantity: pos_integer,
    cost: Decimal.t,
    purchase_fees: Decimal.t
  }

  schema "purchases" do
    field :date, :date
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

  @spec display_column_for_sorting(pos_integer) :: atom
  def display_column_for_sorting(column) do
    [:date]
    |> Enum.at(column)
  end

  @spec total_cost(t) :: Decimal.t
  def total_cost(%Purchase{} = purchase), do: Decimal.add(purchase.cost, purchase.purchase_fees)
end
