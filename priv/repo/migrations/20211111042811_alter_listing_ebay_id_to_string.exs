defmodule Kamansky.Repo.Migrations.AlterListingEbayIdToString do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      modify :ebay_id, :string
    end
  end
end
