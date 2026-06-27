import Config

# echo_bot runs the live POLLING updater in dev (F10.1-D9, the manual demo): set the bot's
# `token_env` env var (ECHO_BOT_HELLO_TOKEN) to a real Telegram token and a `/start` to the dev
# bot returns a reply. With the token unset, EchoBot.Application logs a warning and starts no bot
# — the engine app still boots (F10.1-INV1), so a bare `iex -S mix` works with no token.
config :echo_bot, updater: :polling

# Codemojex dev: a local Postgres and the endpoint on :4000.
config :codemojex, Codemojex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "codemojex_dev",
  pool_size: 10,
  show_sensitive_data_on_connection_error: true

config :codemojex, CodemojexWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  # Dev convenience: accept WebSocket connections regardless of Origin host, so the
  # LiveView and channel sockets connect whether the app is reached at localhost or
  # 127.0.0.1 (without this, a 127.0.0.1 Origin fails the check against the configured
  # "localhost" url host and the live socket never connects). Prod keeps its explicit
  # check_origin allowlist in runtime.exs.
  check_origin: false,
  debug_errors: true,
  secret_key_base: String.duplicate("dev_secret_key_base_", 4),
  watchers: []
