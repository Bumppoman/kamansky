defmodule KamanskyWeb.Components.Modal do
  use Phoenix.Component

  @spec modal(map) :: Phoenix.LiveView.Rendered.t
  def modal(assigns) do
    ~H"""
    <div
      class="bottom-0 fixed flex h-screen inset-x-0 overflow-y-auto z-50"
      id={"kamansky-modal-#{@parent_id}"}
      phx-hook="modalInit"
      phx-target={"##{@parent_id}"}
      x-data={"{open: false}"}
      x-init={
        "() => {
          $nextTick(() => open = true);
          $watch('open', isOpen => $dispatch('kamansky:toggle-modal', { open: isOpen, id: '##{@parent_id}' }));
        }"
      }
      x-on:phx:kamansky:close-modal.camel.window="open = false"
      x-show="open"
    >
      <div
        class="fixed inset-0 transition-opacity"
        x-show="open"
        x-transition:enter="ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
      >
        <div class="absolute bg-gray-900 inset-0 opacity-50"></div>
      </div>
      <div
        class="max-w-3xl m-auto px-4 shadow sm:px-0 w-full"
        x-show="open"
        x-transition:enter="ease-out duration-300"
        x-transition:enter-start="opacity-0 sm:scale-95"
        x-transition:enter-end="opacity-100 sm:scale-100"
        x-transition:leave="ease-in duration-200"
        x-transition:leave-start="opacity-100 sm:scale-100"
        x-transition:leave-end="opacity-0 sm:scale-95"
      >
        <div
          class="bg-white border border-gray-200 flex flex-col relative sm:rounded-lg sm:overflow-hidden"
          x-on:click.away="open = false"
          x-on:keydown.escape.window="open = false"
        >
          <div class="flex items-center justify-between p-4">
            <h3 class="text-lg leading-6 font-medium text-gray-900"><%= @title %></h3>
              <button
                class="
                  text-gray-400
                  focus:outline-none
                  focus:text-gray-500
                  hover:text-gray-500"
                type="button"
                x-on:click="open = false"
              >
                <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
          </div>
          <div class="flex-auto p-4 relative w-full">
            <%= render_slot(@inner_block) %>
          </div>
          <%= unless assigns[:footer] == false do %>
            <div class="bg-gray-50 flex flex-row-reverse px-4 py-3 text-right sm:px-6">
              <button
                type="submit"
                class={"btn btn-blue ml-1" <> if(Map.get(assigns, :external), do: " kamansky-external", else: "")}
                form={assigns[:form_id]}
                phx-click={assigns[:button_action]}
              >
                <div class="kamansky-button-loading">
                  <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Processing
                </div>
                <span class="kamansky-button-normal"><%= Map.get(assigns, :button_text, @title) %></span>
              </button>
              <button
                class="btn btn-gray"
                type="button"
                x-on:click="open = false"
              >Cancel</button>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
