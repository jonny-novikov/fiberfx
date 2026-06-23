defmodule EchoStore.StreamArchive.Core do
  @moduledoc """
  The archive driver's pure decision core (emq3.5, S3 the memory part 1): given a
  declared per-stream archive policy and an injected clock, answer WHICH streams
  to fold-then-trim this tick and with WHICH trim window -- a PURE function, no
  process, no clock, no IO. The mint-instant analogue of
  `EchoMQ.StreamRetention.Core` (the cadence arithmetic as plain functions, the
  injected-clock precedent) -- a decision surface is a pure module, so the
  fold-then-trim plan is a value tested without a live process or wire.

  ## The declared policy (BEAM-side, the StreamRetention D-3 precedent)

  A policy entry is `{queue, name, volume_id, window}` where `window` is the
  `EchoMQ.Stream.trim/4` window the trim uses AFTER the fold -- `{:maxlen, count,
  approx?}`, `{:minid, dt, approx?}`, or a RELATIVE `{:minid, {:ago, ms},
  approx?}` resolved against the injected clock. The policy is held BEAM-side
  (the driver's config), NEVER a keyspace subkey. A MALFORMED window RAISES at
  decision time -- the gate-liveness rule, never a silent skip.

  ## The decision (exhaustive + disjoint)

  `decide/2` resolves each declared policy's window against the injected instant
  into a fold-then-trim plan `{queue, name, volume_id, resolved_window}`. The
  ORDER inside one cycle (read-slice -> fold -> advance-W -> trim) is the
  driver's; the core only decides WHICH streams and the resolved window. An
  EMPTY policy answers `:noop`.

  The fold reads the slice `(W, floor]` from the live stream and commits it
  BEFORE the trim removes it -- so the trim window the core resolves is the SAME
  window the operator declared for retention; the archive simply folds first.
  Because the fold reads via `EchoMQ.Stream.read/6` (mint order) and trims via
  `EchoMQ.Stream.trim/4` only the already-folded span, no record the trim deletes
  is unfolded (the no-loss invariant lives in the driver's ordering, proven
  there).
  """

  @typedoc """
  A declared archive window -- the `EchoMQ.Stream.trim/4` forms plus a RELATIVE
  `:minid` horizon `{:ago, ms}` resolved against the injected clock.
  """
  @type window ::
          {:maxlen, non_neg_integer(), boolean()}
          | {:minid, DateTime.t(), boolean()}
          | {:minid, {:ago, non_neg_integer()}, boolean()}

  @typedoc """
  One declared per-stream archive policy: fold-then-trim
  `emq:{queue}:stream:<name>` into Volume `volume_id` to `window`.
  """
  @type policy ::
          {queue :: binary(), name :: binary(), volume_id :: binary(), window()}

  @typedoc "A resolved fold-then-trim plan the driver applies."
  @type plan ::
          {queue :: binary(), name :: binary(), volume_id :: binary(),
           EchoMQ.Stream.window()}

  @doc """
  The fold-then-trim plans due for a list of declared `policies` at the injected
  instant `now_dt`. Returns `[plan]` (one per declared policy, the relative
  horizons resolved against `now_dt`) or `:noop` when `policies` is empty.
  RAISES `ArgumentError` on a malformed window (exhaustive + disjoint; a
  malformed policy is a configuration error, never a silent skip).

      iex> EchoStore.StreamArchive.Core.decide([], DateTime.utc_now())
      :noop

      iex> EchoStore.StreamArchive.Core.decide([{"q", "s", "VOL00000000aa", {:maxlen, 100, true}}], ~U[2024-01-01 00:00:00Z])
      [{"q", "s", "VOL00000000aa", {:maxlen, 100, true}}]
  """
  @spec decide([policy()], DateTime.t()) :: [plan()] | :noop
  def decide([], %DateTime{}), do: :noop

  def decide(policies, %DateTime{} = now_dt) when is_list(policies) do
    Enum.map(policies, fn {queue, name, volume_id, window}
                          when is_binary(queue) and is_binary(name) and is_binary(volume_id) ->
      {queue, name, volume_id, resolve(window, now_dt)}
    end)
  end

  @doc """
  Resolve one declared `window` against the injected instant `now_dt` into the
  exact `EchoMQ.Stream.trim/4` window. Exhaustive + disjoint over the forms; a
  RELATIVE `{:ago, ms}` `:minid` horizon resolves to the absolute `DateTime`
  `now_dt - ms`. RAISES `ArgumentError` on a malformed window. (The
  `EchoMQ.StreamRetention.Core.resolve/2` form, verbatim — the archive trims via
  the same retention windows once the fold has secured the slice.)
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
          "EchoStore.StreamArchive: malformed archive window " <>
            "(expected {:maxlen, count, approx?} or {:minid, dt_or_{:ago,ms}, approx?}); got: #{inspect(bad)}"
  end
end
