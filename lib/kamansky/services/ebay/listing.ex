require Logger

defmodule Kamansky.Services.Ebay.Listing do
  import SweetXml

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Sales.Listings.{Listing, Platforms}
  alias Kamansky.Sales.Listings.Platforms.EbayListing
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

  @spec list(Listing.t, map) :: {:ok, EbayListing.t} | {:error, any}
  def list(%Listing{stamp: stamp} = listing, opts \\ %{}) do
    with response <-
      """
      <?xml version="1.0" encoding="utf-8"?>
      <AddItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
        #{Ebay.requester_credentials()}
        <Item>
          <SKU>#{stamp.inventory_key}</SKU>
          <Title>#{title(listing, opts)}</Title>
          <Description>
            <![CDATA[
              <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet" />
              <div style="width: 75% !important; margin: 0 auto;">
                #{description(listing, opts)}
              </div>
            ]]>
          </Description>
          <PrimaryCategory>
            <CategoryID>#{category_id(stamp)}</CategoryID>
          </PrimaryCategory>
          <StartPrice>#{auction_price(listing, opts)}</StartPrice>
          <BuyItNowPrice>#{buy_it_now_price(listing, opts)}</BuyItNowPrice>
          <Currency>USD</Currency>
          <ListingDuration>Days_7</ListingDuration>
          <DispatchTimeMax>3</DispatchTimeMax>
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
          <ReturnPolicy>
            <ReturnsAcceptedOption>ReturnsNotAccepted</ReturnsAcceptedOption>
          </ReturnPolicy>
          <ShippingDetails>
            <ShippingType>Flat</ShippingType>
            <ShippingServiceOptions>
              <ShippingService>USPSFirstClass</ShippingService>
              <FreeShipping>#{free_shipping?(listing, opts)}</FreeShipping>
              <ShippingServiceCost>#{shipping_cost(listing, opts)}</ShippingServiceCost>
            </ShippingServiceOptions>
          </ShippingDetails>
          <Site>US</Site>
        </Item>
      </AddItemRequest>
      """
      |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "AddItem"}]))
      |> Map.get(:body)
    do
      response
      |> parse(dtd: :none)
      |> xpath(
        ~x"//AddItemResponse",
        outcome: ~x".//Ack/text()"s,
        ebay_id: ~x".//ItemID/text()"s,
        start_time: ~x".//StartTime/text()"s,
        end_time: ~x".//EndTime/text()"s
      )
      |> case do
        %{outcome: "Success"} = ebay_listing ->
          Platforms.create_external_listing(
            :ebay,
            listing,
            %{
              ebay_id: ebay_listing.ebay_id,
              start_time: Ebay.parse_time(ebay_listing.start_time),
              end_time: Ebay.parse_time(ebay_listing.end_time)
            }
          )

        _ ->
          Logger.error(response)
          {:error, %{code: :ebay_add_listing_error, dump: response}}
      end
    end
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
      <OutputSelector>CurrentPrice</OutputSelector>
      <OutputSelector>ItemID</OutputSelector>
      <OutputSelector>SKU</OutputSelector>
    </GetSellerListRequest>
    """
    |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "GetSellerList"}]))
    |> Map.get(:body)
    |> parse(dtd: :none)
    |> xpath(
      ~x"//Item"l,
      bid_count: ~x".//BidCount/text()"s,
      current_bid: ~x".//CurrentPrice/text()"s,
      inventory_key: ~x".//SKU/text()"s,
      ebay_id: ~x".//ItemID/text()"s
    )
    |> Enum.filter(&(String.to_integer(&1.bid_count) > 0))
  end

  @spec relist(EbayListing.t) :: {:ok, EbayListing.t} | {:error, %{code: :ebay_relist_listing_error, dump: String.t}}
  def relist(%EbayListing{} = ebay_listing) do
    with response <-
      """
      <?xml version="1.0" encoding="utf-8"?>
      <RelistItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
        #{Ebay.requester_credentials()}
        <Item>
          <ItemID>#{ebay_listing.ebay_id}</ItemID>
        </Item>
      </RelistItemRequest>
      """
      |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "RelistItem"}]))
      |> Map.get(:body)
    do
      response
      |> parse(dtd: :none)
      |> xpath(
        ~x"//RelistItemResponse",
        outcome: ~x".//Ack/text()"s,
        ebay_id: ~x".//ItemID/text()"s,
        start_time: ~x".//StartTime/text()"s,
        end_time: ~x".//EndTime/text()"s
      )
      |> case do
        %{outcome: "Success"} = relisted_listing ->
          Platforms.update_external_listing(
            ebay_listing,
            %{
              ebay_id: relisted_listing.ebay_id,
              start_time: Ebay.parse_time(relisted_listing.start_time),
              end_time: Ebay.parse_time(relisted_listing.end_time)
            }
          )

        _ -> {:error, %{code: :ebay_relist_listing_error, dump: response}}
      end
    end
  end

  @spec maybe_remove_listing(Listing.t) :: {:ebay_removed | :noop, Listing.t}
  def maybe_remove_listing(%Listing{} = listing) do
    with %EbayListing{ebay_id: ebay_id} = ebay_listing <- Platforms.get_ebay_listing_for_listing(listing),
      response <-
        """
        <?xml version="1.0" encoding="utf-8"?>
        <EndItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
          #{Ebay.requester_credentials()}
          <ItemID>#{ebay_id}</ItemID>
          <EndingReason>NotAvailable</EndingReason>
        </EndItemRequest>
        """
        |> then(&Ebay.post!("", &1, headers: [{"X-EBAY-API-CALL-NAME", "EndItem"}]))
        |> Map.get(:body)
    do
      response
      |> parse(dtd: :none)
      |> xpath(
        ~x"//EndItemResponse",
        outcome: ~x".//Ack/text()"s,
        end_time: ~x".//EndTime/text()"s
      )
      |> case do
        %{outcome: "Success"} ->
          Platforms.delete_external_listing(ebay_listing)
          {:ebay_removed, listing}

        _ -> {:error, %{code: :ebay_remove_listing_error, dump: response}}
      end
    else
      _ -> {:noop, listing}
    end
  end

  @spec suggested_auction_price(Listing.t) :: Decimal.t
  def suggested_auction_price(%Listing{listing_price: listing_price}), do: Decimal.sub(listing_price, "0.01")

  @spec suggested_buy_it_now_price(Listing.t) :: Decimal.t
  def suggested_buy_it_now_price(%Listing{listing_price: listing_price}) do
    listing_price
    |> Decimal.mult(2)
    |> Decimal.sub("0.01")
  end

  @spec suggested_description(Stamp.t) :: String.t
  def suggested_description(%Stamp{} = stamp) do
    """
    <h1>Bumppoman Stamps</h1>
    <p>#{Stamp.sale_description(stamp)}.</p>
    <p>See photo for detail. Actual stamp shown. Bumppoman Stamps does not use stock images on any listing...we wouldn't buy for our collection sight unseen so why should you?! Ships with USPS First Class.</p>
    """
  end

  @spec suggested_title(Stamp.t) :: String.t
  def suggested_title(%Stamp{} = stamp) do
    with description <- Stamp.sale_description(stamp) do
      cond do
        String.length(description) <= 63 -> "Bumppoman Stamps " <> description
        String.length(description) in 64..71 -> "Bumppoman " <> description
        true -> "Bumppoman " <> String.slice(description, 0, 70)
      end
    end
  end

  @spec auction_price(Listing.t, map) :: Decimal.t
  defp auction_price(%Listing{}, %{"auction_price" => auction_price}), do: auction_price
  defp auction_price(%Listing{} = listing, _opts), do: suggested_auction_price(listing)

  @spec buy_it_now_price(Listing.t, map) :: Decimal.t
  defp buy_it_now_price(%Listing{}, %{"buy_it_now_price" => buy_it_now_price}), do: buy_it_now_price
  defp buy_it_now_price(%Listing{} = listing, _opts), do: suggested_buy_it_now_price(listing)

  @spec category_id(Stamp.t) :: integer
  defp category_id(%Stamp{stamp_reference: %StampReference{issue_type: :airmail}}), do: 680
  defp category_id(%Stamp{stamp_reference: %StampReference{issue_type: issue_type}}) when issue_type != :standard, do: 681
  defp category_id(%Stamp{stamp_reference: %StampReference{year_of_issue: year_of_issue}}) when year_of_issue < 1900, do: 676
  defp category_id(%Stamp{stamp_reference: %StampReference{year_of_issue: year_of_issue}}) when year_of_issue >= 1900 and year_of_issue < 1941, do: 3461
  defp category_id(%Stamp{}), do: 679

  @spec denomination(Stamp.t) :: String.t
  defp denomination(%Stamp{stamp_reference: %StampReference{denomination: denomination}}) do
    cond do
      Decimal.lt?(denomination, 1) -> "#{Decimal.to_integer(Decimal.mult(denomination, 100))} Cent"
      Decimal.eq?(denomination, 1) -> "1 Dollar"
      Decimal.eq?(denomination, 2) -> "2 Dollar"
      Decimal.eq?(denomination, 5) -> "5 Dollar"
      true -> denomination
    end
  end

  @spec description(Listing.t, map) :: String.t
  defp description(%Listing{stamp: %Stamp{}}, %{"description" => description}), do: description
  defp description(%Listing{stamp: %Stamp{} = stamp}, _opts), do: suggested_description(stamp)

  @spec free_shipping?(Listing.t, map) :: boolean
  defp free_shipping?(%Listing{listing_price: listing_price}, opts), do: Decimal.gt?(Map.get(opts, "auction_price", listing_price), "14.99")

  @spec grade(Stamp.t) :: String.t
  defp grade(%Stamp{grade: grade}) when grade in 70..74, do: "F/VF (Fine/Very Fine)"
  defp grade(%Stamp{grade: grade}) when grade in 75..79, do: "VF (Very Fine)"
  defp grade(%Stamp{grade: grade}) when grade in 80..84, do: "VF/XF (Very Fine/Extremely Fine)"
  defp grade(%Stamp{grade: grade}) when grade in 85..89, do: "XF (Extremely Fine)"
  defp grade(%Stamp{grade: grade}) when grade in 90..94, do: "XF/S (Extremely Fine/Superb"
  defp grade(%Stamp{grade: grade}) when grade in 95..97, do: "Superb"
  defp grade(%Stamp{grade: grade}) when grade in 98..100, do: "Gem"
  defp grade(%Stamp{}), do: "Ungraded"

  @spec quality(Stamp.t) :: String.t
  defp quality(%Stamp{gum_disturbance: true}), do: "Original Gum"
  defp quality(%Stamp{hinged: true}), do: "Mint Hinged"
  defp quality(%Stamp{hinge_remnant: true}), do: "Hinge Remaining"
  defp quality(%Stamp{no_gum: true}), do: "Mint No Gum/MNG"
  defp quality(%Stamp{}), do: "Mint Never Hinged/MNH"

  @spec shipping_cost(Listing.t, map) :: String.t
  defp shipping_cost(%Listing{listing_price: listing_price}, opts) do
    if Decimal.lt?(Map.get(opts, "auction_price", listing_price), 15), do: "1.00", else: "0.00"
  end

  @spec title(Listing.t, map) :: String.t
  defp title(%Listing{stamp: %Stamp{}}, %{"title" => title}), do: title
  defp title(%Listing{stamp: %Stamp{} = stamp}, _opts), do: suggested_title(stamp)
end
