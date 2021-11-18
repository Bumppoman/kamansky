defmodule Kamansky.Operations.Accounts.Subscriptions do
  import Ecto.Query, warn: false

  alias Kamansky.Operations.Accounts.Subscriptions.Subscription
  alias Kamansky.Operations.Accounts.User
  alias Kamansky.Repo

  @spec get_subscription_for_user!(User.t, String.t) :: Subscription.t
  def get_subscription_for_user!(%User{id: user_id}, topic) do
    Subscription
    |> where(user_id: ^user_id, topic: ^topic)
    |> Repo.one!()
  end

  @spec list_subscriptions_for_user(User.t) :: [Subscription.t]
  def list_subscriptions_for_user(%User{id: user_id}) do
    Subscription
    |> where(user_id: ^user_id)
    |> Repo.all()
  end

  @spec update_subscription(Subscription.t, map) :: {:ok, Subscription.t} | {:error, Ecto.Changeset.t}
  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end
end
