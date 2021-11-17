defmodule Kamansky.Repo.Migrations.AddBidInformationToEbayListings do
  use Ecto.Migration

  def change do
    alter table(:ebay_listings) do
      add :bid_count, :integer
      add :current_bid, :decimal
    end
  end
end
