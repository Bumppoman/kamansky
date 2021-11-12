import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do

  config :kamansky, Kamansky.Repo,
    socket_dir: "/var/run/postgresql",
    database: "kamansky",
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :kamansky, KamanskyWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :kamansky, KamanskyWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.
  config :kamansky, KamanskyWeb.Endpoint, server: true

  config :kamansky, :username, "Bumppoman"
  config :kamansky, :password, "2728Manhattan"
  config :kamansky, :uploads_directory, "/data/kamansky"
  config :kamansky, :hipstamp_api_key, "hspr6aedf3b8b4e6848f780d75794292"
  config :kamansky, :hipstamp_username, "Bumppoman"
  config :kamansky, :ebay_authorization_token, "AgAAAA**AQAAAA**aAAAAA**7jKMYQ**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wNkYeiDJaDowmdj6x9nY+seQ**KdgGAA**AAMAAA**QXOQtAT8gUgcLSfgBmn6bXG/h3gJWpIpGMKjzFA6vz23+7iqR4Lomt/Iv25RTvgbXkttS1b/CZSMpzrD0icXrdsqPVag+UHkRGrU+u8wOCpUy5TlU01DoeKhKL/+cny1XztxAINGztv4Jp3Kbm8v/w8wr3JA0iPV5CDcqhhq5b2MEcXfLwSvMDr7naId/PAZbgsacV0ZuW8ASrFBsyLs+RoBJY55IdMslnNqKLwIsQOsiI6OBIxaYsGA1CXMWVkXrbjbWUQn8VYsB0A287ODXXMyPBgiKcaW8q1x+KMXrQ7EArafLN3/QcOv1g05DPBMdvvP+xgzMLzqtDMkWhTux+LlpPaQftwjp0RUNa+rY9uzQbbB/h7ZMoGKnxcsakDH3jcI64+B3mbHmipdIILT/GXN1COMNyD8Fk3t6bfKE8aDURkfJ2Qhg9PHM69j48l1vVBtir7FSaQFfxH7XrS4WOleTBy42XlAMW2KgGEOSmZLSwlXr7k03zvoBUJxjaAwqafuHeADWUTXs+/5zCOL9wdYz8Miw5YxzPzHFutZ5m/d1o9Sj1UB1BNpXKDRtspIfOEhZkSeejOeINS7GTyZs7iFwCr0OWVVX5Nfk4/CMxl+FVy8BGlisLemre+xhIqX47K9w47YyoQqYGvpjKBQC6BwGLWFSiod++UEiBGvDcV5TpyjHJSRNjSOEOmAM4+YkO12JLb5byFqq6uXl1TTGDS0r+Qsp/+BAoR4mSa8DSlXqNEZ+KoQ5+0E6D/VXJMP"
  config :kamansky, :ebay_client_id, "BrendonS-Kamansky-PRD-dddd5c0ce-8e82ef7d"
  config :kamansky, :ebay_client_secret, "PRD-ddd5c0ce8fed-8fa1-47d6-9907-7f4e"
  config :kamansky, :ebay_redirect_uri, "Brendon_Stanton-BrendonS-Kamans-shvxuces"

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :kamansky, Kamansky.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
