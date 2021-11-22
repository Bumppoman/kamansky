defmodule Kamansky.Repo.Migrations.RecreateSubscriptions do
  use Ecto.Migration

  def change do
    drop table(:subscriptions)

    create table(:subscriptions, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :topic, :integer, primary_key: true
      add :last_read, :utc_datetime
    end
  end
end
