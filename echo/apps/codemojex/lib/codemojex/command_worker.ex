defmodule Codemojex.CommandWorker do
  @moduledoc """
  Drains the `cm.bot.commands` lane that `Codemojex.EchoBot.bridge/1` fills — from `echo_bot`'s
  updater or a webhook — and dispatches each normalized command. Keeping inbound handling on the
  bus (rather than in the updater) makes commands durable, per-chat ordered, and replayable, and
  lets the slow parts (a DB write, a reply) happen off the hot path.

  This is a deliberately small dispatcher: `/start` and `/help` reply with static text, and
  anything else is logged and ignored. The reply goes back out through `Codemojex.Notifier`, so
  it inherits the same rate limiting and retries as every other outbound message — delivered by
  `echo_bot`.
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

  defp dispatch(%{"command" => "start", "chat" => chat}) when not is_nil(chat) do
    {:ok, _} = Notifier.notify(chat, "Welcome to Codemoji. Tap the button to play.")
    :ok
  end

  defp dispatch(%{"command" => "help", "chat" => chat}) when not is_nil(chat) do
    {:ok, _} = Notifier.notify(chat, "Codemoji — crack the 6-emoji code. Open the app to play; /start to begin.")
    :ok
  end

  defp dispatch(%{"command" => cmd, "chat" => chat}) when not is_nil(cmd) do
    Logger.debug("CommandWorker: unhandled command #{inspect(cmd)} from #{inspect(chat)}")
    :ok
  end

  defp dispatch(_other), do: :ok
end
