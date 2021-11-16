defmodule Kamansky.Repo.Migrations.AddTitleToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :title, :string
    end
  end
end
