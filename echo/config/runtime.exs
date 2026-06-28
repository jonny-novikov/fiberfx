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
    # Accept /socket WebSocket Origins from BOTH the public host and the *.fly.dev fallback, so the
    # PHX_HOST apex cutover (codemojex.fly.dev -> codemoji.games) drops no live game socket on either
    # host. The Telegram Mini App's WS Origin is its launch URL's host (the apex, once cut over).
    check_origin: ["https://#{phx_host}", "https://codemojex.fly.dev"],
    secret_key_base: secret_key_base

  # OPTIONAL full-edge mode: when STATIC_HOST is set (e.g. edge.codemoji.games), Phoenix generates
  # ~p"/assets/..." URLs against the edge host, so the LiveView client + CSS serve from Tigris too
  # (you must then also upload priv/static to the bucket). Unset by default — the LiveView client
  # serves from this machine, and only the GAME bundle is edge-sourced (Codemojex.Edge).
  if static_host = System.get_env("STATIC_HOST") do
    config :codemojex, CodemojexWeb.Endpoint,
      static_url: [host: static_host, port: 443, scheme: "https"]
  end

  # Per-deploy fallback for the React game bundle if the edge pointer is unreachable. The live value
  # comes from edge.codemoji.games/manifest.json (Codemojex.Edge); this is only the safety net.
  config :codemojex, :game_asset_url, System.get_env("GAME_ASSET_URL")

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

  # The Codemoji Telegram bot (@codemoji_bot). CODEMOJI_BOT_TOKEN arms the OUTBOUND send path —
  # Codemojex.Bot resolves it so the notification worker can deliver. Unset → every send drops with
  # :no_token and the app still boots (the bot is simply idle).
  #
  # INBOUND transport is chosen by CODEMOJI_WEBHOOK_SECRET:
  #
  #   * SET   → WEBHOOK mode (production). Telegram POSTs to /api/telegram/webhook, secret-checked
  #             against this value by CodemojexWeb.TelegramController, then bridged onto the bus. No
  #             poller runs (echo_bot's updater stays at its :none base), so this SCALES across
  #             machines. Register once with:
  #               setWebhook(url: "https://codemoji.games/api/telegram/webhook",
  #                          secret_token: <CODEMOJI_WEBHOOK_SECRET>)
  #   * UNSET → POLLING fallback. The echo_bot engine long-polls updates for the Codemoji bot
  #             (priv/bots/codemoji.yaml → Codemojex.Bot.Handler). SINGLE machine only — a second
  #             getUpdates poller gets Telegram 409 Conflict.
  #
  # Either way the inbound update lands as a CMD job on the bus, drained by Codemojex.CommandWorker.
  # See apps/codemojex/docs/notifications.md.
  if bot_token = System.get_env("CODEMOJI_BOT_TOKEN") do
    config :codemojex, Codemojex.Telegram, token: bot_token

    case System.get_env("CODEMOJI_WEBHOOK_SECRET") do
      secret when is_binary(secret) and secret != "" ->
        config :codemojex, CodemojexWeb.TelegramController, secret: secret

      _ ->
        config :echo_bot,
          updater: :polling,
          bot_config: Path.join(:code.priv_dir(:codemojex), "bots/codemoji.yaml")
    end
  end
end

# Dev/local: arm the codemojex bot's OUTBOUND send token from CODEMOJI_BOT_TOKEN (it
# lives in echo/.env — `set -a && source echo/.env` before `mix phx.server`, because
# mix does not load .env itself). Without this the dev token wiring did not exist (the
# block above is :prod-only), so Codemojex.Bot.token/0 fell back to the demo hello bot
# and resolved nil. INBOUND polling stays off in dev on purpose: prod owns
# @codemoji_bot's webhook and a dev getUpdates poller would conflict with it — wire a
# separate dev bot token if dev inbound is ever needed.
if config_env() == :dev do
  if bot_token = System.get_env("CODEMOJI_BOT_TOKEN") do
    config :codemojex, Codemojex.Telegram, token: bot_token
  end
end
