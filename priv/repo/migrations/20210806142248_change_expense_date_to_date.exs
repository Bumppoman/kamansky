defmodule Kamansky.Repo.Migrations.ChangeExpenseDateToDate do
  use Ecto.Migration

  def change do
    alter table(:expenses) do
      modify :date, :date
    end
  end
end
