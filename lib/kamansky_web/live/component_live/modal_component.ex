defmodule KamanskyWeb.ComponentLive.ModalComponent do
  use KamanskyWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="modal fade"
      phx-hook="modalHook"
      phx-target="#<%= @id %>"
      phx-page-loading
    >
      <div class="modal-dialog modal-dialog-centered <%= size_for_type(Keyword.get(@opts, :type)) %>">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title"><%= @opts[:title] %></h5>
            <a class="btn btn-close close-modal"></a>
          </div>
          <div class="modal-body">
            <%= live_component @component, @opts %>
          </div>
          <%= unless @opts[:footer] == false do %>
            <div class="modal-footer">
              <a class="btn btn-secondary close-modal">Cancel</a>
              <button
                type="submit"
                class="btn btn-primary"
                form="<%= Keyword.get(@opts, :form_id) %>"
                phx-click="<%= Keyword.get(@opts, :button_action) %>"
              ><%= @opts[:title] %></button>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end

  defp size_for_type(:confirmation), do: "modal-sm"
  defp size_for_type(:confirmation_large), do: ""
  defp size_for_type(_), do: "modal-lg"
end
