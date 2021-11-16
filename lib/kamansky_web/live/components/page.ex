defmodule KamanskyWeb.Components.Page do
  use Phoenix.Component

  @spec link_with_confirmation(map) :: Phoenix.LiveView.Rendered.t
  def link_with_confirmation(assigns) do
    ~H"""
    <a
      class="action-icon"
      title={@title}
      x-data
      x-on:click={confirmation_dispatch(@action, @content, @title, @values)}
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
              <.header_button {button} />
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @spec button_color(atom) :: String.t
  defp button_color(:blue), do: " bg-indigo-600 border-transparent text-white hover:bg-indigo-700"
  defp button_color(:gray), do: " bg-white border-gray-300 text-gray-700 hover:bg-gray-50"
  defp button_color(:secondary), do: " bg-indigo-100 border-transparent text-indigo-700 hover:bg-indigo-200"

  @spec confirmation_dispatch(String.t, String.t, String.t, [{String.t, String.t}]) :: String.t
  defp confirmation_dispatch(action, content, title, values) do
    "$dispatch(
      'kamansky:openConfirmationModal',
      {
        action: '#{action}',
        content: '#{content}',
        title: '#{title}',
        values: [#{Enum.map_join(values, ",", &("{key:'#{elem(&1, 0)}',value:'#{elem(&1, 1)}'}"))}]
      }
    )"
  end

  defp header_button(%{with_confirmation: true} = assigns) do
    ~H"""
    <button
      type="button"
      class={"
        inline-flex
        items-center
        ml-3
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
        focus:ring-indigo-500" <> button_color(Map.get(assigns, :color, :blue))}
      x-data
      x-on:click={confirmation_dispatch(@options.confirmation.action, @options.confirmation.content, @title, @options.confirmation.values)}
    >
      <%= @title %>
    </button>
    """
  end

  defp header_button(assigns) do
    ~H"""
    <button
      type="button"
      class={"
        inline-flex
        items-center
        ml-3
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
        focus:ring-indigo-500" <> button_color(Map.get(assigns, :color, :blue))}
      { @options }
    >
      <%= @title %>
    </button>
    """
  end

  @spec navbar_link_class(String.t, boolean) :: String.t
  defp navbar_link_class("desktop", true), do: "font-medium px-3 py-2 rounded-md text-sm bg-gray-900 text-white"
  defp navbar_link_class("desktop", false), do: "font-medium px-3 py-2 rounded-md text-sm text-gray-300 hover:bg-gray-700 hover:text-white"
  defp navbar_link_class("mobile", true), do: "block font-medium px-3 py-2 rounded-md text-base bg-gray-900 text-white"
  defp navbar_link_class("mobile", false), do: "block font-medium px-3 py-2 rounded-md text-base text-gray-300 hover:bg-gray-700 hover:text-white"
end
