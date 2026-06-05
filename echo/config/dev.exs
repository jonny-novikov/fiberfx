import Config

# Dev runs the in-memory event-store adapter — the engine suite/path stays
# in-memory. Production overrides to Postgres in `prod.exs` (F5.8-INV4).
config :portal, :event_store, Portal.EventStore.InMemory

# Portal.Repo (F6.3) — local Postgres on localhost:5432, the system user `jonny`
# with no password. Repo is a supervision child, so this DB must exist before any
# `iex -S mix` / `mix run` boots (run `mix ecto.create` first). The :event_store
# above stays InMemory; the Repo is the persistence edge the Postgres adapter +
# the F6.4 contexts drive.
config :portal, Portal.Repo,
  username: "jonny",
  password: "",
  hostname: "localhost",
  database: "portal_dev",
  pool_size: 10

# echo_bot runs the live POLLING updater in dev (F10.1-D9, the manual demo): set the bot's
# `token_env` env var (ECHO_BOT_HELLO_TOKEN) to a real Telegram token and a `/start` to the dev
# bot returns a reply. With the token unset, EchoBot.Application logs a warning and starts no bot
# — the engine app still boots (F10.1-INV1), so a bare `iex -S mix` works with no token.
config :echo_bot, updater: :polling
