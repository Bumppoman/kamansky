defmodule Kamansky.Sales.Listings do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing

  @spec add_listing_to_order(Listing.t, map) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def add_listing_to_order(%Listing{} = listing, attrs \\ %{}) do
    listing
    |> change_listing(attrs)
    |> Ecto.Changeset.put_change(:status, :sold)
    |> Repo.update()
  end

  @spec change_listing(Listing.t, map) :: Ecto.Changeset.t
  def change_listing(%Listing{} = listing, attrs \\ %{}), do: Listing.changeset(listing, attrs)

  @spec count_listings(atom) :: integer | nil
  def count_listings(status) do
    Listing
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  @spec create_listing(Kamansky.Stamps.Stamp.t, map) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def create_listing(stamp, attrs) do
    stamp
    |> Ecto.build_assoc(:listing)
    |> Listing.changeset(attrs)
    |> Repo.insert()
  end

  @impl true
  @spec exclude_from_count(Ecto.Query.t) :: Ecto.Query.t
  def exclude_from_count(query), do: query

  @spec find_row_number_for_listing(atom, map) :: integer
  def find_row_number_for_listing(status, options) do
    Listing
    |> where(status: ^status)
    |> join(:left, [l], s in assoc(l, :stamp))
    |> select([l, s], {l.id, row_number() |> over(order_by: [{:asc, s.scott_number}, {:asc, l.id}])})
    |> Repo.all
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

  @spec get_listing!(integer) :: Listing.t
  def get_listing!(id), do: Repo.get!(Listing, id)

  @spec get_listing_to_list(integer) :: Listing.t | nil
  def get_listing_to_list(id) do
    Listing
    |> where(id: ^id)
    |> join(:inner, [l], s in assoc(l, :stamp))
    |> join(:left, [l, s], sr in assoc(s, :stamp_reference))
    |> join(:left, [l, s], fp in assoc(s, :front_photo))
    |> join(:left, [l, s], rp in assoc(s, :rear_photo))
    |> preload([l, s, sr, fp, rp], [stamp: {s, [front_photo: fp, rear_photo: rp, stamp_reference: sr]}])
    |> Repo.one()
  end

  @spec get_median_listing_price_for_scott_number(integer) :: Decimal.t | nil
  def get_median_listing_price_for_scott_number(scott_number) do
    Listing
    |> join(:left, [l], s in assoc(l, :stamp))
    |> where([l, s], s.scott_number == ^scott_number)
    |> select([l, s], fragment("PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ?)", l.listing_price))
    |> Repo.one()
  end

  @spec list_listings(atom, Kamansky.Paginate.params) :: [Listing.t]
  def list_listings(status, params) do
    Listing
    |> where(status: ^status)
    |> join(:left, [l], s in assoc(l, :stamp))
    |> preload([l, s], [stamp: s])
    |> then(&Paginate.list(Listings, &1, params))
  end

  @spec list_sold_listings(Kamansky.Paginate.params) :: [%Listing{status: :sold}]
  def list_sold_listings(params) do
    Listing
    |> where(status: :sold)
    |> join(:left, [l], s in assoc(l, :stamp))
    |> join(:left, [l], o in assoc(l, :order))
    |> preload([l, s, o], [stamp: s, order: {o, :listings}])  # Can't join listings twice for some reason so it's separately loaded
    |> then(&Paginate.list(Listings, &1, params))
  end

  @spec mark_listing_sold(Listing.t, [order_id: integer, sale_price: Decimal.t])
    :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def mark_listing_sold(%Listing{} = listing, order_id: order_id, sale_price: sale_price) do
    listing
    |> Ecto.Changeset.change(order_id: order_id, sale_price: sale_price, status: :sold)
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
  def sort(query, %{column: 0, direction: direction}) do
    order_by(
      query,
      [l, s],
      [{^direction, s.scott_number}, {:asc, l.id}]
    )
  end

  def sort(query, %{column: 1, direction: direction}) do
    order_by(
      query,
      [l, s, o],
      [{^direction, o.ordered_at}, {:asc, s.scott_number}, {:asc, l.id}]
    )
  end

  @spec total_listings_price(atom) :: float | nil
  def total_listings_price(status) do
    Listing
    |> where(status: ^status)
    |> Repo.aggregate(:sum, :listing_price)
  end

  @spec update_hipstamp_listing(Listing.t, map) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def update_hipstamp_listing(%Listing{} = listing, params) do
    listing
    |> Listing.hipstamp_changeset(params)
    |> Repo.update()
  end

  @spec update_listing_selling_fees(Listing.t, Decimal.t) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def update_listing_selling_fees(%Listing{} = listing, selling_fees) do
    listing
    |> Ecto.Changeset.change(selling_fees: selling_fees)
    |> Repo.update()
  end
end
