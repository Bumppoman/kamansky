defmodule Kamansky.Stamps.StampReferences do
  import Ecto.Query, warn: false
  import Kamansky.Helpers, only: [get_value_for_ecto_enum: 3]

  @sort_columns [
    :scott_number,
    [quote(do: dynamic([sr, ..., l], count(l.id)))],
    [quote(do: dynamic([sr], fragment("conversion_percentage"))), {:desc, quote(do: dynamic([sr, ..., l], count(l.id)))}, {:asc, :scott_number}],
    [quote(do: dynamic([sr], fragment("median_sale_price")))],
    [quote(do: dynamic([sr, s, l], sum(l.sale_price - s.cost - s.purchase_fees)))]
  ]
  use Kamansky.Paginate

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @spec change_stamp_reference(StampReference.t, map) :: Ecto.Changeset.t
  def change_stamp_reference(%StampReference{} = stamp_reference, attrs \\ %{}), do: StampReference.changeset(stamp_reference, attrs)

  @spec count_stamp_references(String.t | nil) :: integer
  def count_stamp_references(search \\ nil) do
    StampReference
    |> maybe_search(search)
    |> Repo.aggregate(:count, :id)
  end

  @spec count_stamp_references_missing_from_collection(String.t | nil) :: integer
  def count_stamp_references_missing_from_collection(search \\ nil) do
    missing_from_collection_query()
    |> maybe_search(search)
    |> Repo.aggregate(:count, :id)
  end

  @spec count_stamp_references_with_sales(String.t | nil) :: integer
  def count_stamp_references_with_sales(search \\ nil) do
    with_sales_query()
    |> maybe_search(search)
    |> distinct([sr], sr.id)
    |> Repo.aggregate(:count, :id)
  end

  @spec create_stamp_reference(map) :: {:ok, StampReference.t} | {:error, Ecto.Changeset.t}
  def create_stamp_reference(attrs) do
    %StampReference{}
    |> StampReference.changeset(attrs)
    |> Repo.insert()
  end

  @spec find_row_number_for_stamp_reference(pos_integer, integer, Paginate.sort_direction) :: integer | nil
  def find_row_number_for_stamp_reference(stamp_reference_id, sort, direction) do
    Paginate.find_row_number(StampReference, stamp_reference_id, StampReference.display_column_for_sorting(sort), direction)
  end

  @spec get_stamp_reference!(integer) :: StampReference.t
  def get_stamp_reference!(id), do: Repo.get!(StampReference, id)

  @spec get_or_initialize_stamp_reference(String.t) :: StampReference.t
  def get_or_initialize_stamp_reference(""), do: %StampReference{}
  def get_or_initialize_stamp_reference(id), do: get_stamp_reference!(String.to_integer(id))

  @spec list_stamp_references(Paginate.params) :: [StampReference.t]
  def list_stamp_references(params) do
    StampReference
    |> maybe_search(params.search)
    |> then(&Paginate.list(StampReferences, &1, params))
  end

  @spec list_stamp_references_missing_from_collection(Paginate.params) :: [StampReference.t]
  def list_stamp_references_missing_from_collection(params) do
    missing_from_collection_query()
    |> maybe_search(params.search)
    |> then(&Paginate.list(StampReferences, &1, params))
  end

  @spec list_stamp_references_with_sales(Paginate.params) :: [StampReference.t]
  def list_stamp_references_with_sales(params) do
    with(
      stamps <-
        with_sales_query()
        |> maybe_search(params.search)
        |> join(:left, [sr, s], l in assoc(s, :listing))
        |> group_by([sr, s, l], sr.id)
        |> select(
          [sr, s, l],
          %{
            conversion_percentage:
              fragment(
                "((CAST(? AS FLOAT) / (SELECT COUNT(id) FROM stamps WHERE status IN (?, ?) AND scott_number = ?)) * 100) AS conversion_percentage",
                count(l.id),
                ^get_value_for_ecto_enum(Stamp, :status, :listed),
                ^get_value_for_ecto_enum(Stamp, :status, :sold),
                sr.scott_number
              ),
            median_sale_price: fragment("PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ?) AS median_sale_price", l.listing_price),
            scott_number: sr.scott_number,
            total_profit: sum(l.sale_price - s.cost - s.purchase_fees),
            total_sold: count(l.id)
          }
        )
    ) do
      Paginate.list(StampReferences, stamps, params)
    end
  end

  @spec update_stamp_reference(StampReference.t, map) :: {:ok, StampReference.t} | {:error, Ecto.Changeset.t}
  def update_stamp_reference(%StampReference{} = stamp_reference, attrs) do
    stamp_reference
    |> StampReference.changeset(attrs)
    |> Repo.update()
  end

  @spec maybe_search(Ecto.Queryable.t, String.t | nil) :: Ecto.Queryable.t
  defp maybe_search(query, nil), do: query
  defp maybe_search(query, search) do
    query
    |> where([s], ilike(s.scott_number, ^"#{search}%"))
    |> or_where([s], ilike(s.title, ^"%#{search}%"))
  end

  @spec missing_from_collection_query :: Ecto.Query.t
  defp missing_from_collection_query do
    StampReference
    |> join(:left, [sr], s in Stamp, on: sr.scott_number == s.scott_number and s.status == :collection)
    |> where([..., s], is_nil(s.scott_number))
  end

  @spec with_sales_query :: Ecto.Query.t
  defp with_sales_query, do: join(StampReference, :inner, [sr], s in Stamp, on: sr.scott_number == s.scott_number and s.status == :sold)
end
