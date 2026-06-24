defmodule Codemojex.Bot do
  @moduledoc """
  The Telegram I/O seam, over the `echo_bot` engine.

  Outbound notifications are delivered through `EchoBot.Platform.Telegram.send_reply/3`
  — the `echo_bot` app's owned, vendored ex_gram client — so the umbrella speaks to
  Telegram through one client, not two. The token is resolved from `config :codemojex,
  Codemojex.Telegram, token: ...` (the existing send-side config) first, then from
  `echo_bot`'s configured YAML bot; with no token configured a send is dropped (a dev
  default), never a crash.

  Inbound updates are handled by `Codemojex.Bot.Handler` when `echo_bot`'s updater is
  enabled — `config :echo_bot, updater: :polling` (or `:webhook`) with a `bot_config`
  that names that handler. See `docs/codemojex/notifications`.
  """

  @doc """
  Deliver `text` to a Telegram `chat` through the `echo_bot` platform. Returns the
  delivery verdict the notification worker classifies: `:ok`, `{:retry, reason}`
  (transient — retried with backoff up to the worker's cap), or `{:drop, reason}`
  (no token, or give up).
  """
  @spec deliver(integer() | binary(), binary()) :: :ok | {:retry, term()} | {:drop, term()}
  def deliver(chat, text) do
    case token() do
      nil ->
        {:drop, :no_token}

      tok ->
        case EchoBot.Platform.Telegram.send_reply(tok, chat, text) do
          :ok -> :ok
          {:error, reason} -> {:retry, reason}
        end
    end
  end

  @doc "The resolved bot token, or nil — app config first, then `echo_bot`'s YAML bot."
  @spec token() :: binary() | nil
  def token do
    case Keyword.get(Application.get_env(:codemojex, Codemojex.Telegram, []), :token) do
      nil -> echo_bot_token()
      t -> t
    end
  end

  defp echo_bot_token do
    case EchoBot.Config.load(EchoBot.Config.bot_config_path()) do
      {:ok, %{token: t}} -> t
      _ -> nil
    end
  end
end

defmodule Codemojex.Bot.Handler do
  @moduledoc """
  The `echo_bot` handler for the Codemoji bot. When `echo_bot`'s updater is enabled it
  normalizes each inbound Telegram update and routes it here; this handler bridges the
  normalized update onto the EchoMQ bus (`Codemojex.EchoBot.bridge/1`) and returns
  `:noreply`, so a command is handled durably and per-chat-ordered by
  `Codemojex.CommandWorker` — which replies through the same notification path — rather
  than synchronously inside the updater. Returning a reply here would couple the engine
  to a send; keeping the reply on the bus does not.
  """
  @behaviour EchoBot.Handler

  alias EchoBot.Platform.Update

  @impl EchoBot.Handler
  def handle(%Update{} = update) do
    _ = Codemojex.EchoBot.bridge(update)
    :noreply
  end
end
