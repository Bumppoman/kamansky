defmodule Kamansky.Services.Stamp do
  alias Kamansky.Sales.Listings
  alias Kamansky.Services.Hipstamp

  @spec list_stamp_for_sale(pos_integer, %{required(String.t) => boolean, optional(any) => any}) :: :ok
  def list_stamp_for_sale(listing_id, %{"hipstamp" => hipstamp}) do
    with listing <- Listings.get_listing_to_list(listing_id) do
      if String.to_existing_atom(hipstamp), do: Hipstamp.Listing.list(listing)

      :ok
    end
  end
end
