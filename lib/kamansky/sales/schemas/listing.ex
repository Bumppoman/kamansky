defmodule Kamansky.Sales.Listings.Listing do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset

  alias __MODULE__
  alias Kamansky.Stamps.Stamp

  @type t :: Ecto.Schema.t | %Listing{
    listing_price: Decimal.t,
    sale_price: Decimal.t,
    hipstamp_id: integer,
    ebay_id: integer,
    status: atom
  }

  schema "listings" do
    field :listing_price, :decimal
    field :sale_price, :decimal
    field :hipstamp_id, :integer
    field :ebay_id, :integer
    field :status, Ecto.Enum, values: [pending: 1, active: 2, removed: 3, sold: 4], default: :active

    field :hipstamp, :boolean, virtual: true, default: true

    timestamps(updated_at: false)

    belongs_to :stamp, Kamansky.Stamps.Stamp
    belongs_to :order, Kamansky.Sales.Orders.Order
  end

  @spec changeset(Listing.t, map) :: Ecto.Changeset.t
  def changeset(%Listing{} = listing, attrs) do
    listing
    |> cast(attrs, [:hipstamp, :listing_price, :order_id, :sale_price])
    |> validate_required([])
  end

  @spec hipstamp_changeset(Listing.t, map) :: Ecto.Changeset.t
  def hipstamp_changeset(%Listing{} = listing, attrs) do
    cast(listing, attrs, [:inserted_at, :hipstamp_id])
  end

  @spec net_profit(Listing.t) :: Decimal.t
  def net_profit(%Listing{} = listing), do: Decimal.sub(listing.sale_price, Stamp.total_cost(listing.stamp))
end
