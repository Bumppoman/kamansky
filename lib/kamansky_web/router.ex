defmodule KamanskyWeb.Router do
  use KamanskyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {KamanskyWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug KamanskyWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KamanskyWeb do
    pipe_through :browser

    live "/customers", CustomerLive.Index, :index
    live "/customers/:id/edit", CustomerLive.Index, :edit

    live "/dashboard", DashboardLive.Index, :index

    live "/expenses", ExpenseLive.Index, :index
    live "/expenses/new", ExpenseLive.Index, :new

    live "/listings", ListingLive.Active, :index
    live "/listings/sold", ListingLive.Sold, :index
    live "/listings/:id/add-to-order", ListingLive.Active, :add_to_order

    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete

    live "/orders/pending", OrderLive.Index, :pending
    live "/orders/finalized", OrderLive.Index, :finalized
    live "/orders/processed", OrderLive.Index, :processed
    live "/orders/shipped", OrderLive.Index, :shipped
    live "/orders/completed", OrderLive.Index, :completed
    live "/orders/load", OrderLive.Index, :load
    live "/orders/new", OrderLive.Index, :new
    live "/orders/:id", OrderLive.Show, :show
    live "/orders/:id/edit", OrderLive.Index, :edit
    live "/orders/:id/mark-completed", OrderLive.Index, :mark_completed
    live "/orders/:id/mark-processed", OrderLive.Index, :mark_processed
    live "/orders/:id/mark-shipped", OrderLive.Index, :mark_shipped

    live "/stamp_references", StampReferenceLive.Index, :index
    live "/stamp_references/new", StampReferenceLive.Index, :new
    live "/stamp_references/:id/edit", StampReferenceLive.Index, :edit

    live "/stamps/collection", StampLive.Index, :collection
    live "/stamps/stock", StampLive.Index, :stock
    live "/stamps/new", StampLive.Index, :new
    live "/stamps/:id", StampLive.Index, :show
    live "/stamps/:id/edit", StampLive.Index, :edit
    live "/stamps/:id/move-to-stock", StampLive.Index, :move_to_stock
    live "/stamps/:id/sell", StampLive.Index, :sell

    live "/statistics", StatisticsLive.Index, :index
    live "/statistics/report", StatisticsLive.Show, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", KamanskyWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/phx_dashboard", metrics: KamanskyWeb.Telemetry
    end
  end
end
