defmodule KamanskyWeb.StampLive.DetailComponent do
  use KamanskyWeb, :live_component
  use KamanskyWeb.Modal

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1]

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec handle_event(String.t, %{required(String.t) => String.t}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("change_photo", %{"display" => display}, socket), do: {:noreply, assign(socket, :current_photo, display)}

  @impl true
  @spec open_assigns(Phoenix.LiveView.Socket.t, map) :: Phoenix.LiveView.Socket.t
  def open_assigns(socket, %{"stamp-id" => stamp_id}) do
    socket
    |> assign(:current_photo, "front")
    |> assign(:stamp, Stamps.get_stamp_detail!(stamp_id))
  end

  @spec current_photo(Phoenix.LiveView.Socket.t, Stamp.t, String.t) :: String.t
  def current_photo(socket, %Stamp{front_photo: nil, rear_photo: nil}, _display), do: Routes.static_path(socket, "/images/blank-stamp.png")
  def current_photo(_socket, %Stamp{rear_photo: rear_photo}, "rear"), do: Attachment.path(rear_photo)
  def current_photo(_socket, %Stamp{front_photo: front_photo}, "front"), do: Attachment.path(front_photo)

  @spec display_photo_nav(Stamp.t) :: boolean
  def display_photo_nav(%Stamp{front_photo: nil}), do: false
  def display_photo_nav(%Stamp{rear_photo: nil}), do: false
  def display_photo_nav(%Stamp{}), do: true

  @spec formatted_history(Stamp.t) :: String.t
  def formatted_history(%Stamp{} = stamp) do
    stamp
    |> Stamp.history()
    |> Enum.join("<br />")
  end
end
