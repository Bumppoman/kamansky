defmodule KamanskyWeb.StampLiveTest do
  use KamanskyWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Kamansky.Stamps

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp fixture(:stamp) do
    {:ok, stamp} = Stamps.create_stamp(@create_attrs)
    stamp
  end

  defp create_stamp(_) do
    stamp = fixture(:stamp)
    %{stamp: stamp}
  end

  describe "Index" do
    setup [:create_stamp]

    test "lists all stamps", %{conn: conn, stamp: stamp} do
      {:ok, _index_live, html} = live(conn, Routes.stamp_index_path(conn, :index))

      assert html =~ "Listing Stamps"
    end

    test "saves new stamp", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.stamp_index_path(conn, :index))

      assert index_live |> element("a", "New Stamp") |> render_click() =~
               "New Stamp"

      assert_patch(index_live, Routes.stamp_index_path(conn, :new))

      assert index_live
             |> form("#stamp-form", stamp: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#stamp-form", stamp: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.stamp_index_path(conn, :index))

      assert html =~ "Stamp created successfully"
    end

    test "updates stamp in listing", %{conn: conn, stamp: stamp} do
      {:ok, index_live, _html} = live(conn, Routes.stamp_index_path(conn, :index))

      assert index_live |> element("#stamp-#{stamp.id} a", "Edit") |> render_click() =~
               "Edit Stamp"

      assert_patch(index_live, Routes.stamp_index_path(conn, :edit, stamp))

      assert index_live
             |> form("#stamp-form", stamp: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#stamp-form", stamp: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.stamp_index_path(conn, :index))

      assert html =~ "Stamp updated successfully"
    end

    test "deletes stamp in listing", %{conn: conn, stamp: stamp} do
      {:ok, index_live, _html} = live(conn, Routes.stamp_index_path(conn, :index))

      assert index_live |> element("#stamp-#{stamp.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#stamp-#{stamp.id}")
    end
  end

  describe "Show" do
    setup [:create_stamp]

    test "displays stamp", %{conn: conn, stamp: stamp} do
      {:ok, _show_live, html} = live(conn, Routes.stamp_show_path(conn, :show, stamp))

      assert html =~ "Show Stamp"
    end

    test "updates stamp within modal", %{conn: conn, stamp: stamp} do
      {:ok, show_live, _html} = live(conn, Routes.stamp_show_path(conn, :show, stamp))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Stamp"

      assert_patch(show_live, Routes.stamp_show_path(conn, :edit, stamp))

      assert show_live
             |> form("#stamp-form", stamp: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#stamp-form", stamp: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.stamp_show_path(conn, :show, stamp))

      assert html =~ "Stamp updated successfully"
    end
  end
end
