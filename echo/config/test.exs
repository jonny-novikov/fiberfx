import Config

# echo_bot runs the FAKE updater under test (F10.1-INV6) — the `:noup` analog, a no-op updates
# source that contacts no Telegram. The supervised bot boots from the YAML v1.0 file under the
# `ExGram.Updater.Noup` updater, so handler tests feed constructed updates with no live poll. The
# loader still resolves `token_env` at boot (the full v1.0 validation runs), but the fake updater
# never USES the token (it contacts no Telegram). Config is evaluated before the umbrella's apps
# start, so this sets the bot's env var here — a dummy value that satisfies the loader and is
# never sent anywhere.
System.put_env("ECHO_BOT_HELLO_TOKEN", "test-token-never-sent")

config :echo_bot, updater: :fake

# Codemojex under test: a sandboxed Repo and a non-serving endpoint.
config :codemojex, Codemojex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "codemojex_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

config :codemojex, CodemojexWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: String.duplicate("test_secret_key_base", 4),
  server: false
