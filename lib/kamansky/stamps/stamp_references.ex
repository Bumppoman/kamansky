defmodule Kamansky.Stamps.StampReferences do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @spec change_stamp_reference(StampReference.t, map) :: Ecto.Changeset.t
  def change_stamp_reference(%StampReference{} = stamp_reference, attrs \\ %{}) do
    StampReference.changeset(stamp_reference, attrs)
  end

  @spec count_stamp_references :: integer
  def count_stamp_references, do: Repo.aggregate(StampReference, :count, :id)

  @spec count_stamp_references_missing_from_collection :: integer
  def count_stamp_references_missing_from_collection, do: Repo.aggregate(missing_from_collection_query(), :count, :id)

  @spec count_stamp_references_with_sales :: integer
  def count_stamp_references_with_sales do
    with_sales_query()
    |> distinct([sr], sr.id)
    |> Repo.aggregate(:count, :id)
  end

  @spec create_stamp_reference(map) :: {:ok, StampReference.t} | {:error, Ecto.Changeset.t}
  def create_stamp_reference(attrs) do
    %StampReference{}
    |> StampReference.changeset(attrs)
    |> Repo.insert()
  end

  @spec find_row_number_for_stamp_reference(Paginate.params) :: integer
  def find_row_number_for_stamp_reference(options) do
    Paginate.find_row_number(StampReference, StampReference.display_column_for_sorting(options[:sort][:column]), options)
  end

  @spec find_row_number_for_stamp_reference_missing_from_collection(Paginate.params) :: integer
  def find_row_number_for_stamp_reference_missing_from_collection(options) do
    Paginate.find_row_number(
      missing_from_collection_query(),
      StampReference.display_column_for_sorting(options[:sort][:column]),
      options
    )
  end

  @spec find_row_number_for_stamp_reference_with_sales(Paginate.params) :: integer
  def find_row_number_for_stamp_reference_with_sales(options) do
    Paginate.find_row_number(
      with_sales_query(),
      StampReference.display_column_for_sorting(options[:sort][:column]),
      options
    )
  end

  @spec get_stamp_reference!(integer) :: StampReference.t
  def get_stamp_reference!(id), do: Repo.get!(StampReference, id)

  @spec list_stamp_references(Paginate.params) :: [StampReference.t]
  def list_stamp_references(params), do: Paginate.list(StampReferences, StampReference, params)

  @spec list_stamp_references_missing_from_collection(Paginate.params) :: [StampReference.t]
  def list_stamp_references_missing_from_collection(params) do
    Paginate.list(StampReferences, missing_from_collection_query(), params)
  end

  @spec list_stamp_references_with_sales(Paginate.params) :: [StampReference.t]
  def list_stamp_references_with_sales(params) do
    with(
      stamps <-
        with_sales_query()
        |> join(:left, [sr, s], l in assoc(s, :listing))
        |> group_by([sr, s, l], [sr.scott_number, l.id])
        |> select(
          [sr, s, l],
          %{
            conversion_percentage: (count(l.id) / over(count(l.id))) * 100,
            median_sale_price: fragment("PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ?)", l.listing_price),
            scott_number: sr.scott_number,
            total_profit: sum(l.sale_price - s.cost - s.purchase_fees),
            total_sold: count(l.id)
          }
        )
    ) do
      Paginate.list(StampReferences, stamps, params)
    end
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search) do
    query
    |> where([s], ilike(s.scott_number, ^"#{search}%"))
    |> or_where([s], ilike(s.title, ^"%#{search}%"))
  end

  @impl true
  @spec sort(Ecto.Query.t, Kamansky.Paginate.sort) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :scott_number})
  def sort(query, %{column: 1, direction: direction}), do: order_by(query, [sr, s, l], {^direction, count(l.id)})
  def sort(query, %{column: 3, direction: direction}) do
    order_by(query, [sr, s, l], {^direction, sum(l.sale_price - s.cost - s.purchase_fees)})
  end

  @spec update_stamp_reference(StampReference.t, map) :: {:ok, StampReference.t} | {:error, Ecto.Changeset.t}
  def update_stamp_reference(%StampReference{} = stamp_reference, attrs) do
    stamp_reference
    |> StampReference.changeset(attrs)
    |> Repo.update()
  end

  defp missing_from_collection_query do
    StampReference
    |> join(:left, [sr], s in Stamp, on: sr.scott_number == s.scott_number and s.status == :collection)
    |> where([..., s], is_nil(s.scott_number))
  end

  defp with_sales_query do
    join(StampReference, :inner, [sr], s in Stamp, on: sr.scott_number == s.scott_number and s.status == :sold)
  end
end
