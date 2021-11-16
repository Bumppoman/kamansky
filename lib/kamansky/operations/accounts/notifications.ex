defmodule Kamansky.Operations.Accounts.Notifications do
  import Ecto.Query, warn: false

  alias Kamansky.Operations.Accounts.Notifications.Notification
  alias Kamansky.Operations.Accounts.User
  alias Kamansky.Repo

  @spec list_unread_notifications_for_user(User.t) :: [Notification.t]
  def list_unread_notifications_for_user(%User{id: user_id}) do
    Notification
    |> join(:left, [n], u in assoc(n, :user))
    |> where([n, u], n.status == :unread and u.id == ^user_id)
    |> Repo.all()
  end

  @spec mark_notification_read(pos_integer) :: {:ok, Notification.t}
  def mark_notification_read(notification_id) do
    Notification
    |> Repo.get(notification_id)
    |> Ecto.Changeset.change(status: :read)
    |> Repo.update()
  end

  @spec send_notification(User.t, atom, String.t, String.t) :: {:ok, Notification.t}
  def send_notification(%User{id: user_id}, topic, title, body) do
    %Notification{}
    |> Notification.change_notification(%{body: body, title: title, topic: topic})
    |> Ecto.Changeset.put_change(:user_id, user_id)
    |> Repo.insert!()
  end
end
