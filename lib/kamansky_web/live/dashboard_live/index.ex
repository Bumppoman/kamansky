defmodule KamanskyWeb.DashboardLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Operations.Dashboard
  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order
  alias Kamansky.Stamps

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    with date <- DateTime.now!(socket.assigns.timezone),
      day <- date.day,
      days <- max(day, (Date.add(date, -day)).day),
      first_of_previous_month <- Date.add(date, -days),
      previous_month <- first_of_previous_month.month,
      previous_year <- first_of_previous_month.year,
      this_month <- date.month,
      this_year <- date.year
    do
      socket
      |> assign(
        [
          cost_of_stamps_last_month_for_collection: Stamps.cost_of_stamps(:collection, previous_year, previous_month),
          cost_of_stamps_last_month_for_listings: Stamps.cost_of_stamps([:listed, :sold], previous_year, previous_month),
          cost_of_stamps_last_month_for_stock: Stamps.cost_of_stamps(:stock, previous_year, previous_month),
          cost_of_stamps_this_month_for_collection: Stamps.cost_of_stamps(:collection, this_year, this_month),
          cost_of_stamps_this_month_for_listings: Stamps.cost_of_stamps([:listed, :sold], this_year, this_month),
          cost_of_stamps_this_month_for_stock: Stamps.cost_of_stamps(:stock, this_year, this_month),
          net_profit_last_month: Orders.total_net_profit(year: previous_year, month: previous_month),
          net_profit_this_month: Orders.total_net_profit(year: this_year, month: this_month),
          orders_last_month: Orders.count_orders(year: previous_year, month: previous_month),
          orders_this_month: Orders.count_orders(year: this_year, month: this_month),
          page_title: "Dashboard",
          stamps_in_orders_last_month: Orders.total_stamps_in_orders(year: previous_year, month: previous_month),
          stamps_in_orders_this_month: Orders.total_stamps_in_orders(year: previous_year, month: this_month),
          stamps_last_month_for_collection: Stamps.count_stamps_purchased(:collection, previous_year, previous_month),
          stamps_last_month_for_listings: Stamps.count_stamps_purchased([:listed, :sold], previous_year, previous_month),
          stamps_last_month_for_stock: Stamps.count_stamps_purchased(:stock, previous_year, previous_month),
          stamps_this_month_for_collection: Stamps.count_stamps_purchased(:collection, this_year, this_month),
          stamps_this_month_for_listings: Stamps.count_stamps_purchased([:listed, :sold], this_year, this_month),
          stamps_this_month_for_stock: Stamps.count_stamps_purchased(:stock, this_year, this_month),
          total_gross_profit: Orders.total_gross_profit(:all),
          total_net_profit: Orders.total_net_profit(:all),
        ]
      )
      |> assign(:data, Dashboard.load_dashboard_data(socket.assigns.timezone))
      |> assign(:unshipped_orders, Dashboard.list_unshipped_orders())
      |> ok()
    end
  end
end
