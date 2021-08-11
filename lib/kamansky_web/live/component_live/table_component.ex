defmodule KamanskyWeb.ComponentLive.TableComponent do
  use KamanskyWeb, :live_component

  @default_table_data %{
    current_page: 1,
    page: 1,
    per_page: 10
  }

  @spec end_value(pos_integer, pos_integer, pos_integer) :: pos_integer
  def end_value(current_page, per_page, total_items) do
    with start_value <- start_value(current_page, per_page) do
      if total_items < (per_page + start_value) do
        total_items
      else
        (start_value + per_page) - 1
      end
    end
  end

  @impl true
  @spec handle_event(String.t, %{required(String.t) => String.t}, Phoenix.LiveView.Socket.t)
    :: {:noreply, Phoenix.LiveView.Socket.t}
  def handle_event("go_to_page", %{"page" => page}, socket) do
    with page <- String.to_integer(page),
      socket <- assign(socket, current_page: page)
    do
      {:noreply, assign_data(socket)}
    end
  end

  def handle_event("per_page_changed", %{"per_page" => per_page}, socket) do
    with per_page <- String.to_integer(per_page),
      socket <-
        socket
        |> assign(:current_page, 1)
        |> assign(:per_page, per_page)
        |> assign(:total_pages, total_pages(socket.assigns.total_items, per_page))
    do
      {:noreply, assign_data(socket)}
    end
  end

  def handle_event("search", %{"search" => search}, socket) do
    with(
      socket <-
        socket
        |> assign(:current_page, 1)
        |> assign(:search, search)
    ) do
      {:noreply, assign_data(socket)}
    end
  end

  def handle_event("sort", %{"sort" => sort, "sort_direction" => sort_direction}, socket) do
    with(
      sort <-
        %{
          action: Map.get(socket.assigns, :parent_action),
          column: String.to_integer(sort),
          direction: invert_sort_direction(sort_direction),
        },
      socket <- assign(socket, sort: sort)
    ) do
      {:noreply, assign_data(socket)}
    end
  end

  @spec load_data_for_page(
    %{
      current_page: pos_integer,
      data_source: (map -> [Ecto.Schema.t] | {pos_integer, [Ecto.Schema.t]}),
      per_page: pos_integer,
      search: String.t | nil,
      sort: Kamansky.Paginate.sort
    }
  ) :: [Ecto.Schema.t] | {pos_integer, [Ecto.Schema.t]}
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
  @spec mount(Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def mount(socket) do
    with(
      socket <-
        socket
        |> assign(current_page: @default_table_data.current_page)
        |> assign(page: @default_table_data.page)
        |> assign(per_page: @default_table_data.per_page)
        |> assign(search: nil)
    ) do
      {:ok, socket}
    end
  end

  @spec page_links(pos_integer, pos_integer, String.t) :: [String.t]
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

  @spec start_value(pos_integer, pos_integer) :: pos_integer
  def start_value(current_page, per_page), do: ((current_page * per_page) - per_page) + 1

  @spec sort_direction(pos_integer, %{column: pos_integer, direction: :asc | :desc}) :: String.t
  def sort_direction(column, %{column: column, direction: :asc}), do: "asc"
  def sort_direction(column, %{column: column, direction: :desc}), do: "desc"
  def sort_direction(_column, _sort), do: nil

  @spec total_items(%{data_count: pos_integer} | %{data: Enum.t}) :: pos_integer
  def total_items(%{data_count: data_count}), do: data_count
  def total_items(%{data: data}), do: Enum.count(data)

  @spec total_pages(pos_integer, pos_integer) :: pos_integer
  def total_pages(total_items, per_page) do
    total_items / per_page
    |> Float.ceil()
    |> round()
  end

  @doc false
  @impl true
  @spec update(%{optional(atom) => any}, Phoenix.LiveView.Socket.t) :: {:ok, Phoenix.LiveView.Socket.t}
  def update(assigns, socket) do
    with(
      socket <-
        socket
        |> assign(assigns)
        |> assign_new(:sort, fn -> build_sort(assigns.options[:sort]) end),
      socket <- assign(socket, :current_page, record_location(socket, assigns.options[:go_to_record])),
      socket <- assign_data(socket),
      socket <-
        socket
        |> assign_new(:total_items, fn -> total_items(socket.assigns) end)
        |> assign_new(:total_pages, fn -> total_pages(total_items(socket.assigns), socket.assigns.per_page) end)
    ) do
      {:ok, socket}
    end
  end

  @spec assign_data(Phoenix.LiveView.Socket.t) :: Phoenix.LiveView.Socket.t
  defp assign_data(%{assigns: %{search: nil}} = socket) do
    assign(
      socket,
      :data,
      load_data_for_page(
        %{
          data_source: socket.assigns.data_source,
          current_page: socket.assigns.current_page,
          per_page: socket.assigns.per_page,
          search: socket.assigns.search,
          sort: socket.assigns.sort
        }
      )
    )
  end

  defp assign_data(socket) do
    with(
      {count, data} <-
        load_data_for_page(
          %{
            data_source: socket.assigns.data_source,
            current_page: socket.assigns.current_page,
            per_page: socket.assigns.per_page,
            search: socket.assigns.search,
            sort: socket.assigns.sort
          }
        )
    ) do
      socket
      |> assign(data: data)
      |> assign(search: socket.assigns.search)
      |> assign(total_items: count)
      |> assign(total_pages: total_pages(count, socket.assigns.per_page))
    end
  end

  @spec build_sort(map | pos_integer | nil) :: %{column: pos_integer, direction: :asc | :desc}
  defp build_sort(sort_parameters) when is_map(sort_parameters), do: sort_parameters
  defp build_sort(sort_column) when is_integer(sort_column), do: %{column: sort_column, direction: :asc}
  defp build_sort(nil), do: %{column: 0, direction: :asc}

  @spec dummy_page_link :: Phoenix.HTML.safe
  defp dummy_page_link do
    ~E"""
      <li>
        <%= link "...", to: "#", class: "disabled" %>
      </li>
    """
  end

  @spec invert_sort_direction(String.t) :: :asc | :desc
  defp invert_sort_direction("desc"), do: :asc
  defp invert_sort_direction(_), do: :desc

  @spec link_to_page(pos_integer, pos_integer, String.t) :: Phoenix.HTML.safe
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

  @spec record_location(Phoenix.LiveView.Socket.t, pos_integer | nil) :: pos_integer
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
