defmodule Kamansky.Sales.Customers do
  use Kamansky.Paginate

  import Ecto.Query

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Customers.Customer
  alias Kamansky.Sales.Orders.Order

  @spec change_customer(Customer.t, map) :: Ecto.Changeset.t
  def change_customer(%Customer{} = customer, attrs \\ %{}), do: Customer.changeset(customer, attrs)

  @spec count_customers :: integer
  def count_customers, do: Repo.aggregate(Customer, :count, :id)

  @spec find_row_number_for_customer(map) :: integer | nil
  def find_row_number_for_customer(options) do
    Paginate.find_row_number(Customer, Customer.display_column_for_sorting(options[:sort][:column]), options)
  end

  @spec get_customer!(integer) :: Customer.t
  def get_customer!(id), do: Repo.get(Customer, id)

  @spec get_customer_detail(pos_integer) :: Customer.t
  def get_customer_detail(id) do
    Customer
    |> where(id: ^id)
    |> Repo.one()
  end

  @spec insert_or_update_hipstamp_customer(map) :: {:ok, Customer.t} | {:error, Ecto.Changeset.t}
  def insert_or_update_hipstamp_customer(attrs) do
    Customer
    |> where(hipstamp_id: ^attrs[:hipstamp_id])
    |> Repo.one()
    |> case do
      %Customer{} = customer -> customer
      nil -> %Customer{}
    end
    |> change_customer(attrs)
    |> Repo.insert_or_update()
  end

  @spec list_customers(map) :: [Customer.t] | {integer, Customer.t}
  def list_customers(params) do
    with(
      most_recent_order <-
        Order
        |> where([o], parent_as(:customer).id == o.customer_id)
        |> order_by(desc: :ordered_at)
        |> limit(1),
      customers <-
        Customer
        |> from(as: :customer)
        |> join(:left, [c], o in assoc(c, :orders))
        |> join(:inner_lateral, [c], lo in subquery(most_recent_order))
        |> group_by([c, o, lo], [c.id, lo.ordered_at])
        |> select_merge(
          [c, o, lo],
          %{
            amount_spent_ytd: fragment("? AS amount_spent_ytd", sum(o.item_price + o.shipping_price)),
            most_recent_order_date: lo.ordered_at
          }
        )
    ) do
      Paginate.list(Customers, customers, params)
    end
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search), do: where(query, [c], ilike(c.name, ^"%#{search}%"))

  @doc false
  @impl true
  @spec sort(Ecto.Query.t, Kamansky.Paginate.sort) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :id})
  def sort(query, %{column: 3, direction: direction}), do: order_by(query, {^direction, fragment("amount_spent_ytd")})
  def sort(query, %{column: 4, direction: direction}), do: order_by(query, [o, ..., lo], {^direction, lo.ordered_at})

  @spec update_customer(Customer.t, map) :: {:ok, Customer.t} | {:error, Ecto.Changeset.t}
  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end
end
