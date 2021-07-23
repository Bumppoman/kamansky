defmodule Kamansky.Paginate do
  import Ecto.Query

  alias Kamansky.Repo

  @callback as_list_query(Ecto.Query.t) :: Ecto.Query.t
  @callback primary_key :: atom
  @callback search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  @callback sort(Ecto.Query.t, %{column: integer, direction: :asc | :desc}) :: Ecto.Query.t

  @optional_callbacks as_list_query: 1, primary_key: 0

  @type params :: %{
    required(:limit) => integer,
    required(:offset) => integer,
    required(:search) => String.t | nil,
    required(:sort) => %{column: integer, direction: :asc | :desc},
    optional(atom) => any
  }

  defmacro __using__(opts \\ []) do
    quote do
      alias Kamansky.Paginate

      @behaviour Paginate

      @doc false
      @impl true
      def primary_key, do: unquote(Keyword.get(opts, :primary_key, :id))
    end
  end

  @doc "Return an `Ecto.Query`, limited for display in a `KamanskyWeb.TableLiveComponent`."
  @spec limit_for_data_table(Ecto.Query.t, params) :: Ecto.Query.t
  def limit_for_data_table(query, %{limit: limit, offset: offset}) do
    query
    |> limit(^limit)
    |> offset(^offset)
  end

  @spec list(atom, Ecto.Query.t, params) :: [any] | {integer, [any]}
  def list(implementation, query, %{search: nil} = params), do: records(implementation, query, params)

  def list(implementation, query, %{search: search} = params) do
    with query <- implementation.search_query(query, search),
      count <-
        query
        |> exclude(:join)
        |> exclude(:group_by)
        |> Repo.aggregate(:count, implementation.primary_key()),
      records <- records(implementation, query, params)
    do
      {count, records}
    end
  end

  @spec sort_and_limit(atom, Ecto.Query.t, params) :: Ecto.Query.t
  def sort_and_limit(implementation, query, %{sort: sort} = params) do
    query
    |> implementation.sort(sort)
    |> limit_for_data_table(params)
  end

  @spec records(atom, Ecto.Query.t, params) :: [any]
  defp records(implementation, query, params) do
    implementation
    |> sort_and_limit(query, params)
    |> Repo.all()
  end
end
