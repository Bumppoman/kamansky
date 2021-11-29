defmodule Kamansky.Services.Hipstamp do
  use Tesla

  alias Kamansky.Stamps.StampReferences.StampReference
  alias Kamansky.Stamps.Stamp

  plug Tesla.Middleware.BaseUrl, "https://www.hipstamp.com/api"
  plug Tesla.Middleware.Headers, [
    {"Content-Type", "application/json"},
    {"X-Apikey", Application.get_env(:kamansky, :hipstamp_api_key)}
  ]
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Query, [api_key: Application.get_env(:kamansky, :hipstamp_api_key)]

  @spec condition(Stamp.t) :: String.t
  def condition(%Stamp{hinged: hinged, hinge_remnant: hinge_remnant, no_gum: no_gum}) when hinged == true or hinge_remnant == true or no_gum == true, do: "unused"
  def condition(%Stamp{}), do: "mint-nh"

  @spec format(Stamp.t) :: String.t
  def format(%Stamp{format: format}) when format in [:block, :mail_early_block, :zip_block], do: "block"
  def format(%Stamp{format: :plate_block}), do: "plate-block"
  def format(%Stamp{format: :pair}), do: "pair"
  def format(%Stamp{format: :souvenir_sheet}), do: "souvenir-sheet"
  def format(%Stamp{}), do: "single"

  @spec grade(Stamp.t) :: String.t
  def grade(%Stamp{grade: grade}) do
    case grade do
      g when g in 95..100 ->
        "superb"
      g when g in 90..95 ->
        "xf-superb"
      g when g in 85..90 ->
        "xf"
      g when g in 80..85 ->
        "vf-xf"
      g when g in 75..80 ->
        "vf"
      g when g in 70..75 ->
        "f-vf"
      _ ->
        "not-specified"
    end
  end

  @spec issue_type(Stamp.t) :: String.t
  def issue_type(%Stamp{stamp_reference: %StampReference{issue_type: issue_type}}) do
    case issue_type do
      :airmail ->
        "air-mail"
      _ ->
        "general-issue"
    end
  end
end
