defmodule KamanskyWeb.ExpenseLiveTest do
  use KamanskyWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Kamansky.Operations.Expenses

  @create_expense_attrs %{category: :equipment, description: "New odontometer", date: ~D[2023-01-01], amount: Decimal.new("8.75")}

  defp create_expense(_) do
    expense = expense_fixture()
    %{expense: expense}
  end

  defp expense_fixture do
    {:ok, expense} = Expenses.create_expense(@create_expense_attrs)
    expense
  end

  describe "Add an expense" do
    setup [:register_and_log_in_user]

    test "expense can be added", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/expenses")

      view
      |> element("button", "Add New Expense")
      |> render_click()

      view
      |> form("#expense-form", expense: %{category: "supplies", description: "Watermark fluid", amount: "22.99", date: ~D[2023-01-01]})
      |> render_submit()

      assert render(view) =~ "January 1, 2023"
    end
  end

  describe "Update an expense" do
    setup [:register_and_log_in_user, :create_expense]

    test "expense can be updated", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/expenses")

      view
      |> element("a[phx-value-expense-id]")
      |> render_click()

      view
      |> form("#expense-form", expense: %{description: "Dealer cards"})
      |> render_submit()

      response = render(view)
      assert response =~ "Dealer cards"
      refute response =~ "Watermark fluid"
    end
  end
end
