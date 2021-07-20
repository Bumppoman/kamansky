defmodule Kamansky.Repo do
  use Ecto.Repo,
    otp_app: :kamansky,
    adapter: Ecto.Adapters.Postgres
end
