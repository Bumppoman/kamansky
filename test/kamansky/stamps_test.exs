defmodule Kamansky.StampsTest do
  use Kamansky.DataCase

  alias Kamansky.Stamps

  describe "stamps" do
    alias Kamansky.Stamps.Stamp

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def stamp_fixture(attrs \\ %{}) do
      {:ok, stamp} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Stamps.create_stamp()

      stamp
    end

    test "list_stamps/0 returns all stamps" do
      stamp = stamp_fixture()
      assert Stamps.list_stamps() == [stamp]
    end

    test "get_stamp!/1 returns the stamp with given id" do
      stamp = stamp_fixture()
      assert Stamps.get_stamp!(stamp.id) == stamp
    end

    test "create_stamp/1 with valid data creates a stamp" do
      assert {:ok, %Stamp{} = stamp} = Stamps.create_stamp(@valid_attrs)
    end

    test "create_stamp/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stamps.create_stamp(@invalid_attrs)
    end

    test "update_stamp/2 with valid data updates the stamp" do
      stamp = stamp_fixture()
      assert {:ok, %Stamp{} = stamp} = Stamps.update_stamp(stamp, @update_attrs)
    end

    test "update_stamp/2 with invalid data returns error changeset" do
      stamp = stamp_fixture()
      assert {:error, %Ecto.Changeset{}} = Stamps.update_stamp(stamp, @invalid_attrs)
      assert stamp == Stamps.get_stamp!(stamp.id)
    end

    test "delete_stamp/1 deletes the stamp" do
      stamp = stamp_fixture()
      assert {:ok, %Stamp{}} = Stamps.delete_stamp(stamp)
      assert_raise Ecto.NoResultsError, fn -> Stamps.get_stamp!(stamp.id) end
    end

    test "change_stamp/1 returns a stamp changeset" do
      stamp = stamp_fixture()
      assert %Ecto.Changeset{} = Stamps.change_stamp(stamp)
    end
  end
end
