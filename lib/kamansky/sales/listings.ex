defmodule Kamansky.Sales.Listings do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps

  @spec add_listing_to_order(Listing.t, map) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def add_listing_to_order(%Listing{stamp_id: stamp_id} = listing, attrs \\ %{}) do
    with(
      {:ok, _stamp} <-
        stamp_id
        |> Stamps.get_stamp!()
        |> Stamps.mark_stamp_as_sold()
    ) do
      listing
      |> change_listing(attrs)
      |> Ecto.Changeset.put_change(:status, :sold)
      |> Repo.update()
    end
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
    |> select([l, s], {l.id, over(row_number(), order_by: [{:asc, s.scott_number}, {:asc, l.id}])})
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

  def median_price_data_for_sold_listings do
    for class <- Stamps.Stamp.grade_classes() do
      {
        class.name,
        Listing
        |> join(:left, [l], s in assoc(l, :stamp))
        |> where(status: :sold)
        |> where([l, s], s.grade >= ^class.start and s.grade <= ^class.finish)
        |> select([l, s], fragment("PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ?)", l.sale_price))
        |> Repo.one()
      }
    end
    |> Enum.into(%{})
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search), do: where(query, [l, s], ilike(s.scott_number, ^"%#{search}%"))

  def sold_listing_data_by_era do
    for era <- Stamps.StampReferences.StampReference.eras() do
      with(
        era_sold_listings_query <-
          Listing
          |> join(:left, [l], s in assoc(l, :stamp))
          |> join(:left, [l, s], sr in assoc(s, :stamp_reference))
          |> where(status: :sold)
          |> where([l, s, sr], sr.year_of_issue >= ^era.start and sr.year_of_issue <= ^era.finish),
        total_sold <-
          Listing
          |> where(status: :sold)
          |> Repo.aggregate(:count)
      ) do
        {
          era.name,
          %{
            total_sales_income: Repo.aggregate(era_sold_listings_query, :sum, :sale_price),
            percentage_of_total_sales: round((Repo.aggregate(era_sold_listings_query, :count) / total_sold) * 100)
          }
        }
      end
    end
  end

  @impl true
  @spec sort(Ecto.Query.t, Kamansky.Paginate.sort) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}) do
    order_by(
      query,
      [l, s],
      [{^direction, s.scott_number}, {:asc, l.id}]
    )
  end

  def sort(query, %{action: :active, column: 1, direction: direction}) do
    order_by(
      query,
      [l, s],
      [{^direction, s.scott_number}, {^direction, s.inventory_key}]
    )
  end

  def sort(query, %{action: :sold, column: 1, direction: direction}) do
    order_by(
      query,
      [l, s, o],
      [{^direction, o.ordered_at}, {:asc, s.scott_number}, {:asc, l.id}]
    )
  end

  def sort(query, %{action: :active, column: 2, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {^String.to_existing_atom(Atom.to_string(direction) <> "_nulls_last"), s.grade},
        {:asc, s.scott_number}
      ]
    )
  end

  def sort(query, %{action: :sold, column: 2, direction: direction}), do: order_by(query, {^direction, :sale_price})
  def sort(query, %{action: :active, column: 3, direction: direction}), do: order_by(query, {^direction, :listing_price})

  def sort(query, %{action: :sold, column: 3, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {
          ^direction,
          s.cost + s.purchase_fees
        },
        {:asc, s.scott_number}
      ]
    )
  end

  def sort(query, %{action: :active, column: 4, direction: direction}), do: order_by(query, {^direction, :inserted_at})

  def sort(query, %{action: :sold, column: 4, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {
          ^direction,
          l.sale_price - (s.cost + s.purchase_fees)
        },
        {:asc, s.scott_number}
      ]
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
