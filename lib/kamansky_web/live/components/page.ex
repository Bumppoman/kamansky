defmodule KamanskyWeb.Components.Page do
  use Phoenix.Component

  @spec confirm(map) :: Phoenix.LiveView.Rendered.t
  def confirm(assigns) do
    ~H"""
    <div
      id="kamansky-confirmation-modal"
      class="fixed inset-0 overflow-y-auto z-10"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
      x-data="{detail: {action: null, content: null, title: null, values: null}, open: false}"
      x-show="open"
      @open-confirmation-modal.window="() => {
        open = true;
        detail = $event.detail;

        if ($event.detail.values) {
          for (value of $event.detail.values) {
            $refs.success.setAttribute(`phx-value-${value.key}`, value.value);
          }
        }
      }"
      @phx:kamansky:close-confirmation-modal.camel.window="open = false"
    >
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          aria-hidden="true"
          x-show="open"
          x-transition:enter="ease-out duration-300"
          x-transition:enter-start="opacity-0"
          x-transition:enter-end="opacity-100"
          x-transition:leave="ease-in duration-200"
          x-transition:leave-start="opacity-100"
          x-transition:leave-end="opacity-0"
        ></div>

        <!-- This element is to trick the browser into centering the modal contents. -->
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div
          class="
            align-bottom
            bg-white
            inline-block
            overflow-hidden
            rounded-lg
            shadow-xl
            text-left
            transform
            transition-all
            sm:align-middle
            sm:max-w-lg
            sm:my-8
            sm:w-full"
          x-show="open"
          x-transition:enter="ease-out duration-300"
          x-transition:enter-start="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          x-transition:enter-end="opacity-100 translate-y-0 sm:scale-100"
          x-transition:leave="ease-in duration-200"
          x-transition:leave-start="opacity-100 translate-y-0 sm:scale-100"
          x-transition:leave-end="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
        >
          <div class="bg-white pb-4 pt-5 px-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div
                class="
                  bg-blue-100
                  flex
                  flex-shrink-0
                  h-12
                  items-center
                  justify-center
                  mx-auto
                  rounded-full
                  w-12
                  sm:h-10
                  sm:mx-0
                  sm:w-10"
              >
                <!-- Heroicon name: outline/exclamation -->
                <svg
                  class="h-6 w-6 text-blue-600"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <h3 class="text-lg leading-6 font-medium text-gray-900" x-text="detail.title" />
                <div class="mt-2">
                  <p class="text-gray-500 text-sm" x-text="detail.content" />
                </div>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              class="
                bg-blue-600
                border
                border-transparent
                font-medium
                inline-flex
                justify-center
                rounded-md
                px-4
                py-2
                shadow-sm
                text-base
                text-white
                w-full
                focus:outline-none
                focus:ring-2
                focus:ring-offset-2
                focus:ring-blue-500
                hover:bg-blue-700
                sm:ml-3
                sm:w-auto
                sm:text-sm"
              :phx-click="detail.action"
              x-ref="success"
              x-text="detail.title"
            />
            <button
              type="button"
              class="
                bg-white
                border
                border-gray-300
                font-medium
                inline-flex
                justify-center
                mt-3
                rounded-md
                px-4
                py-2
                shadow-sm
                text-base
                text-gray-700
                w-full
                focus:outline-none
                focus:ring-2
                focus:ring-offset-2
                focus:ring-indigo-500
                hover:bg-gray-50
                sm:mt-0
                sm:ml-3
                sm:w-auto
                sm:text-sm"
              x-on:click="open = false"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @spec link_with_confirmation(map) :: Phoenix.LiveView.Rendered.t
  def link_with_confirmation(assigns) do
    ~H"""
    <a
      class="action-icon"
      title={@title}
      x-data
      x-on:click=
      {
        "$dispatch(
          'open-confirmation-modal',
          {
            action: '#{@action}',
            content: '#{@content}',
            title: '#{@title}',
            values: [#{Enum.map_join(@values, ",", &("{key:'#{elem(&1, 0)}',value:'#{elem(&1, 1)}'}"))}]
          }
        )"
      }
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  @spec page_header(map) :: Phoenix.LiveView.Rendered.t
  def page_header(assigns) do
    ~H"""
    <div>
      <%= if Map.has_key?(assigns, :breadcrumbs) do %>
        <div>
          <nav class="hidden sm:flex" aria-label="Breadcrumb">
            <ol role="list" class="flex items-center space-x-4">
              <li>
                <div class="flex">
                  <%= live_redirect elem(hd(@breadcrumbs), 0),
                    to: elem(hd(@breadcrumbs), 1),
                    class: "font-medium text-gray-500 text-sm hover:text-gray-700"
                  %>
                </div>
              </li>
              <%= for breadcrumb <- tl(@breadcrumbs) do %>
                <li>
                  <div class="flex items-center">
                    <KamanskyWeb.Components.Icons.chevron_right />
                    <%= if is_tuple(breadcrumb) do %>
                      <%= live_redirect elem(breadcrumb, 0),
                        to: elem(breadcrumb, 1),
                        class: "font-medium ml-4 text-gray-500 text-sm hover:text-gray-700"
                      %>
                    <% else %>
                      <span class="font-medium ml-4 text-gray-500 text-sm"><%= breadcrumb %></span>
                    <% end %>
                  </div>
                </li>
              <% end %>
            </ol>
          </nav>
        </div>
      <% end %>
      <div class="mt-2 md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            <%= @page_title %>
          </h2>
        </div>
        <%= if Map.has_key?(assigns, :buttons) do %>
          <div class="mt-5 flex lg:mt-0 lg:ml-4">
            <%= for button <- @buttons, Map.get(button, :display, true) do %>
              <span class="sm:ml-3">
                <button
                  type="button"
                  class={"
                    inline-flex
                    items-center
                    px-4
                    py-2
                    border
                    rounded-md
                    shadow-sm
                    text-sm
                    font-medium
                    focus:outline-none
                    focus:ring-2
                    focus:ring-offset-2
                    focus:ring-indigo-500" <> button_color(Map.get(button, :color, :blue))}
                  {button.options}
                >
                  <%= button.title %>
                </button>
              </span>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp button_color(:blue), do: " bg-indigo-600 border-transparent text-white hover:bg-indigo-700"
  defp button_color(:gray), do: " bg-white border-gray-300 text-gray-700 hover:bg-gray-50"
end
