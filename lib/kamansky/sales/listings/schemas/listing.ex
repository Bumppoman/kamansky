defmodule Kamansky.Sales.Listings.Listing do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Sales.Listings.Platforms.{EbayListing, HipstampListing}
  alias Kamansky.Stamps.Stamp

  @type t :: Ecto.Schema.t | %Listing{
    listing_price: Decimal.t,
    sale_price: Decimal.t,
    status: atom
  }

  schema "listings" do
    field :listing_price, :decimal
    field :sale_price, :decimal
    field :status, Ecto.Enum, values: [pending: 1, active: 2, bid: 3, sold: 4, removed: 5, lost: 6], default: :active

    field :ebay, :boolean, virtual: true, default: false
    field :ebay_description, :string, virtual: true
    field :ebay_title, :string, virtual: true
    field :hipstamp, :boolean, virtual: true, default: true
    field :hipstamp_description, :string, virtual: true
    field :hipstamp_title, :string, virtual: true

    timestamps(updated_at: false)

    belongs_to :stamp, Kamansky.Stamps.Stamp
    belongs_to :order, Kamansky.Sales.Orders.Order

    has_one :ebay_listing, Kamansky.Sales.Listings.Platforms.EbayListing
    has_one :hipstamp_listing, Kamansky.Sales.Listings.Platforms.HipstampListing
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(%Listing{} = listing, attrs) do
    listing
    |> cast(attrs, [:ebay, :ebay_description, :ebay_title, :hipstamp, :hipstamp_description, :hipstamp_title, :listing_price, :order_id, :sale_price])
    |> validate_required([])
  end

  @spec display_column_for_sorting(integer) :: atom | keyword
  def display_column_for_sorting(column) do
    [[dynamic([l, s], s.scott_number), {:asc, dynamic([l], l.id)}]]
    |> Enum.at(column)
  end

  @spec ebay?(t) :: boolean
  def ebay?(%Listing{ebay_listing: %EbayListing{}}), do: true
  def ebay?(%Listing{}), do: false

  @spec hipstamp?(t) :: boolean
  def hipstamp?(%Listing{hipstamp_listing: %HipstampListing{}}), do: true
  def hipstamp?(%Listing{}), do: false

  @spec internal_only?(t) :: boolean
  def internal_only?(%Listing{ebay_listing: nil, hipstamp_listing: nil}), do: true
  def internal_only?(%Listing{}), do: false

  @spec net_profit(t) :: Decimal.t
  def net_profit(%Listing{} = listing), do: Decimal.sub(listing.sale_price, Stamp.total_cost(listing.stamp))
end
