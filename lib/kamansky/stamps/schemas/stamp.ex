defmodule Kamansky.Stamps.Stamp do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset
  import Kamansky.Helpers

  alias __MODULE__
  alias Kamansky.Stamps.StampReferences.StampReference

  @grade_classes [
    %{
      start: 0,
      finish: 39,
      name: "---",
      long_name: "---"
    },
    %{
      start: 40,
      finish: 69,
      name: 'F',
      long_name: 'Fine'
    },
    %{
      start: 70,
      finish: 74,
      name: 'F/VF',
      long_name: 'Fine/Very Fine'
    },
    %{
      start: 75,
      finish: 79,
      name: 'VF',
      long_name: 'Very Fine'
    },
    %{
      start: 80,
      finish: 84,
      name: 'VF/XF',
      long_name: 'Very Fine/Extra Fine'
    },
    %{
      start: 85,
      finish: 89,
      name: 'XF',
      long_name: 'Extra Fine'
    },
    %{
      start: 90,
      finish: 94,
      name: 'XF/Superb',
      long_name: 'Extra Fine/Superb',
    },
    %{
      start: 95,
      finish: 97,
      name: 'Superb',
      long_name: 'Superb'
    },
    %{
      start: 98,
      finish: 100,
      name: 'Gem',
      long_name: 'Gem'
    }
  ]

  schema "stamps" do
    field :scott_number, :string
    field :grade, :integer
    field :cost, :decimal
    field :purchase_fees, :decimal
    field :inventory_key, :string
    field :status, Ecto.Enum, values: [pending: 1, collection: 2, stock: 3, listed: 4, sold: 5]
    field :format, Ecto.Enum, values: [single: 1, pair: 2, se_tenant: 3, souvenir_sheet: 4, block: 5, plate_block: 6, zip_block: 7, mail_early_block: 8], default: :single
    field :blind_perforation, :boolean, default: false
    field :crease, :boolean, default: false
    field :gum_disturbance, :boolean, default: false
    field :gum_skip, :boolean, default: false
    field :hinge_remnant, :boolean, default: false
    field :hinged, :boolean, default: false
    field :inclusion, :boolean, default: false
    field :ink_transfer, :boolean, default: false
    field :no_gum, :boolean, default: false
    field :pencil, :boolean, default: false
    field :short_perforation, :boolean, default: false
    field :stain, :boolean, default: false
    field :tear, :boolean, default: false
    field :thin_spot, :boolean, default: false
    field :toning, :boolean, default: false
    timestamps(updated_at: false)
    field :moved_to_stock_at, :utc_datetime

    belongs_to :front_photo, Kamansky.Attachments.Attachment
    belongs_to :rear_photo, Kamansky.Attachments.Attachment
    belongs_to :stamp_reference,
      Kamansky.Stamps.StampReferences.StampReference,
      define_field: false,
      foreign_key: :scott_number,
      references: :scott_number

    has_one :listing, Kamansky.Sales.Listings.Listing
  end

  @doc false
  def changeset(stamp, attrs) do

    # Workaround for Ecto.Enum (7/2021)
    attrs = cast_enum_fields(attrs, ["format"])

    stamp
    |> cast(attrs, [:scott_number, :grade, :cost, :purchase_fees,
      :format, :blind_perforation, :crease, :gum_disturbance,
      :gum_skip, :hinge_remnant, :hinged, :inclusion,
      :ink_transfer, :no_gum, :pencil, :short_perforation,
      :stain, :tear, :thin_spot, :toning])
    |> validate_required([:scott_number])
  end

  def flaws do
    [
      :blind_perforation,
      :crease,
      :gum_disturbance,
      :gum_skip,
      :hinge_remnant,
      :hinged,
      :inclusion,
      :ink_transfer,
      :no_gum,
      :pencil,
      :short_perforation,
      :stain,
      :tear,
      :thin_spot,
      :toning
    ]
  end

  def flaws?(stamp), do: Enum.any?(flaws(), &(Map.get(stamp, &1)))

  def format_code(%Stamp{format: :single}), do: ""
  def format_code(%Stamp{format: :pair}), do: "P"
  def format_code(%Stamp{format: :se_tenant}), do: "ST"
  def format_code(%Stamp{format: :souvenir_sheet}), do: "SS"
  def format_code(%Stamp{format: :block}), do: "B"
  def format_code(%Stamp{format: :plate_block}), do: "PB"
  def format_code(%Stamp{format: :zip_block}), do: "ZB"
  def format_code(%Stamp{format: :mail_early_block}), do: "MB"

  def formats do
    [
      {"Single", :single},
      {"Pair", :pair},
      {"Se-tenant", :se_tenant},
      {"Souvenir sheet", :souvenir_sheet},
      {"Block", :block},
      {"Plate block", :plate_block},
      {"ZIP block", :zip_block},
      {"Mail Early block", :mail_early_block}
    ]
  end

  def formatted_flaws(%Stamp{} = stamp) do
    flaws = Enum.filter(Stamp.flaws, fn flaw -> Map.get(stamp, flaw) end)

    if Enum.count(flaws) == 0 do
      "None"
    else
      flaws
      |> Enum.map(fn flaw ->
        flaw
        |> Atom.to_string()
        |> String.replace("_", " ")
      end)
      |> Enum.join("; ")
      |> String.capitalize()
    end
  end

  def formatted_grade(%Stamp{grade: nil}), do: "---"
  def formatted_grade(%Stamp{grade: grade} = stamp), do: "#{letter_grade(stamp)} (#{grade})"

  def history(%Stamp{} = stamp) do
    h =
      if stamp.moved_to_stock_at != stamp.inserted_at do
        [
          "Added to collection on #{formatted_date(stamp.inserted_at)}",
          (if stamp.status == :stock, do: "Moved to stock on #{formatted_date(stamp.moved_to_stock_at)}")
        ]
      else
        ["Added to stock on #{formatted_date(stamp.moved_to_stock_at)}"]
      end

    #unless is_nil(stamp.listing) do
    #  h = h ++ [
    #    "Listed for sale on #{Calendar.strftime(stamp.listing.inserted_at, "%B %-d, %Y")}",
    #    (if stamp.listing.sold, do: "Sold on #{Calendar.strftime(stamp.listing.sold_at, "%B %-d, %Y")}")
    #  ]
    #end

    h
  end

  def letter_grade(%Stamp{grade: grade}) do
    @grade_classes
    |> Enum.find(fn %{start: start, finish: finish} -> grade >= start && grade <= finish end)
    |> Map.get(:name)
  end

  def quality(%Stamp{no_gum: true}), do: "unused no gum"
  def quality(%Stamp{hinge_remnant: true}), do: "unused HR"
  def quality(%Stamp{hinged: true}), do: "unused hinged"
  def quality(%Stamp{gum_disturbance: true}), do: "unused disturbed gum"
  def quality(%Stamp{}), do: "MNH OG"

  def sale_description(%Stamp{} = stamp) do
    [StampReference.description(stamp.stamp_reference), quality(stamp)]
    |> Kernel.++(if !is_nil(stamp.grade) and stamp.grade >= 70, do: [Stamp.letter_grade(stamp)], else: [])
    |> Enum.join(" ")
  end

  def total_cost(%Stamp{cost: cost, purchase_fees: purchase_fees}), do: Decimal.add(cost, purchase_fees)
end
