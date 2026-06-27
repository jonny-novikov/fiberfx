# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
#
# This configures the apps in the echo umbrella — the echo_bot engine, codemojex,
# and echo_store's durability backend (below).
import Config

# The echo_bot engine (F10.1). `:bot_config` is the YAML v1.0 file the loader reads — a relative
# path resolves against the :echo_bot priv dir, so the one bot is `priv/bots/hello_bot.yaml`.
# `:updater` selects the updater per env: the BASE default is `:none`, so a bare `iex -S mix`
# boots the engine app with no live poll and no token required (F10.1-INV1). dev.exs flips it to
# `:polling` (live long-poll); test.exs to `:fake` (the no-op updates source, F10.1-INV6).
config :echo_bot,
  bot_config: "bots/hello_bot.yaml",
  updater: :none

# Codemojex — relational persistence for crucial data (Postgres via Ecto), plus the
# Phoenix surface for the Mini App. BCS still mints the branded ids, EchoStore still
# caches the hot reads over the Repo, and EchoMQ still runs the queues; this just
# names the Repo, the bus port, and the JSON/WS endpoint.
config :codemojex,
  ecto_repos: [Codemojex.Repo],
  valkey_port: 6390

config :codemojex, CodemojexWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  # The JSON API renders errors as JSON; the LiveView/browser tier needs an :html
  # format too, or render_errors raises on a browser-tier error.
  render_errors: [
    formats: [html: CodemojexWeb.ErrorHTML, json: CodemojexWeb.ErrorJSON],
    layout: false
  ],
  # The LiveView socket signs its session payload with this salt (separate from the
  # cookie session signing_salt in CodemojexWeb.Endpoint's @session_options).
  live_view: [signing_salt: "cmjxLV01"],
  pubsub_server: Codemojex.PubSub

config :phoenix, :json_library, Jason

# EchoStore pluggable durability — the transactional-enqueue outbox backend. Default: the
# shipped SQLite journal (exqlite), zero infra, a file per group. Postgres and the EchoMQ 4+
# Graft commit-log-as-outbox are opt-in adapters a host provides in its own app (bring-your-own
# dependency), so echo_store core carries no SQL client. See `EchoStore.Durability`.
config :echo_store, EchoStore.Durability, adapter: EchoStore.Durability.SQLite

# Per-environment overrides — load the matching env file last so its values win.
import_config "#{config_env()}.exs"
