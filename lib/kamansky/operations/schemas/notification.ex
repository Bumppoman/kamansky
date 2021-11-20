defmodule Kamansky.Operations.Notifications.Notification do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__
  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias KamanskyWeb.Router.Helpers, as: Routes

  @topics [
    ebay_bid_received: 1,
    ebay_new_order: 2,
    ebay_listing_relisted: 3,
    hipstamp_new_order: 4
  ]

  @type t :: Ecto.Schema.t | %Notification{
    topic: pos_integer,
    associated_record: integer
  }

  schema "notifications" do
    field :topic, Ecto.Enum, values: @topics
    field :associated_record, :integer

    timestamps(updated_at: false)
  end

  @spec body(t, struct) :: String.t
  def body(%Notification{topic: :ebay_new_order}, order), do: "eBay order ##{order.ebay_id} for #{Order.total_paid(order)} is ready for processing"
  def body(%Notification{topic: :hipstamp_new_order}, order), do: "Hipstamp order ##{order.hipstamp_id} for #{Order.total_paid(order)} is ready for processing"

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(notification, attrs \\ %{}) do
    notification
    |> cast(attrs, [:topic, :associated_record])
  end

  @spec display(t)
    :: %{
      required(:body) => String.t,
      required(:id) => pos_integer,
      required(:route) => {fun, atom, integer},
      required(:timestamp) => DateTime.t,
      required(:title) => String.t
    }
  def display(%Notification{} = notification) do
    with associated_record <- associated_record(notification) do
      %{
        body: body(notification, associated_record),
        id: notification.id,
        route: route(notification, associated_record),
        timestamp: notification.inserted_at,
        title: title(notification)
      }
    end
  end

  @spec topics :: keyword
  def topics, do: @topics

  @spec associated_record(t) :: struct
  def associated_record(%Notification{topic: topic, associated_record: order_id}) when topic in [:ebay_new_order, :hipstamp_new_order], do: Orders.get_order!(order_id)

  @spec route(t, struct) :: {fun, atom, integer}
  defp route(%Notification{topic: :ebay_new_order}, order), do: {&Routes.order_show_path/3, :show, order.id}
  defp route(%Notification{topic: :hipstamp_new_order}, order), do: {&Routes.order_show_path/3, :show, order.id}

  @spec title(t) :: String.t
  defp title(%Notification{topic: :ebay_new_order}), do: "New eBay Order"
  defp title(%Notification{topic: :hipstamp_new_order}), do: "New Hipstamp Order"
end
