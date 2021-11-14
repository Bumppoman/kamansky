defmodule Kamansky.Jobs.ManageSettings do
  use GenServer

  alias Kamansky.Operations.Administration
  alias Kamansky.Operations.Administration.Settings

  @config_file "config/kamansky.json"
  @name Kamansky.Settings

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: @name)

  @spec insert(atom, any) :: any
  def insert(key, value), do: GenServer.call(@name, {:insert, {key, value}})

  @impl true
  @spec init(any) :: {:ok, any}
  def init(state) do
    :ets.new(@name, [:set, :protected, :named_table])
    load_config()
    {:ok, state}
  end

  @impl true
  @spec handle_call({:insert, any}, {pid, any}, any) :: {:reply, :ok, any}
  def handle_call({:insert, kv}, _ref, state) do
    insert_into_table(kv)
    {:reply, :ok, state}
  end

  @spec get_value(atom) :: any
  def get_value(key) do
    @name
    |> :ets.lookup(key)
    |> hd()
    |> elem(1)
  end

  @spec list_settings :: map
  def list_settings do
    @name
    |> :ets.tab2list()
    |> then(&struct(Settings, &1))
  end

  @spec lookup(atom) :: [{atom, any}]
  def lookup(key), do: :ets.lookup(@name, key)

  @spec update(Ecto.Changeset.t) :: {:ok, Settings.t}
  def update(changeset) do
    with :ok <- Enum.each(changeset.changes, fn {key, value} -> insert(key, value) end) do
      save_config()
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end
  end

  @spec insert_into_table({atom, any}) :: true
  defp insert_into_table(kv), do: :ets.insert(@name, kv)

  @spec load_config :: :ok
  defp load_config do
    with {:ok, body} <- File.read(@config_file),
      {:ok, json} <- Jason.decode(body),
      changes <- Enum.into(json, %{}, fn {key, value} -> {String.to_atom(key), value} end),
      changeset <- Administration.change_settings(%Settings{}, changes)
    do
      Enum.each(changeset.changes, &insert_into_table/1)
    end
  end

  @spec save_config :: :ok
  defp save_config do
    list_settings()
    |> Jason.encode!()
    |> then(&File.write!(@config_file, &1))
  end
end
