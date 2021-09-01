defmodule KamanskyWeb.OrderLive.EditComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Sales.Orders

  @impl true
  @spec update(%{required(:order) => Kamansky.Sales.Orders.Order.t, optional(:any) => any}, Phoenix.LiveView.Socket.t)
    :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{order: order} = assigns, socket) do
    with changeset <- Orders.change_new_order(order),
      socket <-
        socket
        |> assign(assigns)
        |> assign(:changeset, changeset)
        |> assign(:customer, order.customer)
    do
      {:ok, socket}
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => map}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("submit", %{"order" => order_params}, socket) do
    case Orders.update_order(socket.assigns.order, order_params) do
      {:ok, order} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "You have successfully updated this order.")
          |> push_redirect(to: Routes.order_index_path(socket, order.status, go_to_record: order.id))
        }
    end
  end

  def handle_event("validate", %{"order" => order_params}, socket) do
    with(
      changeset <-
        socket.assigns.order
        |> Orders.change_new_order(order_params)
        |> Map.put(:action, :validate)
    ) do
      {:noreply, assign(socket, :changeset, changeset)}
    end
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
