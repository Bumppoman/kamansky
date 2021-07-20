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

  def condition(%Stamp{hinged: hinged, hinge_remnant: hinge_remnant, no_gum: no_gum}) when
    hinged == true or hinge_remnant == true or no_gum == true
  do
    "unused"
  end

  def condition(%Stamp{}), do: "mint-nh"

  def format(%Stamp{format: format}) do
    case format do
      f when f in [:block, :mail_early_block] ->
        "block"
      :plate_block ->
        "plate-block"
      :pair ->
        "pair"
      :souvenir_sheet ->
        "souvenir-sheet"
      _ ->
        "single"
    end
  end

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

  def issue_type(%Stamp{stamp_reference: %StampReference{issue_type: issue_type}}) do
    case issue_type do
      :airmail ->
        "air-mail"
      _ ->
        "general-issue"
    end
  end
end
