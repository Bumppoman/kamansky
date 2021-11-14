defmodule Kamansky.Operations.Administration.Settings do
  @derive Jason.Encoder

  import Ecto.Changeset

  alias __MODULE__

  @type t :: %Settings{
    additional_ounce: Decimal.t,
    shipping_cost: Decimal.t
  }

  defstruct [
    :additional_ounce,
    :shipping_cost
  ]

  @types %{
    additional_ounce: :decimal,
    shipping_cost: :decimal
  }

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(settings, params) do
    {settings, types()}
    |> cast(params, Map.keys(types()))
  end

  @spec types :: map
  def types, do: @types
end
