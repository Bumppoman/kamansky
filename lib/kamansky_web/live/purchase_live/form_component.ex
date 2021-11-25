defmodule KamanskyWeb.PurchaseLive.FormComponent do
  use KamanskyWeb, :live_component

  alias Kamansky.Operations.Purchases
  alias Kamansky.Operations.Purchases.Purchase

  @impl true
  @spec update(%{required(:trigger_params) => %{required(String.t) => any}, optional(atom) => any}, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(%{trigger_params: %{"action" => action, "purchase-id" => purchase_id}} = assigns, socket) do
    with purchase <- Purchases.get_or_initialize_purchase(purchase_id) do
      {
        :ok,
        socket
        |> assign(assigns)
        |> assign(:action, action)
        |> assign(:changeset, Purchases.change_purchase(purchase))
        |> assign(:purchase, purchase)
        |> assign(:title, (if action == "new", do: "Add Purchase", else: "Update Purchase"))
      }
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
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
  def handle_event("submit", %{"purchase" => purchase_params}, socket), do: save_purchase(socket, purchase_params)

  @spec save_purchase(Phoenix.LiveView.Socket.t, map) :: {:noreply, Phoenix.LiveView.Socket.t}
  defp save_purchase(%Phoenix.LiveView.Socket{assigns: %{action: "edit"}} = socket, purchase_params) do
    case Purchases.update_purchase(socket.assigns.purchase, purchase_params) do
      {:ok, %Purchase{id: purchase_id}} ->
        send self(), {:purchase_updated, purchase_id}
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_purchase(%Phoenix.LiveView.Socket{assigns: %{action: "new"}} = socket, purchase_params) do
    case Purchases.create_purchase(purchase_params) do
      {:ok, %Purchase{id: purchase_id}} ->
        send self(), {:purchase_added, purchase_id}
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
