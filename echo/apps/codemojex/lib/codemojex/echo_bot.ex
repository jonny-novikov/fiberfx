defmodule Codemojex.EchoBot do
  @moduledoc """
  The Codemoji bot, wired to the EchoMQ bus on both sides and to Telegram through the
  `echo_bot` engine.

  **Out (to Telegram):** `deliver/3` is the single send path the notification worker calls
  after the rate limiter grants a token; it delegates to `Codemojex.Bot.deliver/2`, which
  sends through `echo_bot`'s vendored client and returns a verdict the worker classifies as
  ack, retry, or drop.

  **In (from Telegram):** an inbound update — from `echo_bot`'s updater via
  `Codemojex.Bot.Handler`, or from a webhook handing a raw map to `ingest/1` — is normalized
  and bridged onto the bus as a `CMD` job on a fair lane per chat (`bridge/1`). That keeps the
  inbound path fast and makes commands durable, per-chat ordered, and replayable; a separate
  consumer (`Codemojex.CommandWorker`) drains the lane and replies through the same
  notification path.
  """
  use GenServer
  require Logger

  alias Codemojex.Bus
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
  def deliver(chat_id, text, _opts \\ []) do
    # Delivery goes through the echo_bot platform (the vendored ex_gram client).
    # send_reply carries text only, so per-message opts (parse_mode, reply_markup)
    # are not forwarded; the worker classifies the verdict as ack / retry / drop.
    Codemojex.Bot.deliver(chat_id, text)
  end

  @doc """
  Bridge a decoded Telegram update onto the bus. Extracts the chat id for the fair-lane key and
  enqueues the raw update as a `bot.commands` job. Returns `{:ok, job_id} | {:error, term()}`.
  """
  @spec ingest(map()) :: {:ok, EchoData.BrandedId.t()} | {:ok, :ignored} | {:error, term()}
  def ingest(raw) when is_map(raw) do
    raw |> EchoBot.Platform.Telegram.decode_and_normalize() |> bridge()
  end

  @doc """
  Bridge a normalized `EchoBot.Platform.Update` onto the bus: take the chat for the fair-lane
  key and enqueue the command as a `CMD` job on the bot-commands lane. Returns `{:ok, job_id}`,
  `{:ok, :ignored}` for a chat-less update, or `{:error, term()}`.
  """
  @spec bridge(EchoBot.Platform.Update.t()) ::
          {:ok, EchoData.BrandedId.t()} | {:ok, :ignored} | {:error, term()}
  def bridge(%EchoBot.Platform.Update{chat_ref: nil}), do: {:ok, :ignored}

  def bridge(%EchoBot.Platform.Update{} = u) do
    job_id = EchoData.BrandedId.generate!("CMD")

    payload =
      Jason.encode!(%{
        update_id: u.update_id,
        chat: u.chat_ref,
        command: u.command,
        args: u.args || [],
        text: u.text
      })

    case Lanes.enqueue(Bus.conn(), @commands_queue, to_string(u.chat_ref), job_id, payload) do
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
    if is_binary(url), do: Logger.info("Codemojex.EchoBot: webhook target #{url}")
    {:noreply, state}
  end

  # --- helpers ----------------------------------------------------------------

  defp cfg(key), do: Keyword.get(Application.get_env(:codemojex, __MODULE__, []), key)
end
