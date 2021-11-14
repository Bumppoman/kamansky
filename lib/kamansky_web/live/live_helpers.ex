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

  @spec live_navbar_links(Phoenix.LiveView.Socket.t, atom) :: [%{title: String.t, to: String.t, active: boolean}]
  def live_navbar_links(%Phoenix.LiveView.Socket{view: view} = socket, live_action) do
    [
      %{
        title: "Collection",
        to: Routes.stamp_index_path(socket, :collection),
        active: view == KamanskyWeb.StampLive.Index and live_action == :collection
      },
      %{
        title: "Stock",
        to: Routes.stamp_index_path(socket, :stock),
        active: view == KamanskyWeb.StampLive.Index and live_action == :stock
      },
      %{
        title: "Listings",
        to: Routes.listing_active_path(socket, :index),
        active: view in [KamanskyWeb.ListingLive.Active, KamanskyWeb.ListingLive.Bid, KamanskyWeb.ListingLive.Sold]
      },
      %{
        title: "Orders",
        to: Routes.order_index_path(socket, :pending),
        active: view == KamanskyWeb.OrderLive.Index
      }
    ]
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
end
