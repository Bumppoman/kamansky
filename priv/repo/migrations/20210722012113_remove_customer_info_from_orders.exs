defmodule Kamansky.Repo.Migrations.RemoveCustomerInfoFromOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      remove :name
      remove :email
      remove :street_address
      remove :city
      remove :state
      remove :zip
    end
  end
end
