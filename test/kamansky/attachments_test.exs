defmodule Kamansky.AttachmentsTest do
  use Kamansky.DataCase

  alias Kamansky.Attachments

  describe "attachments" do
    alias Kamansky.Attachments.Attachment

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def attachment_fixture(attrs \\ %{}) do
      {:ok, attachment} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Attachments.create_attachment()

      attachment
    end

    test "list_attachments/0 returns all attachments" do
      attachment = attachment_fixture()
      assert Attachments.list_attachments() == [attachment]
    end

    test "get_attachment!/1 returns the attachment with given id" do
      attachment = attachment_fixture()
      assert Attachments.get_attachment!(attachment.id) == attachment
    end

    test "create_attachment/1 with valid data creates a attachment" do
      assert {:ok, %Attachment{} = attachment} = Attachments.create_attachment(@valid_attrs)
    end

    test "create_attachment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Attachments.create_attachment(@invalid_attrs)
    end

    test "update_attachment/2 with valid data updates the attachment" do
      attachment = attachment_fixture()
      assert {:ok, %Attachment{} = attachment} = Attachments.update_attachment(attachment, @update_attrs)
    end

    test "update_attachment/2 with invalid data returns error changeset" do
      attachment = attachment_fixture()
      assert {:error, %Ecto.Changeset{}} = Attachments.update_attachment(attachment, @invalid_attrs)
      assert attachment == Attachments.get_attachment!(attachment.id)
    end

    test "delete_attachment/1 deletes the attachment" do
      attachment = attachment_fixture()
      assert {:ok, %Attachment{}} = Attachments.delete_attachment(attachment)
      assert_raise Ecto.NoResultsError, fn -> Attachments.get_attachment!(attachment.id) end
    end

    test "change_attachment/1 returns a attachment changeset" do
      attachment = attachment_fixture()
      assert %Ecto.Changeset{} = Attachments.change_attachment(attachment)
    end
  end
end
