defmodule Kamansky.Sales.Orders do
  @sort_columns [
    :id,
    [quote(do: dynamic([o, c], c.name)), {:desc, :id}],
    :ordered_at
  ]
  use Kamansky.Paginate

  import Ecto.Query, warn: false
  import Kamansky.Helpers, only: [filter_query_for_year: 3, filter_query_for_year_and_month: 4]

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order

  @spec change_new_order(Order.t, map) :: Ecto.Changeset.t
  def change_new_order(%Order{} = order, attrs \\ %{}), do: Order.full_changeset(order, attrs)

  @spec change_order(Order.t, map) :: Ecto.Changeset.t
  def change_order(%Order{} = order, attrs \\ %{}), do: Order.changeset(order, attrs)

  @spec count_orders(:all | [{:month, integer} | {:status, atom}]) :: integer
  def count_orders(:all), do: Repo.aggregate(Order, :count, :id)

  def count_orders(year: year, month: month) do
    Order
    |> filter_query_for_year_and_month(year, month, :ordered_at)
    |> Repo.aggregate(:count, :id)
  end

  @spec count_orders(:completed | :pending | :processed | :shipped, String.t | nil) :: integer
  def count_orders(status, search) do
    Order
    |> maybe_search(search)
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  @spec count_orders_for_customer(pos_integer, String.t | nil) :: integer
  def count_orders_for_customer(customer_id, search \\ nil) do
    Order
    |> maybe_search(search)
    |> where(customer_id: ^customer_id)
    |> Repo.aggregate(:count, :id)
  end

  @spec create_order(map) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def create_order(attrs) do
    %Order{}
    |> Order.full_changeset(attrs)
    |> Ecto.Changeset.put_change(:ordered_at, DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.insert()
  end

  @spec find_row_number_for_order(:completed | :pending | :processed | :shipped, pos_integer, integer, Paginate.sort_direction) :: integer | nil
  def find_row_number_for_order(status, order_id, sort, direction) do
    Order
    |> where(status: ^status)
    |> Paginate.find_row_number(order_id, Order.display_column_for_sorting(sort), direction)
  end

  @spec get_or_initialize_order(keyword) :: Order.t
  def get_or_initialize_order(params) do
    Order
    |> where(^params)
    |> limit(1)
    |> Repo.one()
    |> case do
      %Order{} = order -> order
      nil -> struct(Order, params)
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
    |> maybe_determine_platform()
  end

  @spec get_order_detail(integer) :: Order.t
  def get_order_detail(id) do
    with (
      listings_query <-
        Listing
        |> join(:left, [l], s in assoc(l, :stamp))
        |> join(:left, [l, s], sr in assoc(s, :stamp_reference))
        |> join(:left, [l, s, sr], fp in assoc(s, :front_photo))
        |> join(:left, [l, s, ..., fp], rp in assoc(s, :rear_photo))
        |> order_by([l, s], s.scott_number)
        |> preload([l, s, sr, fp, rp], [stamp: {s, [stamp_reference: sr, front_photo: fp, rear_photo: rp]}])
    ) do
      Order
      |> where(id: ^id)
      |> join(:left, [o], c in assoc(o, :customer))
      |> preload([o, c], customer: c, listings: ^listings_query)
      |> Repo.one()
    end
  end

  @spec initialize_order(keyword) :: Order.t | nil
  def initialize_order(params) do
    Order
    |> where(^params)
    |> limit(1)
    |> Repo.one()
    |> case do
      %Order{} -> nil
      nil -> struct(Order, params)
    end
  end

  @spec insert_order(Order.t, map) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def insert_order(order, attrs) do
    order
    |> change_order(attrs)
    |> Repo.insert()
  end

  @spec list_orders(keyword) :: [Order.t]
  def list_orders(params \\ []) do
    Order
    |> where(^params)
    |> Repo.all()
  end

  @spec list_orders(:display, atom, Paginate.params) :: [Order.t]
  def list_orders(:display, status, params) do
    with(
      listings_query <-
        Listing
        |> join(:left, [l], s in assoc(l, :stamp))
        |> preload([l, s], [stamp: s])
    ) do
      Order
      |> maybe_search(params.search)
      |> where(status: ^status)
      |> join(:left, [o], c in assoc(o, :customer))
      |> preload([o, c, l, s], [customer: c, listings: ^listings_query])
      |> then(&Paginate.list(Orders, &1, params))
    end
  end

  @spec list_orders_for_customer(pos_integer, Paginate.params) :: [Order.t]
  def list_orders_for_customer(customer_id, params) do
    Order
    |> maybe_search(params.search)
    |> where(customer_id: ^customer_id)
    |> join(:left, [o], c in assoc(o, :customer))
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

  @spec most_recent_order(:hipstamp | :ebay) :: Order.t | nil
  def most_recent_order(:ebay) do
    Order
    |> where([o], not is_nil(o.ebay_id))
    |> order_by(desc: :ordered_at)
    |> limit(1)
    |> Repo.one()
  end

  def most_recent_order(:hipstamp) do
    Order
    |> where([o], not is_nil(o.hipstamp_id))
    |> order_by(desc: :ordered_at)
    |> limit(1)
    |> Repo.one()
  end

  @spec total_gross_profit(atom | keyword) :: Decimal.t
  def total_gross_profit(:all) do
    Order
    |> select([o], sum(o.item_price + o.shipping_price))
    |> Repo.one()
  end

  def total_gross_profit(year: year, month: month) do
    Order
    |> filter_query_for_year_and_month(year, month, :ordered_at)
    |> select([o], sum(o.item_price + o.shipping_price))
    |> Repo.one()
  end

  def total_gross_profit(year: year) do
    Order
    |> filter_query_for_year(year, :ordered_at)
    |> select([o], sum(o.item_price + o.shipping_price))
    |> Repo.one()
  end

  @spec total_net_profit(atom | keyword) :: Decimal.t
  def total_net_profit(:all), do: total_net_profit_calculation(Order)

  def total_net_profit(year: year, month: month) do
    Order
    |> filter_query_for_year_and_month(year, month, :ordered_at)
    |> total_net_profit_calculation()
  end

  def total_net_profit(year: year) do
    Order
    |> filter_query_for_year(year, :ordered_at)
    |> total_net_profit_calculation()
  end

  @spec total_stamps_in_orders(atom | [year: integer, month: integer]) :: integer
  def total_stamps_in_orders(:all), do: stamps_in_orders_calculation(Order)

  def total_stamps_in_orders(year: year, month: month) do
    Order
    |> filter_query_for_year_and_month(year, month, :ordered_at)
    |> stamps_in_orders_calculation()
  end

  @spec update_order(Order.t, map) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.full_changeset(attrs)
    |> Repo.update()
  end

  @spec update_order_fees(Order.t, [selling_fees: Decimal.t, shipping_cost: Decimal.t]) :: {:ok, Order.t} | {:error, Ecto.Changeset.t}
  def update_order_fees(%Order{} = order, selling_fees: selling_fees, shipping_cost: shipping_cost) do
    order
    |> Ecto.Changeset.change(selling_fees: selling_fees, shipping_cost: shipping_cost)
    |> Repo.update()
  end

  @spec maybe_determine_platform(Order.t | nil) :: Order.t | nil
  defp maybe_determine_platform(nil), do: nil
  defp maybe_determine_platform(%Order{} = order), do: %{order | platform: Order.platform(order)}

  @spec maybe_search(Ecto.Queryable.t, String.t | nil) :: Ecto.Queryable.t
  defp maybe_search(query, nil), do: query
  defp maybe_search(query, search), do: where(query, [o], ilike(fragment("CAST(? AS text)", o.id), ^"%#{search}%"))

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
    |> Enum.reduce(0, &(Decimal.add(Order.net_profit(&1), &2)))
  end

  @spec with_stamps_query(Ecto.Queryable.t) :: Ecto.Query.t
  defp with_stamps_query(query) do
    query
    |> join(:left, [o], l in assoc(o, :listings))
    |> join(:left, [o, l], s in assoc(l, :stamp))
  end
end
