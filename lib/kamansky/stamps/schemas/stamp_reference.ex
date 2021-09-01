defmodule Kamansky.Stamps.StampReferences.StampReference do
  use Ecto.Schema

  import Ecto.Changeset
  import Kamansky.Helpers

  alias __MODULE__

  @type t :: Ecto.Schema.t | %StampReference{
    scott_number: String.t,
    denomination: Decimal.t,
    year_of_issue: integer,
    color: String.t,
    issue_type: atom,
    commemorative: boolean,
    title: String.t,
    synopsis: String.t
  }

  schema "stamp_references" do
    field :scott_number, :string
    field :denomination, :decimal
    field :year_of_issue, :integer
    field :color, :string
    field :issue_type, Ecto.Enum, values: [standard: 1, semi_postal: 2, airmail: 3, airmail_special_delivery: 4, special_delivery: 5, registered: 6, certified: 7, postage_due: 8]
    field :commemorative, :boolean, default: true
    field :title, :string
    field :synopsis, :string
  end

  @doc false
  @spec changeset(StampReference.t, %{}) :: Ecto.Changeset.t
  def changeset(stamp_reference, attrs) do

    # Workaround for Ecto.Enum (7/2021)
    attrs = cast_enum_fields(attrs, ["issue_type"])

    stamp_reference
    |> cast(attrs, [:color, :denomination, :issue_type, :scott_number, :title, :year_of_issue])
    |> validate_required([])
  end

  @spec description(StampReference.t) :: String.t
  def description(%StampReference{} = stamp_reference) do
    "Scott ##{stamp_reference.scott_number} #{stamp_reference.year_of_issue} #{formatted_denomination(stamp_reference)} #{stamp_reference.title}"
  end

  @spec display_column_for_sorting(integer) :: atom
  def display_column_for_sorting(column) do
    [:scott_number]
    |> Enum.at(column)
  end

  @spec formatted_denomination(StampReference.t) :: String.t
  def formatted_denomination(%StampReference{} = stamp_reference) do
    cond do
      stamp_reference.denomination == nil -> "Forever"
      Decimal.lt?(stamp_reference.denomination, 1) ->
        stamp_reference.denomination
        |> Decimal.rem(Decimal.from_float(0.01))
        |> Decimal.round(4)
        |> Decimal.to_float()
        |> case do
          0.005 ->
            "#{if Decimal.eq?(stamp_reference.denomination, Decimal.from_float(0.005)), do: "", else: Decimal.round(Decimal.mult(stamp_reference.denomination, 100), 0, :floor)}\u00BD¢"
          0.0025 ->
            "#{Decimal.round(Decimal.mult(stamp_reference.denomination, 100), 0, :floor)}\u00BC¢"
          0.0 ->
            "#{Decimal.round(Decimal.mult(stamp_reference.denomination, 100), 0)}¢"
          _ ->
            "#{Decimal.round(Decimal.mult(stamp_reference.denomination, 100), 1)}¢"
          end
      true ->
        "$#{if !Decimal.eq?(Decimal.rem(stamp_reference.denomination, 1), Decimal.from_float(0.0)), do: :io_lib.format("~.2f", [Decimal.to_float(stamp_reference.denomination)]), else: Decimal.round(stamp_reference.denomination, 0)}"
    end
  end

  @spec issue_types :: [tuple]
  def issue_types do
    [
      {"Standard", :standard},
      {"Semi-Postal", :semi_postal},
      {"Airmail", :airmail},
      {"Airmail Special Delivery", :airmail_special_delivery},
      {"Special Delivery", :special_delivery},
      {"Registered", :registered},
      {"Certified", :certified},
      {"Postage Due", :postage_due}
    ]
  end

  @spec standard?(StampReference.t) :: boolean
  def standard?(%StampReference{issue_type: :standard}), do: true
  def standard?(%StampReference{}), do: false
end
