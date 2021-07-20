defmodule KamanskyWeb.ComponentLive.TableComponent do
  use KamanskyWeb, :live_component

  @default_table_data %{
    current_page: 1,
    page: 1,
    per_page: 10
  }

  def end_value(current_page, per_page, total_items) do
    start_value = start_value(current_page, per_page)

    cond do
      total_items < (per_page + start_value) ->
        total_items
      true ->
        (start_value + per_page) - 1
    end
  end

  @impl true
  def handle_event("go_to_page", %{"page" => page}, %{assigns: %{search: search}} = socket) when is_binary(search) do
    page = String.to_integer(page)

    {count, data} =
      load_data_for_page(
        %{
          data_source: socket.assigns.data_source,
          current_page: page,
          per_page: socket.assigns.per_page,
          search: search,
          sort: socket.assigns.sort
        }
      )

    socket =
      socket
      |> assign(current_page: page)
      |> assign(data: data)
      |> assign(search: search)
      |> assign(total_items: count)
      |> assign(total_pages: total_pages(count, socket.assigns.per_page))

    {:noreply, socket}
  end

  def handle_event("go_to_page", %{"page" => page}, socket) do
    page = String.to_integer(page)

    socket =
      socket
      |> assign(current_page: page)
      |> assign(
        data: load_data_for_page(
          %{
            data_source: socket.assigns.data_source,
            current_page: page,
            per_page: socket.assigns.per_page,
            search: socket.assigns.search,
            sort: socket.assigns.sort
          }
        )
      )

    {:noreply, socket}
  end

  def handle_event("per_page_changed", %{"per_page" => per_page}, socket) do
    per_page = String.to_integer(per_page)

    socket =
      socket
      |> assign(current_page: 1)
      |> assign(
        data: load_data_for_page(
          %{
            data_source: socket.assigns.data_source,
            current_page: 1,
            per_page: per_page,
            search: socket.assigns.search,
            sort: socket.assigns.sort
          }
        )
      )
      |> assign(per_page: per_page)
      |> assign(total_pages: total_pages(socket.assigns.total_items, per_page))

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {count, data} =
      load_data_for_page(
        %{
          data_source: socket.assigns.data_source,
          current_page: 1,
          per_page: socket.assigns.per_page,
          search: search,
          sort: socket.assigns.sort
        }
      )

    socket =
      socket
      |> assign(current_page: 1)
      |> assign(data: data)
      |> assign(search: search)
      |> assign(total_items: count)
      |> assign(total_pages: total_pages(count, socket.assigns.per_page))

    {:noreply, socket}
  end

  def handle_event("sort", %{"sort" => sort, "sort_direction" => sort_direction}, socket) do
    sort = %{column: String.to_integer(sort), direction: invert_sort_direction(sort_direction)}

    socket =
      socket
      |> assign(data: load_data_for_page(%{socket.assigns | sort: sort}))
      |> assign(sort: sort)

      {:noreply, socket}
  end

  def load_data_for_page(parameters) do
    parameters[:data_source].(
      %{
        limit: parameters[:per_page],
        offset: start_value(parameters[:current_page], parameters[:per_page]) - 1,
        search: parameters[:search],
        sort: parameters[:sort]
      }
    )
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(current_page: @default_table_data.current_page)
      |> assign(page: @default_table_data.page)
      |> assign(per_page: @default_table_data.per_page)

    {:ok, socket}
  end

  def page_links(current_page, total_pages, target) do
    cond do
      total_pages < 8 ->
        for page <- (1..total_pages) do
          link_to_page(page, current_page, target)
        end
      current_page - 3 > 1 and current_page + 3 < total_pages ->
        pages =
          for page <- (current_page - 2..current_page + 2) do
            link_to_page(page, current_page, target)
          end

        [link_to_page(1, current_page, target), dummy_page_link()]
        ++ pages
        ++ [dummy_page_link(), link_to_page(total_pages, current_page, target)]
      current_page + 7 < total_pages ->
        pages =
          for page <- (1..7) do
            link_to_page(page, current_page, target)
          end

        pages ++ [dummy_page_link(), link_to_page(total_pages, current_page, target)]
      true ->
        pages =
          for page <- (total_pages - 7..total_pages) do
            link_to_page(page, current_page, target)
          end

        [link_to_page(1, current_page, target), dummy_page_link()] ++ pages
    end
  end

  def start_value(current_page, per_page) do
    ((current_page * per_page) - per_page) + 1
  end

  def sort_direction(column, sort) do
    cond do
      column == sort.column && sort.direction == :asc -> "asc"
      column == sort.column && sort.direction == :desc -> "desc"
      true -> nil
    end
  end

  def total_items(%{data_count: data_count}) do
    data_count
  end

  def total_items(%{data: data}) do
    Enum.count(data)
  end

  def total_pages(total_items, per_page) do
    total_items / per_page
    |> Float.ceil()
    |> round()
  end

  @impl true
  def update(assigns, socket) do
    socket =
      if assigns[:headers] do
        socket
        |> assign(assigns)
        |> assign(search: "")
        |> assign(sort: build_sort(assigns.options[:sort]))
      else
        socket
      end

    socket =
      socket
      |> assign(:current_page, record_location(socket, assigns.options[:go_to_record]))

    socket =
      assign(
        socket,
        data: load_data_for_page(
          %{
            data_source: socket.assigns.data_source,
            current_page: socket.assigns.current_page,
            per_page: socket.assigns.per_page,
            sort: socket.assigns.sort
          }
        )
      )

    socket =
      socket
      |> assign(total_items: total_items(socket.assigns))
      |> assign(total_pages: total_pages(total_items(socket.assigns), socket.assigns.per_page))

    {:ok, socket}
  end

  defp build_sort(sort_parameters) when is_map(sort_parameters) do
    sort_parameters
  end

  defp build_sort(sort_column) when is_integer(sort_column) do
    %{column: sort_column, direction: :asc}
  end

  defp build_sort(nil) do
    %{column: 0, direction: :asc}
  end

  defp dummy_page_link do
    ~E"""
      <li>
        <%= link "...", to: "#", class: "disabled" %>
      </li>
    """
  end

  defp invert_sort_direction(sort_direction) do
    if sort_direction == "asc", do: :desc, else: :asc
  end

  defp link_to_page(page, current_page, target) do
    ~E"""
      <li>
        <%= link page,
          to: "#",
          class: (if page == current_page, do: "active"),
          "phx-click": "go_to_page",
          "phx-value-page": page,
          "phx-target": target
        %>
      </li>
    """
  end

  defp record_location(socket, nil), do: socket.assigns.current_page
  defp record_location(socket, record_id) do
    %{
      record_id: record_id,
      search: Map.get(socket.assigns, :search),
      sort: socket.assigns.sort
    }
    |> socket.assigns.data_locator.()
    |> Kernel./(socket.assigns.per_page)
    |> Kernel.ceil()
  end
end
