defmodule EchoMQ.BatchShaper.Core do
  @moduledoc """
  The batch shaper's pure decision core: the `min_size`/`timeout` flush
  decision as a plain function of the observed pending depth, the ms elapsed
  since the window opened, and the two knobs, with no process, no clock, and
  no I/O. The `EchoMQ.Pump.Core` isomorph (`pump/core.ex`) -- a cadence the
  consumer can compute and table; the `EchoMQ.BatchConsumer` shell reads the
  knobs once at start and feeds the watched depth + the injected elapsed in.
  emq.5.2.

  The decision rule (the carve's "waits for >= `min_size` OR until `timeout`,
  then drains"):

    * **D1 the size floor (watch-depth).** When `depth >= min_size`, flush --
      request `size = depth` (the full observed ready depth; `@bclaim` clamps
      to the depth, so a flood drains all-ready, never over-popping, and the
      request is always `>= min_size`).
    * **D2 the latency ceiling (ceiling-wins, the floor is soft).** When
      `elapsed_ms >= timeout`, flush whatever is present -- request `size =
      depth` (the partial, possibly `1..(min_size - 1)`); a window with
      `depth == 0` at the ceiling flushes NOTHING (no batch -- re-open the
      window), since a zero-member batch carries no work.
    * Otherwise (`depth < min_size` and `elapsed_ms < timeout`), wait -- the
      floor is not yet met and the ceiling has not fired.

  The decision NEVER touches Valkey: it computes a verdict the consumer
  redeems through the byte-frozen `EchoMQ.Jobs.claim_batch/4`.
  """

  @doc """
  Validate the shaper knobs the `EchoMQ.Pump.Core` way: `min_size` and
  `timeout` must each be a positive integer, else RAISE -- a shaper that
  cannot advance (a zero/negative floor or ceiling) is a configuration error,
  not a silent no-op. Returns the validated `{min_size, timeout}` pair.

      iex> EchoMQ.BatchShaper.Core.validate!(10, 200)
      {10, 200}
  """
  @spec validate!(integer(), integer()) :: {pos_integer(), pos_integer()}
  def validate!(min_size, timeout) do
    {check!(:min_size, min_size), check!(:timeout, timeout)}
  end

  defp check!(_knob, n) when is_integer(n) and n > 0, do: n

  defp check!(knob, bad) do
    raise ArgumentError, "#{knob} must be a positive integer, got: #{inspect(bad)}"
  end

  @doc """
  The flush decision: given the observed pending `depth`, the ms `elapsed`
  since the window opened, and the validated `min_size`/`timeout`, answer
  `{:flush, size}` to drain `size` members now, or `:wait` to keep the window
  open. The knobs are re-validated (a non-positive knob RAISES -- the
  `Pump.Core` discipline holds at the decision point too).

  D1 the floor met (`depth >= min_size`) -> `{:flush, depth}` (request the
  full ready depth; always `>= min_size`). D2 the ceiling fired
  (`elapsed >= timeout`) with `depth > 0` -> `{:flush, depth}` (the partial);
  with `depth == 0` -> `:wait` (the empty case -- re-open, no batch).
  Otherwise -> `:wait`.

      iex> EchoMQ.BatchShaper.Core.decide(10, 50, 10, 200)
      {:flush, 10}
      iex> EchoMQ.BatchShaper.Core.decide(12, 50, 10, 200)
      {:flush, 12}
      iex> EchoMQ.BatchShaper.Core.decide(3, 50, 10, 200)
      :wait
      iex> EchoMQ.BatchShaper.Core.decide(3, 200, 10, 200)
      {:flush, 3}
      iex> EchoMQ.BatchShaper.Core.decide(0, 200, 10, 200)
      :wait
  """
  @spec decide(non_neg_integer(), non_neg_integer(), integer(), integer()) ::
          {:flush, pos_integer()} | :wait
  def decide(depth, elapsed, min_size, timeout)
      when is_integer(depth) and depth >= 0 and is_integer(elapsed) and elapsed >= 0 do
    {min_size, timeout} = validate!(min_size, timeout)

    cond do
      # D1 -- the size floor met: request the full observed depth (>= min_size)
      depth >= min_size -> {:flush, depth}
      # D2 -- the latency ceiling fired: flush the partial, or nothing if empty
      elapsed >= timeout and depth > 0 -> {:flush, depth}
      # the ceiling fired on an empty window, or the window is still open
      true -> :wait
    end
  end
end
