defmodule Kamansky.Services.Stamp do
  alias Kamansky.Sales.Listings
  alias Kamansky.Services.Hipstamp

  def list_stamp_for_sale(listing_id, %{"hipstamp" => hipstamp}) do
    with listing <- Listings.get_listing_to_list(listing_id) do
      if hipstamp, do: Hipstamp.Listing.list(listing)

      :ok
    end
  end
end
