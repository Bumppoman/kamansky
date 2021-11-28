defmodule Kamansky.Operations.Purchases do
  @sort_columns [:date]
  use Kamansky.Paginate

  import Ecto.Query, warn: false
  import Kamansky.Helpers, only: [get_value_for_ecto_enum: 3]

  alias __MODULE__
  alias Kamansky.Operations.Purchases.Purchase
  alias Kamansky.Repo

  @spec change_purchase(Purchase.t, map) :: Ecto.Changeset.t
  def change_purchase(%Purchase{} = purchase, attrs \\ %{}), do: Purchase.changeset(purchase, attrs)

  @spec count_purchases(String.t | nil) :: integer
  def count_purchases(search \\ nil) do
    Purchase
    |> maybe_search(search)
    |> Repo.aggregate(:count, :id)
  end

  @spec create_purchase(map) :: {:ok, Purchase.t} | {:error, Ecto.Changeset.t}
  def create_purchase(attrs) do
    %Purchase{}
    |> Purchase.changeset(attrs)
    |> Repo.insert()
  end

  @spec find_row_number_for_purchase(pos_integer, integer, Paginate.sort_direction) :: integer | nil
  def find_row_number_for_purchase(purchase_id, sort, direction) do
    Paginate.find_row_number(Purchase, purchase_id, Purchase.display_column_for_sorting(sort), direction)
  end

  @spec get_or_initialize_purchase(String.t) :: Purchase.t
  def get_or_initialize_purchase(""), do: %Purchase{}
  def get_or_initialize_purchase(id), do: get_purchase!(String.to_integer(id))

  @spec get_purchase!(pos_integer) :: Purchase.t
  def get_purchase!(id), do: Repo.get!(Purchase, id)

  @spec list_purchases_for_display(Paginate.params) :: [Purchase.t]
  def list_purchases_for_display(params) do
    Purchase
    |> maybe_search(params.search)
    |> then(&Paginate.list(Purchases, &1, params))
    |> Repo.preload([stamps: :listing])
  end

  @spec update_purchase(Purchase.t, map) :: {:ok, Purchase.t} | {:error, Ecto.Changeset.t}
  def update_purchase(%Purchase{} = purchase, attrs) do
    purchase
    |> Purchase.changeset(attrs)
    |> Repo.update()
  end

  @spec maybe_search(Ecto.Queryable.t, String.t | nil) :: Ecto.Queryable.t
  defp maybe_search(query, nil), do: query
  defp maybe_search(query, search), do: where(query, [p], ilike(p.description, ^"%#{search}%"))
end
