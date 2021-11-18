defmodule Kamansky.Operations.Accounts.Subscriptions.Subscription do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__
  alias Kamansky.Operations.Notifications.Notification

  @type t :: Ecto.Schema.t | %Subscription{
    topic: pos_integer,
    user_id: pos_integer
  }

  schema "subscriptions" do
    field :topic, Ecto.Enum, values: Notification.topics()
    field :last_read, :utc_datetime

    belongs_to :user, Kamansky.Operations.Accounts.User
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(subscription, attrs \\ %{}) do
    subscription
    |> cast(attrs, [:topic, :last_read, :user_id])
  end
end
