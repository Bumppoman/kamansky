defmodule Kamansky.Repo.Migrations.RemoveTitleAndBodyFromNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      remove :title
      remove :body
    end
  end
end
