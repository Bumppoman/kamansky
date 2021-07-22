defmodule Kamansky.Sales.Customers do
  use Kamansky.Paginate

  import Ecto.Query

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Customers.Customer

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
    customers =
      Customer

    Paginate.list(Customers, customers, params)
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search) do
    where(query, [o], ilike(o.name, ^"%#{search}%"))
  end

  @doc false
  @impl true
  @spec sort(Ecto.Query.t, %{column: integer, direction: :asc | :desc}) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :id})
end
