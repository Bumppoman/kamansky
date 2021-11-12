defmodule Kamansky.Repo.Migrations.AddEbayTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ebay_token, :string
    end
  end
end
