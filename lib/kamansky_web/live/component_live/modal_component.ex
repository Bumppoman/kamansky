defmodule KamanskyWeb.ComponentLive.ModalComponent do
  use KamanskyWeb, :live_component

  @impl true
  @spec render(map) :: Phoenix.LiveView.Rendered.t
  def render(assigns) do
    ~H"""
    <div id={@id} class="modal fade"
      phx-hook="modalHook"
      phx-target={"##{@id}"}
      phx-page-loading
    >
      <div class={"modal-dialog modal-dialog-centered #{size_for_type(Keyword.get(@opts, :type))}"}>
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title"><%= @opts[:title] %></h5>
            <a class="btn btn-close close-modal"></a>
          </div>
          <div class="modal-body">
            <%= live_component @component, @opts %>
          </div>
          <div class="modal-footer">
            <a class="btn btn-secondary close-modal">Cancel</a>
            <button
              type="submit"
              class="btn btn-primary"
              form={Keyword.get(@opts, :form_id)}
              phx-click={Keyword.get(@opts, :button_action)}
            ><%= @button_text %></button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  @spec handle_event(String.t, map, Phoenix.LiveView.Socket.t) :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end

  @spec size_for_type(atom) :: String.t
  defp size_for_type(:confirmation), do: "modal-sm"
  defp size_for_type(:confirmation_large), do: ""
  defp size_for_type(_), do: "modal-lg"
end
