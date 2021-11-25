defmodule Kamansky.Sales.Customers do
  import Ecto.Query, warn: false

  @sort_columns [
    :id,
    nil,
    nil,
    [quote(do: dynamic([c], fragment("amount_spent_ytd")))],
    [quote(do: dynamic([o, ..., lo], lo.ordered_at))]
  ]
  use Kamansky.Paginate

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Customers.Customer
  alias Kamansky.Sales.Orders.Order

  @spec change_customer(Customer.t, map) :: Ecto.Changeset.t
  def change_customer(%Customer{} = customer, attrs \\ %{}), do: Customer.changeset(customer, attrs)

  @spec count_customers(String.t | nil) :: integer
  def count_customers(search \\ nil) do
    Customer
    |> maybe_search(search)
    |> Repo.aggregate(:count, :id)
  end

  @spec find_row_number_for_customer(pos_integer, integer, Paginate.sort_direction) :: integer | nil
  def find_row_number_for_customer(customer_id, sort, direction) do
    Paginate.find_row_number(Customer, customer_id, Customer.display_column_for_sorting(sort), direction)
  end

  @spec get_customer!(integer) :: Customer.t
  def get_customer!(id), do: Repo.get(Customer, id)

  @spec get_customer_detail(pos_integer) :: Customer.t
  def get_customer_detail(id) do
    Customer
    |> where(id: ^id)
    |> Repo.one()
  end

  @spec insert_or_update_customer(Customer.t, map) :: {:ok, Customer.t} | {:error, Ecto.Changeset.t}
  def insert_or_update_customer(%Customer{} = customer, attrs) do
    customer
    |> change_customer(attrs)
    |> Repo.insert_or_update()
  end

  @spec insert_or_update_ebay_customer(map) :: {:ok, Customer.t} | {:error, Ecto.Changeset.t}
  def insert_or_update_ebay_customer(attrs) do
    Customer
    |> where(ebay_id: ^attrs[:ebay_id])
    |> Repo.one()
    |> case do
      %Customer{} = customer -> customer
      nil -> %Customer{}
    end
    |> change_customer(attrs)
    |> Repo.insert_or_update()
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

  @spec list_customers(Paginate.params) :: [Customer.t]
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
        |> maybe_search(params.search)
        |> join(:left, [c], o in assoc(c, :orders))
        |> join(:left_lateral, [c], lo in subquery(most_recent_order))
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

  @spec search_customers_by_name(String.t) :: [Customer.t]
  def search_customers_by_name(name) do
    Customer
    |> where([c], ilike(c.name, ^"%#{String.downcase(name)}%"))
    |> Repo.all()
  end

  @spec update_customer(Customer.t, map) :: {:ok, Customer.t} | {:error, Ecto.Changeset.t}
  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end

  @spec maybe_search(Ecto.Queryable.t, String.t | nil) :: Ecto.Queryable.t
  defp maybe_search(query, nil), do: query
  defp maybe_search(query, search), do: where(query, [c], ilike(c.name, ^"%#{search}%"))
end
