defmodule KamanskyWeb.StampLive.DetailComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  def update(assigns, socket) do
    with socket <- assign(socket, assigns) do
      {:ok, assign(socket, :current_photo, current_photo("front", socket))}
    end
  end

  @impl true
  def handle_event("change_photo", %{"display" => display}, socket) do
    {:noreply, assign(socket, :current_photo, current_photo(display, socket))}
  end

  def current_photo(_display, %{assigns: %{stamp: %Stamp{front_photo: nil, rear_photo: nil}}} = socket) do
    {:blank, Routes.static_path(socket, "/images/blank-stamp.png")}
  end

  def current_photo("rear", %{assigns: %{stamp: %Stamp{rear_photo: rear_photo}}}) do
    {:rear, Attachment.path(rear_photo)}
  end

  def current_photo("front", %{assigns: %{stamp: %Stamp{front_photo: front_photo}}}) do
    {:front, Attachment.path(front_photo)}
  end

  def display_photo_nav(%Stamp{front_photo: nil}), do: false
  def display_photo_nav(%Stamp{rear_photo: nil}), do: false
  def display_photo_nav(_), do: true

  def formatted_history(%Stamp{} = stamp) do
    stamp
    |> Stamp.history()
    |> Enum.join("<br />")
  end
end
