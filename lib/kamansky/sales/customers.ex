defmodule Kamansky.Sales.Customers do
  use Kamansky.Paginate

  import Ecto.Query

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Customers.Customer
  alias Kamansky.Sales.Orders.Order

  def change_customer(%Customer{} = customer, attrs \\ %{}), do: Customer.changeset(customer, attrs)

  def count_customers, do: Repo.aggregate(Customer, :count, :id)

  def find_row_number_for_customer(options) do
    Customer
    |> select([c], {c.id, row_number() |> over(order_by: [{:asc, c.id}])})
    |> Repo.all()
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

  def get_customer!(id), do: Repo.get(Customer, id)

  def list_customers(params) do
    most_recent_order =
      Order
      |> where([o], parent_as(:customer).id == o.customer_id)
      |> order_by(desc: :ordered_at)
      |> limit(1)

    customers =
      Customer
      |> from(as: :customer)
      |> join(:left, [c], o in assoc(c, :orders))
      |> join(:inner_lateral, [c], lo in subquery(most_recent_order))
      |> group_by([c, o, lo], [c.id, lo.ordered_at])
      |> select_merge(
        [c, o, lo],
        %{
          amount_spent_ytd: sum(fragment("? + ?", field(o, :item_price), field(o, :shipping_price))),
          most_recent_order_date: lo.ordered_at
        }
      )

    Paginate.list(Customers, customers, params)
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search) do
    where(query, [c], ilike(c.name, ^"%#{search}%"))
  end

  @doc false
  @impl true
  @spec sort(Ecto.Query.t, %{column: integer, direction: :asc | :desc}) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :id})

  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end
end
