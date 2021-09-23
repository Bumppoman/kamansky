# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :kamansky,
  ecto_repos: [Kamansky.Repo]

# Configures the endpoint
config :kamansky, KamanskyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/S2JnWSYgEb/LLMeEhXL1hk/t+3WY1mLqDCt6u5Cv/xQ80T1Nmf/vzxaWkqr/yZ8",
  render_errors: [view: KamanskyWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Kamansky.PubSub,
  live_view: [signing_salt: "tCSNjkQC"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.26",
  default: [
    args: ~w(js/app.js --bundle --target=es2020 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure Dart Sass
config :dart_sass,
version: "1.42.1",
default: [
  args: ~w(css/app.scss ../priv/static/assets/app.css),
  cd: Path.expand("../assets", __DIR__)
]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :tesla, adapter: Tesla.Adapter.Hackney

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
