defmodule KamanskyWeb.UserLive.Settings do
  use KamanskyWeb, :live_view

  alias Kamansky.Operations.Accounts
  alias Kamansky.Operations.Accounts.User
  alias Kamansky.Operations.Notifications.Notification

  @impl true
  @spec mount(map, map, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "User Settings")
    }
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("submit_subscriptions", %{"user" => %{"subscriptions" => subscriptions_params}}, socket) do
    with subscriptions <- subscriptions(subscriptions_params) do
      socket.assigns.current_user
      |> Accounts.change_user_subscriptions(subscriptions)
      |> Accounts.update_user()
      |> case do
        {:ok, user} ->
          {
            :noreply,
            socket
            |> put_flash(:info, %{type: :success, message: "You have successfully updated your subscriptions.", timestamp: DateTime.utc_now()})
            |> assign(:current_user, user)
            |> assign(:subscriptions, load_user_subscriptions(user))
          }
      end
    end
  end

  def handle_event("validate_subscriptions", %{"user" => %{"subscriptions" => subscriptions_params}}, socket) do
    {:noreply, assign(socket, :subscriptions, subscriptions(subscriptions_params))}
  end

  @impl true
  @spec handle_params(map, String.t, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_params(%{"section" => "subscriptions"}, _uri, socket) do
    with socket <- assign(socket, :current_user, Accounts.load_subscriptions_for_user(socket.assigns.current_user)) do
      {
        :noreply,
        socket
        |> assign(:changeset, Accounts.change_user_subscriptions(socket.assigns.current_user, []))
        |> assign(:section, "subscriptions")
        |> assign(:subscriptions, load_user_subscriptions(socket.assigns.current_user))
        |> assign(:topics, Notification.list_topic_details())
      }
    end
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :section, Map.get(params, "section", "account"))}
  end

  @spec load_user_subscriptions(User.t) :: [String.t]
  defp load_user_subscriptions(%User{subscriptions: subscriptions}), do: Enum.map(subscriptions, &(Atom.to_string(&1.topic)))

  @spec subscriptions(map) :: [String.t]
  defp subscriptions(params), do: Enum.flat_map(params, fn {k, v} -> if v == "true", do: [k], else: [] end)

  @spec subscribed?([String.t], atom) :: boolean
  defp subscribed?(subscriptions, topic), do: Enum.member?(subscriptions, Atom.to_string(topic))
end
