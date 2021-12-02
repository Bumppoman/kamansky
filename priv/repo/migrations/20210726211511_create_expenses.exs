defmodule Kamansky.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses) do
      add :category, :integer
      add :description, :string
      add :date, :utc_datetime
      add :amount, :decimal
    end
  end
end
