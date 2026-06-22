defmodule EchoMQ.StreamRetention.Core do
  @moduledoc """
  The trim driver's pure decision core (emq3.4, S2 the readers part 2): given a
  declared per-stream retention policy and an injected clock, answer WHICH
  `EchoMQ.Stream.trim/4` call to make for each stream (or `:noop` when nothing
  is declared) -- a PURE function, no process, no clock, no IO. The decision is
  a value the consumer can compute and table; the GenServer shell
  (`EchoMQ.StreamRetention`) reads the policy at `init` and applies the core's
  decision on each tick. The mint-instant analogue of `EchoMQ.Pump.Core` (the
  cadence arithmetic as plain functions) -- the verdict-surface law: a decision
  surface is a pure module, not a process `defp`, so the destructive call is
  never buried in an IO `defp` and the policy validation is exhaustively
  testable without a live process.

  ## The declared policy (BEAM-side, D-3)

  A policy entry is `{queue, name, window}` where `window` is the
  `EchoMQ.Stream.trim/4` window verbatim -- `{:maxlen, count, approx?}` or
  `{:minid, dt, approx?}`. The policy is held BEAM-side (the driver's config or
  an ETS map), NEVER a keyspace subkey (D-3). A MALFORMED window RAISES at
  decision time (`decide/2`) -- the gate-liveness rule "a gate specifies its own
  liveness", never a silent skip.

  ## The decision (exhaustive + disjoint over the policy forms)

  `decide/2` is exhaustive and disjoint over the window forms:

    * a `{:maxlen, count, approx?}` with a non-negative integer `count` and a
      boolean `approx?` -> a trim call `{queue, name, {:maxlen, count, approx?}}`;
    * a `{:minid, dt, approx?}` with a `DateTime` `dt` and a boolean `approx?`
      -> a trim call `{queue, name, {:minid, dt, approx?}}` (the floor is
      derived inside `Stream.trim/4` from `Snowflake.min_for/1`);
    * any other window shape -> RAISES `ArgumentError` (a malformed policy is a
      configuration error, never a no-op).

  An EMPTY policy list answers `:noop` (nothing declared -> nothing trimmed).

  ## The injected clock

  `decide/2` takes `now_dt` (a `DateTime`) so the cadence is a pure function of
  the injected clock -- the `EchoMQ.BatchShaper.Core` injected-clock precedent.
  The `:minid` window's horizon may be ABSOLUTE (a `DateTime` carried verbatim)
  or RELATIVE (a `{:ago, ms}` duration resolved against `now_dt` to
  `DateTime.add(now_dt, -ms, :millisecond)`) -- so a "keep the last N ms"
  policy is a pure function of the injected clock, tested directly, never a
  wall-clock flake.
  """

  @typedoc """
  A declared retention window. The `EchoMQ.Stream.trim/4` window forms, plus a
  RELATIVE `:minid` horizon `{:ago, ms}` the core resolves against the injected
  clock (keep entries minted within the last `ms`).
  """
  @type window ::
          {:maxlen, non_neg_integer(), boolean()}
          | {:minid, DateTime.t(), boolean()}
          | {:minid, {:ago, non_neg_integer()}, boolean()}

  @typedoc "One declared per-stream policy: trim `emq:{queue}:stream:<name>` to `window`."
  @type policy :: {queue :: binary(), name :: binary(), window()}

  @typedoc "A resolved trim instruction the driver applies via `EchoMQ.Stream.trim/4`."
  @type trim_call :: {binary(), binary(), EchoMQ.Stream.window()}

  @doc """
  The trim calls due for a list of declared `policies` at the injected instant
  `now_dt`. Returns `[trim_call]` (one per declared policy, the relative
  horizons resolved against `now_dt`) or `:noop` when `policies` is empty.
  RAISES `ArgumentError` on a malformed window (exhaustive + disjoint; a
  malformed policy is a configuration error, never a silent skip).

      iex> EchoMQ.StreamRetention.Core.decide([], DateTime.utc_now())
      :noop

      iex> EchoMQ.StreamRetention.Core.decide([{"q", "s", {:maxlen, 100, true}}], DateTime.utc_now())
      [{"q", "s", {:maxlen, 100, true}}]
  """
  @spec decide([policy()], DateTime.t()) :: [trim_call()] | :noop
  def decide([], %DateTime{}), do: :noop

  def decide(policies, %DateTime{} = now_dt) when is_list(policies) do
    Enum.map(policies, fn {queue, name, window}
                          when is_binary(queue) and is_binary(name) ->
      {queue, name, resolve(window, now_dt)}
    end)
  end

  @doc """
  Resolve one declared `window` against the injected instant `now_dt` into the
  exact `EchoMQ.Stream.trim/4` window. Exhaustive + disjoint over the forms; a
  RELATIVE `{:ago, ms}` `:minid` horizon resolves to the absolute `DateTime`
  `now_dt - ms`. RAISES `ArgumentError` on a malformed window.
  """
  @spec resolve(window(), DateTime.t()) :: EchoMQ.Stream.window()
  def resolve({:maxlen, count, approx?}, %DateTime{})
      when is_integer(count) and count >= 0 and is_boolean(approx?),
      do: {:maxlen, count, approx?}

  def resolve({:minid, %DateTime{} = dt, approx?}, %DateTime{}) when is_boolean(approx?),
    do: {:minid, dt, approx?}

  def resolve({:minid, {:ago, ms}, approx?}, %DateTime{} = now_dt)
      when is_integer(ms) and ms >= 0 and is_boolean(approx?),
      do: {:minid, DateTime.add(now_dt, -ms, :millisecond), approx?}

  def resolve(bad, %DateTime{}) do
    raise ArgumentError,
          "EchoMQ.StreamRetention: malformed retention window " <>
            "(expected {:maxlen, count, approx?} or {:minid, dt_or_{:ago,ms}, approx?}); got: #{inspect(bad)}"
  end
end
