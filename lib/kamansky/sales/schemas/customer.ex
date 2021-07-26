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
    field :hipstamp_id, :integer
    field :ebay_id, :integer

    field :amount_spent_ytd, :decimal, virtual: true
    field :most_recent_order_date, :utc_datetime, virtual: true

    has_many :orders, Kamansky.Sales.Orders.Order
  end

  def changeset(%Customer{} = customer, attrs) do
    customer
    |> cast(attrs,
      [
        :city, :email, :hipstamp_id, :name,
        :state, :street_address, :zip
      ]
    )
  end

  def formatted_email(%Customer{email: email}) when email in [nil, ""], do: "---"
  def formatted_email(%Customer{email: email}), do: email

  def full_address(%Customer{} = customer) do
    [
      customer.street_address,
      customer.city,
      "#{customer.state} #{customer.zip}"
    ]
    |> Enum.join(", ")
  end
end
