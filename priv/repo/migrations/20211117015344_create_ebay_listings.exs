defmodule Kamansky.Repo.Migrations.CreateEbayListings do
  use Ecto.Migration

  def change do
    create table(:ebay_listings, primary_key: false) do
      add :ebay_id, :string, primary_key: true
      add :listing_id, references(:listings)
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
    end
  end
end
