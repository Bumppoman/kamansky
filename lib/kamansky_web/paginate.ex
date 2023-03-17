defmodule KamanskyWeb.Paginate do
  import Phoenix.{Component, LiveView}

  @callback count_data(Phoenix.LiveView.Socket.t, String.t | nil) :: integer
  @callback find_item_in_data(Phoenix.LiveView.Socket.t, pos_integer, integer, :asc | :desc) :: integer
  @callback load_data(Phoenix.LiveView.Socket.t, Kamansky.Paginate.params) :: [any]
  @callback self_path(Phoenix.LiveView.Socket.t, atom, map) :: String.t
  @callback sort_action(Phoenix.LiveView.Socket.t) :: atom
  @optional_callbacks find_item_in_data: 4, sort_action: 1

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour KamanskyWeb.Paginate

      on_mount {KamanskyWeb.Paginate, :paginate}

      @impl true
      def handle_event("search", %{"search" => search}, socket) do
        socket
        |> push_patch(
          to: self_path(
            socket,
            socket.assigns.live_action,
            socket.assigns.pagination,
            %{page: 1, search: search, show: nil}
          )
        )
        |> noreply()
      end

      @spec default_direction(atom) :: :asc | :desc
      def default_direction(_action) do
        unquote(opts)
        |> Keyword.get(:sort)
        |> elem(1)
      end

      @spec default_sort(atom) :: integer
      def default_sort(_action) do
        unquote(opts)
        |> Keyword.get(:sort)
        |> elem(0)
      end

      @spec self_path(Phoenix.LiveView.Socket.t, atom, Kamansky.Paginate.params, map) :: String.t
      def self_path(socket, action, params, add) do
        self_path(
          socket,
          action,
          KamanskyWeb.Paginate.build_uri_params(socket.view, action, params, add)
        )
      end

      @impl true
      def sort_action(socket), do: socket.assigns.live_action

      defoverridable default_direction: 1, default_sort: 1, sort_action: 1
    end
  end

  @spec on_mount(:paginate, map, map, Phoenix.LiveView.Socket.t) :: {:cont, Phoenix.LiveView.Socket.t}
  def on_mount(:paginate, _params, _session, socket), do: {:cont, attach_hook(socket, :paginate, :handle_params, &paginate/3)}

  @spec build_uri_params(module, atom, Kamansky.Paginate.params, map) :: map
  def build_uri_params(implementation, action, params, add) do
    params
    |> Map.take([:direction, :show, :page, :search, :sort])
    |> Map.merge(add)
    |> Map.filter(fn {k, v} -> necessary?(implementation, action, k, v) end)
  end

  @spec current_page(Phoenix.LiveView.Socket.t, map, integer, Kamansky.Paginate.sort_direction, integer) :: integer
  defp current_page(socket, %{"show" => show}, sort, direction, per_page) do
    socket.view
    |> apply(
      :find_item_in_data,
      [
        socket,
        String.to_integer(show),
        sort,
        direction
      ]
    )
    |> case do
      nil -> 1
      location ->
        location
        |> Kernel./(per_page)
        |> Float.ceil()
        |> round()
    end
  end
  defp current_page(_socket, %{"page" => page}, _sort, _direction, _per_page), do: String.to_integer(page)
  defp current_page(_, _, _, _, _), do: 1

  @spec direction(Phoenix.LiveView.Socket.t, map) :: :asc | :desc
  defp direction(_socket, %{"direction" => direction}), do: String.to_existing_atom(direction)
  defp direction(%Phoenix.LiveView.Socket{} = socket, _), do: apply(socket.view, :default_direction, [socket.assigns.live_action])

  @spec maybe_update_page(Phoenix.LiveView.Socket.t, Kamansky.Paginate.params, integer) :: Phoenix.LiveView.Socket.t
  defp maybe_update_page(socket, %{page: page, search: search, show: show} = params, uri_page) when not is_nil(show) and (not is_nil(search) or page != uri_page) do
    push_patch(socket, to: apply(socket.view, :self_path, [socket, socket.assigns.live_action, params, %{search: nil}]))
  end
  defp maybe_update_page(socket, %{page: page, total_pages: total_pages} = params, _uri_page) when total_pages != 0 and page > total_pages do
    push_patch(socket, to: apply(socket.view, :self_path, [socket, socket.assigns.live_action, %{params | page: total_pages}, %{}]))
  end
  defp maybe_update_page(socket, _params, _uri_page), do: socket

  @spec necessary?(module, atom, atom, any) :: boolean
  defp necessary?(implementation, action, :direction, value), do: value != apply(implementation, :default_direction, [action]) and value not in ["", nil]
  defp necessary?(_implementation, _action, :page, value), do: value != 1 and value not in ["", nil]
  defp necessary?(implementation, action, :sort, value), do: value != apply(implementation, :default_sort, [action]) and value not in ["", nil]
  defp necessary?(_, _, _, value), do: value not in ["", nil]

  @spec page_params(Phoenix.LiveView.Socket.t, map) :: Kamansky.Paginate.params
  defp page_params(socket, params) do
    with direction <- direction(socket, params),
      per_page <- Map.get(socket.assigns, :per_page, 10),
      search <- search(params),
      show <- show(params),
      sort <- sort(socket, params),
      sort_action <- apply(socket.view, :sort_action, [socket]),
      total_items <- apply(socket.view, :count_data, [socket, search]),
      total_pages <- total_pages(total_items, per_page),
      page <- current_page(socket, params, sort, direction, per_page)
    do
      %{
        action: sort_action,
        direction: direction,
        page: page,
        per_page: per_page,
        search: search,
        show: show,
        sort: sort,
        total_items: total_items,
        total_pages: total_pages
      }
    end
  end

  @spec paginate(map, String.t, Phoenix.LiveView.Socket.t) :: {:cont, Phoenix.LiveView.Socket.t}
  defp paginate(params, _uri, socket) do
    with page_params <- page_params(socket, params) do
      {
        :cont,
        socket
        |> maybe_update_page(page_params, parse_page(params["page"]))
        |> assign(:data, apply(socket.view, :load_data, [socket, page_params]))
        |> assign(:pagination, page_params)
      }
    end
  end

  @spec parse_page(String.t | nil) :: integer
  defp parse_page(page) when page in ["", nil], do: 1
  defp parse_page(page), do: String.to_integer(page)

  @spec search(map) :: String.t | nil
  defp search(params) when is_map_key(params, "show"), do: nil
  defp search(%{"search" => search}), do: search
  defp search(_), do: nil

  @spec show(map) :: integer | nil
  defp show(%{"show" => show}), do: String.to_integer(show)
  defp show(_), do: nil

  @spec sort(Phoenix.LiveView.Socket.t, map) :: integer
  defp sort(_socket, %{"sort" => sort}), do: String.to_integer(sort)
  defp sort(%Phoenix.LiveView.Socket{} = socket, _), do: apply(socket.view, :default_sort, [socket.assigns.live_action])

  @spec total_pages(integer, integer) :: integer
  defp total_pages(total_items, per_page) do
    total_items
    |> Kernel./(per_page)
    |> Float.ceil()
    |> round()
  end
end
