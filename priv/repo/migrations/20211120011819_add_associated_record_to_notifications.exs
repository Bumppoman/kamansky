defmodule Kamansky.Repo.Migrations.AddAssociatedRecordToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :associated_record, :integer
    end
  end
end
