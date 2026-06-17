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
