defmodule KamanskyWeb.NotificationLive.Notifications do
  use KamanskyWeb, :live_view_without_layout
  on_mount KamanskyWeb.InitAssigns

  alias Kamansky.Operations.Accounts.Notifications
  alias Kamansky.Operations.Accounts.Notifications.Notification

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Kamansky.PubSub, "ebay")
    {:ok, assign(socket, :notifications, Notifications.list_unread_notifications_for_user(socket.assigns.current_user))}
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("read", %{"notification_id" => notification_id}, socket) do
    with notification_id <- String.to_integer(notification_id),
      {:ok, _notification} <- Notifications.mark_notification_read(notification_id)
    do
      {:noreply, assign(socket, :notifications, Enum.reject(socket.assigns.notifications, &(&1.id == notification_id)))}
    end
  end

  @impl true
  @spec handle_info({:new, Notification.t}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:new, %Notification{} = notification}, socket), do: {:noreply, assign(socket, :notifications, [notification | socket.assigns.notifications])}
end
