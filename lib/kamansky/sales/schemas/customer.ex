defmodule Kamansky.Sales.Customers.Customer do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  schema "customers" do
    field :name, :string
    field :email, :string
    field :street_address, :string
    field :city, :string
    field :state, :string
    field :zip, :string
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:city, :email, :name, :state, :street_address, :zip])
  end
end
