defmodule Codemojex.Notifier do
  @moduledoc """
  The enqueue side of notifications — what the game calls to *send* a Telegram message without
  touching Telegram or the rate limiter directly.

  Every notification is minted a `NOT` branded id (typed, time-ordered) and enqueued on a fair
  lane keyed by chat id, so the bus spreads a chat's notifications behind the
  `NotificationWorker`'s rate limit rather than firing them at once. The call returns the job id
  and is cheap: it does one enqueue and no network I/O. Delivery, rate limiting, retries, and
  backoff are the worker's job (`Codemojex.NotificationWorker`).

  Game helpers (`game_result/3`, `prize_won/3`) are thin wrappers that format the text; they
  exist so call sites stay readable and the wording lives in one place.
  """
  alias Codemojex.{Bus, NotificationWorker}
  alias EchoMQ.Lanes

  @doc """
  Enqueue a notification to `chat_id`. `opts` are passed through to `sendMessage`
  (`:parse_mode`, `:reply_markup`, ...). Returns `{:ok, job_id} | {:error, term()}`.
  """
  @spec notify(integer() | binary(), binary(), keyword()) ::
          {:ok, EchoData.BrandedId.t()} | {:error, term()}
  def notify(chat_id, text, opts \\ []) do
    job_id = EchoData.BrandedId.generate!("JOB")
    payload = Jason.encode!(%{chat: chat_id, text: text, opts: Map.new(opts), id: job_id, attempt: 1})

    # A bus lane is keyed by a BRANDED id (EchoMQ.Lanes.lane_key!) — the chat id is not branded, so
    # each notification rides its own JOB-id lane and the ring rotates across them for fairness,
    # drained by Codemojex.NotificationWorker. This mirrors the shipped scoring enqueue (a JOB id +
    # a branded group), the only shape EchoMQ.Lanes.claim can drain. Lanes.enqueue returns
    # {:ok, :enqueued} | {:ok, :duplicate} (both success), {:error, :kind}, or a connector passthrough.
    case Lanes.enqueue(Bus.conn(), NotificationWorker.queue(), job_id, job_id, payload) do
      {:ok, _} -> {:ok, job_id}
      other -> {:error, other}
    end
  end

  @doc "Notify a player how a finished game scored them."
  @spec game_result(integer() | binary(), EchoData.BrandedId.t(), non_neg_integer()) ::
          {:ok, EchoData.BrandedId.t()} | {:error, term()}
  def game_result(chat_id, game_id, score) do
    notify(chat_id, "Game #{game_id} is done — you scored #{score}/600. 🎯")
  end

  @doc "Notify a player they won a prize, with the diamond amount."
  @spec prize_won(integer() | binary(), EchoData.BrandedId.t(), non_neg_integer()) ::
          {:ok, EchoData.BrandedId.t()} | {:error, term()}
  def prize_won(chat_id, prize_id, diamonds) do
    notify(chat_id, "🏆 You won prize #{prize_id}: #{diamonds} 💎. Tap to claim.")
  end

  @doc "Notify a player they won a Golden Room, with the diamond amount."
  @spec golden_win(integer() | binary(), EchoData.BrandedId.t(), non_neg_integer()) ::
          {:ok, EchoData.BrandedId.t()} | {:error, term()}
  def golden_win(chat_id, game_id, diamonds) do
    notify(chat_id, "✨ GOLDEN ROOM #{game_id} — you took #{diamonds} 💎. Tap to claim.")
  end

  @doc """
  Nudge a member of a gathering Golden Room toward its `room_deadline` — the
  bot-engagement notification (cm.5 R9). The deadline is the promotional-event end.
  """
  @spec gather_nudge(integer() | binary(), EchoData.BrandedId.t(), DateTime.t()) ::
          {:ok, EchoData.BrandedId.t()} | {:error, term()}
  def gather_nudge(chat_id, game_id, %DateTime{} = deadline) do
    notify(
      chat_id,
      "⏳ The Golden Room #{game_id} is gathering — it ends #{DateTime.to_string(deadline)}. Bring a friend to fill the room!"
    )
  end
end
