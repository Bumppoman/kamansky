require Logger

defmodule Kamansky.Services.Hipstamp.Listing do
  alias Kamansky.Attachments.Attachment
  alias Kamansky.Operations.Administration
  alias Kamansky.Sales.Listings.{Listing, Platforms}
  alias Kamansky.Sales.Listings.Platforms.HipstampListing
  alias Kamansky.Services.Hipstamp
  alias Kamansky.Stamps.Stamp

  @spec get(%Listing{hipstamp_listing: %HipstampListing{}}) :: %{required(String.t) => any}
  def get(%Listing{hipstamp_listing: %HipstampListing{hipstamp_id: hipstamp_id}}) do
    "/listings/#{hipstamp_id}"
    |> Hipstamp.get!()
    |> Map.get(:body)
    |> Map.get("results")
  end

  @spec list(Listing.t) :: {:ok, HipstampListing.t}
  def list(%Listing{stamp: stamp} = listing, opts \\ %{}) do

    %{
      listing_type: :product,
      name: title(listing, opts),
      description: description(listing, opts),
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
    |> then(&Hipstamp.post!("/listings", &1))
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
  end

  @spec maybe_remove_listing(Listing.t) :: :ok
  def maybe_remove_listing(%Listing{} = listing) do
    with %HipstampListing{hipstamp_id: hipstamp_id} = hipstamp_listing <- Platforms.get_hipstamp_listing_for_listing(listing) do
      Hipstamp.delete!("/listings/#{hipstamp_id}")
      Platforms.delete_external_listing(hipstamp_listing)
      Logger.info("Deleted Hipstamp listing for listing #{listing.id}")
    end

    :ok
  end

  @spec suggested_description(Stamp.t) :: String.t
  def suggested_description(%Stamp{} = stamp), do: Stamp.sale_description(stamp) <> ".\n\n" <> Administration.get_setting!(:hipstamp_description)

  @spec suggested_title(Stamp.t) :: String.t
  def suggested_title(%Stamp{} = stamp) do
    with description <- Stamp.sale_description(stamp) do
      binary_part(description, 0, min(79, byte_size(description)))
    end
  end

  @spec description(Listing.t, map) :: String.t
  defp description(%Listing{stamp: %Stamp{}}, %{"description" => description}), do: description
  defp description(%Listing{stamp: %Stamp{} = stamp}, _opts), do: suggested_description(stamp)

  @spec title(Listing.t, map) :: String.t
  defp title(%Listing{stamp: %Stamp{}}, %{"title" => title}), do: title
  defp title(%Listing{stamp: %Stamp{} = stamp}, _opts), do: suggested_title(stamp)
end
