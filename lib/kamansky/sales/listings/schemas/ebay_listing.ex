defmodule Kamansky.Sales.Listings.Platforms.EbayListing do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @primary_key {:ebay_id, :string, []}

  @type t :: Ecto.Schema.t | %EbayListing{
    ebay_id: String.t,
    listing_id: pos_integer,
    start_time: DateTime.t,
    end_time: DateTime.t,
    bid_count: integer,
    current_bid: Decimal.t
  }

  schema "ebay_listings" do
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :bid_count, :integer, default: 0
    field :current_bid, :decimal

    field :auction_price, :decimal, virtual: true
    field :buy_it_now_price, :decimal, virtual: true
    field :title, :string, virtual: true

    belongs_to :listing, Kamansky.Sales.Listings.Listing
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(%EbayListing{} = ebay_listing, attrs) do
    cast(
      ebay_listing,
      attrs,
      [
        :auction_price, :bid_count, :buy_it_now_price, :current_bid,
        :ebay_id, :end_time, :listing_id, :start_time, :title
      ]
    )
  end
end
