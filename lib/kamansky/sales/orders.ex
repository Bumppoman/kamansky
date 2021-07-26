defmodule Kamansky.Sales.Orders do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order

  @spec change_new_order(Order.t, map) :: Ecto.Changeset.t
  def change_new_order(%Order{} = order, attrs \\ %{}), do: Order.new_changeset(order, attrs)

  @spec change_order(Order.t, map) :: Ecto.Changeset.t
  def change_order(%Order{} = order, attrs \\ %{}), do: Order.changeset(order, attrs)

  @spec count_orders(:all | [{:month, integer} | {:status, atom}]) :: integer
  def count_orders(:all), do: Repo.aggregate(Order, :count, :id)

  def count_orders(month: month) do
    Order
    |> where([o], fragment("DATE_PART('month', ?)", o.ordered_at) == ^month)
    |> Repo.aggregate(:count, :id)
  end

  def count_orders(status: status) do
    Order
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  @spec create_order(map) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def create_order(attrs) do
    %Order{}
    |> Order.new_changeset(attrs)
    |> Ecto.Changeset.put_change(:ordered_at, DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.insert()
  end

  @spec find_row_number_for_order(atom, map) :: integer
  def find_row_number_for_order(status, options) do
    Order
    |> where(status: ^status)
    |> select([o], {o.id, row_number() |> over(order_by: [{:asc, o.id}])})
    |> Repo.all
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

  @spec get_or_initialize_order(keyword) :: Order.t
  def get_or_initialize_order(params) do
    Order
    |> where(^params)
    |> limit(1)
    |> Repo.one()
    |> case do
      %Order{} = order ->
        order
      nil ->
        struct(Order, params)
    end
  end

  @spec get_order!(integer) :: Order.t
  def get_order!(id), do: Repo.get!(Order, id)

  @spec get_order_with_customer!(integer) :: %Order{customer: Kamansky.Sales.Customers.Customer.t}
  def get_order_with_customer!(id) do
    Order
    |> where(id: ^id)
    |> join(:left, [o], c in assoc(o, :customer))
    |> preload([o, c], [customer: c])
    |> Repo.one!()
  end

  @spec get_order_detail(integer)
    :: %Order{
      customer: Kamansky.Sales.Customers.Customer.t,
      listings:
        [
          %Listing{
            stamp: %Kamansky.Stamps.Stamp{
              front_photo: Kamansky.Attachments.Attachment.t,
              rear_photo: Kamansky.Attachments.Attachment.t,
              stamp_reference: Kamansky.Stamps.StampReferences.StampReference.t
            }
          }
        ]
    }
  def get_order_detail(id) do
    with (
      listings_query <-
        Listing
        |> join(:left, [l], s in assoc(l, :stamp))
        |> join(:left, [l, s], sr in assoc(s, :stamp_reference))
        |> join(:inner, [l, s, sr], fp in assoc(s, :front_photo))
        |> join(:inner, [l, s, ..., fp], rp in assoc(s, :rear_photo))
        |> preload([l, s, sr, fp, rp], [stamp: {s, [stamp_reference: sr, front_photo: fp, rear_photo: rp]}])
    ) do
      Order
      |> where(id: ^id)
      |> join(:left, [o], c in assoc(o, :customer))
      |> preload([o, c], customer: c, listings: ^listings_query)
      |> Repo.one()
    end
  end

  @spec insert_or_update_hipstamp_order(Order.t, map) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def insert_or_update_hipstamp_order(order, attrs) do
    order
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert_or_update()
  end

  @spec list_orders(keyword) :: [Order.t]
  def list_orders(params \\ []) do
    Order
    |> where(^params)
    |> Repo.all()
  end

  @spec list_orders(:display, atom, map) :: [Order.t]
  def list_orders(:display, status, params) do
    Order
    |> where(status: ^status)
    |> join(:left, [o], c in  assoc(o, :customer))
    |> join(:left, [o], l in assoc(o, :listings))
    |> join(:left, [o, ..., l], s in assoc(l, :stamp))
    |> preload([o, c, l, s], [customer: c, listings: {l, [stamp: s]}])
    |> then(&Paginate.list(Orders, &1, params))
  end

  @spec list_pending_orders_to_add_listing :: [Order.t]
  def list_pending_orders_to_add_listing do
    Order
    |> where(status: :pending)
    |> join(:left, [o], c in assoc(o, :customer))
    |> preload([o, c], [customer: c])
    |> Repo.all()
  end

  @spec mark_order_as_completed(Order.t) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def mark_order_as_completed(%Order{} = order) do
    order
    |> Ecto.Changeset.change(
      status: :completed,
      completed_at: DateTime.truncate(DateTime.utc_now(), :second)
    )
    |> Repo.update()
  end

  @spec mark_order_as_processed(Order.t) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def mark_order_as_processed(%Order{} = order) do
    order
    |> Ecto.Changeset.change(
      status: :processed,
      processed_at: DateTime.truncate(DateTime.utc_now(), :second)
    )
    |> Repo.update()
  end

  @spec mark_order_as_shipped(Order.t) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def mark_order_as_shipped(%Order{} = order) do
    order
    |> Ecto.Changeset.change(
      status: :shipped,
      shipped_at: DateTime.truncate(DateTime.utc_now(), :second)
    )
    |> Repo.update()
  end

  @spec most_recent_order :: Order.t | nil
  def most_recent_order do
    Order
    |> order_by(desc: :ordered_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search) do
    where(query, [o], ilike(fragment("CAST(id AS text)"), ^"%#{search}%"))
  end

  @impl true
  @spec sort(Ecto.Query.t, %{column: integer, direction: :asc | :desc}) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :id})
  def sort(query, %{column: 1, direction: direction}), do: order_by(query, {^direction, :ordered_at})

  @spec total_gross_profit(:all) :: integer
  def total_gross_profit(:all) do
    Order
    |> select(sum(fragment("item_price + shipping_price")))
    |> Repo.one()
  end

  @spec total_net_profit(atom) :: Decimal.t
  def total_net_profit(:all), do: total_net_profit_calculation(Order)

  @spec total_net_profit([month: integer]) :: Decimal.t
  def total_net_profit(month: month) do
    Order
    |> where([s], fragment("DATE_PART('month', ?)", s.ordered_at) == ^month)
    |> total_net_profit_calculation()
  end

  @spec total_stamps_in_orders(atom | [{:month, integer}]) :: integer
  def total_stamps_in_orders(:all), do: stamps_in_orders_calculation(Order)

  def total_stamps_in_orders(month: month) do
    Order
    |> where([s], fragment("DATE_PART('month', ?)", s.ordered_at) == ^month)
    |> stamps_in_orders_calculation()
  end

  @spec update_order(Order.t, map) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @spec update_order_fees(Order.t, [selling_fees: Decimal.t, shipping_cost: Decimal.t])
    :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def update_order_fees(%Order{} = order, selling_fees: selling_fees, shipping_cost: shipping_cost) do
    order
    |> Ecto.Changeset.change(selling_fees: selling_fees, shipping_cost: shipping_cost)
    |> Repo.update()
  end

  @spec stamps_in_orders_calculation(Ecto.Queryable.t) :: integer
  defp stamps_in_orders_calculation(query) do
    query
    |> with_stamps_query()
    |> select([o, ..., s], count(s.id))
    |> Repo.one()
  end

  @spec total_net_profit_calculation(Ecto.Queryable.t) :: Decimal.t
  defp total_net_profit_calculation(query) do
    query
    |> with_stamps_query()
    |> preload([o, l, s], listings: {l, [stamp: s]})
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &(Decimal.add(Order.net_profit(&1), &2)))
  end

  @spec with_stamps_query(Ecto.Queryable.t) :: Ecto.Query.t
  defp with_stamps_query(query) do
    query
    |> join(:left, [o], l in assoc(o, :listings))
    |> join(:left, [o, l], s in assoc(l, :stamp))
  end
end
