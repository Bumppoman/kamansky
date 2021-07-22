defmodule Kamansky.Sales.Orders do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Services.Hipstamp

  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def count_orders(:all) do
    Repo.aggregate(Order, :count, :id)
  end

  def count_orders(month: month) do
    Order
    |> where([o], fragment("DATE_PART('month', ?)", o.ordered_at) == ^month)
    |> Repo.aggregate(:count, :id)
  end

  def count_orders(status) do
    Order
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def find_row_number_for_order(status, options) do
    Order
    |> where(status: ^status)
    |> select([o], {o.id, row_number() |> over(order_by: [{:asc, o.id}])})
    |> Repo.all
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

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

  def get_order!(id), do: Repo.get!(Order, id)

  def get_order_detail(id) do
    listings_query =
      Listing
      |> join(:left, [l], s in assoc(l, :stamp))
      |> join(:left, [l, s], sr in assoc(s, :stamp_reference))
      |> preload([l, s, sr], [stamp: {s, [stamp_reference: sr]}])

    Order
    |> where(id: ^id)
    |> join(:left, [o], c in assoc(o, :customer))
    |> preload([o, c], customer: c, listings: ^listings_query)
    |> Repo.one()
  end

  def insert_or_update_hipstamp_order(order, attrs) do
    order
    |> Order.hipstamp_changeset(attrs)
    |> Repo.insert_or_update()
  end

  def list_orders(status, params) do
    orders =
      Order
      |> where(status: ^status)
      |> preload([o], [listings: :stamp])

    Paginate.list(Orders, orders, params)
  end

  def mark_order_as_completed(%Order{} = order) do
    order
    |> Ecto.Changeset.change(
      status: :completed,
      completed_at: DateTime.truncate(DateTime.utc_now(), :second)
    )
    |> Repo.update()
  end

  def mark_order_as_processed(%Order{} = order) do
    order
    |> Ecto.Changeset.change(
      status: :processed,
      processed_at: DateTime.truncate(DateTime.utc_now(), :second)
    )
    |> Repo.update()
  end

  def mark_order_as_shipped(%Order{} = order) do
    with :ok <- Hipstamp.Order.mark_shipped(order) do
      order
      |> Ecto.Changeset.change(
        status: :shipped,
        shipped_at: DateTime.truncate(DateTime.utc_now(), :second)
      )
      |> Repo.update()
    end
  end

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

  def total_gross_profit(:all) do
    Order
    |> select(sum(fragment("item_price + shipping_price")))
    |> Repo.one()
  end

  def total_net_profit(:all), do: total_net_profit_query(Order)

  def total_net_profit(month: month) do
    Order
    |> where([s], fragment("DATE_PART('month', ?)", s.ordered_at) == ^month)
    |> total_net_profit_query()
  end

  def total_stamps_in_orders(:all), do: stamps_in_orders_query(Order)

  def total_stamps_in_orders(month: month) do
    Order
    |> where([s], fragment("DATE_PART('month', ?)", s.ordered_at) == ^month)
    |> stamps_in_orders_query()
  end

  def update_order_fees(%Order{} = order, selling_fees: selling_fees, shipping_cost: shipping_cost) do
    order
    |> Ecto.Changeset.change(selling_fees: selling_fees, shipping_cost: shipping_cost)
    |> Repo.update()
  end

  defp stamps_in_orders_query(query) do
    query
    |> with_stamps_query()
    |> select([o, ..., s], count(s.id))
    |> Repo.one()
  end

  defp total_net_profit_query(query) do
    query
    |> with_stamps_query()
    |> preload([o, l, s], listings: {l, [stamp: s]})
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &(Decimal.add(Order.net_profit(&1), &2)))
  end

  defp with_stamps_query(query) do
    query
    |> join(:left, [o], l in assoc(o, :listings))
    |> join(:left, [o, l], s in assoc(l, :stamp))
  end
end
