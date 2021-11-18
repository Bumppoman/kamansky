defmodule Kamansky.Operations.Notifications.Notification do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @topics [
    ebay_bid_received: 1,
    ebay_new_order: 2,
    ebay_listing_relisted: 3,
    hipstamp_new_order: 4
  ]

  @type t :: Ecto.Schema.t | %Notification{
    body: String.t,
    title: String.t,
    topic: pos_integer
  }

  schema "notifications" do
    field :title, :string
    field :body, :string
    field :topic, Ecto.Enum, values: @topics

    timestamps(updated_at: false)
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(notification, attrs \\ %{}) do
    notification
    |> cast(attrs, [:body, :title, :topic])
  end

  @spec topics :: keyword
  def topics, do: @topics
end
