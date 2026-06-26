import Config

# Runtime configuration for the echo umbrella, evaluated at boot in every environment.
# Below: the codemojex production runtime — the database URL, endpoint, and secret are
# read from the environment.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "environment variable DATABASE_URL is missing"

  # Fly's 6PN is IPv6-only (echo-postgres.internal resolves to an AAAA record only), so Postgrex
  # must dial inet6 — otherwise the Repo silently never connects (Ecto retries forever, no crash,
  # and a DB-less /api/health hides it). ECTO_IPV6=true is already set in fly.toml; read it here.
  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :codemojex, Codemojex.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

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

  # The shared Valkey — the EchoMQ bus + the real-time competitive state — lives on the dedicated
  # echo-valkey Fly node (private 6PN, requirepass). Wire host/port/password from the env. If
  # VALKEY_HOST is unset (local dev/test), the connectors fall back to 127.0.0.1:6390 with no auth.
  if valkey_host = System.get_env("VALKEY_HOST") do
    config :codemojex, valkey_host: String.to_charlist(valkey_host)
  end

  if valkey_password = System.get_env("VALKEY_PASSWORD") do
    config :codemojex, valkey_password: valkey_password
  end

  config :codemojex, valkey_port: String.to_integer(System.get_env("VALKEY_PORT") || "6390")
end
