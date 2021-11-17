defmodule KamanskyWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  alias KamanskyWeb.Router.Helpers, as: Routes

  @spec live_confirmation_modal(keyword) :: Phoenix.LiveView.Component.t
  def live_confirmation_modal(opts) do
    live_modal(
      KamanskyWeb.Components.ConfirmationModalComponent,
      Keyword.merge(
        opts,
        [
          button_action: Keyword.get(opts, :success),
          type: Keyword.get(opts, :type, :confirmation)
        ]
      )
    )
  end

  @spec live_modal(module, keyword) :: Phoenix.LiveView.Component.t
  def live_modal(component, opts \\ []) do
    with id <- Keyword.get(opts, :id, :modal),
      path <- Keyword.fetch(opts, :return_to),
      modal_opts <- [component: component, id: id, return_to: path, opts: opts]
    do
      live_component(KamanskyWeb.Components.Modal, modal_opts)
    end
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

  @spec refresh_datatable(String.t, keyword) :: {:phoenix, :send_update, any}
  def refresh_datatable(table_id, options \\ []), do: Phoenix.LiveView.send_update(KamanskyWeb.Components.DataTable, id: table_id, options: options)
end
