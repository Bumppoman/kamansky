defmodule KamanskyWeb.StampLive.CollectionComponents do
  use Phoenix.Component

  alias KamanskyWeb.Router.Helpers, as: Routes

  def types_footer(assigns) do
    ~H"""
    <ul class="nav nav-pills justify-content-center">
      <li class="nav-item">
        <%= live_redirect "In Collection",
          to: Routes.stamp_index_path(@socket, :collection),
          class: ["nav-link"] ++ (if @live_action == :collection, do: [" active"], else: [])
        %>
      </li>
      <li class="nav-item">
        <%= live_redirect "Below XF",
          to: Routes.stamp_index_path(@socket, :collection_to_replace),
          class: ["nav-link"] ++ (if @live_action == :collection_to_replace, do: [" active"], else: [])
        %>
      </li>
      <li class="nav-item">
        <%= live_redirect "Missing",
          to: Routes.stamp_reference_index_path(@socket, :missing_from_collection),
          class: ["nav-link"] ++ (if @live_action == :missing_from_collection, do: [" active"], else: [])
        %>
      </li>
    </ul>
    """
  end
end
