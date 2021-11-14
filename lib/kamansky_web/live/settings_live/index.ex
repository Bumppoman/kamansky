defmodule KamanskyWeb.SettingsLive.Index do
  use KamanskyWeb, :live_view

  alias Kamansky.Operations.Administration

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    with settings <- Kamansky.Jobs.ManageSettings.list_settings() do
      {
        :ok,
        socket
        |> assign(:changeset, Administration.change_settings(settings))
        |> assign(:page_title, "Settings")
        |> assign(:settings, settings)
      }
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => any}, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("validate", %{"settings" => settings_params}, socket) do
    with changeset <-
      socket.assigns.settings
      |> Administration.change_settings(settings_params)
      |> Map.put(:action, :validate)
    do
      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("submit", %{"settings" => settings_params}, socket) do
    case Administration.update_settings(socket.assigns.settings, settings_params) do
      {:ok, settings} ->
        {
          :noreply,
          socket
          |> assign(:settings, settings)
          |> put_flash(:info, %{message: "You have successfully updated the application settings.", timestamp: DateTime.utc_now()})
        }
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
