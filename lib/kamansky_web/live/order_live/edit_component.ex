defmodule KamanskyWeb.OrderLive.EditComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Sales.Orders
  alias Kamansky.Sales.Orders.Order

  @impl true
  @spec update(%{required(:trigger_params) => %{String.t => any}, optional(:any) => any}, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{trigger_params: %{"order-id" => id}} = assigns, socket) do
    with order <- Orders.get_order_with_customer!(id),
      changeset <- Orders.change_new_order(order)
    do
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)
      |> assign(:customer, order.customer)
      |> assign(:order, order)
      |> ok()
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => map}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("submit", %{"order" => order_params}, socket) do
    case Orders.update_order(socket.assigns.order, order_params) do
      {:ok, %Order{id: order_id}} ->
        send self(), {:order_updated, order_id}
        noreply(socket)
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"order" => order_params}, socket) do
    socket.assigns.order
    |> Orders.change_new_order(order_params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
    |> noreply()
  end

  @spec existing_customer(Ecto.Changeset.t) :: boolean
  def existing_customer(changeset), do: Ecto.Changeset.get_field(changeset, :existing_customer)

  @spec get_platform_id_field(Ecto.Changeset.t) :: :ebay_id | :hipstamp_id
  def get_platform_id_field(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:platform)
    |> case do
      :ebay -> :ebay_id
      _ -> :hipstamp_id
    end
  end

  @spec get_platform_id_field_label(Ecto.Changeset.t) :: String.t
  def get_platform_id_field_label(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:platform)
    |> case do
      :ebay -> "eBay ID"
      _ -> "Hipstamp ID"
    end
  end
end
