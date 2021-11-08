defmodule KamanskyWeb.Router do
  use KamanskyWeb, :router

  import KamanskyWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, {KamanskyWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KamanskyWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :default, on_mount: KamanskyWeb.InitAssigns do
      live "/", DashboardLive.Index, :index

      live "/customers", CustomerLive.Index, :index
      live "/customers/:id/edit", CustomerLive.Index, :edit
      live "/customers/:id/show", CustomerLive.Show, :show

      live "/dashboard", DashboardLive.Index, :index

      live "/expenses", ExpenseLive.Index, :index
      live "/expenses/new", ExpenseLive.Index, :new

      live "/listings", ListingLive.Active, :index
      live "/listings/sold", ListingLive.Sold, :index
      live "/listings/sold/:id", ListingLive.Sold, :show
      live "/listings/:id", ListingLive.Active, :show
      live "/listings/:id/add-to-order", ListingLive.Active, :add_to_order

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

      live "/purchases", PurchaseLive.Index, :index
      live "/purchases/new", PurchaseLive.Index, :new

      live "/reports", ReportLive.Index, :index
      live "/reports/overall", ReportLive.Show, :index

      live "/stamps/collection", StampLive.Index, :collection
      live "/stamps/collection/replaceable", StampLive.Index, :collection_to_replace
      live "/stamps/collection/missing", StampReferenceLive.Index, :missing_from_collection
      live "/stamps/stock", StampLive.Index, :stock
      live "/stamps/new", StampLive.Index, :new
      live "/stamps/references", StampReferenceLive.Index, :index
      live "/stamps/references/new", StampReferenceLive.Index, :new
      live "/stamps/references/:id/edit", StampReferenceLive.Index, :edit
      live "/stamps/trends/sold", TrendLive.Sold, :index
      live "/stamps/:id", StampLive.Index, :show
      live "/stamps/:id/edit", StampLive.Index, :edit
      live "/stamps/:id/move-to-stock", StampLive.Index, :move_to_stock
      live "/stamps/:id/sell", StampLive.Index, :sell

      live "/trends", TrendLive.Index, :index
    end
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
      live_dashboard "/dashboard", metrics: KamanskyWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", KamanskyWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/login", UserSessionController, :new
    post "/users/login", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", KamanskyWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", KamanskyWeb do
    pipe_through [:browser]

    delete "/users/logout", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
