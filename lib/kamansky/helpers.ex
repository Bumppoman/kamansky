defmodule Kamansky.Helpers do
  def cast_enum_fields(attrs, fields) do
    attrs
    |> Enum.map(fn {key, value} -> if key in fields, do: {key, String.to_existing_atom(value)}, else: {key, value} end)
    |> Enum.into(%{})
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
  def formatted_date(%DateTime{} = date) do
    date
    |> DateTime.shift_zone("America/New_York")
    |> elem(1)
    |> Calendar.strftime("%B %-d, %Y")
  end

  def formatted_date(%Date{} = date), do: Calendar.strftime(date, "%B %-d, %Y")
  def formatted_date(_), do: nil

  @doc "Return a capitalized and humanized string"
  @spec humanize_and_capitalize(atom | String.t) :: String.t
  def humanize_and_capitalize(string) do
    string
    |> Phoenix.Naming.humanize()
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
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
end
