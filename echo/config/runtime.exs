import Config

# Runtime configuration for the echo umbrella, evaluated at boot in every environment.
# The portal/portal_web runtime settings (SECRET_KEY_BASE, PORT, PHX_HOST/PHX_SERVER,
# the Postgres DATABASE_URL + IPv6 socket options, the deep-link base) moved out to
# their own repository with the apps. Nothing staying in
# echo reads runtime env today; this file is retained as the umbrella's runtime hook.

# Codemojex production runtime: the database URL and endpoint come from the env.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "environment variable DATABASE_URL is missing"

  config :codemojex, Codemojex.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing"

  config :codemojex, CodemojexWeb.Endpoint,
    server: true,
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: secret_key_base
end
