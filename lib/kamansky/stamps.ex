defmodule Kamansky.Stamps do
  import Ecto.Query, warn: false
  import Kamansky.Helpers, only: [filter_query_for_month: 2]

  @sort_columns [
    [:scott_number, {:asc, :id}],
    [nulls_last: :grade, asc: :id],
    [quote(do: dynamic([s], s.cost + s.purchase_fees)), {:asc, :id}]
  ]
  use Kamansky.Paginate

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @spec change_stamp(Stamp.t, map) :: Ecto.Changeset.t
  def change_stamp(%Stamp{} = stamp, attrs \\ %{}), do: Stamp.changeset(stamp, attrs)

  @spec cost_of_stamps(atom) :: float
  def cost_of_stamps(status) do
    Stamp
    |> where(status: ^status)
    |> select([s], sum(s.cost + s.purchase_fees))
    |> Repo.one()
  end

  @spec cost_of_stamps([atom], integer) :: float
  def cost_of_stamps(status, month) when is_list(status) do
    Stamp
    |> where([s], s.status in ^status)
    |> cost_of_stamps_for_month(month)
  end

  @spec cost_of_stamps(atom, integer) :: float
  def cost_of_stamps(status, month) do
    Stamp
    |> where(status: ^status)
    |> cost_of_stamps_for_month(month)
  end

  @spec count_stamps(atom, String.t | nil) :: integer
  def count_stamps(status, search \\ nil) do
    Stamp
    |> maybe_search(search)
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  @spec count_stamps_in_collection_below_grade(pos_integer, String.t | nil) :: integer
  def count_stamps_in_collection_below_grade(grade, search \\ nil) do
    Stamp
    |> maybe_search(search)
    |> where(status: :collection)
    |> where([s], s.grade < ^grade)
    |> Repo.aggregate(:count, :id)
  end

  @spec count_stamps_purchased([atom], integer) :: integer
  def count_stamps_purchased(status, month) when is_list(status) do
    Stamp
    |> where([s], s.status in ^status)
    |> count_stamps_purchased_in_month(month)
  end

  @spec count_stamps_purchased(atom, integer) :: integer
  def count_stamps_purchased(status, month) do
    Stamp
    |> where(status: ^status)
    |> count_stamps_purchased_in_month(month)
  end

  @spec create_stamp(%{}, Kamansky.Attachments.Attachment.t, Kamansky.Attachments.Attachment.t) :: {:ok, Stamp.t} | {:error, Ecto.Changeset.t}
  def create_stamp(attrs, front_photo, rear_photo) do
    %Stamp{}
    |> Stamp.changeset(attrs)
    |> Ecto.Changeset.change([front_photo: front_photo, rear_photo: rear_photo])
    |> Repo.insert()
  end

  @spec find_row_number_for_stamp(atom, pos_integer, integer, Paginate.sort_direction) :: integer
  def find_row_number_for_stamp(status, item_id, sort, direction) do
    Stamp
    |> where(status: ^status)
    |> Paginate.find_row_number(item_id, Stamp.display_column_for_sorting(sort), direction)
  end

  @spec get_or_initialize_stamp(String.t) :: Stamp.t
  def get_or_initialize_stamp(""), do: %Stamp{}
  def get_or_initialize_stamp(id), do: get_stamp!(String.to_integer(id))

  @spec get_stamp!(integer) :: Stamp.t
  def get_stamp!(id), do: Repo.get!(Stamp, id)

  @spec get_stamp_by_inventory_key(String.t, with_listing: true) :: %Stamp{listing: Listings.Listing.t} | nil
  def get_stamp_by_inventory_key(inventory_key, with_listing: true) do
    Stamp
    |> where(inventory_key: ^inventory_key)
    |> join(:left, [s], l in assoc(s, :listing))
    |> preload([s, l], [listing: l])
    |> Repo.one()
  end

  @spec get_stamp_in_collection_by_scott_number(String.t) :: Stamp.t | nil
  def get_stamp_in_collection_by_scott_number(scott_number) do
    Stamp
    |> where(status: :collection, scott_number: ^scott_number)
    |> join(:left, [s], sr in assoc(s, :stamp_reference))
    |> join(:left, [s], fp in assoc(s, :front_photo))
    |> preload([s, sr, fp], [stamp_reference: sr, front_photo: fp])
    |> Repo.one()
  end

  @spec get_stamp_detail!(integer) :: Stamp.t
  def get_stamp_detail!(id) do
    Stamp
    |> where(id: ^id)
    |> join(:left, [s], l in assoc(s, :listing))
    |> join(:left, [s, l], o in assoc(l, :order))
    |> join(:left, [s], sr in assoc(s, :stamp_reference))
    |> join(:left, [s], fp in assoc(s, :front_photo))
    |> join(:left, [s], rp in assoc(s, :rear_photo))
    |> preload(
      [s, l, o, sr, fp, rp],
      [listing: {l, [order: o]}, stamp_reference: sr, front_photo: fp, rear_photo: rp]
    )
    |> Repo.one!()
  end

  @spec list_sold_stamps_raw :: [Stamp.t]
  def list_sold_stamps_raw do
    Stamp
    |> where(status: :sold)
    |> Repo.all()
  end

  @spec list_stamps(atom, Paginate.params) :: [Stamp.t]
  def list_stamps(status, params) do
    Stamp
    |> maybe_search(params.search)
    |> where(status: ^status)
    |> then(&Paginate.list(Stamps, &1, params))
  end

  @spec list_stamps_in_collection_below_grade(pos_integer, Paginate.params) :: [Stamp.t]
  def list_stamps_in_collection_below_grade(grade, params) do
    Stamp
    |> where(status: :collection)
    |> where([s], s.grade < ^grade)
    |> then(&Paginate.list(Stamps, &1, params))
  end

  @spec mark_stamp_as_sold(Stamp.t) :: {:ok, Stamp.t} | {:error, Ecto.Changeset.t}
  def mark_stamp_as_sold(%Stamp{} = stamp) do
    stamp
    |> Ecto.Changeset.change(status: :sold)
    |> Repo.update()
  end

  @spec move_stamp_to_stock(pos_integer) :: {:ok, %Stamp{status: :stock}} | {:error, Ecto.Changeset.t}
  def move_stamp_to_stock(stamp_id) do
    stamp_id
    |> get_stamp!()
    |> Stamp.changeset(%{})
    |> Ecto.Changeset.put_change(:status, :stock)
    |> Repo.update()
  end

  @spec sell_stamp(Stamp.t, map) :: {:ok, %Stamp{status: :listed}, integer} | {:error, Ecto.Changeset.t}
  def sell_stamp(%Stamp{} = stamp, attrs) do
    with {:ok, stamp} <- set_stamp_inventory_key(stamp),
      {:ok, %{id: id}} <- Listings.create_listing(stamp, attrs)
    do
      stamp
      |> Stamp.changeset(%{})
      |> Ecto.Changeset.put_change(:status, :listed)
      |> Repo.update()
      |> Tuple.append(id)
    end
  end

  @spec set_stamp_inventory_key(%Stamp{scott_number: String.t, format: atom}) :: {:ok, %Stamp{inventory_key: String.t}} | {:error, Ecto.Changeset.t}
  def set_stamp_inventory_key(%Stamp{scott_number: scott_number, format: format} = stamp) do
    with(
      search_number <-
        if format == :se_tenant do
          scott_number
          |> String.split("-")
          |> hd()
        else
          scott_number
        end,
      numeric_length <-
        search_number
        |> String.graphemes()
        |> Enum.count(&(&1 in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])),
      stamp <- Repo.preload(stamp, [:stamp_reference]),
      numeric_length <-
        if(!StampReference.standard?(stamp.stamp_reference), do: numeric_length + 1, else: numeric_length),
      formatted_scott_number <-
        String.pad_leading(search_number, String.length(search_number) + (4 - numeric_length), "0"),
      suffix_code <-
        case format do
          :single -> ""
          _ -> "-#{Stamp.format_code(stamp)}"
        end,
      order <-
        Stamp
        |> where(scott_number: ^scott_number)
        |> where([s], not is_nil(s.inventory_key))
        |> Repo.aggregate(:count, :id)
        |> Kernel.+(1)
    ) do
      stamp
      |> Stamp.changeset(%{})
      |> Ecto.Changeset.put_change(
        :inventory_key,
        "#{DateTime.utc_now().year}#{formatted_scott_number}#{:io_lib.format("~2..0B", [order])}#{suffix_code}"
      )
      |> Repo.update()
    end
  end

  @spec update_stamp(
    Stamp.t,
    map,
    Kamansky.Attachments.Attachment.t | nil,
    Kamansky.Attachments.Attachment.t | nil
  ) :: {:ok, Stamp.t} | {:error, Ecto.Changeset.t}
  def update_stamp(%Stamp{} = stamp, attrs, front_photo, rear_photo) do
    stamp
    |> Stamp.changeset(attrs)
    |> handle_photos(front_photo, rear_photo)
    |> Repo.update()
  end

  @spec cost_of_stamps_for_month(Ecto.Query.t, integer) :: float
  defp cost_of_stamps_for_month(query, month) do
    query
    |> filter_query_for_month(month)
    |> select([s], sum(s.cost + s.purchase_fees))
    |> Repo.one()
  end

  @spec count_stamps_purchased_in_month(Ecto.Query.t, integer) :: integer
  defp count_stamps_purchased_in_month(query, month) do
    query
    |> filter_query_for_month(month)
    |> Repo.aggregate(:count, :id)
  end

  @spec handle_photos(Ecto.Changeset.t, Kamansky.Attachments.Attachment.t | nil, Kamansky.Attachments.Attachment.t) :: Ecto.Changeset.t
  defp handle_photos(changeset, nil, nil), do: changeset
  defp handle_photos(changeset, front_photo, nil), do: Ecto.Changeset.put_change(changeset, :front_photo_id, front_photo.id)
  defp handle_photos(changeset, nil, rear_photo), do: Ecto.Changeset.put_change(changeset, :rear_photo_id, rear_photo.id)
  defp handle_photos(changeset, front_photo, rear_photo), do: Ecto.Changeset.change(changeset, [front_photo_id: front_photo.id, rear_photo_id: rear_photo.id])

  @spec maybe_search(Ecto.Queryable.t, String.t | nil) :: Ecto.Queryable.t
  defp maybe_search(query, nil), do: query
  defp maybe_search(query, search), do: where(query, [s], ilike(s.scott_number, ^"#{search}%"))
end
