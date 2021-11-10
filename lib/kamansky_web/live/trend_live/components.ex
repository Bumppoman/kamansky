defmodule KamanskyWeb.TrendLive.Components do
  use Phoenix.Component

  alias KamanskyWeb.Router.Helpers, as: Routes

  @spec footer(map) :: Phoenix.LiveView.Rendered.t
  def footer(assigns) do
    ~H"""
    <div class="mt-4 sm:hidden">
      <label for="tabs" class="sr-only">Select a tab</label>
      <select
        id="tabs"
        name="tabs"
        class="block w-full focus:ring-indigo-500 focus:border-indigo-500 border-gray-300 rounded-md"
        x-data
        x-on:change="window.location.href = $el.value"
      >
        <option
          value={Routes.trend_index_path(@socket, :index)}
          {if @socket.view == KamanskyWeb.TrendLive.Index, do: [selected: ""], else: []}
        >Overall</option>
        <option
          value={Routes.trend_sold_path(@socket, :index)}
          {if @socket.view == KamanskyWeb.TrendLive.Sold, do: [selected: ""], else: []}
        >Below XF</option>
      </select>
    </div>
    <div class="hidden sm:block sm:mt-4">
      <nav class="flex font-medium justify-center leading-6">
        <%= live_redirect "Overall",
          to: Routes.trend_index_path(@socket, :index),
          class: "block mr-3 px-4 py-2 text-gray-500" <> (
            if @socket.view == KamanskyWeb.TrendLive.Index do
              " bg-blue-100 rounded-md text-blue-600"
            else
              " text-opacity-70"
            end
          )
        %>
        <%= live_redirect "Sold",
          to: Routes.trend_sold_path(@socket, :index),
          class: "block mr-3 px-4 py-2 text-gray-500" <> (
            if @socket.view == KamanskyWeb.TrendLive.Sold do
              " bg-blue-100 rounded-md text-blue-600"
            else
              " text-opacity-70"
            end
          )
        %>
      </nav>
    </div>
    """
  end
end
