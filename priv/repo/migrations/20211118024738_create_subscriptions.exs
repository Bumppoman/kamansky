defmodule Kamansky.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :user_id, references(:users)
      add :topic, :integer
      add :last_read, :utc_datetime
    end
  end
end
