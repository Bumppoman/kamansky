defmodule Kamansky.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :ordered_at, :utc_datetime_usec
      add :item_price, :decimal
      add :shipping_price, :decimal
      add :selling_fees, :decimal
      add :shipping_cost, :decimal
      add :supply_cost, :decimal
      add :status, :integer
      add :hipstamp_id, :integer
      add :name, :string
      add :street_address, :string
      add :city, :string
      add :state, :string
      add :zip, :string
      add :email, :string
      add :processed_at, :utc_datetime_usec
      add :shipped_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
    end
  end
end
