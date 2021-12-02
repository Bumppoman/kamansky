defmodule Kamansky.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :name, :string
      add :email, :string
      add :street_address, :string
      add :city, :string
      add :state, :string
      add :zip, :string
    end

    alter table(:orders) do
      add :customer_id, references(:customers)
    end
  end
end
