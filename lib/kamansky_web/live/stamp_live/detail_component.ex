defmodule KamanskyWeb.StampLive.DetailComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  def formatted_history(%Stamp{} = stamp) do
    stamp
    |> Stamp.history()
    |> Enum.join("<br />")
  end

  def front_photo_path(%Stamp{front_photo: nil}) do
    "/images/blank-stamp.png"
  end

  def front_photo_path(%Stamp{front_photo: front_photo}) do
    Attachment.path(front_photo)
  end
end
