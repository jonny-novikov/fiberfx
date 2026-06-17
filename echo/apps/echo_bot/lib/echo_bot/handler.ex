defmodule EchoBot.Handler do
  @moduledoc """
  The handler contract — a bot's command router (F10.1-D6).

  A handler is a **pure function of the update**: `handle/1` maps a normalized
  `EchoBot.Platform.Update` to a reply, with no accumulating state and no external write. Purity
  is what makes a re-delivered update idempotent (F10.1-INV7) — the same update in yields the
  same reply out, so a Telegram resend never doubles an effect.

  `handle/1` returns `{:reply, text}` to answer, or `:noreply` to ignore an unmatched update.
  """

  @typedoc "A handler's verdict for one update: a static reply, or nothing."
  @type reply :: {:reply, String.t()} | :noreply

  @doc "Route one normalized update to a static reply (pure — no state, no I/O)."
  @callback handle(update :: EchoBot.Platform.Update.t()) :: reply()
end
