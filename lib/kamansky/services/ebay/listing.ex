defmodule Kamansky.Services.Ebay.Listing do
  import SweetXml

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Sales.Listings
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference
  alias Kamansky.Services.Ebay

  @spec get_listing(String.t) :: any
  def get_listing(listing_id) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <GetItem xmlns="urn:ebay:apis:eBLBaseComponents">
      #{Ebay.requester_credentials()}
      <ItemID>#{listing_id}</ItemID>
    </GetItem>
    """
    |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "GetItem"}]))
    |> Map.get(:body)
    |> xpath(~x"//ListingStatus/text()")
  end

  #@spec list(Listing.t) :: :ok
  def list(%Listing{stamp: stamp} = listing) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <AddItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
      #{Ebay.requester_credentials()}
      <Item>
        <SKU>#{stamp.inventory_key}</SKU>
        <Title>#{title(stamp)}</Title>
        <Description>
          <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet" />
          <div style="width:75% !important; margin:0 auto;">
            <h1>Bumppoman Stamps</h1>
            <p>#{Stamp.sale_description(stamp)}. Item ##{stamp.inventory_key}.</p>
            <p>See photo for detail. Actual stamp shown. Bumppoman Stamps does not use stock images on any listing...we wouldn't buy for our collection sight unseen so why should you?! &nbsp;<span style="font-size:1rem;">Ships with USPS First Class.</span></p>
          </div>
        </Description>
        <PrimaryCategory>
          <CategoryID>#{category_id(stamp)}</CategoryID>
        </PrimaryCategory>
        <StartPrice>#{Decimal.sub(listing.listing_price, "0.01")}</StartPrice>
        <Currency>USD</Currency>
        <ListingDuration>Days_7</ListingDuration>
        <PictureDetails>
          <PictureURL>#{Attachment.full_path(stamp.front_photo)}</PictureURL>
          <PictureURL>#{Attachment.full_path(stamp.rear_photo)}</PictureURL>
        </PictureDetails>
        <Country>US</Country>
        <PostalCode>13760</PostalCode>
        <ItemSpecifics>
          <NameValueList>
            <Name>Certification</Name>
            <Value>Uncertified</Value>
          </NameValueList>
          <NameValueList>
            <Name>Color</Name>
            <Value>#{String.capitalize(stamp.stamp_reference.color)}</Value>
          </NameValueList>
          <NameValueList>
            <Name>Denomination</Name>
            <Value>#{denomination(stamp)}</Value>
          </NameValueList>
          <NameValueList>
            <Name>Grade</Name>
            <Value>#{grade(stamp)}</Value>
          </NameValueList>
          <NameValueList>
            <Name>Place of Origin</Name>
            <Value>United States</Value>
          </NameValueList>
          <NameValueList>
            <Name>Quality</Name>
            <Value>#{quality(stamp)}</Value>
          </NameValueList>
          <NameValueList>
            <Name>Year of Issue</Name>
            <Value>#{StampReference.era(stamp.stamp_reference)}</Value>
          </NameValueList>
        </ItemSpecifics>
        <ShippingDetails>
          <ShippingType>Flat</ShippingType>
          <ShippingServiceOptions>
            <FreeShipping>#{Decimal.gt?(listing.listing_price, "14.99")}</FreeShipping>
            <ShippingServiceCost>#{shipping_cost(listing)}</ShippingServiceCost>
          </ShippingServiceOptions>
        </ShippingDetails>
      </Item>
    </AddItemRequest>
    """
    |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "AddItem"}]))
    |> Map.get(:body)
    |> parse(dtd: :none)
  end

  @spec list_active_listings_with_bids :: [%{required(:bid_count) => String.t, required(:item_id) => String.t}]
  def list_active_listings_with_bids do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <GetSellerListRequest xmlns="urn:ebay:apis:eBLBaseComponents">
      #{Ebay.requester_credentials()}
      <EndTimeFrom>#{DateTime.to_iso8601(DateTime.utc_now())}</EndTimeFrom>
      <EndTimeTo>#{DateTime.to_iso8601(DateTime.add(DateTime.utc_now(), 604800))}</EndTimeTo>
      <GranularityLevel>Fine</GranularityLevel>
      <Pagination>
        <EntriesPerPage>200</EntriesPerPage>
      </Pagination>
      <OutputSelector>BidCount</OutputSelector>
      <OutputSelector>ItemID</OutputSelector>
    </GetSellerListRequest>
    """
    |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "GetSellerList"}]))
    |> Map.get(:body)
    |> parse(dtd: :none)
    |> xpath(
      ~x"//Item"l,
      bid_count: ~x".//BidCount/text()"s,
      item_id: ~x".//ItemID/text()"s
    )
    |> Enum.filter(&(String.to_integer(&1.bid_count) > 0))
  end

  @spec maybe_remove_listing(Listing.t) :: :ok | {:error, Ecto.Changeset.t} | {:ok, Listing.t}
  def maybe_remove_listing(%Listing{ebay_id: ebay_id} = listing) when not is_nil(ebay_id) do
    remove_listing(listing)
    Listings.remove_ebay_id_from_listing(listing)
  end
  def maybe_remove_listing(%Listing{} = _listing), do: :ok

  @spec remove_listing(Listing.t) :: :ok
  def remove_listing(%Listing{} = listing) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <EndItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
      #{Ebay.requester_credentials()}
      <ItemID>#{listing.ebay_id}</ItemID>
      <EndingReason>NotAvailable</EndingReason>
    </EndItemRequest>
    """
    |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "EndItem"}]))
    |> Map.get(:body)
    |> parse(dtd: :none)
    |> xpath(~x"//EndTime"s)

    :ok
  end

  @spec category_id(Stamp.t) :: integer
  def category_id(%Stamp{stamp_reference: %StampReference{issue_type: :airmail}}), do: 680
  def category_id(%Stamp{stamp_reference: %StampReference{issue_type: issue_type}}) when issue_type != :standard, do: 681
  def category_id(%Stamp{stamp_reference: %StampReference{year_of_issue: year_of_issue}}) when year_of_issue < 1900, do: 676
  def category_id(%Stamp{stamp_reference: %StampReference{year_of_issue: year_of_issue}}) when year_of_issue >= 1900 and year_of_issue < 1941, do: 3461
  def category_id(%Stamp{}), do: 679

  @spec denomination(Stamp.t) :: String.t
  def denomination(%Stamp{stamp_reference: %StampReference{denomination: denomination}}) do
    cond do
      Decimal.lt?(denomination, 1) -> "#{Decimal.to_integer(Decimal.mult(denomination, 100))} Cent"
      Decimal.eq?(denomination, 1) -> "1 Dollar"
      Decimal.eq?(denomination, 2) -> "2 Dollar"
      Decimal.eq?(denomination, 5) -> "5 Dollar"
      true -> denomination
    end
  end

  @spec grade(Stamp.t) :: String.t
  def grade(%Stamp{grade: grade}) when grade in 70..74, do: "F/VF (Fine/Very Fine)"
  def grade(%Stamp{grade: grade}) when grade in 75..79, do: "VF (Very Fine)"
  def grade(%Stamp{grade: grade}) when grade in 80..84, do: "VF/XF (Very Fine/Extremely Fine)"
  def grade(%Stamp{grade: grade}) when grade in 85..89, do: "XF (Extremely Fine)"
  def grade(%Stamp{grade: grade}) when grade in 90..94, do: "XF/S (Extremely Fine/Superb"
  def grade(%Stamp{grade: grade}) when grade in 95..97, do: "Superb"
  def grade(%Stamp{grade: grade}) when grade in 98..100, do: "Gem"
  def grade(%Stamp{}), do: "Ungraded"

  @spec quality(Stamp.t) :: String.t
  def quality(%Stamp{gum_disturbance: true}), do: "Original Gum"
  def quality(%Stamp{hinged: true}), do: "Mint Hinged"
  def quality(%Stamp{hinge_remnant: true}), do: "Hinge Remaining"
  def quality(%Stamp{no_gum: true}), do: "Mint No Gum/MNG"
  def quality(%Stamp{}), do: "Mint Never Hinged/MNH"

  @spec shipping_cost(Listing.t) :: String.t
  def shipping_cost(%Listing{listing_price: listing_price}) do
    if Decimal.lt?(listing_price, 15), do: "1.00", else: "0.00"
  end

  @spec title(Stamp.t) :: String.t
  defp title(%Stamp{} = stamp) do
    with description <- Stamp.sale_description(stamp) do
      cond do
        String.length(description) <= 63 -> "Bumppoman Stamps " <> description
        String.length(description) in 64..71 -> "Bumppoman " <> description
        true -> "Bumppoman " <> String.slice(description, 0, 70)
      end
    end
  end
end
