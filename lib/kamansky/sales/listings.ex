defmodule Kamansky.Sales.Listings do
  import Ecto.Query, warn: false

  use Kamansky.Paginate

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Services
  alias Kamansky.Stamps

  @spec add_listing_to_order(Listing.t, map) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def add_listing_to_order(%Listing{stamp_id: stamp_id} = listing, attrs \\ %{}) do
    with(
      {:ok, _stamp} <-
        stamp_id
        |> Stamps.get_stamp!()
        |> Stamps.mark_stamp_as_sold(),
      {:ok, listing} <-
        listing
        |> change_listing(attrs)
        |> Ecto.Changeset.put_change(:status, :sold)
        |> Repo.update(),
      :ok <- Services.Listing.delist_any_external_listings(listing)
    ) do
      listing
    end
  end

  @spec change_listing(Listing.t, map) :: Ecto.Changeset.t
  def change_listing(%Listing{} = listing, attrs \\ %{}), do: Listing.changeset(listing, attrs)

  @spec count_listings(atom, String.t | nil) :: integer
  def count_listings(status, search \\ nil) do
    Listing
    |> join(:left, [l], s in assoc(l, :stamp))
    |> maybe_search(search)
    |> where([l], l.status == ^status)
    |> Repo.aggregate(:count)
  end

  @spec count_listings_with_bids(String.t | nil) :: integer
  def count_listings_with_bids(search \\ nil) do
    Listing
    |> maybe_search(search)
    |> join(:inner, [l], el in assoc(l, :ebay_listing))
    |> where([l, el], el.bid_count > 0)
    |> Repo.aggregate(:count)
  end

  @spec create_listing(Kamansky.Stamps.Stamp.t, map) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def create_listing(stamp, attrs) do
    stamp
    |> Ecto.build_assoc(:listing)
    |> Listing.changeset(attrs)
    |> Repo.insert()
  end

  @spec find_row_number_for_listing(atom, pos_integer, integer, Paginate.sort_direction) :: integer | nil
  def find_row_number_for_listing(status, listing_id, sort, direction) do
    Listing
    |> where(status: ^status)
    |> join(:left, [l], s in assoc(l, :stamp))
    |> Paginate.find_row_number(
      listing_id,
      Listing.display_column_for_sorting(sort),
      direction
    )
  end

  @spec get_listing!(integer) :: Listing.t
  def get_listing!(id), do: Repo.get!(Listing, id)

  @spec get_listing_by_ebay_id(pos_integer) :: Listing.t
  def get_listing_by_ebay_id(ebay_id) do
    Listing
    |> join(:left, [l], s in assoc(l, :stamp))
    |> join(:inner, [l], el in assoc(l, :ebay_listing))
    |> where([l, ..., el], el.ebay_id == ^ebay_id)
    |> preload([l, s, el], [stamp: s, ebay_listing: el])
    |> Repo.one()
  end

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

  @spec list_active_listings(Paginate.params) :: [Listing.t]
  def list_active_listings(params) do
    Listing
    |> where(status: :active)
    |> join(:left, [l], s in assoc(l, :stamp))
    |> join(:left, [l], el in assoc(l, :ebay_listing))
    |> join(:left, [l], hl in assoc(l, :hipstamp_listing))
    |> maybe_search(params.search)
    |> preload([l, s, el, hl], [stamp: s, ebay_listing: el, hipstamp_listing: hl])
    |> then(&Paginate.list(Listings, &1, params))
  end

  @spec list_listings_for_order(pos_integer) :: [Listing.t]
  def list_listings_for_order(order_id) do
    Listing
    |> where(order_id: ^order_id)
    |> Repo.all()
  end

  @spec list_listings_with_bids(Paginate.params) :: [Listing.t]
  def list_listings_with_bids(params) do
    Listing
    |> join(:left, [l], s in assoc(l, :stamp))
    |> join(:inner, [l], el in assoc(l, :ebay_listing))
    |> where([l, ..., el], el.bid_count > 0)
    |> maybe_search(params.search)
    |> preload([l, s, el], stamp: s, ebay_listing: el)
    |> then(&Paginate.list(Listings, &1, params))
  end

  @spec list_sold_listings(Paginate.params) :: [%Listing{status: :sold}]
  def list_sold_listings(params) do
    Listing
    |> where(status: :sold)
    |> join(:left, [l], s in assoc(l, :stamp))
    |> join(:left, [l], o in assoc(l, :order))
    |> maybe_search(params.search)
    |> preload([l, s, o], [stamp: s, order: {o, :listings}])  # Can't join listings twice for some reason so it's separately loaded
    |> then(&Paginate.list(Listings, &1, params))
  end

  @spec mark_listing_sold(Listing.t, [order_id: integer, sale_price: Decimal.t]) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def mark_listing_sold(%Listing{} = listing, order_id: order_id, sale_price: sale_price) do
    listing
    |> Ecto.Changeset.change(order_id: order_id, sale_price: sale_price, status: :sold)
    |> Repo.update()
  end

  @spec median_price_data_for_sold_listings :: map
  def median_price_data_for_sold_listings do
    for class <- Stamps.Stamp.grade_classes(), into: %{} do
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
  end

  @impl true
  @spec sort(Ecto.Query.t, Kamansky.Paginate.sort) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {^direction, s.scott_number},
        {:asc, s.inventory_key}
      ]
    )
  end

  def sort(query, %{action: :active, column: 1, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {^direction, s.scott_number},
        {^direction, s.inventory_key}
      ]
    )
  end

  def sort(query, %{action: :sold, column: 1, direction: direction}) do
    order_by(
      query,
      [l, s, o],
      [
        {^direction, o.ordered_at},
        {:asc, s.inventory_key}
      ]
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

  def sort(query, %{action: :sold, column: 2, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {^direction, :sale_price},
        {:asc, s.inventory_key}
      ]
    )
  end

  def sort(query, %{action: :active, column: 3, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {^direction, :listing_price},
        {:asc, s.inventory_key}
      ]
    )
  end

  def sort(query, %{action: :sold, column: 3, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {^direction, s.cost + s.purchase_fees},
        {:asc, s.inventory_key}
      ]
    )
  end

  def sort(query, %{action: :active, column: 4, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {^direction, fragment("DATE(?)", l.inserted_at)},
        {:asc, s.inventory_key}
      ]
    )
  end

  def sort(query, %{action: :bid, column: 4, direction: direction}) do
    order_by(
      query,
      [l, s, el],
      [
        {^direction, el.end_time},
        {:asc, s.scott_number}
      ]
    )
  end

  def sort(query, %{action: :sold, column: 4, direction: direction}) do
    order_by(
      query,
      [l, s],
      [
        {^direction, l.sale_price - (s.cost + s.purchase_fees)},
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

  @spec update_listing_selling_fees(Listing.t, Decimal.t) :: {:ok, Listing.t} | {:error, Ecto.Changeset.t}
  def update_listing_selling_fees(%Listing{} = listing, selling_fees) do
    listing
    |> Ecto.Changeset.change(selling_fees: selling_fees)
    |> Repo.update()
  end

  @spec maybe_search(Ecto.Queryable.t, String.t | nil) :: Ecto.Queryable.t
  defp maybe_search(query, nil), do: query
  defp maybe_search(query, search), do: where(query, [l, s], ilike(s.scott_number, ^"%#{search}%"))
end
