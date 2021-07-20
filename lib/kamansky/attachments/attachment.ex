defmodule Kamansky.Attachments.Attachment do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @type t :: Ecto.Schema.t | %Attachment{
    filename: String.t,
    size: integer,
    content_type: String.t,
    hash: String.t,
    inserted_at: DateTime.t,
    updated_at: DateTime.t
  }

  schema "attachments" do
    field :filename, :string
    field :size, :integer
    field :content_type, :string
    field :hash, :string

    timestamps()
  end

  @doc "Return an empty `Ecto.Changeset` for an attachment."
  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(attachment, attrs \\ %{}) do
    cast(attachment, attrs, [:content_type, :filename, :hash, :size])
  end

  def hash_path(hash) do
    [String.slice(hash, 0, 2), String.slice(hash, 2, 2), String.slice(hash, 4, 2)]
    |> Path.join()
  end

  def path(nil), do: nil
  def path(%Attachment{} = attachment) do
    filename = String.slice(attachment.hash, 0, 16) <> Path.extname(attachment.filename)

    Path.join(["/files", hash_path(attachment.hash), filename])
  end
end
