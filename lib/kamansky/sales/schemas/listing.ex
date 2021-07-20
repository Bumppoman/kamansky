defmodule Kamansky.Sales.Listings.Listing do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Stamps.Stamp

  schema "listings" do
    field :listing_price, :decimal
    field :individual_supply_cost, :decimal
    field :selling_fees, :decimal
    field :sale_price, :decimal
    field :hipstamp_id, :integer
    field :ebay_id, :integer
    field :status, Ecto.Enum, values: [pending: 1, active: 2, removed: 3, sold: 4], default: :active

    timestamps(updated_at: false)

    belongs_to :stamp, Kamansky.Stamps.Stamp
    belongs_to :order, Kamansky.Sales.Orders.Order
  end

  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [:individual_supply_cost, :listing_price])
    |> validate_required([])
  end

  def gross_profit(%Listing{sale_price: sale_price} = listing) do
    Decimal.add(sale_price, Listing.shipping_price(listing))
  end

  def net_profit(%Listing{} = listing) do
    gross_profit(listing)
    |> Decimal.sub(
      Decimal.add(listing.selling_fees,
        Decimal.add(Listing.shipping_cost(listing),
          Decimal.add(Listing.supply_cost(listing), Stamp.total_cost(listing.stamp))
        )
      )
    )
  end

  def shipping_cost(%Listing{order: %Order{} = order}) do
    Order.per_item_shipping_cost(order)
  end

  def shipping_price(%Listing{order: %Order{} = order}) do
    Order.per_item_shipping_price(order)
  end

  def supply_cost(%Listing{individual_supply_cost: individual_supply_cost, order: %Order{} = order}) do
    order
    |> Order.per_item_order_supply_cost()
    |> Decimal.add(individual_supply_cost)
  end
end
