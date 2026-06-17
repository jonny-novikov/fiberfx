defmodule EchoMQ.Backoff do
  @moduledoc """
  The retry delay vocabulary, host-side. A pure function from a policy and an
  attempt count to a literal `delay_ms`, computed above the wire and handed
  to `EchoMQ.Jobs.retry/7` as `ARGV[3]` -- the wire takes a literal delay and
  never computes a curve (the v2 HOLD: backoff above the wire). No process,
  no clock, no I/O: a deterministic function of `(policy, attempts)`, so the
  consumer's retry cadence is a value it can compute, table, and test without
  a server. Chapter 3.7.

  Policies:

    * `{:fixed, ms}` -- the same delay on every attempt.
    * `{:exponential, base_ms, cap_ms}` -- `base * 2^(attempts-1)`, clamped to
      `cap_ms`, so the curve climbs and then holds at the ceiling.
    * `{:jitter, inner}` -- a wrap over any inner policy: a uniform random
      delay in `0..inner_delay`, the full-jitter form that spreads a retry
      storm. The only non-deterministic policy, and the randomness is the
      point; the inner delay is its bound.

  `attempts` is the attempt that just failed (1 for the first), matching the
  fencing token `EchoMQ.Jobs.claim/3` mints and `retry/7` carries.
  """

  @type policy ::
          {:fixed, non_neg_integer()}
          | {:exponential, pos_integer(), pos_integer()}
          | {:jitter, policy()}

  @doc """
  The delay, in milliseconds, before the next attempt under `policy` given
  the attempt that just failed.

      iex> EchoMQ.Backoff.delay_ms({:fixed, 1_000}, 1)
      1000
      iex> EchoMQ.Backoff.delay_ms({:fixed, 1_000}, 5)
      1000

      iex> EchoMQ.Backoff.delay_ms({:exponential, 100, 10_000}, 1)
      100
      iex> EchoMQ.Backoff.delay_ms({:exponential, 100, 10_000}, 3)
      400
      iex> EchoMQ.Backoff.delay_ms({:exponential, 100, 10_000}, 20)
      10000
  """
  @spec delay_ms(policy(), pos_integer()) :: non_neg_integer()
  def delay_ms({:fixed, ms}, attempts)
      when is_integer(ms) and ms >= 0 and is_integer(attempts) and attempts >= 1,
      do: ms

  def delay_ms({:exponential, base, cap}, attempts)
      when is_integer(base) and base >= 1 and is_integer(cap) and cap >= 1 and
             is_integer(attempts) and attempts >= 1 do
    # base * 2^(attempts-1), clamped at cap; the shift is exact-integer and
    # the cap holds the curve from overflowing past the ceiling.
    raw = base * Bitwise.bsl(1, attempts - 1)
    min(raw, cap)
  end

  def delay_ms({:jitter, inner}, attempts) when is_integer(attempts) and attempts >= 1 do
    bound = delay_ms(inner, attempts)
    if bound <= 0, do: 0, else: :rand.uniform(bound + 1) - 1
  end
end
