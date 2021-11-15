defmodule Kamansky.Operations.Administration do
  alias Kamansky.Operations.Administration.Settings

  @spec change_settings(map, map) :: Ecto.Changeset.t
  def change_settings(%Settings{} = settings, attrs \\ %{}), do: Settings.changeset(settings, attrs)

  @spec get_setting!(atom) :: any
  def get_setting!(setting), do: Map.get(get_settings(), setting)

  @spec get_settings :: Settings.t
  def get_settings, do: Kamansky.Jobs.ManageSettings.get_settings()

  @spec update_settings(Settings.t, map) :: {:ok, Settings.t} | {:error, Ecto.Changeset.t}
  def update_settings(%Settings{} = settings, attrs) do
    settings
    |> change_settings(attrs)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset -> Kamansky.Jobs.ManageSettings.update(changeset)
      changeset -> {:error, changeset}
    end
  end
end
