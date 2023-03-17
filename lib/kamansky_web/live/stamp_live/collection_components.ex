defmodule KamanskyWeb.StampLive.CollectionComponents do
  use Phoenix.Component

  alias KamanskyWeb.Router.Helpers, as: Routes

  @spec types_footer(map) :: Phoenix.LiveView.Rendered.t
  def types_footer(assigns) do
    ~H"""
    <div class="mt-4 sm:hidden">
      <label for="tabs" class="sr-only">Select a tab</label>
      <select id="tabs" name="tabs" class="block w-full focus:ring-indigo-500 focus:border-indigo-500 border-gray-300 rounded-md" x-data
        x-on:change="window.location.href = $el.value">
        <option
          value={Routes.stamp_index_path(@socket, :collection)}
          {if @live_action == :collection, do: [selected: ""], else: []}>
          In Collection
        </option>
        <option
          value={Routes.stamp_index_path(@socket, :collection_to_replace)}
          {if @live_action == :collection_to_replace, do: [selected: ""], else: []}>
          Below XF
        </option>
        <option
          value={Routes.stamp_reference_index_path(@socket, :missing_from_collection)}
          {if @live_action == :missing_from_collection, do: [selected: ""], else: []}>
          Missing
        </option>
      </select>
    </div>
    <div class="hidden sm:block sm:mt-4">
      <nav class="flex font-medium justify-center leading-6">
        <.link navigate={Routes.stamp_index_path(@socket, :collection)}
          class={"block mr-3 px-4 py-2 text-gray-500" <> (if @live_action == :collection, do: " bg-blue-100 rounded-md text-blue-600", else: " text-opacity-70")}>
          In Collection
        </.link>
        <.link navigate={Routes.stamp_index_path(@socket, :collection_to_replace)}
          class={"block mr-3 px-4 py-2 text-gray-500" <> (
            if @live_action == :collection_to_replace do
              " bg-blue-100 rounded-md text-blue-600"
            else
              " text-opacity-70"
            end
          )}>
          Below XF
        </.link>
        <.link navigate={Routes.stamp_reference_index_path(@socket, :missing_from_collection)}
          class={"block mr-3 px-4 py-2 text-gray-500" <> (
            if @live_action == :missing_from_collection do
              " bg-blue-100 rounded-md text-blue-600"
            else
              " text-opacity-70"
            end
          )}>
          Missing
        </.link>
      </nav>
    </div>
    """
  end
end
