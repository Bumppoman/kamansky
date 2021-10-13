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
      name: "F",
      long_name: "Fine"
    },
    %{
      start: 70,
      finish: 74,
      name: "F/VF",
      long_name: "Fine/Very Fine"
    },
    %{
      start: 75,
      finish: 79,
      name: "VF",
      long_name: "Very Fine"
    },
    %{
      start: 80,
      finish: 84,
      name: "VF/XF",
      long_name: "Very Fine/Extra Fine"
    },
    %{
      start: 85,
      finish: 89,
      name: "XF",
      long_name: "Extra Fine"
    },
    %{
      start: 90,
      finish: 94,
      name: "XF/Superb",
      long_name: "Extra Fine/Superb",
    },
    %{
      start: 95,
      finish: 97,
      name: "Superb",
      long_name: "Superb"
    },
    %{
      start: 98,
      finish: 100,
      name: "Gem",
      long_name: "Gem"
    }
  ]

  @type t :: Ecto.Schema.t | %Stamp{
    scott_number: String.t,
    grade: integer,
    cost: Decimal.t,
    purchase_fees: Decimal.t,
    inventory_key: String.t,
    status: atom,
    format: atom,
    blind_perforation: boolean,
    crease: boolean,
    gum_disturbance: boolean,
    gum_skip: boolean,
    hinge_remnant: boolean,
    hinged: boolean,
    inclusion: boolean,
    ink_transfer: boolean,
    no_gum: boolean,
    pencil: boolean,
    short_perforation: boolean,
    stain: boolean,
    tear: boolean,
    thin_spot: boolean,
    toning: boolean,
    inserted_at: DateTime.t,
    front_photo_id: integer,
    rear_photo_id: integer,
    purchase_id: integer
  }

  schema "stamps" do
    field :scott_number, :string
    field :grade, :integer
    field :cost, :decimal
    field :purchase_fees, :decimal
    field :inventory_key, :string
    field :status, Ecto.Enum, values: [pending: 1, collection: 2, stock: 3, listed: 4, sold: 5]
    field :format, Ecto.Enum, values: [single: 1, pair: 2, se_tenant: 3, souvenir_sheet: 4, block: 5, plate_block: 6, zip_block: 7, mail_early_block: 8, first_day_cover: 9], default: :single
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

    field :add_to, Ecto.Enum, values: [:collection, :stock], virtual: true

    belongs_to :front_photo, Kamansky.Attachments.Attachment
    belongs_to :rear_photo, Kamansky.Attachments.Attachment
    belongs_to :purchase, Kamansky.Operations.Purchases.Purchase
    belongs_to :stamp_reference,
      Kamansky.Stamps.StampReferences.StampReference,
      define_field: false,
      foreign_key: :scott_number,
      references: :scott_number

    has_one :listing, Kamansky.Sales.Listings.Listing
  end

  @doc false
  @spec changeset(Stamp.t, map) :: Ecto.Changeset.t
  def changeset(stamp, attrs) do
    stamp
    |> cast(attrs, [:scott_number, :grade, :cost, :purchase_fees,
      :format, :blind_perforation, :crease, :gum_disturbance,
      :gum_skip, :hinge_remnant, :hinged, :inclusion,
      :ink_transfer, :no_gum, :pencil, :short_perforation,
      :stain, :tear, :thin_spot, :toning, :status, :add_to])
    |> validate_required([:scott_number])
  end

  @spec display_column_for_sorting(integer) :: atom
  def display_column_for_sorting(column) do
    [:scott_number, :grade]
    |> Enum.at(column)
  end

  @spec flaws :: [atom]
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

  @spec flaws?(Stamp.t) :: boolean
  def flaws?(%Stamp{} = stamp), do: Enum.any?(flaws(), &(Map.get(stamp, &1)))

  @spec format_code(%Stamp{format: atom}) :: String.t
  def format_code(%Stamp{format: :single}), do: ""
  def format_code(%Stamp{format: :pair}), do: "P"
  def format_code(%Stamp{format: :se_tenant}), do: "ST"
  def format_code(%Stamp{format: :souvenir_sheet}), do: "SS"
  def format_code(%Stamp{format: :block}), do: "B"
  def format_code(%Stamp{format: :plate_block}), do: "PB"
  def format_code(%Stamp{format: :zip_block}), do: "ZB"
  def format_code(%Stamp{format: :mail_early_block}), do: "MB"
  def format_code(%Stamp{format: :first_day_cover}), do: "FDC"

  @spec formats :: [{String.t, atom}]
  def formats do
    [
      {"Single", :single},
      {"Pair", :pair},
      {"Se-tenant", :se_tenant},
      {"Souvenir sheet", :souvenir_sheet},
      {"Block", :block},
      {"Plate block", :plate_block},
      {"ZIP block", :zip_block},
      {"Mail Early block", :mail_early_block},
      {"First day cover", :first_day_cover}
    ]
  end

  @spec formatted_flaws(Stamp.t) :: String.t
  def formatted_flaws(%Stamp{} = stamp) do
    with flaws <- Enum.filter(Stamp.flaws, &(Map.get(stamp, &1))) do
      if Enum.count(flaws) == 0 do
        "None"
      else
        flaws
        |> Enum.map_join("; ", fn flaw ->
          flaw
          |> Atom.to_string()
          |> String.replace("_", " ")
        end)
        |> String.capitalize()
      end
    end
  end

  @spec formatted_grade(%Stamp{grade: nil | integer}) :: String.t
  def formatted_grade(%Stamp{grade: nil}), do: "---"
  def formatted_grade(%Stamp{grade: grade} = stamp), do: "#{letter_grade(stamp)} (#{grade})"

  @spec grade_classes :: [%{start: integer, finish: integer, name: String.t, long_name: String.t}]
  def grade_classes, do: @grade_classes

  @spec hinged?(%Stamp{hinged: boolean}) :: boolean
  def hinged?(%Stamp{hinged: hinged}), do: hinged

  @spec history(Stamp.t) :: [String.t]
  def history(%Stamp{} = stamp) do
    with(
      h <- ["Purchased on #{formatted_date(stamp.inserted_at)}"],
      h <-
        if is_nil(stamp.listing) do
          h
        else
          h ++ [
            "Listed for sale on #{formatted_date(stamp.listing.inserted_at)}",
            (if stamp.listing.status == :sold, do: "Sold on #{formatted_date(stamp.listing.order.ordered_at, "%B %-d, %Y")}")
          ]
        end
    ) do
      Enum.reject(h, &is_nil/1)
    end
  end

  @spec letter_grade(%Stamp{grade: nil | integer}) :: String.t
  def letter_grade(%Stamp{grade: nil}), do: "---"
  def letter_grade(%Stamp{grade: grade}) do
    @grade_classes
    |> Enum.find(&(grade in &1.start..&1.finish))
    |> Map.get(:name)
  end

  @spec quality(Stamp.t) :: String.t
  def quality(%Stamp{no_gum: true}), do: "unused no gum"
  def quality(%Stamp{hinge_remnant: true}), do: "unused HR"
  def quality(%Stamp{hinged: true}), do: "unused hinged"
  def quality(%Stamp{gum_disturbance: true}), do: "unused disturbed gum"
  def quality(%Stamp{}), do: "MNH OG"

  @spec sale_description(Stamp.t) :: String.t
  def sale_description(%Stamp{} = stamp) do
    [StampReference.description(stamp.stamp_reference), quality(stamp)]
    |> Kernel.++(if !is_nil(stamp.grade) and stamp.grade >= 70, do: [Stamp.letter_grade(stamp)], else: [])
    |> Enum.join(" ")
  end

  @spec total_cost(%Stamp{cost: Decimal.t, purchase_fees: Decimal.t}) :: Decimal.t
  def total_cost(%Stamp{cost: cost, purchase_fees: purchase_fees}), do: Decimal.add(cost, purchase_fees)
end
