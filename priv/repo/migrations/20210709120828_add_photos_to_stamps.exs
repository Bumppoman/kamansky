defmodule Kamansky.Repo.Migrations.AddPhotosToStamps do
  use Ecto.Migration

  def change do
    alter table(:stamps) do
      add :front_photo_id, references(:attachments)
      add :rear_photo_id, references(:attachments)
    end
  end
end
