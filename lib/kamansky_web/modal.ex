defmodule KamanskyWeb.Modal do
  import Phoenix.LiveView

  @callback open_assigns(Phoenix.LiveView.Socket.t, map) :: Phoenix.LiveView.Socket.t

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import KamanskyWeb.LiveHelpers

      @behaviour KamanskyWeb.Modal

      @impl true
      def mount(socket), do: {:ok, assign(socket, :open, false)}

      def handle_event("close", _params, socket), do: {:noreply, assign(socket, :open, false)}
      def handle_event("open", params, socket) do
        socket
        |> assign(:open, true)
        |> KamanskyWeb.Modal.dispatch_open_assigns(__MODULE__, params)
        |> noreply()
      end

      defoverridable mount: 1
    end
  end

  def dispatch_open_assigns(socket, module, params), do: apply(module, :open_assigns, [socket, params])
end
