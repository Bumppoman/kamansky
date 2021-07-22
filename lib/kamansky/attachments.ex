defmodule Kamansky.Attachments do
  import Ecto.Changeset
  import Ecto.Query
  import Kamansky.Helpers

  alias Kamansky.Attachments.Attachment
  alias Kamansky.Repo

  def create_attachment(%{path: tmp_path}, %{client_size: size, client_name: filename, client_type: content_type}) do
    Repo.transaction fn ->
      with hash <- hash_attachment(tmp_path),
        {:ok, attachment} <-
          %Attachment{}
          |> Attachment.changeset(
            %{
              content_type: content_type,
              filename: filename,
              hash: hash,
              size: size
            }
          )
          |> Repo.insert(),
        :ok <- create_necessary_directories(hash),
        :ok <- save_attachment_file(tmp_path, hash, Path.extname(filename))
      do
        {:ok, attachment}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end
  end

  @doc "Create the directories necessary to store the attachment."
  defp create_necessary_directories(hash) do
    Application.get_env(:kamansky, :uploads_directory)
    |> Path.join(Attachment.hash_path(hash))
    |> File.mkdir_p()
  end

  @spec hash_attachment(String.t) :: String.t
  defp hash_attachment(tmp_path) do
    tmp_path
    |> File.stream!([], 2048)
    |> sha256_file()
  end

  defp save_attachment_file(tmp_path, hash, file_type) do
    tmp_path
    |> File.cp(
      Path.join(
        [
          Application.get_env(:kamansky, :uploads_directory),
          Attachment.hash_path(hash),
          String.slice(hash, 0, 24) <> file_type
        ]
      )
    )
  end
end
