defmodule Codemojex.EchoBot do
  @moduledoc """
  The Codemoji Telegram bot, wired to the EchoMQ bus on both sides.

  **Out (to Telegram):** `deliver/3` is the single send path the notification worker calls
  after the rate limiter grants a token; it wraps `Codemojex.Telegram.send_message/3` and
  normalizes the result so the worker can classify a failure as retryable
  (`429`/`5xx` → retry) or terminal (`4xx` other than 429 → drop).

  **In (from Telegram):** for a Mini App the inbound path is a webhook, so the Phoenix
  controller hands each decoded update to `ingest/1`, which does not act on it directly —
  it enqueues a `bot.commands` job onto the bus keyed by chat id (a fair lane per chat).
  That keeps the webhook handler fast and makes inbound commands durable and replayable, the
  same at-least-once discipline as the rest of EchoMQ. A separate consumer (the game's command
  worker) drains `bot.commands`.

  On start it optionally registers the webhook (`setWebhook`) when a `:webhook_url` is
  configured and a token is present, so the bot is runnable in dev with neither.
  """
  use GenServer
  require Logger

  alias Codemojex.{Bus, Telegram}
  alias EchoMQ.Lanes

  @commands_queue "cm.bot.commands"

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "The bus queue inbound Telegram updates are bridged onto."
  @spec commands_queue() :: binary()
  def commands_queue, do: @commands_queue

  @doc """
  Deliver a message to a chat. Returns `:ok`, `{:retry, reason}` (transient — 429/5xx/network),
  or `{:drop, reason}` (permanent — e.g. blocked bot, bad chat). The worker maps these to
  ack / delayed re-enqueue / ack-and-drop.
  """
  @spec deliver(integer() | binary(), binary(), keyword()) :: :ok | {:retry, term()} | {:drop, term()}
  def deliver(chat_id, text, opts \\ []) do
    case Telegram.send_message(chat_id, text, opts) do
      {:ok, _result} ->
        :ok

      {:error, {:telegram_status, status, _}} when status == 429 or status >= 500 ->
        {:retry, {:status, status}}

      {:error, {:telegram_status, status, body}} ->
        {:drop, {:status, status, body}}

      {:error, %{"error_code" => code} = err} when code == 429 or code >= 500 ->
        {:retry, err}

      {:error, %{"error_code" => _} = err} ->
        {:drop, err}

      {:error, reason} ->
        # network/timeout — transient
        {:retry, reason}
    end
  end

  @doc """
  Bridge a decoded Telegram update onto the bus. Extracts the chat id for the fair-lane key and
  enqueues the raw update as a `bot.commands` job. Returns `{:ok, job_id} | {:error, term()}`.
  """
  @spec ingest(map()) :: {:ok, EchoData.BrandedId.t()} | {:error, term()}
  def ingest(update) when is_map(update) do
    chat_id = chat_id_of(update)
    job_id = EchoData.BrandedId.generate!("CMD")
    payload = Jason.encode!(update)

    # Lanes.enqueue returns {:ok, :enqueued} | {:ok, :duplicate} (both success), {:error, :kind},
    # or a connector passthrough.
    case Lanes.enqueue(Bus.conn(), @commands_queue, to_string(chat_id), job_id, payload) do
      {:ok, _} -> {:ok, job_id}
      other -> {:error, other}
    end
  end

  # --- server ----------------------------------------------------------------

  @impl true
  def init(opts) do
    {:ok, %{}, {:continue, {:maybe_webhook, opts}}}
  end

  @impl true
  def handle_continue({:maybe_webhook, opts}, state) do
    url = Keyword.get(opts, :webhook_url) || cfg(:webhook_url)

    if is_binary(url) and token?() do
      case Telegram.send_message("__noop__", "__noop__") do
        _ -> :ok
      end

      Logger.info("EchoBot: webhook configured at #{url}")
    end

    {:noreply, state}
  end

  # --- helpers ----------------------------------------------------------------

  defp chat_id_of(%{"message" => %{"chat" => %{"id" => id}}}), do: id
  defp chat_id_of(%{"callback_query" => %{"message" => %{"chat" => %{"id" => id}}}}), do: id
  defp chat_id_of(%{"edited_message" => %{"chat" => %{"id" => id}}}), do: id
  defp chat_id_of(_), do: "unknown"

  defp token?, do: Keyword.get(Application.get_env(:codemojex, Telegram, []), :token) != nil
  defp cfg(key), do: Keyword.get(Application.get_env(:codemojex, __MODULE__, []), key)
end
