defmodule Kamansky.Helpers do
  import Ecto.Query, warn: false

  @spec begin_and_end_date_for_month(pos_integer) :: {DateTime.t, DateTime.t}
  def begin_and_end_date_for_month(month) do
    with(
      year <-
        "America/New_York"
        |> DateTime.now!()
        |> Map.get(:year)
    ) do
      begin_and_end_date_for_year_and_month(year, month)
    end
  end

  @spec begin_and_end_date_for_year_and_month(pos_integer, pos_integer) :: {DateTime.t, DateTime.t}
  def begin_and_end_date_for_year_and_month(year, month) do
    with(
      begin_date <-
        year
        |> Date.new!(month, 1)
        |> DateTime.new!(Time.new!(0, 0, 0), "America/New_York")
        |> DateTime.shift_zone!("Etc/UTC"),
      end_date <-
        year
        |> Date.new!(month, 1)
        |> Date.end_of_month()
        |> DateTime.new!(Time.new!(23, 59, 59), "America/New_York")
        |> DateTime.shift_zone!("Etc/UTC")
    ) do
      {begin_date, end_date}
    end
  end

  @spec begin_and_end_date_for_year_and_month(pos_integer, pos_integer, :date) :: {Date.t, Date.t}
  def begin_and_end_date_for_year_and_month(year, month, :date) do
    with begin_date <- Date.new!(year, month, 1),
      end_date <- Date.end_of_month(begin_date)
    do
      {begin_date, end_date}
    end
  end

  @spec get_value_for_ecto_enum(atom, atom, atom) :: integer | String.t
  def get_value_for_ecto_enum(schema, field, enum_key) do
    schema
    |> apply(:__schema__, [:type, field])
    |> elem(2)
    |> Map.get(:on_dump)
    |> Map.get(enum_key)
  end

  @spec filter_query_for_month(Ecto.Queryable.t, pos_integer, atom | nil) :: Ecto.Query.t
  def filter_query_for_month(query, month, field_name \\ :inserted_at) do
    with {begin_date, end_date} <- begin_and_end_date_for_month(month) do
      filter_query_for_dates(query, field_name, begin_date, end_date)
    end
  end

  @spec filter_query_for_year_and_month(Ecto.Queryable.t, pos_integer, pos_integer, atom) :: Ecto.Query.t
  def filter_query_for_year_and_month(query, year, month, field_name \\ :inserted_at) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month) do
      filter_query_for_dates(query, field_name, begin_date, end_date)
    end
  end

  @spec filter_query_for_year_and_month_as_date(Ecto.Queryable.t, pos_integer, pos_integer, atom) :: Ecto.Query.t
  def filter_query_for_year_and_month_as_date(query, year, month, field_name \\ :date) do
    with {begin_date, end_date} <- begin_and_end_date_for_year_and_month(year, month, :date) do
      filter_query_for_dates(query, field_name, begin_date, end_date)
    end
  end

  @spec format_decimal_as_currency(Decimal.t | nil) :: String.t
  def format_decimal_as_currency(nil), do: "$0.00"

  def format_decimal_as_currency(decimal) do
    decimal
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> String.replace(~r/\d+(?=\.)|\A\d+\z/, fn int ->
      int
      |> String.graphemes
      |> Enum.reverse
      |> Enum.chunk_every(3)
      |> Enum.join(",")
      |> Kernel.<>("$")
      |> String.reverse
    end)
  end

  @doc "Return a formatted date"
  @spec formatted_date(any) :: String.t | nil
  def formatted_date(date) when is_struct(date, DateTime) or is_struct(date, Date), do: formatted_date(date, "%B %-d, %Y")
  def formatted_date(_), do: nil

  @spec formatted_date(any, String.t) :: String.t | nil
  def formatted_date(%DateTime{} = date, format) do
    date
    |> DateTime.shift_zone!("America/New_York")
    |> Calendar.strftime(format)
  end
  def formatted_date(%Date{} = date, format), do: Calendar.strftime(date, format)
  def formatted_date(_, _), do: nil

  @doc "Return a capitalized and humanized string"
  @spec humanize_and_capitalize(atom | String.t) :: String.t
  def humanize_and_capitalize(string) do
    string
    |> Phoenix.Naming.humanize()
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @doc "Return a capitalized and humanized list of enum values"
  @spec humanize_enum_options([atom]) :: [String.t]
  def humanize_enum_options(values), do: Enum.map(values, &({humanize_and_capitalize(&1), &1}))

  @doc "Returns a SHA256 hash of a file"
  @spec sha256_file(File.Stream.t) :: String.t
  def sha256_file(chunks_enum) do
    chunks_enum
    |> Enum.reduce(:crypto.hash_init(:sha256), &(:crypto.hash_update(&2, &1)))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end

  @spec states :: [String.t]
  def states do
    [
      "AL", "AK", "AZ", "AR",
      "CA", "CO", "CT", "DC",
      "DE", "FL", "GA", "HI",
      "ID", "IL", "IN", "IA",
      "KS", "KY", "LA", "ME",
      "MD", "MA", "MI", "MN",
      "MS", "MO", "MT", "NE",
      "NV", "NH", "NJ", "NM",
      "NY", "NC", "ND", "OH",
      "OK", "OR", "PA", "RI",
      "SC", "SD", "TN", "TX",
      "UT", "VT", "VA", "WA",
      "WV", "WI", "WY"
    ]
  end

  @spec filter_query_for_dates(Ecto.Queryable.t, atom, DateTime.t | Date.t, DateTime.t | Date.t) :: Ecto.Queryable.t
  defp filter_query_for_dates(query, field_name, begin_date, end_date) do
    where(
      query,
      [q],
      fragment(
        "? BETWEEN ? AND ?",
        field(q, ^field_name),
        ^begin_date,
        ^end_date
      )
    )
  end
end
