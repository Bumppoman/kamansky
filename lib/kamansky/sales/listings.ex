defmodule Kamansky.Sales.Listings do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing

  def add_listing_to_order(%Listing{} = listing, attrs) do
    listing
    |> Listing.changeset(attrs)
    |> Ecto.Changeset.put_change(:status, :sold)
    |> Repo.update()
  end

  def change_listing(%Listing{} = listing, attrs \\ %{}) do
    Listing.changeset(listing, attrs)
  end

  def count_listings(status) do
    Listing
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  def create_listing(stamp, attrs) do
    stamp
    |> Ecto.build_assoc(:listing)
    |> Listing.changeset(attrs)
    |> Repo.insert()
  end

  @impl true
  def exclude_from_count(query), do: query

  def find_row_number_for_listing(status, options) do
    Listing
    |> where(status: ^status)
    |> join(:left, [l], s in assoc(l, :stamp))
    |> select([l, s], {l.id, row_number() |> over(order_by: [{:asc, s.scott_number}])})
    |> Repo.all
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

  def get_listing!(id), do: Repo.get!(Listing, id)

  def list_listings(status, params) do
    listings_query =
      Listing
      |> where(status: ^status)
      |> join(:left, [l], s in assoc(l, :stamp))
      |> preload([l, s], [stamp: s])

    Paginate.list(Listings, listings_query, params)
  end

  def list_sold_listings(params) do

    # Can't join listings twice for some reason so it's separately loaded
    listings =
      Listing
      |> where(status: :sold)
      |> join(:left, [l], s in assoc(l, :stamp))
      |> join(:left, [l], o in assoc(l, :order))
      |> preload([l, s, o], [stamp: s, order: {o, :listings}])

    Paginate.list(Listings, listings, params)
  end

  def mark_listing_sold(%Listing{} = listing, order_id: order_id, sale_price: sale_price) do
    listing
    |> Ecto.Changeset.change(order_id: order_id, sale_price: sale_price)
    |> Repo.update()
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search) do
    where(query, [l, s],
      ilike(s.scott_number, ^"%#{search}%")
    )
  end

  @impl true
  @spec sort(Ecto.Query.t, %{column: integer, direction: :asc | :desc}) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, [l, s], {^direction, s.scott_number})
  def sort(query, %{column: 1, direction: direction}), do: order_by(query, [l, s, o], {^direction, o.ordered_at})

  def total_listings_price(status) do
    Listing
    |> where(status: ^status)
    |> Repo.aggregate(:sum, :listing_price)
  end

  def update_listing_selling_fees(%Listing{} = listing, selling_fees) do
    listing
    |> Ecto.Changeset.change(selling_fees: selling_fees)
    |> Repo.update()
  end
end
