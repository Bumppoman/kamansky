defmodule Kamansky.Repo.Migrations.AddInitialsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :initials, :string
    end
  end
end
