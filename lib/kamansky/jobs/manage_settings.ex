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

  @spec get_value(atom) :: any
  def get_value(key) do
    @name
    |> :ets.lookup(:settings)
  end

  @spec lookup(atom) :: [{atom, any}]
  def lookup(key), do: :ets.lookup(@name, key)

  #@spec update(Ecto.Changeset.t) :: {:ok, Settings.t}
  #def update(changeset) do
  #  with :ok <- Enum.each(changeset.changes, fn {key, value} -> insert(key, value) end) do
  #    save_config()
  #    {:ok, Ecto.Changeset.apply_changes(changeset)}
  #  end
  #end

  #@spec load_config :: true
  defp load_config do
    @config_file
    |> File.read!()
    |> Jason.decode!()
    |> Enum.into(%{}, fn {key, value} -> {String.to_atom(key), value} end)
    |> then(&Administration.change_settings(%Settings{}, &1))
    |> Ecto.Changeset.apply_changes()
    |> then(&:ets.insert(@name, {:settings, &1}))
  end

  #@spec save_config :: :ok
  #defp save_config do
  #  list_settings()
  #  |> Jason.encode!()
  #  |> then(&File.write!(@config_file, &1))
  #end
end
