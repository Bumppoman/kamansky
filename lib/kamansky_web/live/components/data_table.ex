defmodule KamanskyWeb.Components.DataTable do
  use Phoenix.Component

  import Phoenix.HTML.Form

  @spec table(map) :: Phoenix.LiveView.Rendered.t
  def table(assigns) do
    ~H"""
    <div class="kamansky-data-table">
      <div class="flex items-center justify-between py-2">
        <div class="pb-2.5">
          <label class="mb-0">
            <%= select :kamansky_data_table,
              :per_page,
              [
                [key: "5", value: 5],
                [key: "10", value: 10],
                [key: "20", value: 20],
                [key: "25", value: 25]
              ],
              class: "border-gray-300 mr-3",
              selected: Map.get(assigns, :per_page, 10)
            %> items/page
          </label>
        </div>
        <div class="pb-2.5">
          <form phx-change="search">
            <input
              class="block border border-gray-300 leading-normal px-3 py-2.5 text-gray-600 text-sm w-full"
              name="search"
              placeholder="Search..."
              value={Map.get(assigns, :search, "")}
            />
          </form>
        </div>
      </div>
      <div class="flex flex-col">
        <div class="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
            <div class="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <%= for {col, index} <- Enum.with_index(@col) do %>
                      <th
                        scope="col"
                        class={
                          "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" <>
                            (if index == @pagination.sort, do: " sorting-#{@pagination.direction}", else: "")
                        }
                      >
                        <%= if col[:sort] == "disabled" do %>
                          <%= col[:label] %>
                        <% else %>
                          <%= live_patch col[:label],
                            to: path(@socket, @live_action, @pagination, sort: index, direction: sort_direction(index, @pagination), show: nil)
                          %>
                        <% end %>
                      </th>
                    <% end %>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= if Enum.empty?(@rows) do %>
                    <tr>
                      <td class="text-center" colspan={Enum.count(@col)}><%= @empty_message %></td>
                    </tr>
                  <% else %>
                    <%= for {row, row_index} <- Enum.with_index(@rows) do %>
                      <tr class={if rem(row_index, 2) == 0, do: "even", else: "odd"}>
                        <%= for {col, col_index} <- Enum.with_index(@col) do %>
                          <td class={if col_index == @pagination.sort, do: "sorting"}><%= render_slot(col, row) %></td>
                        <% end %>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
                <%= if @pagination.total_items > 0 do %>
                  <tfoot class={if @pagination.total_pages == 1, do: "hidden sm:table-footer-group", else: ""}>
                    <tr>
                      <td colspan={Enum.count(@col)}>
                        <div class="bg-white px-4 flex items-center justify-between sm:px-6">
                          <div class="flex-1 flex justify-between sm:hidden">
                            <%= live_patch "Previous",
                              to: path(@socket, @live_action, @pagination, page: @pagination.page - 1),
                              class: "relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50" <>
                                (if assigns[:current_page] == 1, do: " disabled", else: "")
                            %>
                            <%= live_patch "Next",
                              to: path(@socket, @live_action, @pagination, page: @pagination.page + 1),
                              class: "ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50" <>
                                (if @pagination.page == @pagination.total_pages, do: " disabled", else: "")
                            %>
                          </div>
                          <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                            <div>
                              <p class="text-sm text-gray-700">
                                Showing
                                <span class="font-medium"><%= start_value(@pagination.page, @pagination.per_page) %></span>
                                to
                                <span class="font-medium"><%= end_value(@pagination.page, @pagination.per_page, @pagination.total_items) %></span>
                                of
                                <span class="font-medium"><%= @pagination.total_items %></span>
                                entries
                              </p>
                            </div>
                            <%= if @pagination.total_pages > 1 do %>
                              <div>
                                <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                                  <%= live_patch to: path(@socket, @live_action, @pagination, page: @pagination.page - 1),
                                    class: "relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50" <>
                                      (if @pagination.page == 1, do: " disabled", else: "")
                                  do %>
                                    <span class="sr-only">Previous</span>
                                    <KamanskyWeb.Components.Icons.chevron_left />
                                  <% end %>
                                  <%= page_links(@socket, @live_action, @pagination) %>
                                  <%= live_patch to: path(@socket, @live_action, @pagination, page: @pagination.page + 1),
                                    class: "relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50" <>
                                      (if @pagination.page == @pagination.total_pages, do: " disabled", else: "")
                                  do %>
                                    <span class="sr-only">Next</span>
                                    <KamanskyWeb.Components.Icons.chevron_right />
                                  <% end %>
                                </nav>
                              </div>
                            <% end %>
                          </div>
                        </div>
                      </td>
                    </tr>
                  </tfoot>
                <% end %>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp dummy_page_link do
    Phoenix.HTML.Tag.content_tag(
      :span,
      "...",
      class: "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700"
    )
  end

  @spec end_value(pos_integer, pos_integer, pos_integer) :: pos_integer
  defp end_value(current_page, per_page, total_items) do
    with start_value <- start_value(current_page, per_page) do
      if total_items < (per_page + start_value) do
        total_items
      else
        (start_value + per_page) - 1
      end
    end
  end

  @spec link_to_page(Phoenix.LiveView.Socket.t, atom, KamanskyWeb.Paginate.params, pos_integer) :: Phoenix.HTML.safe
  defp link_to_page(socket, action, pagination, page) do
    live_patch page,
      to: path(socket, action, pagination, page: page, show: nil),
      class: "relative inline-flex items-center px-4 py-2 border text-sm font-medium" <> (
        if page == pagination.page do
          " z-10 bg-indigo-50 border-indigo-500 text-indigo-600"
        else
          " bg-white border-gray-300 text-gray-500 hover:bg-gray-50"
        end
      )
  end

  @spec page_links(Phoenix.LiveView.Socket.t, atom, KamanskyWeb.Paginate.params) :: [String.t]
  defp page_links(socket, action, pagination) do
    cond do
      pagination.total_pages < 8 ->
        for page <- (1..pagination.total_pages) do
          link_to_page(socket, action, pagination, page)
        end
      pagination.page - 3 > 1 and pagination.page + 3 < pagination.total_pages ->
        with(
          pages <-
            for page <- (pagination.page - 2..pagination.page + 2) do
              link_to_page(socket, action, pagination, page)
            end
        ) do
          [link_to_page(socket, action, pagination, 1), dummy_page_link()]
          ++ pages
          ++ [dummy_page_link(), link_to_page(socket, action, pagination, pagination.total_pages)]
        end
      pagination.page + 7 < pagination.total_pages ->
        with(
          pages <-
            for page <- (1..7) do
              link_to_page(socket, action, pagination, page)
            end
        ) do
          pages ++ [dummy_page_link(), link_to_page(socket, action, pagination, pagination.total_pages)]
        end
      true ->
        pages =
          for page <- (pagination.total_pages - 7..pagination.total_pages) do
            link_to_page(socket, action, pagination, page)
          end

        [link_to_page(socket, action, pagination, 1), dummy_page_link()] ++ pages
    end
  end

  @spec path(Phoenix.LiveView.Socket.t, atom, Kamansky.Paginate.params, keyword) :: String.t
  defp path(socket, action, pagination, opts) do
    apply(
      socket.view,
      :self_path,
      [
        socket,
        action,
        pagination,
        Enum.into(opts, %{})
      ]
    )
  end

  @spec sort_direction(integer, Kamansky.Paginate.params) :: Kamansky.Paginate.sort_direction
  defp sort_direction(column, %{sort: column, direction: :asc}), do: :desc
  defp sort_direction(_column, _params), do: :asc

  @spec start_value(pos_integer, pos_integer) :: pos_integer
  defp start_value(current_page, per_page), do: ((current_page * per_page) - per_page) + 1
end
