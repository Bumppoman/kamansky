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
    ebay_id: String.t,
    hipstamp_id: integer,
    processed_at: DateTime.t,
    shipped_at: DateTime.t,
    completed_at: DateTime.t,
    gross_profit: Decimal.t,
    net_profit: Decimal.t,
    platform: atom,
    stamp_cost: Decimal.t,
    customer: Kamansky.Sales.Customers.Customer.t,
    listings: [Kamansky.Sales.Listings.Listing.t]
  }

  schema "orders" do
    field :ordered_at, :utc_datetime
    field :item_price, :decimal
    field :shipping_price, :decimal
    field :selling_fees, :decimal
    field :shipping_cost, :decimal
    field :status, Ecto.Enum,
      values: [pending: 1, processed: 2, shipped: 3, completed: 4],
      default: :pending
    field :ebay_id, :string
    field :hipstamp_id, :integer
    field :processed_at, :utc_datetime
    field :shipped_at, :utc_datetime
    field :completed_at, :utc_datetime

    field :existing_customer, :boolean, virtual: true, default: true
    field :gross_profit, :decimal, virtual: true
    field :net_profit, :decimal, virtual: true
    field :platform, Ecto.Enum, values: [:hipstamp, :ebay], virtual: true, default: :hipstamp
    field :stamp_cost, :decimal, virtual: true

    belongs_to :customer, Kamansky.Sales.Customers.Customer, on_replace: :update
    has_many :listings, Kamansky.Sales.Listings.Listing
  end

  @doc guard: true
  defguard is_ebay(order) when not is_nil(order.ebay_id)

  @doc guard: true
  defguard is_hipstamp(order) when not is_nil(order.hipstamp_id)

  @spec changeset(Order.t, map) :: Ecto.Changeset.t
  def changeset(order, attrs) do
    order
    |> cast(attrs,
      [
        :ordered_at, :item_price, :shipping_price, :selling_fees,
        :shipping_cost, :status, :ebay_id, :hipstamp_id,
        :processed_at, :shipped_at, :completed_at, :existing_customer,
        :customer_id, :platform
      ]
    )
    |> validate_required([])
  end

  @spec completed?(Order.t) :: boolean
  def completed?(%Order{status: :completed}), do: true
  def completed?(%Order{}), do: false

  @spec display_column_for_sorting(integer) :: atom
  def display_column_for_sorting(column) do
    [:id, :ordered_at]
    |> Enum.at(column)
  end

  @spec formatted_platform(Order.t) :: String.t
  def formatted_platform(%Order{} = order) when is_ebay(order), do: "eBay"
  def formatted_platform(%Order{} = order) when is_hipstamp(order), do: "Hipstamp"

  @spec full_changeset(t, map) :: Ecto.Changeset.t
  def full_changeset(%Order{} = order, attrs) do
    cast(
      order,
      attrs,
      [
        :customer_id, :ebay_id, :existing_customer, :hipstamp_id,
        :item_price, :platform, :selling_fees, :shipping_cost,
        :shipping_price
      ]
    )
  end

  @spec net_profit(Order.t) :: Decimal.t
  def net_profit(%Order{} = order), do: Decimal.sub(total_paid(order), total_cost(order))

  @spec order_number(Order.t) :: charlist
  def order_number(%Order{id: id}), do: :io_lib.format("~9..0B", [id])

  @spec pending?(Order.t) :: boolean
  def pending?(%Order{status: :pending}), do: true
  def pending?(%Order{}), do: false

  @spec platform(Order.t) :: :ebay | :hipstamp
  def platform(%Order{} = order) when is_ebay(order), do: :ebay
  def platform(%Order{} = order) when is_hipstamp(order), do: :hipstamp

  @spec platform_id(Order.t) :: integer | String.t
  def platform_id(%Order{} = order) when is_ebay(order), do: order.ebay_id
  def platform_id(%Order{} = order) when is_hipstamp(order), do: order.hipstamp_id

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

  @spec total_items(Order.t) :: pos_integer()
  def total_items(%Order{listings: listings}), do: Enum.count(listings)

  @spec total_paid(Order.t) :: Decimal.t
  def total_paid(%Order{item_price: item_price, shipping_price: shipping_price}), do: Decimal.add(item_price, shipping_price)

  @spec total_stamp_cost(Order.t) :: Decimal.t
  def total_stamp_cost(%Order{listings: listings}), do: Enum.reduce(listings, 0, &Decimal.add(Stamp.total_cost(&1.stamp), &2))
end
