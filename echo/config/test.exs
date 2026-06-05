import Config

# Tests run the in-memory event-store adapter — the engine suite needs no database,
# and `Portal.EventStore.InMemory.reset/0` gives per-test isolation (CLAUDE.md §4).
# The Postgres adapter is tested DIRECTLY through the sandbox (Portal.DataCase),
# never through the engine, so this stays InMemory (F6.3-INV5/INV6).
config :portal, :event_store, Portal.EventStore.InMemory

# Portal.Repo (F6.3) — the sandbox DB for DB-touching tests. `pool:
# Ecto.Adapters.SQL.Sandbox` isolates each test in a rolled-back transaction;
# test_helper.exs sets `:manual` mode and Portal.DataCase checks out an owner per
# test. portal_test must exist before `mix test` (run `MIX_ENV=test mix
# ecto.create`); Repo is a supervision child and boots against it.
config :portal, Portal.Repo,
  username: "jonny",
  password: "",
  hostname: "localhost",
  database: "portal_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  log: false

# The endpoint runs with `server: false` under test so ConnTest exercises the plug
# pipeline WITHOUT binding a port — avoids the :4000 TIME_WAIT race across repeated
# runs (RK-5). The secret_key_base is a fixed 64-char dummy (signing only; no real
# secret needed in test).
config :portal_web, PortalWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_at_least_sixtyfour_bytes_long_for_phoenix_0000",
  server: false

# echo_bot runs the FAKE updater under test (F10.1-INV6) — the `:noup` analog, a no-op updates
# source that contacts no Telegram. The supervised bot boots from the YAML v1.0 file under the
# `ExGram.Updater.Noup` updater, so handler tests feed constructed updates with no live poll. The
# loader still resolves `token_env` at boot (the full v1.0 validation runs), but the fake updater
# never USES the token (it contacts no Telegram). Config is evaluated before the umbrella's apps
# start, so this sets the bot's env var here — a dummy value that satisfies the loader and is
# never sent anywhere.
System.put_env("ECHO_BOT_HELLO_TOKEN", "test-token-never-sent")

config :echo_bot, updater: :fake
