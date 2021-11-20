defmodule Kamansky.Operations.Notifications do
  import Ecto.Query, warn: false

  alias Kamansky.Operations.Accounts.Subscriptions.Subscription
  alias Kamansky.Operations.Notifications.Notification
  alias Kamansky.Repo

  @spec get_notification!(pos_integer) :: Notification.t
  def get_notification!(notification_id), do: Repo.get!(Notification, notification_id)

  @spec list_notifications_for_user([Subscription.t]) :: [Notification.t]
  def list_notifications_for_user(subscriptions) do
    subscriptions
    |> Enum.reduce(
      Notification,
      fn subscription, query ->
        from q in query, or_where: q.topic == ^subscription.topic and q.inserted_at > ^subscription.last_read
      end
    )
    |> Repo.all()
    |> Enum.map(&Notification.display/1)
  end

  @spec send_notification(atom, pos_integer) :: Notification.t
  def send_notification(topic, associated_record) do
    with {:ok, notification} <-
      %Notification{}
      |> Notification.changeset(%{topic: topic, associated_record: associated_record})
      |> Repo.insert()
    do
      Phoenix.PubSub.broadcast(Kamansky.PubSub, Atom.to_string(topic), {:new, notification})
    end
  end
end
