defmodule Kamansky.Repo.Migrations.CreateHipstampListing do
  use Ecto.Migration

  def change do
    create table(:hipstamp_listings, primary_key: false) do
      add :hipstamp_id, :integer, primary_key: true
      add :listing_id, references(:listings)
      add :start_time, :utc_datetime
    end
  end
end
