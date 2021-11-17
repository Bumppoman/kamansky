require Logger

defmodule Kamansky.Services.Hipstamp.Listing do
  alias Kamansky.Attachments.Attachment
  alias Kamansky.Sales.Listings.{Listing, Platforms}
  alias Kamansky.Sales.Listings.Platforms.HipstampListing
  alias Kamansky.Services.Hipstamp
  alias Kamansky.Stamps.Stamp

  @spec get(%Listing{hipstamp_id: integer}) :: %{required(String.t) => any}
  def get(%Listing{hipstamp_id: id}) do
    with {:ok, response} <- Hipstamp.get("/listings/#{id}") do
      hd(response.body["results"])
    end
  end

  @spec list(Listing.t) :: :ok
  def list(%Listing{stamp: stamp} = listing) do
    body = %{
      listing_type: :product,
      name: String.slice(Stamp.sale_description(stamp), 0, 79),
      description: Stamp.sale_description(stamp) <> ".\n\n" <> "See photo for detail. Actual stamp shown.  Bumppoman Stamps does not use stock images on any listing...we wouldn't buy for our collection sight unseen so why should you?!\n\nAdditional stamps in the same order ship for 10¢ each, unless otherwise marked.  We strive for SAME or NEXT DAY shipping.",
      category_id: 12,
      private_id: stamp.inventory_key,
      quantity: 1,
      buyout_price: listing.listing_price,
      images:
        [
          Attachment.full_path(stamp.front_photo),
          Attachment.full_path(stamp.rear_photo)
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join("||"),
      item_specifics_01_country: "United States",
      item_specifics_02_catalog_number: stamp.scott_number,
      item_specifics_03_stamp_type: Hipstamp.issue_type(stamp),
      item_specifics_04_condition: Hipstamp.condition(stamp),
      item_specifics_08_centering: Hipstamp.grade(stamp),
      item_specifics_05_stamp_format: Hipstamp.format(stamp),
      item_specifics_07_year_of_issue: stamp.stamp_reference.year_of_issue
    }

    "/listings"
    |> Hipstamp.post!(body)
    |> Map.get(:body)
    |> Map.get("results")
    |> hd()
    |> then(
      &Platforms.create_external_listing(
        :hipstamp,
        listing,
        %{
          start_time:
            &1["created_at"]
            |> NaiveDateTime.from_iso8601!()
            |> DateTime.from_naive!("America/New_York")
            |> DateTime.shift_zone!("Etc/UTC"),
          hipstamp_id: &1["id"]
        }
      )
    )

    :ok
  end

  @spec maybe_remove_listing(Listing.t) :: :ok
  def maybe_remove_listing(%Listing{} = listing) do
    with %HipstampListing{hipstamp_id: hipstamp_id} <- Platforms.get_hipstamp_listing_for_listing(listing) do
      Hipstamp.delete!("/listings/#{hipstamp_id}")
      Logger.info("Deleted Hipstamp listing for listing #{listing.id}")
    end

    :ok
  end
end
