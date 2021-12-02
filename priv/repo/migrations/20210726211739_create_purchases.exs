defmodule Kamansky.Repo.Migrations.CreatePurchases do
  use Ecto.Migration

  def change do
    create table(:purchases) do
      add :date, :utc_datetime
      add :description, :string
      add :quantity, :integer
      add :cost, :decimal
      add :purchase_fees, :decimal
    end
  end
end
