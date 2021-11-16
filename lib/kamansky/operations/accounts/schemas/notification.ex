defmodule Kamansky.Operations.Accounts.Notifications.Notification do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @topics [
    ebay_bid_received: 1,
    ebay_new_order: 2,
    hipstamp_new_order: 3
  ]

  @type t :: Ecto.Schema.t | %Notification{
    body: String.t,
    title: String.t,
    status: pos_integer,
    topic: pos_integer
  }

  schema "notifications" do
    field :title, :string
    field :body, :string
    field :topic, Ecto.Enum, values: @topics
    field :status, Ecto.Enum, values: [unread: 1, read: 2, archived: 3, deleted: 4], default: :unread

    belongs_to :user, Kamansky.Operations.Accounts.User

    timestamps()
  end

  @spec change_notification(t, map) :: Ecto.Changeset.t
  def change_notification(notification, attrs \\ %{}) do
    notification
    |> cast(attrs, [:body, :title, :topic])
  end
end
