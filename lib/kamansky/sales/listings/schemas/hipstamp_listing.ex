defmodule Kamansky.Sales.Listings.Platforms.HipstampListing do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @primary_key {:hipstamp_id, :integer, []}

  @type t :: Ecto.Schema.t | %HipstampListing{
    hipstamp_id: pos_integer,
    listing_id: pos_integer,
    start_time: DateTime.t
  }

  schema "hipstamp_listing" do
    field :start_time, :utc_datetime

    belongs_to :listing, Kamansky.Sales.Listings.Listing
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(%HipstampListing{} = hipstamp_listing, attrs) do
    cast(hipstamp_listing, attrs, [:hipstamp_id, :start_time])
  end
end
