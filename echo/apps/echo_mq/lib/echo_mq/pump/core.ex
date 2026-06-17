defmodule EchoMQ.Pump.Core do
  @moduledoc """
  The pump's pure decision core: the tick interval and the per-tick batch as
  plain functions of the start options, with no process, no clock, and no
  I/O. The cadence is a value the consumer can compute and table; the
  GenServer shell (`EchoMQ.Pump`) reads these once at `init` and beats on
  them. Chapter 3.7.
  """

  @default_tick_ms 1_000
  @default_batch 100

  @doc """
  The tick interval in milliseconds: the `:tick_ms` option, or the default
  beat. A non-positive tick is refused -- a pump that does not advance is a
  configuration error, not a silent no-op.

      iex> EchoMQ.Pump.Core.tick_ms([])
      1000
      iex> EchoMQ.Pump.Core.tick_ms(tick_ms: 250)
      250
  """
  @spec tick_ms(keyword()) :: pos_integer()
  def tick_ms(opts) do
    case Keyword.get(opts, :tick_ms, @default_tick_ms) do
      ms when is_integer(ms) and ms > 0 -> ms
      bad -> raise ArgumentError, "tick_ms must be a positive integer, got: #{inspect(bad)}"
    end
  end

  @doc """
  The per-tick batch: the `:batch` option, or the default. Bounds both the
  promote LIMIT and the repeat due-read LIMIT in one tick, so a tick's work is
  bounded no matter how much is due.

      iex> EchoMQ.Pump.Core.batch([])
      100
      iex> EchoMQ.Pump.Core.batch(batch: 10)
      10
  """
  @spec batch(keyword()) :: pos_integer()
  def batch(opts) do
    case Keyword.get(opts, :batch, @default_batch) do
      n when is_integer(n) and n > 0 -> n
      bad -> raise ArgumentError, "batch must be a positive integer, got: #{inspect(bad)}"
    end
  end
end
