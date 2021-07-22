defmodule KamanskyWeb.StampLive.DetailComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  def mount(socket), do: {:ok, assign(socket, :current_photo, current_photo(socket))}

  @impl true
  def handle_event("change_photo", %{"display" => display}, socket) do
    {
      :noreply,
      socket
        |> assign(:current_photo, current_photo(socket))
        |> assign(:display, display)
    }
  end

  def current_photo(%{assigns: %{stamp: %Stamp{front_photo: nil, rear_photo: nil}}}) do
    {:blank, Routes.static_path(socket, "/images/blank-stamp.png")}
  end

  def current_photo(%{assigns: %{display: "rear", stamp: %Stamp{rear_photo: rear_photo}}}) do
    {:rear, Attachment.path(rear_photo)}
  end

  def current_photo(%{assigns: %{stamp: %Stamp{front_photo: front_photo}}}), do: {:front, Attachment.path(front_photo)}

  def display_photo_nav(%Stamp{front_photo: nil}), do: false
  def display_photo_nav(%Stamp{rear_photo: nil}), do: false
  def display_photo_nav(_), do: true

  def formatted_history(%Stamp{} = stamp) do
    stamp
    |> Stamp.history()
    |> Enum.join("<br />")
  end
end
