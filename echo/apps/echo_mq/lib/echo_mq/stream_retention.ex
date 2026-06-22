defmodule EchoMQ.StreamRetention do
  @moduledoc """
  The named, opt-in trim driver of EchoMQ 3.0's Stream Tier (emq3.4, S2 the
  readers part 2): a supervised, OPT-IN process that beats on a tick and, on
  each beat, re-applies a DECLARED per-stream retention policy via the public
  `EchoMQ.Stream.trim/4`. The mint-instant analogue of `EchoMQ.Pump` -- a thin
  GenServer shell over the PURE decision core `EchoMQ.StreamRetention.Core` (the
  policy arithmetic as a value tested without a clock; the GenServer calls the
  wire on each tick).

  ## Retention is a property of the STREAM, not of a consumer (D-2)

  The driver is DECOUPLED from consumer liveness: a stream NOBODY drains still
  trims if its policy is declared here, and the frozen emq3.3
  `EchoMQ.StreamConsumer` loop is NOT touched (the trim is never folded into a
  consumer's beat). Coupling a SAFETY property (bounded memory) to a LIVENESS
  fact (a consumer is up) is the silent-no-op class the steward refuses -- so
  the cadence lives HERE, on its own beat.

  ## Opt-in, owner-started (the library law -- no `mod:` auto-start)

  Like `EchoMQ.Pump`, this driver is opt-in: a deployment that wants continuous
  bounded memory over a declared stream starts it; a stream the operator wants
  UNBOUNDED is simply not declared and is never silently trimmed (no default-on
  destructive sweep -- the coupling Lens B refused, D-2). A MANUAL
  `EchoMQ.Stream.trim/4` call is the equally-supported cadence (the driver is
  sugar over the verb, never the only path).

  ## The declared policy is BEAM-side (D-3)

  The per-stream policy is held BEAM-side -- the driver's OWN config (the
  `:policy` option), re-applied at start. NO keyspace subkey
  (`emq:{q}:stream:<name>:policy` is never written), NO at-rest cleanup
  obligation (the policy is process state, retired when the driver stops), NO
  reader-visible policy (a polyglot reader reads ENTRIES, it does not enforce
  retention). A malformed policy RAISES at decision time (in the core), never a
  silent skip.

  ## Restart semantics

  A `:transient` child: a normal stop is final, a crash restarts the cadence
  whole. The trim is idempotent over the stream (re-applying the same window
  removes nothing already removed), so a restart loses no retention guarantee
  and over-deletes nothing.
  """

  use GenServer

  alias EchoMQ.{Connector, Stream}
  alias EchoMQ.StreamRetention.Core

  @doc """
  A transient child: a normal stop is final, a crash restarts the cadence
  whole. The trim is idempotent over the stream, so a restart re-applies the
  declared windows without loss or over-deletion.
  """
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient,
      shutdown: 5_000
    }
  end

  @doc """
  Start the trim driver. Options:

    * `:conn` (a connector this driver drives) or `:connector` (options to start
      one, linked);
    * `:policy` (a list of `{queue, name, window}` declared retention policies --
      `EchoMQ.StreamRetention.Core` window forms; default `[]`, an empty policy
      ticks but trims nothing);
    * `:tick_ms` (the beat, default 1_000);
    * `:name` (an optional registered name);
    * `:clock` (a 0-arity fn returning the `DateTime` for the tick instant,
      default `&DateTime.utc_now/0` -- injected so the decision core is a pure
      function of the clock in test).
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc "Stop the driver; the current tick settles, no further tick is scheduled."
  def stop(driver, timeout \\ 5_000), do: GenServer.stop(driver, :normal, timeout)

  @impl true
  def init(opts) do
    conn =
      case Keyword.fetch(opts, :conn) do
        {:ok, c} ->
          c

        :error ->
          {:ok, c} = Connector.start_link(Keyword.fetch!(opts, :connector))
          c
      end

    state = %{
      conn: conn,
      policy: Keyword.get(opts, :policy, []),
      tick_ms: tick_ms(opts),
      clock: Keyword.get(opts, :clock, &DateTime.utc_now/0)
    }

    {:ok, arm(state)}
  end

  @impl true
  def handle_info(:tick, s) do
    _ = sweep(s)
    {:noreply, arm(s)}
  end

  @doc """
  One sweep, exposed for a direct-drive test (no cadence): apply the declared
  policy's trim calls via `EchoMQ.Stream.trim/4`, at the injected clock instant.
  Answers `{:ok, %{trimmed: removed_total, calls: n}}` -- `removed_total` the
  sum of the per-call `XTRIM` removed-counts, `calls` the number of trim calls
  applied (0 on an empty policy).

  Decoupled from any `EchoMQ.StreamConsumer`: a stream with no consumer still
  trims here. Each trim is SOFT-matched -- a wire hiccup on one stream is logged
  and skipped, never crash-looping the whole cadence; the next tick re-applies
  the declared window (the trim is idempotent over the stream).
  """
  def sweep(%{conn: conn, policy: policy, clock: clock}) do
    case Core.decide(policy, clock.()) do
      :noop ->
        {:ok, %{trimmed: 0, calls: 0}}

      calls when is_list(calls) ->
        {removed, applied} =
          Enum.reduce(calls, {0, 0}, fn {queue, name, window}, {rem_acc, n_acc} ->
            case apply_trim(conn, queue, name, window) do
              {:ok, removed} -> {rem_acc + removed, n_acc + 1}
              :skipped -> {rem_acc, n_acc + 1}
            end
          end)

        {:ok, %{trimmed: removed, calls: applied}}
    end
  end

  # Apply ONE declared trim via the public verb; a wire/server fault is logged
  # and skipped (counted as applied, removed 0) -- the next tick re-applies the
  # idempotent window, so a transient fault loses no retention guarantee.
  defp apply_trim(conn, queue, name, window) do
    case Stream.trim(conn, queue, name, window) do
      {:ok, removed} when is_integer(removed) ->
        {:ok, removed}

      other ->
        require Logger

        Logger.warning(
          "EchoMQ.StreamRetention: trim of #{inspect(queue)}/#{inspect(name)} skipped this tick: #{inspect(other)}"
        )

        :skipped
    end
  end

  # The tick interval: a positive integer, or the default beat. A non-positive
  # tick is refused -- a driver that does not advance is a configuration error,
  # not a silent no-op (the `EchoMQ.Pump.Core.tick_ms/1` rule).
  defp tick_ms(opts) do
    case Keyword.get(opts, :tick_ms, 1_000) do
      ms when is_integer(ms) and ms > 0 -> ms
      bad -> raise ArgumentError, "tick_ms must be a positive integer, got: #{inspect(bad)}"
    end
  end

  defp arm(s) do
    Process.send_after(self(), :tick, s.tick_ms)
    s
  end
end
