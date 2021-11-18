defmodule Kamansky.Repo.Migrations.DropNotifications do
  use Ecto.Migration

  def change do
    drop table(:notifications)
  end
end
