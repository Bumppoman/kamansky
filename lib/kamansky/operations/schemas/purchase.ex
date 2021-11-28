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

    has_many :stamps, Kamansky.Stamps.Stamp
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

  @spec potential_profit(t) :: Decimal.t
  def potential_profit(%Purchase{stamps: stamps}) do
    Enum.reduce(
      stamps,
      0,
      fn stamp, acc ->
        if is_nil(stamp.listing) or stamp.listing.status == :sold, do: acc, else: Decimal.add(stamp.listing.listing_price, acc)
      end
    )
  end

  @spec realized_profit(t) :: Decimal.t
  def realized_profit(%Purchase{stamps: stamps}) do
    Enum.reduce(
      stamps,
      0,
      fn stamp, acc ->
        if is_nil(stamp.listing) or stamp.listing.status != :sold, do: acc, else: Decimal.add(stamp.listing.sale_price, acc)
      end
    )
  end

  @spec stamps_in_collection(t) :: integer
  def stamps_in_collection(%Purchase{stamps: stamps}), do: Enum.count(stamps, &(&1.status == :collection))

  @spec stamps_listed(t) :: integer
  def stamps_listed(%Purchase{stamps: stamps}), do: Enum.count(stamps, &(&1.status == :listed))

  @spec stamps_sold(t) :: integer
  def stamps_sold(%Purchase{stamps: stamps}), do: Enum.count(stamps, &(&1.status == :sold))

  @spec total_cost(t) :: Decimal.t
  def total_cost(%Purchase{} = purchase), do: Decimal.add(purchase.cost, purchase.purchase_fees)

  @spec total_listing_price(t) :: Decimal.t
  def total_listing_price(%Purchase{stamps: stamps}) do
    Enum.reduce(
      stamps,
      0,
      fn stamp, acc ->
        if is_nil(stamp.listing), do: acc, else: Decimal.add(stamp.listing.listing_price, acc)
      end
    )
  end
end
