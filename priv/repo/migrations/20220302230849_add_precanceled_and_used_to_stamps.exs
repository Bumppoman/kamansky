defmodule Kamansky.Repo.Migrations.AddPrecanceledAndUsedToStamps do
  use Ecto.Migration

  def change do
    alter table(:stamps) do
      add :precanceled, :boolean, default: false
      add :used, :boolean, default: false
    end
  end
end
