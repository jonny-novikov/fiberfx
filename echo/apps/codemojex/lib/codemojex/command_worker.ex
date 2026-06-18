defmodule Codemojex.CommandWorker do
  @moduledoc """
  Drains the `cm.bot.commands` lane that `Codemojex.EchoBot.ingest/1` fills from the Telegram
  webhook, and dispatches each update. Keeping inbound handling on the bus (rather than in the
  webhook request) makes commands durable, ordered per chat, and replayable — and lets the slow
  parts (a DB write, a reply) happen off the request path.

  This is a deliberately small dispatcher: `/start` replies with a welcome and the Mini App
  launch, a callback query is acknowledged, and anything else is ignored. The reply goes back
  out through `Codemojex.Notifier`, so it inherits the same rate limiting and retries as every
  other outbound message.
  """
  require Logger

  alias Codemojex.Notifier

  @spec handle(map()) :: :ok
  def handle(%{payload: payload}) do
    case Jason.decode(payload) do
      {:ok, update} -> dispatch(update)
      _ -> :ok
    end
  end

  defp dispatch(%{"message" => %{"chat" => %{"id" => chat}, "text" => "/start" <> _}}) do
    {:ok, _} = Notifier.notify(chat, "Welcome to Codemoji! 🧩 Tap the button to play.", parse_mode: "HTML")
    :ok
  end

  defp dispatch(%{"message" => %{"chat" => %{"id" => chat}, "text" => text}}) do
    Logger.debug("CommandWorker: unhandled text from #{chat}: #{inspect(text)}")
    :ok
  end

  defp dispatch(%{"callback_query" => %{"id" => qid}}) do
    _ = Codemojex.Telegram.answer_callback_query(qid)
    :ok
  end

  defp dispatch(_other), do: :ok
end
