defmodule Kamansky.Services.Ebay.Listing do
  import SweetXml

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
end