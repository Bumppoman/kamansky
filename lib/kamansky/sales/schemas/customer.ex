defmodule Kamansky.Sales.Customers.Customer do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @type t :: Ecto.Schema.t | %Customer{
    name: String.t,
    email: String.t,
    street_address: String.t,
    city: String.t,
    state: String.t,
    zip: String.t,
    country: String.t,
    hipstamp_id: integer,
    ebay_id: integer,
    amount_spent_ytd: Decimal.t,
    most_recent_order_date: DateTime.t,
    orders: [Kamansky.Sales.Orders.Order.t]
  }

  schema "customers" do
    field :name, :string
    field :email, :string
    field :street_address, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :country, :string
    field :hipstamp_id, :integer
    field :ebay_id, :integer

    field :amount_spent_ytd, :decimal, virtual: true
    field :most_recent_order_date, :utc_datetime, virtual: true

    has_many :orders, Kamansky.Sales.Orders.Order
  end

  @spec changeset(Customer.t, map) :: Ecto.Changeset.t
  def changeset(%Customer{} = customer, attrs) do
    customer
    |> cast(attrs,
      [
        :city, :country, :email, :hipstamp_id,
        :name, :state, :street_address, :zip
      ]
    )
  end

  @spec display_column_for_sorting(integer) :: atom
  def display_column_for_sorting(column) do
    [:id]
    |> Enum.at(column)
  end

  @spec formatted_email(Customer.t) :: String.t
  def formatted_email(%Customer{email: email}) when email in [nil, ""], do: "---"
  def formatted_email(%Customer{email: email}), do: email

  @spec full_address(Customer.t) :: String.t
  def full_address(%Customer{} = customer) do
    [
      customer.street_address,
      customer.city,
      "#{customer.state} #{customer.zip}"
    ]
    |> Kernel.++(if customer.country, do: [customer.country], else: [])
    |> Enum.join(", ")
  end
end
