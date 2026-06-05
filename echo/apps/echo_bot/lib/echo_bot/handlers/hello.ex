defmodule EchoBot.Handlers.Hello do
  @moduledoc """
  The one bot's handler — answers `/start` and `/help` with static text (F10.1-D6).

  `handle/1` is a **pure function of the update** (F10.1-INV7): it matches on the normalized
  update's `command` and returns the static reply, holding no state and performing no I/O. The
  same `/start` update handled twice yields the same single `{:reply, @welcome}` — a Telegram
  resend doubles nothing. The handler names no engine-foreign function and no vendored module; it
  reaches the platform only through the reply the engine sends from this verdict (F10.1-INV1, INV4).
  """

  @behaviour EchoBot.Handler

  alias EchoBot.Platform.Update

  @welcome "Welcome to EchoBot. Send /help to see what this bot can do."
  @help "EchoBot commands:\n/start — say hello\n/help — show this help"

  @doc "Route `/start` → the welcome text, `/help` → the help text; anything else → `:noreply`."
  @impl EchoBot.Handler
  def handle(%Update{command: "start"}), do: {:reply, @welcome}
  def handle(%Update{command: "help"}), do: {:reply, @help}
  def handle(%Update{}), do: :noreply

  @doc "The static welcome text answered for `/start` (exposed for the handler test assertion)."
  @spec welcome_text() :: String.t()
  def welcome_text, do: @welcome

  @doc "The static help text answered for `/help` (exposed for the handler test assertion)."
  @spec help_text() :: String.t()
  def help_text, do: @help
end
