defmodule Kamansky.Sales.Listings.Listing do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset

  alias __MODULE__
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Stamps.Stamp

  schema "listings" do
    field :listing_price, :decimal
    field :sale_price, :decimal
    field :hipstamp_id, :integer
    field :ebay_id, :integer
    field :status, Ecto.Enum, values: [pending: 1, active: 2, removed: 3, sold: 4], default: :active

    timestamps(updated_at: false)

    belongs_to :stamp, Kamansky.Stamps.Stamp
    belongs_to :order, Kamansky.Sales.Orders.Order
  end

  def changeset(%Listing{} = listing, attrs) do
    listing
    |> cast(attrs, [:listing_price, :order_id, :sale_price])
    |> validate_required([])
  end

  def hipstamp_changeset(%Listing{} = listing, attrs) do
    cast(listing, attrs, [:inserted_at, :hipstamp_id])
  end

  def net_profit(%Listing{} = listing) do
    Decimal.sub(listing.sale_price, Stamp.total_cost(listing.stamp))
  end
end
