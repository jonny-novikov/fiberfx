import Config

# Runtime configuration for the echo umbrella, evaluated at boot in every environment.
# Below: the codemojex production runtime — the database URL, endpoint, and secret are
# read from the environment.
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

  # The public host Phoenix uses to generate URLs and check socket origins. Driven by
  # PHX_HOST (set in fly.toml) so a Fly app rename or a custom apex (e.g. codemoji.games)
  # is a config change, not a code edit; falls back to the app's *.fly.dev host. TLS is
  # terminated at Fly's edge, so the public URL is https on 443.
  phx_host = System.get_env("PHX_HOST") || "codemojex.fly.dev"

  config :codemojex, CodemojexWeb.Endpoint,
    server: true,
    url: [host: phx_host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: secret_key_base
end
