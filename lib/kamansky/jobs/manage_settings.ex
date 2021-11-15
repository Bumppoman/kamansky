defmodule Kamansky.Jobs.ManageSettings do
  use GenServer

  alias Kamansky.Operations.Administration
  alias Kamansky.Operations.Administration.Settings

  @config_file "config/kamansky.json"
  @name Kamansky.Settings

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: @name)

  @impl true
  @spec init(any) :: {:ok, any}
  def init(state) do
    :ets.new(@name, [:set, :protected, :named_table])
    load_config()
    {:ok, state}
  end

  @impl true
  @spec handle_call(:list, {pid, any}, any) :: {:reply, Settings.t, any}
  def handle_call(:list, _ref, state) do
    {:reply, retrieve_settings(), state}
  end

  @spec get_value(atom) :: any
  def get_value(key), do: Map.get(list_settings(), key)

  @spec list_settings :: Settings.t
  def list_settings, do: GenServer.call(@name, :list)

  @spec update(Ecto.Changeset.t) :: {:ok, Settings.t}
  def update(changeset) do
    with settings <- Ecto.Changeset.apply_changes(changeset) do
      replace_settings(settings)
      save_config()

      {:ok, settings}
    end
  end

  @spec load_config :: true
  defp load_config do
    @config_file
    |> File.read!()
    |> Jason.decode!()
    |> Enum.into(%{}, fn {key, value} -> {String.to_atom(key), value} end)
    |> then(&Administration.change_settings(%Settings{}, &1))
    |> Ecto.Changeset.apply_changes()
    |> replace_settings()
  end

  @spec replace_settings(Settings.t) :: true
  defp replace_settings(settings), do: :ets.insert(@name, {:settings, settings})

  @spec retrieve_settings :: Settings.t
  defp retrieve_settings do
    @name
    |> :ets.lookup(:settings)
    |> Keyword.get(:settings)
  end

  @spec save_config :: :ok
  defp save_config do
    retrieve_settings()
    |> Jason.encode!()
    |> then(&File.write!(@config_file, &1))
  end
end
