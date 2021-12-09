defmodule Kamansky.Paginate do
  import Ecto.Query

  alias Kamansky.Repo

  @callback sort(Ecto.Query.t, %{action: atom, column: integer, direction: :asc | :desc}) :: Ecto.Query.t

  @type params :: %{
    required(:action) => atom,
    required(:direction) => :asc | :desc,
    required(:page) => integer,
    required(:per_page) => integer,
    required(:search) => String.t | nil,
    optional(:show) => integer,
    required(:sort) => integer,
    required(:total_pages) => integer,
    required(:total_items) => integer
  }

  @type sort_direction :: :asc | :desc

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Ecto.Query, warn: false

      alias Kamansky.Paginate

      @behaviour Paginate

      if Module.has_attribute?(__MODULE__, :sort_columns) do
        @sort_columns
        |> Enum.with_index()
        |> Enum.each(fn
          {%{actions: actions, sort: sort}, _index} ->
            sort
            |> Enum.with_index()
            |> Enum.each(fn {column, index} ->
              @impl true
              def sort(query, %{action: action, column: unquote(index), direction: direction}) when action in unquote(actions) do
                order_by(query, ^Paginate.make_query_column(unquote(column), direction))
              end
            end)
          {column, index} ->
            @impl true
            def sort(query, %{column: unquote(index), direction: direction}), do: order_by(query, ^Paginate.make_query_column(unquote(column), direction))
        end)
      else
        @impl true
        def sort(_, _), do: raise "You must implement the sort function or define @sort_columns"
      end

      defoverridable sort: 2
    end
  end

  @spec find_row_number(Ecto.Queryable.t, pos_integer, atom | list, sort_direction) :: integer | nil
  def find_row_number(query, item_id, sort_column, direction) do
    with query_column <- make_query_column(sort_column, direction),
      record_query <-
        query
        |> windows([q], [row: [order_by: ^query_column]])
        |> select(
          [q],
          %{
            id: q.id,
            row_number: over(
              row_number(),
              :row
            )
          }
        )
    do
      from(rq in subquery(record_query))
      |> where(id: ^item_id)
      |> select([rq], rq.row_number)
      |> Repo.one()
    end
  end

  @spec list(module, Ecto.Query.t, params) :: [struct]
  def list(implementation, query, params) do
    query
    |> implementation.sort(%{action: params.action, column: params.sort, direction: params.direction})
    |> limit(^params.per_page)
    |> offset(^((params.page - 1) * params.per_page))
    |> Repo.all()
  end

  @spec make_query_column(atom | list, sort_direction) :: keyword
  def make_query_column(sort_column, direction) when is_list(sort_column), do: Enum.map(sort_column, &(sort_direction(direction, &1)))
  def make_query_column(sort_column, direction), do: [{direction, dynamic([q], field(q, ^sort_column))}]

  @spec sort_direction(:asc | :desc, {atom, atom} | atom) :: {atom, atom}
  defp sort_direction(desired_direction, {:nulls_first, column}), do: {String.to_existing_atom(Atom.to_string(desired_direction) <> "_nulls_first"), column}
  defp sort_direction(desired_direction, {:nulls_last, column}), do: {String.to_existing_atom(Atom.to_string(desired_direction) <> "_nulls_last"), column}
  defp sort_direction(_desired_direction, {direction, column}), do: {direction, column}
  defp sort_direction(desired_direction, column), do: {desired_direction, column}
end
