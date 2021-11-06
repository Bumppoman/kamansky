defmodule KamanskyWeb.StampLive.DetailComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp
  alias Kamansky.Stamps.StampReferences.StampReference

  @impl true
  @spec update(map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{trigger_params: %{"stamp-id" => stamp_id}} = assigns, socket) do
    with socket <- assign(socket, assigns),
      stamp <- Stamps.get_stamp_detail!(stamp_id),
      socket <- assign(socket, :stamp, stamp)
    do
      {:ok, assign(socket, :current_photo, current_photo("front", socket))}
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => String.t}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("change_photo", %{"display" => display}, socket), do: {:noreply, assign(socket, :current_photo, current_photo(display, socket))}

  @spec current_photo(
    String.t,
    %Phoenix.LiveView.Socket{
      assigns: %{
        required(:stamp) => %Stamp{
          front_photo: Kamansky.Attachments.Attachment.t | nil,
          rear_photo: Kamansky.Attachments.Attachment.t | nil
        }
      }
    }
  ) :: {:blank, String.t} | {:front, String.t} | {:rear, String.t}
  def current_photo(_display, %{assigns: %{stamp: %Stamp{front_photo: nil, rear_photo: nil}}} = socket) do
    {:blank, Routes.static_path(socket, "/images/blank-stamp.png")}
  end
  def current_photo("rear", %{assigns: %{stamp: %Stamp{rear_photo: rear_photo}}}), do: {:rear, Attachment.path(rear_photo)}
  def current_photo("front", %{assigns: %{stamp: %Stamp{front_photo: front_photo}}}), do: {:front, Attachment.path(front_photo)}

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
