defmodule KamanskyWeb.StampLive.DetailComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  def handle_event("display_front_photo", _params, socket), do: {:noreply, assign(socket, :current_photo, :front)}
  def handle_event("display_rear_photo", _params, socket), do: {:noreply, assign(socket, :current_photo, :rear)}

  def current_photo(socket, %Stamp{front_photo: nil, rear_photo: nil}) do
    Routes.static_path(socket, "/images/blank-stamp.png")
  end

  def current_photo(%{assigns: %{display_photo: rear_photo}}, %Stamp{rear_photo: rear_photo}) do
    Attachment.path(rear_photo)
  end

  def current_photo(_socket, %Stamp{front_photo: front_photo}), do: Attachment.path(front_photo)

  def display_photo_nav(%Stamp{front_photo: front_photo, rear_photo: rear_photo})
    when not is_nil(front_photo) and not is_nil(rear_photo), do: true
  def display_photo_nav(_), do: false

  def formatted_history(%Stamp{} = stamp) do
    stamp
    |> Stamp.history()
    |> Enum.join("<br />")
  end
end
