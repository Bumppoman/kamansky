defmodule Kamansky.Paginate do
  import Ecto.Query

  alias Kamansky.Repo

  @callback as_list_query(Ecto.Query.t) :: Ecto.Query.t
  @callback exclude_from_count(Ecto.Query.t) :: Ecto.Query.t
  @callback primary_key :: atom
  @callback search_query(Ecto.Query.t, String.t) :: Ecto.Query.t
  @callback sort(Ecto.Query.t, %{action: atom, column: integer, direction: :asc | :desc}) :: Ecto.Query.t

  @optional_callbacks as_list_query: 1, exclude_from_count: 1, primary_key: 0

  @type params :: %{
    required(:limit) => integer,
    required(:offset) => integer,
    required(:search) => String.t | nil,
    required(:sort) => sort,
    optional(atom) => any
  }

  @type sort :: %{
    required(:action) => atom,
    required(:column) => integer,
    required(:direction) => :asc | :desc
  }

  defmacro __using__(opts \\ []) do
    quote do
      alias Kamansky.Paginate

      @behaviour Paginate

      @doc false
      @impl true
      def exclude_from_count(query) do
        query
        |> Ecto.Query.exclude(:join)
        |> Ecto.Query.exclude(:group_by)
      end

      @doc false
      @impl true
      def primary_key, do: unquote(Keyword.get(opts, :primary_key, :id))

      defoverridable exclude_from_count: 1
    end
  end

  defmacrop compare(field_name, operator, value) do
    {
      operator,
      [context: Elixir, import: Kernel],
      [
        {
          :field,
          [],
          [
            {:b, [], Elixir},
            field_name
          ]
        },
        value
      ]
    }
  end

  def cursorize(query, order_by, last) do
    Enum.reduce(order_by, query, fn clause, q ->
      where(q, [{^clause.binding, b}], compare(^clause.field, :>, ^Map.get(last, clause.field)))
    end)
  end

  @spec find_row_number(Ecto.Queryable.t, atom, params) :: integer
  def find_row_number(query, sort_column, options) do
    with(
      record_query <-
        query
        |> select(
          [q],
          %{
            id: q.id,
            row_number: over(
              row_number(),
              order_by:
                {
                  ^options[:sort][:direction],
                  field(q, ^sort_column)
                }
            )
          }
        )
    ) do
      from(rq in subquery(record_query))
      |> where(id: ^(if is_binary(options[:record_id]), do: String.to_integer(options[:record_id]), else: options[:record_id]))
      |> select([rq], rq.row_number)
      |> Repo.one()
    end
  end

  @doc "Return an `Ecto.Query`, limited for display in a `KamanskyWeb.Components.DataTable`."
  @spec limit_for_data_table(Ecto.Query.t, params) :: Ecto.Query.t
  def limit_for_data_table(query, %{limit: limit, offset: offset}) do
    query
    |> limit(^limit)
    |> offset(^offset)
  end

  @spec list(atom, Ecto.Queryable.t, params) :: [any] | {integer, [any]}
  def list(implementation, query, %{search: nil} = params), do: records(implementation, query, params)

  def list(implementation, query, %{search: search} = params) do
    with query <- implementation.search_query(query, search),
      count <-
        query
        |> implementation.exclude_from_count()
        |> Repo.aggregate(:count, implementation.primary_key()),
      records <- records(implementation, query, params)
    do
      {count, records}
    end
  end

  @spec sort_and_limit(atom, Ecto.Queryable.t, params) :: Ecto.Query.t
  def sort_and_limit(implementation, query, %{sort: sort} = params) do
    query
    |> implementation.sort(sort)
    |> limit_for_data_table(params)
  end

  @spec records(atom, Ecto.Queryable.t, params) :: [any]
  defp records(implementation, query, params) do
    implementation
    |> sort_and_limit(query, params)
    |> Repo.all()
  end
end
