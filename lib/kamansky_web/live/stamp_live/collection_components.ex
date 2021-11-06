defmodule KamanskyWeb.StampLive.CollectionComponents do
  use Phoenix.Component

  alias KamanskyWeb.Router.Helpers, as: Routes

  @spec types_footer(map) :: Phoenix.LiveView.Rendered.t
  def types_footer(assigns) do
    ~H"""
    <nav class="flex font-medium justify-center leading-6 mt-4">
      <%= live_redirect "In Collection",
        to: Routes.stamp_index_path(@socket, :collection),
        class: "block mr-3 px-4 py-2 text-gray-500" <> (if @live_action == :collection, do: " bg-blue-100 rounded-md text-blue-600", else: " text-opacity-70")
      %>
      <%= live_redirect "Below XF",
        to: Routes.stamp_index_path(@socket, :collection_to_replace),
        class: "block mr-3 px-4 py-2 text-gray-500" <> (if @live_action == :collection_to_replace, do: " bg-blue-100 rounded-md text-blue-600", else: " text-opacity-70")
      %>
      <%= live_redirect "Missing",
        to: Routes.stamp_reference_index_path(@socket, :missing_from_collection),
        class: "block mr-3 px-4 py-2 text-gray-500" <> (if @live_action == :missing_from_collection, do: " bg-blue-100 rounded-md text-blue-600", else: " text-opacity-70")
      %>
    </nav>
    """
  end
end
