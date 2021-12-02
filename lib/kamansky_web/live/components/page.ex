defmodule KamanskyWeb.Components.Page do
  @type flash_type :: :alert | :error | :success

  use Phoenix.Component

  import Phoenix.LiveView

  @spec confirmation_modal(map) :: Phoenix.LiveView.Rendered.t
  def confirmation_modal(assigns) do
    ~H"""
    <div
      id="kamansky-confirmation-modal"
      class="fixed z-10 inset-0 overflow-y-auto"
      x-cloak
      x-data="{detail: {action: null, content: null, external: false, title: null, values: null}, open: false}"
      x-on:keydown.window.escape="open = false"
      x-on:kamansky:open-confirmation-modal.camel.window="() => {
        open = true;
        detail = $event.detail;

        if ($event.detail.values) {
          for (value of $event.detail.values) {
            $refs.success.setAttribute(`phx-value-${value.key}`, value.value);
          }
        }
      }"
      x-on:phx:kamansky:close-confirmation-modal.camel.window="open = false"
      x-show="open"
      aria-labelledby="modal-title"
      aria-modal="true"
    >
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          x-on:click="open = false"
          x-show="open"
          x-transition:enter="ease-out duration-300"
          x-transition:enter-start="opacity-0"
          x-transition:enter-end="opacity-100"
          x-transition:leave="ease-in duration-200"
          x-transition:leave-start="opacity-100"
          x-transition:leave-end="opacity-0"
          aria-hidden="true"
        > </div>
        <!-- This element is to trick the browser into centering the modal contents. -->
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">​</span>
        <div
          class="align-bottom bg-white inline-block overflow-hidden pb-4 pt-5 px-4 rounded-lg shadow-xl text-left transform transition-all sm:align-middle sm:max-w-lg sm:my-8 sm:p-6 sm:w-full"
          x-show="open"
          x-transition:enter="ease-out duration-300"
          x-transition:enter-start="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          x-transition:enter-end="opacity-100 translate-y-0 sm:scale-100"
          x-transition:leave="ease-in duration-200"
          x-transition:leave-start="opacity-100 translate-y-0 sm:scale-100"
          x-transition:leave-end="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          >
            <div class="sm:flex sm:items-start">
              <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 sm:mx-0 sm:h-10 sm:w-10">
                <svg
                  class="h-6 text-blue-600 w-6"
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
                <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title" x-text="detail.title" />
                <div class="mt-2">
                  <p class="text-sm text-gray-500" x-text="detail.content" />
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
              <button
                type="button"
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white transition ease-in-out duration-150 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm"
                :class="detail.external && 'kamansky-external'"
                :phx-click="detail.action"
                x-ref="success"
              >
                <div class="kamansky-button-loading">
                  <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Processing
                </div>
                <span class="kamansky-button-normal" x-text="detail.title" />
              </button>
              <button
                type="button"
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
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

  @spec flash(map) :: Phoenix.LiveView.Rendered.t
  def flash(assigns) do
    ~H"""
    <%= if @flash do %>
      <div
        id="kamansky-flash"
        class={"mx-auto px-4 py-4 rounded-md w-9/12 " <> flash_background_color(@flash.type)}
        phx-hook="flash"
        phx-value-type={@flash.type}
        x-data={
          "{
            init () {
              this.show = true;
              if($el.getAttribute('phx-value-type') == 'success') {
                setTimeout(() => {
                  this.show = false;
                  setTimeout(() => $dispatch('kamansky:clear-flash'), 600);
                }, 3000);
              }
            },
            show: true
          }"
        }
        x-on:kamansky:flash-updated.camel="init"
        x-show="show"
        x-transition:enter="transition-all ease-out duration-500"
        x-transition:enter-start="max-h-0 py-0"
        x-transition:enter-end="max-h-14 py-4"
        x-transition:leave="transition-all ease-in duration-500"
        x-transition:leave-start="max-h-14 py-4"
        x-transition:leave-end="max-h-0 py-0"
      >
        <div class="flex">
          <div class="flex-shrink-0">
            <.flash_icon type={@flash.type} />
          </div>
          <div
            class="ml-3 "
            x-show="show"
            x-transition:leave="transition-all ease-in duration-500"
            x-transition:leave-start="max-h-14 scale-y-100"
            x-transition:leave-end="max-h-0 scale-y-0"
          >
            <p class={"text-sm font-medium " <> flash_text_color(@flash.type)}><%= @flash.message %></p>
          </div>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button
                type="button"
                class={"inline-flex rounded-md p-1.5 focus:outline-none focus:ring-2 focus:ring-offset-2 " <> flash_button_style(@flash.type)}
                x-on:click="() => {
                  this.show = false;
                  setTimeout(() => $dispatch('kamansky:clear-flash'), 600);
                }"
              >
                <span class="sr-only">Dismiss</span>
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path
                    fill-rule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  @spec header_button(map) :: Phoenix.LiveView.Rendered.t
  def header_button(assigns) do
    with assigns <- assign_new(assigns, :display, fn -> true end),
      attributes <- assigns_to_attributes(assigns, [:color, :display])
    do
      ~H"""
      <%= if @display do %>
        <button
          type="button"
          class={
            "inline-flex items-center px-4 py-2 border rounded-md shadow-sm text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" <>
              button_color(Map.get(assigns, :color, "blue"))
          }
          {attributes}
        >
          <%= render_slot(@inner_block) %>
        </button>
      <% end %>
      """
    end
  end

  @spec header_button_with_confirmation(map) :: Phoenix.LiveView.Rendered.t
  def header_button_with_confirmation(assigns) do
    with assigns <- assign_new(assigns, :display, fn -> true end),
      assigns <- assign_new(assigns, :confirmation_external, fn -> false end),
      attributes <- assigns_to_attributes(assigns, [:color, :confirmation_action, :confirmation_content, :confirmation_external, :confirmation_values, :display])
    do
      ~H"""
      <%= if @display do %>
        <button
          type="button"
          class={
            "inline-flex items-center px-4 py-2 border rounded-md shadow-sm text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" <>
              button_color(Map.get(assigns, :color, "blue"))
          }
          x-data
          x-on:click={
            confirmation_dispatch(
              @confirmation_action,
              @confirmation_content,
              @confirmation_external,
              @confirmation_title,
              @confirmation_values
            )
          }
          {attributes}
        >
          <%= render_slot(@inner_block) %>
        </button>
      <% end %>
      """
    end
  end

  @spec link_with_confirmation(map) :: Phoenix.LiveView.Rendered.t
  def link_with_confirmation(assigns) do
    ~H"""
    <a
      class="action-icon"
      title={@title}
      x-data
      x-on:click={confirmation_dispatch(@action, @content, Map.get(assigns, :external, false), @title, @values)}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  @spec navbar_link(map) :: Phoenix.LiveView.Rendered.t
  def navbar_link(assigns) do
    ~H"""
    <%= live_redirect @title,
      to: @to,
      class: navbar_link_class(@platform, @active)
    %>
    """
  end

  @spec button_color(String.t) :: String.t
  defp button_color("blue"), do: " bg-indigo-600 border-transparent text-white hover:bg-indigo-700"
  defp button_color("gray"), do: " bg-white border-gray-300 text-gray-700 hover:bg-gray-50"
  defp button_color("secondary"), do: " bg-indigo-100 border-transparent text-indigo-700 hover:bg-indigo-200"

  @spec confirmation_dispatch(String.t, String.t, boolean, String.t, [{String.t, String.t}]) :: String.t
  defp confirmation_dispatch(action, content, external, title, values) do
    "$dispatch(
      'kamansky:openConfirmationModal',
      {
        action: '#{action}',
        content: '#{content}',
        external: #{external},
        title: '#{title}',
        values: [#{Enum.map_join(values, ",", &("{key:'#{elem(&1, 0)}',value:'#{elem(&1, 1)}'}"))}]
      }
    )"
  end

  @spec flash_background_color(flash_type) :: String.t
  defp flash_background_color(:error), do: "bg-red-50"
  defp flash_background_color(:success), do: "bg-green-50"

  @spec flash_button_style(flash_type) :: String.t
  defp flash_button_style(:error), do: "bg-red-50 text-red-600 hover:bg-red-50 focus:ring-offset-red-50 focus:ring-red-700"
  defp flash_button_style(:success), do: "bg-green-50 text-green-500 hover:bg-green-100 focus:ring-offset-green-50 focus:ring-green-600"

  @spec flash_icon(%{required(:type) => flash_type}) :: Phoenix.LiveView.Rendered.t
  def flash_icon(%{type: :error} = assigns) do
    ~H"""
    <svg
      class="h-5 text-red-500 w-5"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 20 20"
      fill="currentColor"
      x-show="show"
      x-transition:leave="transition-all ease-in duration-500"
      x-transition:leave-start="max-h-4 scale-y-100"
      x-transition:leave-end="max-h-0 scale-y-0"
    >
      <path
        fill-rule="evenodd"
        d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  def flash_icon(%{type: :success} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="h-5 text-green-400 w-5"
      viewBox="0 0 20 20"
      fill="currentColor"
      x-show="show"
      x-transition:leave="transition-all ease-in duration-500"
      x-transition:leave-start="max-h-4 scale-y-100"
      x-transition:leave-end="max-h-0 scale-y-0"
    >
      <path
        fill-rule="evenodd"
        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  @spec flash_text_color(atom) :: String.t
  defp flash_text_color(:error), do: "text-red-800"
  defp flash_text_color(:success), do: "text-green-700"

  @spec navbar_link_class(String.t, boolean) :: String.t
  defp navbar_link_class("desktop", true), do: "font-medium px-3 py-2 rounded-md text-sm bg-gray-900 text-white"
  defp navbar_link_class("desktop", false), do: "font-medium px-3 py-2 rounded-md text-sm text-gray-300 hover:bg-gray-700 hover:text-white"
  defp navbar_link_class("mobile", true), do: "block font-medium px-3 py-2 rounded-md text-base bg-gray-900 text-white"
  defp navbar_link_class("mobile", false), do: "block font-medium px-3 py-2 rounded-md text-base text-gray-300 hover:bg-gray-700 hover:text-white"
end
