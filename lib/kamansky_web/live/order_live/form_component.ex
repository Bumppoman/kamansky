defmodule KamanskyWeb.OrderLive.FormComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Sales.Orders

  @impl true
  def update(%{order: order} = assigns, socket) do
    with changeset <- Orders.change_new_order(order),
      socket <-
        socket
        |> assign(assigns)
        |> assign(:changeset, changeset)
    do
      {:ok, socket}
    end
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"order" => order_params}, socket) do
    changeset =
      socket.assigns.order
      |> Orders.change_new_order(order_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("submit", %{"order" => order_params}, socket) do
    save_order(socket, socket.assigns.action, order_params)
  end

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

  @spec save_order(Phoenix.LiveView.Socket.t, atom, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_order(socket, :edit, order_params) do
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

  defp save_order(socket, :new, order_params) do
    case Orders.create_order(order_params) do
      {:ok, %{id: id}} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "You have successfully created this order.")
          |> push_redirect(to: Routes.order_index_path(socket, :pending, go_to_record: id))
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
