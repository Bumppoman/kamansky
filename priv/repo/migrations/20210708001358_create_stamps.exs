defmodule Kamansky.Repo.Migrations.CreateStamps do
  use Ecto.Migration

  def change do
    create table(:stamps) do
      add :scott_number, :string
      add :grade, :integer
      add :cost, :decimal
      add :purchase_fees, :decimal
      add :inventory_key, :string
      add :status, :integer
      add :format, :integer
      add :blind_perforation, :boolean, default: false
      add :crease, :boolean, default: false
      add :gum_disturbance, :boolean, default: false
      add :gum_skip, :boolean, default: false
      add :hinge_remnant, :boolean, default: false
      add :hinged, :boolean, default: false
      add :inclusion, :boolean, default: false
      add :ink_transfer, :boolean, default: false
      add :no_gum, :boolean, default: false
      add :pencil, :boolean, default: false
      add :short_perforation, :boolean, default: false
      add :stain, :boolean, default: false
      add :tear, :boolean, default: false
      add :thin_spot, :boolean, default: false
      add :toning, :boolean, default: false
      timestamps(updated_at: false)
      add :moved_to_stock_at, :naive_datetime
    end
  end
end
