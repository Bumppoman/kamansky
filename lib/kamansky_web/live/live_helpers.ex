defmodule KamanskyWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  alias KamanskyWeb.Router.Helpers, as: Routes

  @spec close_modal_with_success_and_reload_data(Phoenix.LiveView.Socket.t, String.t, String.t, pos_integer | nil) :: {:noreply, Phoenix.LiveView.Socket.t}
  def close_modal_with_success_and_reload_data(socket, modal_event, success_message, item_id \\ nil) do
    socket
    |> Phoenix.LiveView.push_event(modal_event, %{})
    |> Phoenix.LiveView.put_flash(:info, %{type: :success, message: success_message, timestamp: Time.utc_now()})
    |> Phoenix.LiveView.push_patch(
      to: apply(
        socket.view,
        :self_path,
        [
          socket,
          socket.assigns.live_action,
          socket.assigns.pagination,
          %{show: item_id}
        ]
      )
    )
    |> noreply()
  end

  @spec live_navbar_admin_links(Phoenix.LiveView.Socket.t, atom) :: [map]
  def live_navbar_admin_links(%Phoenix.LiveView.Socket{view: view} = socket, _live_action) do
    [
      %{
        title: "Customers",
        to: Routes.customer_index_path(socket, :index),
        active: view == KamanskyWeb.CustomerLive.Index
      },
      %{
        title: "Expenses",
        to: Routes.expense_index_path(socket, :index),
        active: view == KamanskyWeb.ExpenseLive.Index
      },
      %{
        title: "Purchases",
        to: Routes.purchase_index_path(socket, :index),
        active: view == KamanskyWeb.PurchaseLive.Index
      },
      %{
        title: "Reports",
        to: Routes.report_index_path(socket, :index),
        active: view == KamanskyWeb.ReportLive.Index
      },
      %{
        title: "Settings",
        to: Routes.settings_index_path(socket, :index),
        active: view == KamanskyWeb.SettingsLive.Index
      },
      %{
        title: "Stamp References",
        to: Routes.stamp_reference_index_path(socket, :index),
        active: view == KamanskyWeb.StampReferenceLive.Index
      },
      %{
        title: "Trends",
        to: Routes.trend_index_path(socket, :index),
        active: view == KamanskyWeb.TrendLive.Index
      }
    ]
  end

  @spec noreply(Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def noreply(%Phoenix.LiveView.Socket{} = socket), do: {:noreply, socket}

  @spec ok(Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def ok(%Phoenix.LiveView.Socket{} = socket), do: {:ok, socket}
end
