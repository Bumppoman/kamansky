defmodule KamanskyWeb.NotificationLive.Notifications do
  use KamanskyWeb, :live_view_without_layout
  on_mount KamanskyWeb.InitAssigns

  alias Kamansky.Operations.Accounts.Subscriptions
  alias Kamansky.Operations.Notifications
  alias Kamansky.Operations.Notifications.Notification

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t, keyword}
  def mount(_params, _session, socket) do
    with subscriptions <- Subscriptions.list_subscriptions_for_user(socket.assigns.current_user) do
      Enum.each(subscriptions, &(Phoenix.PubSub.subscribe(Kamansky.PubSub, Atom.to_string(&1.topic))))

      {
        :ok,
        assign(socket, :notifications, Notifications.list_notifications_for_user(subscriptions)),
        temporary_assigns: [notifications: []]
      }
    end
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("update_last_read", %{"notification-id" => notification_id}, socket) do
    with notification <- Notifications.get_notification!(notification_id) do
      socket.assigns.current_user
      |> Subscriptions.get_subscription_for_user!(notification.topic)
      |> Subscriptions.update_subscription(%{last_read: notification.inserted_at})

      noreply(socket)
    end
  end

  @impl true
  @spec handle_info({:new, Notification.t}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_info({:new, %Notification{} = notification}, socket), do: {:noreply, assign(socket, :notifications, [Notification.display(notification)])}
end
