defmodule Kamansky.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    create table(:attachments) do
      add :filename, :string
      add :size, :bigint
      add :content_type, :string
      add :hash, :string, size: 64

      timestamps()
    end

    create index(:attachments, [:hash])
  end
end
