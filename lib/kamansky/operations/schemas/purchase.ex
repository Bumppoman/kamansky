defmodule Kamansky.Operations.Purchases.Purchase do
  use Ecto.Schema

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
end
