defmodule Kamansky.Operations.Accounts.Subscriptions.Subscription do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__
  alias Kamansky.Operations.Notifications.Notification

  @type t :: Ecto.Schema.t | %Subscription{
    topic: pos_integer,
    user_id: pos_integer
  }

  @primary_key false
  schema "subscriptions" do
    field :topic, Ecto.Enum, values: Notification.list_topics(), primary_key: true
    field :last_read, :utc_datetime, autogenerate: {__MODULE__, :default_last_read, []}

    belongs_to :user, Kamansky.Operations.Accounts.User, primary_key: true
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(subscription, attrs \\ %{}) do
    subscription
    |> cast(attrs, [:topic, :last_read, :user_id])
  end

  @spec default_last_read :: DateTime.t
  def default_last_read, do: DateTime.truncate(DateTime.utc_now(), :second)
end
