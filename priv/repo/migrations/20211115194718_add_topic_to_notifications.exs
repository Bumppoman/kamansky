defmodule Kamansky.Repo.Migrations.AddTopicToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :topic, :integer
    end
  end
end
