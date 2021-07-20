defmodule Kamansky.Repo.Migrations.CreateListings do
  use Ecto.Migration

  def change do
    create table(:listings) do
      add :listing_price, :decimal
      add :individual_supply_cost, :decimal
      add :selling_fees, :decimal
      add :sale_price, :decimal
      add :hipstamp_id, :integer
      add :ebay_id, :integer
      add :status, :integer

      timestamps(updated_at: false)

      add :stamp_id, references("stamps")
    end
  end
end
