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
    job_id = EchoData.BrandedId.generate!("NOT")
    payload = Jason.encode!(%{chat: chat_id, text: text, opts: Map.new(opts), id: job_id, attempt: 1})

    # Lanes.enqueue returns {:ok, :enqueued} | {:ok, :duplicate} (both success — a duplicate
    # NOT id is harmless), {:error, :kind}, or a connector passthrough.
    case Lanes.enqueue(Bus.conn(), NotificationWorker.queue(), to_string(chat_id), job_id, payload) do
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

  @doc "Notify a player they won a Golden Room, with the boosted diamonds and the multiplier."
  @spec golden_win(integer() | binary(), EchoData.BrandedId.t(), non_neg_integer(), pos_integer()) ::
          {:ok, EchoData.BrandedId.t()} | {:error, term()}
  def golden_win(chat_id, game_id, diamonds, multiplier) do
    notify(chat_id, "✨ GOLDEN ROOM #{game_id} — you took #{diamonds} 💎 at a #{multiplier}x boost. Tap to claim.")
  end
end
