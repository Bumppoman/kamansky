defmodule KamanskyWeb.DashboardLive.Index do
  use KamanskyWeb, :live_view

  import Kamansky.Helpers

  alias Kamansky.Sales.{Listings, Orders}
  alias Kamansky.Stamps

  @impl true
  def mount(_params, session, socket) do
    previous_month =
      with(
        date <- DateTime.utc_now,
        day <- date.day,
        days <- max(day, (Date.add(date, -day)).day)
      ) do
        Date.add(date, -days).month
      end

    socket =
      socket
      |> assign_defaults(session)
      |> assign(
        [
          collection_cost: Stamps.cost_of_stamps(:collection),
          cost_of_stamps_last_month_for_collection: Stamps.cost_of_stamps(:collection, previous_month),
          cost_of_stamps_last_month_for_listings: Stamps.cost_of_stamps([:listed, :sold], previous_month),
          cost_of_stamps_last_month_for_stock: Stamps.cost_of_stamps(:stock, previous_month),
          cost_of_stamps_this_month_for_collection: Stamps.cost_of_stamps(:collection, DateTime.utc_now.month),
          cost_of_stamps_this_month_for_listings: Stamps.cost_of_stamps([:listed, :sold], DateTime.utc_now.month),
          cost_of_stamps_this_month_for_stock: Stamps.cost_of_stamps(:stock, DateTime.utc_now.month),
          listed_cost: Stamps.cost_of_stamps(:listed),
          listing_price: Listings.total_listings_price(:active),
          net_profit_last_month: Orders.total_net_profit(month: previous_month),
          net_profit_this_month: Orders.total_net_profit(month: DateTime.utc_now.month),
          orders_last_month: Orders.count_orders(month: previous_month),
          orders_this_month: Orders.count_orders(month: DateTime.utc_now.month),
          page_title: "Dashboard",
          stamps_in_orders_last_month: Orders.total_stamps_in_orders(month: previous_month),
          stamps_in_orders_this_month: Orders.total_stamps_in_orders(month: DateTime.utc_now.month),
          stamps_last_month_for_collection: Stamps.count_stamps_purchased(:collection, previous_month),
          stamps_last_month_for_listings: Stamps.count_stamps_purchased([:listed, :sold], previous_month),
          stamps_last_month_for_stock: Stamps.count_stamps_purchased(:stock, previous_month),
          stamps_this_month_for_collection: Stamps.count_stamps_purchased(:collection, DateTime.utc_now.month),
          stamps_this_month_for_listings: Stamps.count_stamps_purchased([:listed, :sold], DateTime.utc_now.month),
          stamps_this_month_for_stock: Stamps.count_stamps_purchased(:stock, DateTime.utc_now.month),
          stock_cost: Stamps.cost_of_stamps(:stock),
          total_gross_profit: Orders.total_gross_profit(:all),
          total_net_profit: Orders.total_net_profit(:all),
          total_orders: Orders.count_orders(:all),
          total_sold_stamp_cost: Stamps.cost_of_stamps(:sold),
          total_stamps_in_all_orders: Orders.total_stamps_in_orders(:all)
        ]
      )

    {:ok, socket}
  end
end
