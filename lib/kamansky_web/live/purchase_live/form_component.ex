defmodule KamanskyWeb.PurchaseLive.FormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Operations.Purchases
  alias Kamansky.Operations.Purchases.Purchase

  @impl true
  @spec update(%{required(:purchase) => Purchase.t, optional(atom) => any}, Phoenix.LiveView.Socket.t)
    :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{purchase: purchase} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, Purchases.change_purchase(purchase))
    }
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"purchase" => purchase_params}, socket) do
    with(
      changeset <-
        socket.assigns.purchase
        |> Purchases.change_purchase(purchase_params)
        |> Map.put(:action, :validate)
    ) do
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("submit", %{"purchase" => purchase_params}, socket) do
    save_purchase(socket, socket.assigns.action, purchase_params)
  end

  @spec save_purchase(Phoenix.LiveView.Socket.t, :edit | :new, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_purchase(socket, :edit, purchase_params) do
    case Purchases.update_purchase(socket.assigns.purchase, purchase_params) do
      {:ok, _purchase} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "You have successfully updated this purchase.")
          |> push_redirect(to: socket.assigns.return_to)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_purchase(socket, :new, purchase_params) do
    case Purchases.create_purchase(purchase_params) do
      {:ok, %{id: id}} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "You have successfully added this purchase.")
          |> push_redirect(to: Routes.purchase_index_path(socket, :index, go_to_record: id))
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
