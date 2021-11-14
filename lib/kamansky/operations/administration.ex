defmodule Kamansky.Operations.Administration do
  alias Kamansky.Operations.Administration.Settings

  @spec change_settings(Settings.t, map) :: Ecto.Changeset.t
  def change_settings(%Settings{} = settings, attrs \\ %{}), do: Settings.changeset(settings, attrs)

  @spec get_setting!(atom) :: any
  def get_setting!(setting), do: Map.get(list_settings(), setting)

  @spec list_settings :: Settings.t
  def list_settings, do: Kamansky.Jobs.ManageSettings.list_settings()

  @spec update_settings(Settings.t, map) :: {:ok, Settings.t} | {:error, Ecto.Changeset.t}
  def update_settings(%Settings{} = settings, attrs) do
    settings
    |> change_settings(attrs)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset -> {:ok, Kamansky.Jobs.ManageSettings.update(changeset)}
      changeset -> {:error, changeset}
    end
  end
end
