defmodule Kamansky.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :topic, :integer
      add :title, :string
      add :body, :string

      timestamps(updated_at: false)
    end
  end
end
