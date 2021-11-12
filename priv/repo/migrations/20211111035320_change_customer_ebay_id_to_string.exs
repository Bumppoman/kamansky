defmodule Kamansky.Repo.Migrations.ChangeCustomerEbayIdToString do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      modify :ebay_id, :string
    end
  end
end
