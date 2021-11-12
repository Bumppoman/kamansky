defmodule Kamansky.Operations.Accounts.Notification do
  use Ecto.Schema

  #import Ecto.Changeset

  alias __MODULE__

  @type t :: Ecto.Schema.t | %Notification{
    body: String.t,
    status: integer
  }

  schema "notifications" do
    field :body, :string
    field :status, Ecto.Enum, values: [unread: 1, read: 2, archived: 3, deleted: 4]

    belongs_to :user, Kamansky.Operations.Accounts.User

    timestamps()
  end
end
