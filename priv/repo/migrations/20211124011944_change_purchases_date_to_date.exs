defmodule Kamansky.Repo.Migrations.ChangePurchasesDateToDate do
  use Ecto.Migration

  def change do
    alter table(:purchases) do
      modify :date, :date
    end
  end
end
