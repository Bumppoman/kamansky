defmodule Kamansky.Stamps do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Repo
  alias Kamansky.Sales.Listings
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @spec change_stamp(Stamp.t, %{}) :: Ecto.Changeset.t
  def change_stamp(%Stamp{} = stamp, attrs \\ %{}), do: Stamp.changeset(stamp, attrs)

  @spec cost_of_stamps(atom) :: float
  def cost_of_stamps(status) do
    Stamp
    |> where(status: ^status)
    |> select(sum(fragment("cost + purchase_fees")))
    |> Repo.one()
  end

  @spec cost_of_stamps([atom] | atom, integer) :: float
  def cost_of_stamps(status, month) when is_list(status) do
    Stamp
    |> where([s], s.status in ^status)
    |> cost_of_stamps_for_month(month)
  end

  def cost_of_stamps(status, month) do
    Stamp
    |> where(status: ^status)
    |> cost_of_stamps_for_month(month)
  end

  @spec count_stamps(atom) :: integer
  def count_stamps(status) do
    Stamp
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  @spec count_stamps_purchased([atom] | atom, integer) :: integer
  def count_stamps_purchased(status, month) when is_list(status) do
    Stamp
    |> where([s], s.status in ^status)
    |> count_stamps_purchased_in_month(month)
  end

  def count_stamps_purchased(status, month) do
    Stamp
    |> where(status: ^status)
    |> count_stamps_purchased_in_month(month)
  end

  @spec create_stamp(%{}, Kamansky.Attachments.Attachment.t, Kamansky.Attachments.Attachment.t)
    :: {:ok, Stamp.t} | {:error, Ecto.Changeset.t}
  def create_stamp(attrs, front_photo, rear_photo) do
    %Stamp{}
    |> Stamp.changeset(attrs)
    |> Ecto.Changeset.change([front_photo: front_photo, rear_photo: rear_photo])
    |> Repo.insert()
  end

  @spec find_row_number_for_stamp(atom, %{}) :: integer
  def find_row_number_for_stamp(status, options) do
    Stamp
    |> where(status: ^status)
    |> select([s], {s.id, row_number() |> over(order_by: [{:asc, s.scott_number}])})
    |> Repo.all
    |> Enum.find(nil, fn {id, _row} -> id == String.to_integer(options[:record_id]) end)
    |> elem(1)
  end

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
    |> join(:left, [s], sr in assoc(s, :stamp_reference))
    |> join(:left, [s], fp in assoc(s, :front_photo))
    |> join(:left, [s], rp in assoc(s, :rear_photo))
    |> preload([s, sr, fp, rp], [stamp_reference: sr, front_photo: fp, rear_photo: rp])
    |> Repo.one!()
  end

  @spec list_stamps(atom, %{}) :: [Stamp.t]
  def list_stamps(status, params) do
    Stamp
    |> where(status: ^status)
    |> then(&Paginate.list(Stamps, &1, params))
  end

  @spec mark_stamp_as_sold(Stamp.t) :: {:ok, Stamp.t} | {:error, any}
  def mark_stamp_as_sold(%Stamp{} = stamp) do
    stamp
    |> Ecto.Changeset.change(status: :sold)
    |> Repo.update()
  end

  @spec move_stamp_to_stock(Stamp.t)
    :: {:ok, %Stamp{status: :stock, moved_to_stock_at: DateTime.t}} | {:error, Ecto.Changeset.t}
  def move_stamp_to_stock(%Stamp{} = stamp) do
    stamp
    |> Stamp.changeset(%{})
    |> Ecto.Changeset.change([status: :stock, moved_to_stock_at: NaiveDateTime.local_now()])
    |> Repo.update()
  end

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search) do
    where(query, [s],
      ilike(s.scott_number, ^"%#{search}%")
    )
  end

  @spec sell_stamp(Stamp.t, %{}) :: {:ok, %Stamp{status: :listed}, integer} | {:error, Ecto.Changeset.t}
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

  @spec set_stamp_inventory_key(%Stamp{scott_number: String.t, format: atom})
    :: {:ok, %Stamp{inventory_key: String.t}} | {:error, Ecto.Changeset.t}
  def set_stamp_inventory_key(%Stamp{scott_number: scott_number, format: format} = stamp) do

    # Formatted Scott number
    search_number =
      if format == :se_tenant do
        scott_number
        |> String.split("-")
        |> hd()
      else
        scott_number
      end

    # Determine the numeric length of the search number
    numeric_length =
      search_number
      |> String.graphemes()
      |> Enum.count(&(&1 in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]))

    stamp_reference =
      StampReference
      |> where(scott_number: ^scott_number)
      |> Repo.one()

    numeric_length =
      if !StampReference.standard?(stamp_reference), do: numeric_length + 1, else: numeric_length

    formatted_scott_number =
      search_number
      |> String.pad_leading(String.length(search_number) + (4-numeric_length), "0")

    # Suffix code
    suffix_code =
      case format do
        :single ->
          ""
        _ ->
          "-#{Stamp.format_code(stamp)}"
      end

    # Find how many items there are with this number
    order =
      Stamp
      |> where(scott_number: ^scott_number)
      |> where([s], not is_nil(s.inventory_key))
      |> Repo.aggregate(:count, :id)
      |> Kernel.+(1)

    # Save key
    stamp
    |> Stamp.changeset(%{})
    |> Ecto.Changeset.put_change(
      :inventory_key,
      "#{DateTime.utc_now().year}#{formatted_scott_number}#{:io_lib.format("~2..0B", [order])}#{suffix_code}"
    )
    |> Repo.update()
  end

  @impl true
  @spec sort(Ecto.Query.t, %{column: integer, direction: :asc | :desc}) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :scott_number})
  def sort(query, %{column: 1, direction: direction}), do: order_by(query, {^direction, :grade})

  @spec update_stamp(Stamp.t, %{}, integer | nil, integer | nil)
    :: {:ok, Stamp.t} | {:error, Ecto.Changeset.t}
  def update_stamp(%Stamp{} = stamp, attrs, front_photo, rear_photo) when is_nil(front_photo) and is_nil(rear_photo) do
    stamp
    |> Stamp.changeset(attrs)
    |> Repo.update()
  end

  def update_stamp(%Stamp{} = stamp, attrs, front_photo, rear_photo) when is_nil(rear_photo) do
    stamp
    |> Stamp.changeset(attrs)
    |> Ecto.Changeset.put_change(:front_photo_id, front_photo.id)
  end

  def update_stamp(%Stamp{} = stamp, attrs, front_photo, rear_photo) when is_nil(front_photo) do
    stamp
    |> Stamp.changeset(attrs)
    |> Ecto.Changeset.put_change(:rear_photo_id, rear_photo.id)
  end

  def update_stamp(%Stamp{} = stamp, attrs, front_photo, rear_photo) do
    stamp
    |> Stamp.changeset(attrs)
    |> Ecto.Changeset.change([front_photo_id: front_photo.id, rear_photo_id: rear_photo.id])
  end

  @spec cost_of_stamps_for_month(Ecto.Query.t, integer) :: float
  defp cost_of_stamps_for_month(%Ecto.Query{} = query, month) do
    query
    |> where([s], fragment("DATE_PART('month', ?)", s.inserted_at) == ^month)
    |> select(sum(fragment("cost + purchase_fees")))
    |> Repo.one()
  end

  @spec count_stamps_purchased_in_month(Ecto.Query.t, integer) :: integer
  defp count_stamps_purchased_in_month(%Ecto.Query{} = query, month) do
    query
    |> where([s], fragment("DATE_PART('month', ?)", s.inserted_at) == ^month)
    |> Repo.aggregate(:count, :id)
  end
end
