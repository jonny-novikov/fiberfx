defmodule Codemojex.NotificationWorker do
  @moduledoc """
  The robust, rate-limited notification job. An `EchoMQ.Consumer` drains the notify queue and
  this handler delivers each notification through the bot, under three layers of control:

    1. **Fairness** — notifications are enqueued on a *fair lane per chat*
       (`Codemojex.Notifier`), so one chat's burst cannot starve others.
    2. **Rate** — before each send the handler takes a token from `Codemojex.RateLimiter`
       (global ~30/s, per-chat ~1/s). Over budget, it does not block the consumer; it
       re-enqueues the same job with `EchoMQ.Jobs.enqueue_in/5` after the bucket's reported
       wait, and acks — the notification stays durable on the bus, deferred, not dropped.
    3. **Delivery** — `EchoBot.deliver/3` classifies the Telegram result: success acks;
       a transient failure (429/5xx/network) re-enqueues with capped exponential backoff up to
       `@max_attempts`; a permanent failure (blocked bot, bad chat) acks-and-drops with a log.

  At-least-once plus a notification id make duplicates rare and harmless: the same notice is at
  worst delivered twice, never lost. The payload is JSON `{chat, text, opts, id, attempt}`.
  """
  require Logger

  alias Codemojex.{Bus, EchoBot, RateLimiter}
  alias EchoMQ.Jobs

  @queue "cm.notify"
  @max_attempts 6
  @base_backoff_ms 500

  @doc "The notify queue name (used by the consumer child spec and the Notifier)."
  @spec queue() :: binary()
  def queue, do: @queue

  @doc """
  Consumer handler. Receives a delivered job (`%{job_id: ..., payload: ...}`); returns `:ok`
  once handled (delivered, deferred, or dropped) so the lease is released.
  """
  @spec handle(map()) :: :ok
  def handle(%{payload: payload} = job) do
    case Jason.decode(payload) do
      {:ok, %{"chat" => chat, "text" => text} = msg} ->
        attempt = Map.get(msg, "attempt", 1)
        opts = decode_opts(Map.get(msg, "opts", %{}))
        rate_limited_deliver(job, msg, chat, text, opts, attempt)

      _ ->
        Logger.warning("NotificationWorker: undecodable payload, dropping: #{inspect(payload)}")
        :ok
    end
  end

  defp rate_limited_deliver(job, msg, chat, text, opts, attempt) do
    case RateLimiter.take(chat) do
      :ok ->
        deliver(job, msg, chat, text, opts, attempt)

      {:wait, ms} ->
        # Defer, don't block: re-enqueue this exact notification after the bucket refills.
        requeue(msg, ms)
        :ok
    end
  end

  defp deliver(job, msg, chat, text, opts, attempt) do
    case EchoBot.deliver(chat, text, opts) do
      :ok ->
        :ok

      {:retry, reason} when attempt < @max_attempts ->
        delay = backoff(attempt)
        Logger.info("notify #{job_id(job)} chat=#{chat} retry #{attempt}/#{@max_attempts} in #{delay}ms (#{inspect(reason)})")
        requeue(Map.put(msg, "attempt", attempt + 1), delay)
        :ok

      {:retry, reason} ->
        Logger.warning("notify #{job_id(job)} chat=#{chat} exhausted #{@max_attempts} attempts, dropping (#{inspect(reason)})")
        :ok

      {:drop, reason} ->
        Logger.warning("notify #{job_id(job)} chat=#{chat} permanent failure, dropping (#{inspect(reason)})")
        :ok
    end
  end

  # Re-schedule the job on the bus after `delay_ms` — durable, survives a crash.
  defp requeue(msg, delay_ms) do
    job_id = EchoData.BrandedId.generate!("NOT")
    payload = Jason.encode!(msg)
    Jobs.enqueue_in(Bus.conn(), @queue, job_id, payload, max(delay_ms, 1))
  end

  defp backoff(attempt) do
    jitter = :rand.uniform(@base_backoff_ms)
    min(@base_backoff_ms * Bitwise.bsl(1, attempt - 1), 30_000) + jitter
  end

  defp decode_opts(opts) when is_map(opts), do: Enum.map(opts, fn {k, v} -> {String.to_atom(k), v} end)
  defp decode_opts(_), do: []

  # The Consumer delivers each job as `%{id:, payload:, attempts:, group:}` — the envelope key
  # is `:id` (see EchoMQ.Consumer), so extract from `:id`, not `:job_id`.
  defp job_id(%{id: id}), do: id
  defp job_id(_), do: "?"
end
