defmodule Kamansky.Stamps.StampReferences do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Stamps.StampReferences.StampReference

  def change_stamp_reference(%StampReference{} = stamp_reference, attrs \\ %{}) do
    StampReference.changeset(stamp_reference, attrs)
  end

  def count_stamp_references do
    Repo.aggregate(StampReference, :count, :id)
  end

  def create_stamp_reference(attrs) do
    %StampReference{}
    |> StampReference.changeset(attrs)
    |> Repo.insert()
  end

  def find_row_number_for_stamp_reference(options) do
    StampReference
    |> select(
      [s],
      {
        s.id,
        row_number()
        |> over(
          order_by:
            [
              {
                ^options[:sort][:direction],
                field(s, ^StampReference.display_column_for_sorting(options[:sort][:column]))
              }
            ]
          )
      }
    )
    |> Repo.all()
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

  def get_stamp_reference!(id), do: Repo.get!(StampReference, id)

  def list_stamp_references(params) do
    Paginate.list(StampReferences, from(StampReference), params)
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
  @spec sort(Ecto.Query.t, %{column: integer, direction: :asc | :desc}) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :scott_number})

  def update_stamp_reference(%StampReference{} = stamp_reference, attrs) do
    stamp_reference
    |> StampReference.changeset(attrs)
    |> Repo.update()
  end
end
