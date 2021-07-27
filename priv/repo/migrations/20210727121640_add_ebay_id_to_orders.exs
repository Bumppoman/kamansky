defmodule Kamansky.Repo.Migrations.AddEbayIdToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :ebay_id, :string
    end
  end
end
