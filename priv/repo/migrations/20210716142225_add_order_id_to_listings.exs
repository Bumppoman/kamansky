defmodule Kamansky.Repo.Migrations.AddOrderIdToListings do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :order_id, references(:orders)
    end
  end
end
