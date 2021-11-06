defmodule Kamansky.Operations.Purchases do
  use Kamansky.Paginate

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Kamansky.Operations.Purchases.Purchase
  alias Kamansky.Repo

  @spec change_purchase(Purchase.t, map) :: Ecto.Changeset.t
  def change_purchase(%Purchase{} = purchase, attrs \\ %{}), do: Purchase.changeset(purchase, attrs)

  @spec count_purchases :: integer
  def count_purchases, do: Repo.aggregate(Purchase, :count)

  @spec create_purchase(map) :: {:ok, Purchase.t} | {:error, Ecto.Changeset.t}
  def create_purchase(attrs) do
    %Purchase{}
    |> Purchase.changeset(attrs)
    |> Repo.insert()
  end

  @spec find_row_number_for_purchase(map) :: integer
  def find_row_number_for_purchase(options) do
    Paginate.find_row_number(Purchase, Purchase.display_column_for_sorting(options[:sort][:column]), options)
  end

  @spec get_or_initialize_purchase(String.t) :: Purchase.t
  def get_or_initialize_purchase(""), do: %Purchase{}
  def get_or_initialize_purchase(id), do: get_purchase!(String.to_integer(id))

  @spec get_purchase!(pos_integer) :: Purchase.t
  def get_purchase!(id), do: Repo.get!(Purchase, id)

  @spec list_purchases(Paginate.params) :: [Purchase.t]
  def list_purchases(params), do: Paginate.list(Purchases, Purchase, params)

  @doc false
  @impl true
  @spec search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  def search_query(query, search), do: where(query, [p], ilike(p.description, ^"%#{search}%"))

  @impl true
  @spec sort(Ecto.Queryable.t, Paginate.sort) :: Ecto.Query.t
  def sort(query, %{column: 0, direction: direction}), do: order_by(query, {^direction, :date})

  @spec update_purchase(Purchase.t, map) :: {:ok, Purchase.t} | {:error, Ecto.Changeset.t}
  def update_purchase(%Purchase{} = purchase, attrs) do
    purchase
    |> Purchase.changeset(attrs)
    |> Repo.update()
  end
end
