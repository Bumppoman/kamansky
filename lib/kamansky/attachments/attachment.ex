defmodule Kamansky.Attachments.Attachment do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset

  alias __MODULE__

  @type t :: Ecto.Schema.t | %Attachment{
    filename: String.t,
    size: integer,
    content_type: String.t,
    hash: String.t,
    inserted_at: DateTime.t
  }

  schema "attachments" do
    field :filename, :string
    field :size, :integer
    field :content_type, :string
    field :hash, :string

    timestamps(updated_at: false)
  end

  @doc "Return an empty `Ecto.Changeset` for an attachment."
  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(attachment, attrs \\ %{}) do
    cast(attachment, attrs, [:content_type, :filename, :hash, :size])
  end

  @spec full_path(Attachment.t) :: String.t
  def full_path(%Attachment{} = attachment) do
    attachment
    |> path()
    |> then(&Path.join(KamanskyWeb.Endpoint.url(), &1))
  end

  @spec hash_path(String.t) :: String.t
  def hash_path(hash) do
    [String.slice(hash, 0, 2), String.slice(hash, 2, 2), String.slice(hash, 4, 2)]
    |> Path.join()
  end

  @spec path(nil) :: nil
  def path(nil), do: nil

  @spec path(Attachment.t) :: String.t
  def path(%Attachment{} = attachment) do
    attachment.hash
    |> String.slice(0, 24)
    |> Kernel.<>(Path.extname(attachment.filename))
    |> then(&Path.join(["/files", hash_path(attachment.hash), &1]))
  end
end
