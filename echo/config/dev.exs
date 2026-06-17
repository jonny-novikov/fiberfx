import Config

# echo_bot runs the live POLLING updater in dev (F10.1-D9, the manual demo): set the bot's
# `token_env` env var (ECHO_BOT_HELLO_TOKEN) to a real Telegram token and a `/start` to the dev
# bot returns a reply. With the token unset, EchoBot.Application logs a warning and starts no bot
# — the engine app still boots (F10.1-INV1), so a bare `iex -S mix` works with no token.
config :echo_bot, updater: :polling
