defmodule Kamansky.Sales.Orders.Order do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset

  alias __MODULE__
  alias Kamansky.Stamps.Stamp

  @type t :: Ecto.Schema.t | %Order{
    ordered_at: DateTime.t,
    item_price: Decimal.t,
    shipping_price: Decimal.t,
    selling_fees: Decimal.t,
    shipping_cost: Decimal.t,
    status: atom,
    hipstamp_id: integer,
    processed_at: DateTime.t,
    shipped_at: DateTime.t,
    completed_at: DateTime.t,
    customer: Kamansky.Sales.Customers.Customer.t,
    listings: [Kamansky.Sales.Listings.Listing.t]
  }

  schema "orders" do
    field(:ordered_at, :utc_datetime)
    field(:item_price, :decimal)
    field(:shipping_price, :decimal)
    field(:selling_fees, :decimal)
    field(:shipping_cost, :decimal)

    field(:status, Ecto.Enum,
      values: [pending: 1, finalized: 2, processed: 3, shipped: 4, completed: 5],
      default: :pending
    )

    field(:hipstamp_id, :integer)
    field(:processed_at, :utc_datetime)
    field(:shipped_at, :utc_datetime)
    field(:completed_at, :utc_datetime)

    belongs_to(:customer, Kamansky.Sales.Customers.Customer)
    has_many(:listings, Kamansky.Sales.Listings.Listing)
  end

  @spec changeset(Order.t, map) :: Ecto.Changeset.t
  def changeset(order, attrs) do
    order
    |> cast(attrs, [])
    |> validate_required([])
  end

  @spec completed?(Order.t) :: boolean
  def completed?(%Order{status: :completed}), do: true
  def completed?(%Order{}), do: false

  @spec net_profit(Order.t) :: Decimal.t
  def net_profit(%Order{} = order) do
    Decimal.sub(total_paid(order), total_cost(order))
  end

  @spec new_changeset(Order.t, map) :: Ecto.Changeset.t
  def new_changeset(order, attrs) do
    order
    |> cast(attrs, [:item_price, :selling_fees, :shipping_cost, :shipping_price])
    |> cast_assoc(:customer, with: &Kamansky.Sales.Customers.Customer.changeset/2)
  end

  @spec order_number(Order.t) :: charlist
  def order_number(%Order{id: id}), do: :io_lib.format("~9..0B", [id])

  @spec pending?(Order.t) :: boolean
  def pending?(%Order{status: :pending}), do: true
  def pending?(%Order{}), do: false

  @spec processed?(Order.t) :: boolean
  def processed?(%Order{status: :processed}), do: true
  def processed?(%Order{}), do: false

  @spec shipped?(Order.t) :: boolean
  def shipped?(%Order{status: :shipped}), do: true
  def shipped?(%Order{}), do: false

  @spec total_cost(Order.t) :: Decimal.t
  def total_cost(%Order{selling_fees: selling_fees, shipping_cost: shipping_cost} = order) do
    selling_fees
    |> Decimal.add(shipping_cost)
    |> Decimal.add(Order.total_stamp_cost(order))
  end

  @spec total_paid(Order.t) :: Decimal.t
  def total_paid(%Order{item_price: item_price, shipping_price: shipping_price}),
    do: Decimal.add(item_price, shipping_price)

  @spec total_stamp_cost(Order.t) :: Decimal.t
  def total_stamp_cost(%Order{listings: listings}) do
    Enum.reduce(listings, Decimal.new(0), &Decimal.add(Stamp.total_cost(&1.stamp), &2))
  end
end
