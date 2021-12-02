defmodule Kamansky.Repo.Migrations.AddPurchaseIdToStamps do
  use Ecto.Migration

  def change do
    alter table(:stamps) do
      add :purchase_id, references(:purchases)
    end
  end
end
