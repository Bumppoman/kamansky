defmodule Kamansky.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :user_id, references(:users)
      add :body, :string
      add :status, :integer

      timestamps()
    end
  end
end
