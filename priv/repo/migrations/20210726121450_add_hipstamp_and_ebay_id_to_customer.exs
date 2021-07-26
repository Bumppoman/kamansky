defmodule Kamansky.Repo.Migrations.AddHipstampAndEbayIdToCustomer do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :hipstamp_id, :integer
      add :ebay_id, :integer
    end
  end
end
