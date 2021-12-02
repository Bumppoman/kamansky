defmodule Kamansky.Repo.Migrations.CreateStampReferences do
  use Ecto.Migration

  def change do
    create table(:stamp_references) do
      add :scott_number, :string
      add :denomination, :decimal
      add :year_of_issue, :integer
      add :color, :string
      add :issue_type, :integer
      add :commemorative, :boolean
      add :title, :string
      add :synopsis, :string
    end
  end
end
