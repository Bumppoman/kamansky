defmodule Kamansky.Repo.Migrations.AddCountryToCustomer do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :country, :string
    end
  end
end
