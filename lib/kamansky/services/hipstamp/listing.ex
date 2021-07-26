defmodule Kamansky.Services.Hipstamp.Listing do
  alias Kamansky.Attachments.Attachment
  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Services.Hipstamp
  alias Kamansky.Stamps.Stamp

  def get(%Listing{hipstamp_id: id}) do
    with {:ok, response} <- Hipstamp.get("/listings/#{id}") do
      hd(response.body["results"])
    end
  end

  @spec list(Listing.t) :: :ok
  def list(%Listing{stamp: stamp} = listing) do
    body = %{
      listing_type: :product,
      name: Stamp.sale_description(stamp),
      description: Stamp.sale_description(stamp) <> ".\n\n" <> "See photo for detail. Actual stamp shown.  Bumppoman Stamps does not use stock images on any listing...we wouldn't buy for our collection sight unseen so why should you?!\n\nAdditional stamps in the same order ship for 10¢ each, unless otherwise marked.  We strive for SAME or NEXT DAY shipping.",
      category_id: 12,
      private_id: stamp.inventory_key,
      quantity: 1,
      buyout_price: listing.listing_price,
      images: Enum.join(
        [
          Attachment.full_path(stamp.front_photo),
          Attachment.full_path(stamp.rear_photo)
        ],
        "||"
      ),
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
      &Listings.update_hipstamp_listing(
        listing,
        %{
          inserted_at:
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
end
