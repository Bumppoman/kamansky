defmodule KamanskyWeb.PurchaseLive.Show do
  use KamanskyWeb, :live_view
  use KamanskyWeb.Paginate, sort: {0, :asc}

  import Kamansky.Helpers, only: [format_decimal_as_currency: 1, formatted_date: 1]
  import KamanskyWeb.Helpers

  alias Kamansky.Operations.Purchases
  alias Kamansky.Operations.Purchases.Purchase
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps
  alias Kamansky.Stamps.Stamp

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(%{"id" => purchase_id}, _session, socket) do
    with purchase <- Purchases.get_purchase!(purchase_id) do
      socket
      |> assign(:page_title, "#{purchase.description} Purchase (#{formatted_date(purchase.date)})")
      |> assign(:purchase, purchase)
      |> ok()
    end
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(_params, _uri, socket), do: noreply(socket)

  @impl true
  @spec count_data(Phoenix.LiveView.Socket.t, String.t | nil) :: integer
  def count_data(%Phoenix.LiveView.Socket{assigns: %{purchase: %Purchase{id: purchase_id}}}, search), do: Stamps.count_stamps_in_purchase(purchase_id, search)

  @impl true
  @spec load_data(Phoenix.LiveView.Socket.t, Kamansky.Paginate.params) :: [Order.t]
  def load_data(%Phoenix.LiveView.Socket{assigns: %{purchase: %Purchase{id: purchase_id}}}, params), do: Stamps.list_stamps_in_purchase(purchase_id, params)

  @impl true
  @spec self_path(Phoenix.LiveView.Socket.t, :index, map) :: String.t
  def self_path(%Phoenix.LiveView.Socket{assigns: %Phoenix.LiveView.Socket.AssignsNotInSocket{} = assigns} = socket, _action, opts) do
    Routes.purchase_show_path(socket, :show, assigns.__assigns__.purchase.id, opts)
  end
  def self_path(socket, _action, opts), do: Routes.purchase_show_path(socket, :show, socket.assigns.purchase.id, opts)

  @impl true
  @spec sort_action(Phoenix.LiveView.Socket.t) :: atom
  def sort_action(_socket), do: :in_purchase

  @spec formatted_price_to_display(Stamp.t) :: String.t
  defp formatted_price_to_display(%Stamp{} = stamp) do
    with %Decimal{} = price <- raw_price_to_display(stamp) do
      format_decimal_as_currency(price)
    else
      nil -> "---"
    end
  end

  @spec raw_price_to_display(Stamp.t) :: Decimal.t | nil
  defp raw_price_to_display(%Stamp{status: status}) when status in [:collection, :stock], do: nil
  defp raw_price_to_display(%Stamp{status: :listed, listing: %Listing{listing_price: price}}), do: price
  defp raw_price_to_display(%Stamp{status: :sold, listing: %Listing{sale_price: price}}), do: price
end
