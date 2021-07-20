defmodule Kamansky.Sales.Orders.Order do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__
  alias Kamansky.Stamps.Stamp

  schema "orders" do
    field :ordered_at, :utc_datetime_usec
    field :item_price, :decimal
    field :shipping_price, :decimal
    field :selling_fees, :decimal
    field :shipping_cost, :decimal
    field :supply_cost, :decimal
    field :status, Ecto.Enum, values: [pending: 1, finalized: 2, processed: 3, shipped: 4, completed: 5]
    field :hipstamp_id, :integer
    field :name, :string
    field :street_address, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :email, :string
    field :processed_at, :utc_datetime_usec
    field :shipped_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    field :listings_count, :map, virtual: true

    has_many :listings, Kamansky.Sales.Listings.Listing
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [])
    |> validate_required([])
  end

  def net_profit(%Order{} = order) do
    Decimal.sub(total_paid(order), total_cost(order))
  end

  def order_number(%Order{id: id}), do: :io_lib.format("~9..0B", [id])

  def pending?(%Order{status: :pending}), do: true
  def pending?(%Order{}), do: false

  def per_item_order_supply_cost(%Order{supply_cost: supply_cost, listings: listings}) do
    Decimal.div(supply_cost, Decimal.new(Enum.count(listings)))
  end

  def per_item_shipping_cost(%Order{shipping_cost: shipping_cost, listings: listings}) do
    Decimal.div(shipping_cost, Decimal.new(Enum.count(listings)))
  end

  def per_item_shipping_price(%Order{shipping_price: shipping_price, listings: listings}) do
    Decimal.div(shipping_price, Decimal.new(Enum.count(listings)))
  end

  def processed?(%Order{status: :processed}), do: true
  def processed?(%Order{}), do: false

  def shipped?(%Order{status: :shipped}), do: true
  def shipped?(%Order{}), do: false

  def total_cost(%Order{selling_fees: selling_fees, shipping_cost: shipping_cost} = order) do
    selling_fees
    |> Decimal.add(Order.total_supply_cost(order))
    |> Decimal.add(shipping_cost)
    |> Decimal.add(Order.total_stamp_cost(order))
  end

  def total_paid(%Order{item_price: item_price, shipping_price: shipping_price}), do: Decimal.add(item_price, shipping_price)

  def total_stamp_cost(%Order{listings: listings}) do
    Enum.reduce(listings, Decimal.new(0), &(Decimal.add(Stamp.total_cost(&1.stamp), &2)))
  end

  def total_supply_cost(%Order{listings: listings, supply_cost: supply_cost}) do
    listings
    |> Enum.reduce(Decimal.new(0), &(Decimal.add(&1.individual_supply_cost, &2)))
    |> Decimal.add(supply_cost)
  end
end
