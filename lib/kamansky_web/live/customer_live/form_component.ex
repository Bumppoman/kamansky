defmodule KamanskyWeb.CustomerLive.FormComponent do
  use KamanskyWeb, :live_component

  import Kamansky.Helpers

  alias Kamansky.Sales.Customers
  alias Kamansky.Sales.Customers.Customer

  @impl true
  def update(%{customer: customer} = assigns, socket) do
    with changeset <- Customers.change_customer(customer),
      socket <-
        socket
        |> assign(assigns)
        |> assign(:changeset, changeset)
    do
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"customer" => customer_params}, socket) do
    changeset =
      socket.assigns.customer
      |> Customers.change_customer(customer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("submit", %{"customer" => customer_params}, socket) do
    save_customer(socket, customer_params)
  end

  defp save_customer(socket, customer_params) do
    case Customers.update_customer(socket.assigns.customer, customer_params) do
      {:ok, %Customer{id: id}} ->
        {:noreply,
         socket
         |> put_flash(:info, "You have successfully updated this customer.")
         |> push_redirect(to: socket.assigns.return_to, go_to_record: id)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
