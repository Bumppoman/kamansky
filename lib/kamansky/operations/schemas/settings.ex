defmodule Kamansky.Operations.Administration.Settings do
  @derive Jason.Encoder

  import Ecto.Changeset

  alias __MODULE__

  @type t :: %Settings{
    additional_ounce: Decimal.t,
    hipstamp_description: String.t,
    hipstamp_percentage_fee: Decimal.t,
    paypal_flat_fee: Decimal.t,
    paypal_percentage_fee: Decimal.t,
    shipping_cost: Decimal.t
  }

  defstruct [
    :additional_ounce,
    :hipstamp_description,
    :hipstamp_percentage_fee,
    :paypal_flat_fee,
    :paypal_percentage_fee,
    :shipping_cost
  ]

  @types %{
    additional_ounce: :decimal,
    hipstamp_description: :string,
    hipstamp_percentage_fee: :decimal,
    paypal_flat_fee: :decimal,
    paypal_percentage_fee: :decimal,
    shipping_cost: :decimal
  }

  @spec __changeset__ :: map
  def __changeset__, do: @types

  @spec changeset(map, map) :: Ecto.Changeset.t
  def changeset(settings, params) do
    {settings, types()}
    |> cast(params, Map.keys(types()))
  end

  @spec types :: map
  def types, do: @types
end
