defmodule EchoMQ.Metronome.Core do
  @moduledoc """
  The metronome's pure decision core: the beat interval and the dispatch
  decision as plain functions, with no process, no clock, and no I/O. The
  metronome shell (`EchoMQ.Metronome`) reads `beat_ms/1` once at start and,
  on every wake, asks `dispatch/1` which registered-idle consumers to poke.
  The dispatch contract -- one claim authorization per registered-idle
  consumer per wake -- is a value tested without Valkey, the way
  `EchoMQ.Pump.Core` makes the cadence arithmetic a value. emq.4.3.
  """

  @default_beat_ms 1_000

  @doc """
  The beat interval in milliseconds: the `:beat_ms` option, or the default
  beat (the same 1_000 the shipped consumer parks on, `consumer.ex:58`). A
  non-positive beat is refused -- a metronome that does not beat is a
  configuration error, not a silent no-op (the `Pump.Core.tick_ms/1` law).

      iex> EchoMQ.Metronome.Core.beat_ms([])
      1000
      iex> EchoMQ.Metronome.Core.beat_ms(beat_ms: 250)
      250
  """
  @spec beat_ms(keyword()) :: pos_integer()
  def beat_ms(opts) do
    case Keyword.get(opts, :beat_ms, @default_beat_ms) do
      ms when is_integer(ms) and ms > 0 -> ms
      bad -> raise ArgumentError, "beat_ms must be a positive integer, got: #{inspect(bad)}"
    end
  end

  @doc """
  The dispatch decision: given the registered-idle consumers, the pids to
  poke this round. The contract (D-2) is **one claim authorization per
  registered-idle consumer per wake** -- exactly the registered set, each
  poked once -- so readiness is distributed fairly across consumers (a
  poke-one-to-exhaustive-drain would let one worker hog the beat) and no
  registered consumer is permanently passed over while another serves.

  `registered` is the registry as an ordered list of idle pids (insertion
  order -- the metronome holds it as a list so the head, the consumer idle
  longest, is served first, a fair tie-break). The result is the same set in
  the same order: every idle consumer is authorized exactly one `:claim_once`
  this round. An empty registry pokes no one.

      iex> EchoMQ.Metronome.Core.dispatch([])
      []
      iex> EchoMQ.Metronome.Core.dispatch([:a, :b, :c])
      [:a, :b, :c]
  """
  @spec dispatch([pid()]) :: [pid()]
  def dispatch(registered) when is_list(registered), do: registered

  @doc """
  Whether the metronome should re-poke promptly (within the same beat,
  without blocking again) rather than wait out the next beat. The contract
  (D-2) is **re-poke promptly when work remains**: after a poke round, if
  any consumer was poked (so the queue had readiness this round) AND at
  least one consumer is registered-idle again (re-registered after its one
  claim), there may be more serviceable work, so the metronome pokes again
  immediately -- throughput holds while the one-claim-per-idle-consumer
  fairness stays exact.

  This is the pure predicate; the shell drains its mailbox for the
  re-registrations between rounds, then asks here whether to loop or block.

      iex> EchoMQ.Metronome.Core.repoke?(poked: 2, idle: 2)
      true
      iex> EchoMQ.Metronome.Core.repoke?(poked: 0, idle: 3)
      false
      iex> EchoMQ.Metronome.Core.repoke?(poked: 2, idle: 0)
      false
  """
  @spec repoke?(keyword()) :: boolean()
  def repoke?(opts) do
    Keyword.fetch!(opts, :poked) > 0 and Keyword.fetch!(opts, :idle) > 0
  end
end
