defmodule EchoMQ.Metronome do
  @moduledoc """
  The beat made a system. A supervised process per queue that owns the SINGLE
  `BLPOP emq:{q}:wake <beat>` block and a registry of idle consumers, and fans
  readiness out to the pool over BEAM messages. Where the shipped consumer is
  its own metronome -- each parking on the shared wake token, a herd of
  blockers -- this is one blocker per queue: it holds the single block, and on
  a wake pokes the registered-idle consumers, each running the byte-frozen
  `EchoMQ.Lanes.claim/3` exactly once (one claim per idle consumer per wake =
  consumer-fair), re-poking promptly while work remains. The herd is gone (one
  connection blocks), readiness is distributed fairly, and a job admitted while
  a consumer is registered-idle is served well before the beat.

  Modeled on `EchoMQ.Consumer`'s `spawn_link`-loop discipline (a blocking verb
  needs its own process and its own connector lane -- a `GenServer` blocked in
  `handle_info` could not drain its mailbox), with `EchoMQ.Pump`'s pure
  decision core (`EchoMQ.Metronome.Core`). It owns NO Valkey lease: its only
  block is the host-timeout `BLPOP` on the shipped per-queue wake token (the
  beat the fallback), and the in-flight claim a poked consumer takes is
  protected by `@gclaim`'s server-clock lease and the reap path, so a metronome
  restart is clean. Opt-in and host-started (the library law: no `mod:`
  auto-start). It adds no Lua and no wire verb -- the block rides the shipped
  `EchoMQ.Connector.command/3`, the identical call the shipped park makes
  (`consumer.ex:147`), relocated to the one metronome. emq.4.3.
  """

  alias EchoMQ.{Connector, Jobs, Keyspace, Metronome}

  @doc """
  A permanent child: the beat restarts whole, and its self-started connector
  lane dies and returns with it (the `EchoMQ.Consumer.child_spec/1` law). A
  restarted metronome re-blocks on the wake token and consumers re-register on
  their next idle transition; no lease is metronome-owned, so no work is lost.
  """
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent,
      shutdown: 5_000
    }
  end

  @doc """
  Start the beat. Options: `:queue`, and either `:conn` (a connector this
  metronome treats as its own exclusive lane for the single block) or
  `:connector` (options to start one, linked to the loop). `:beat_ms` (the
  fallback timeout + the reap/promote cadence, default 1_000), `:pump_batch`
  (the promote LIMIT per beat, default 100), `:name` (an optional registered
  name -- `EchoMQ.Queue` registers the metronome so its consumers can resolve
  it). The block timeout is host-side, not a lease (INV2).
  """
  def start_link(opts) do
    queue = Keyword.fetch!(opts, :queue)
    name = Keyword.get(opts, :name)

    pid =
      spawn_link(fn ->
        Process.flag(:trap_exit, true)

        conn =
          case Keyword.fetch(opts, :conn) do
            {:ok, c} ->
              c

            :error ->
              {:ok, c} = Connector.start_link(Keyword.fetch!(opts, :connector))
              c
          end

        loop(%{
          conn: conn,
          queue: queue,
          beat_ms: Metronome.Core.beat_ms(opts),
          pump_batch: Keyword.get(opts, :pump_batch, 100),
          # the idle-consumer registry: an ordered list of idle pids (head =
          # idle longest, the fair tie-break) and the monitor refs keyed by pid
          idle: [],
          monitors: %{}
        })
      end)

    # Register the name from the PARENT on the returned pid, synchronously,
    # BEFORE start_link returns -- so the name exists the instant a caller
    # holds {:ok, pid}. Registering inside the spawn_link'd fn (the prior form)
    # left a window where start_link had returned but the loop had not yet run
    # its first reduction, so the name was absent: a rest_for_one Queue could
    # start a consumer whose first act is `send(name, {:register_idle, _})`, and
    # `send/2` to an unregistered atom RAISES (F-2, the F-1 sibling -- a latent
    # startup race the gate cannot see because the consumer's first send sits
    # behind a TCP+RESP handshake, ~1000x the metronome's 2-BIF register, and
    # the supervisor self-heals a loser). Parent-side register closes it by
    # construction.
    if name, do: Process.register(pid, name)

    {:ok, pid}
  end

  @doc """
  Drain and stop: the beat settles, the single block is abandoned at its next
  return, and the loop exits `:normal` -- a self-started connector lane closes
  with it. Synchronous; the reply arrives when the loop is down. Stop latency is
  bounded by the beat (the in-flight `BLPOP` returns within `beat_ms`). The
  unsupervised owner's verb; under a supervisor, `:shutdown` drains the same way
  (the loop traps exits and honors it at the settle point).
  """
  def stop(pid, timeout \\ 5_000) when is_pid(pid) do
    ref = Process.monitor(pid)
    send(pid, {:emq_stop, self(), ref})

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        {:error, :timeout}
    end
  end

  # The beat: drain the registration mailbox at the settle point, run the
  # one-per-queue reap/promote cadence (migrated from each consumer -- SEAM-1),
  # then hold the SINGLE block on the wake token. On a wake (an admit pushed
  # the token) or the beat (the fallback timeout), poke the registered-idle
  # consumers once each, re-poking promptly while work remains.
  defp loop(s) do
    s = drain_mailbox(s)
    {:ok, _} = Jobs.reap(s.conn, s.queue)
    {:ok, _} = Jobs.promote(s.conn, s.queue, s.pump_batch)
    block(s)
    s = poke_round(s)
    loop(s)
  end

  # Hold the single block on the shipped per-queue wake token -- the IDENTICAL
  # `Connector.command/3` BLPOP the shipped park makes (`consumer.ex:147`),
  # relocated to the one metronome (the FROZEN-WIRE verdict: no new verb). The
  # block returns on an admit's LPUSH (readiness) or the beat (the fallback);
  # either way the loop proceeds to poke. The timeout is host-side, NOT a lease.
  defp block(s) do
    secs = :erlang.float_to_binary(s.beat_ms / 1000, decimals: 3)
    wake = Keyspace.queue_key(s.queue, "wake")
    _ = Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)
    :ok
  end

  # One poke round: authorize one `:claim_once` per registered-idle consumer
  # (the pure dispatch contract, `Core.dispatch/1`), clear them from idle (each
  # re-registers after its one claim), then drain the mailbox at the settle
  # point to collect the re-registrations + any death/control. While work was
  # poked AND consumers have re-registered (`Core.repoke?/1`), poke again
  # promptly -- without re-blocking -- so throughput holds while fairness stays
  # one-claim-per-idle-consumer-per-wake. When no one re-registers (or none was
  # poked), the round ends and the loop re-blocks.
  defp poke_round(s) do
    # Fold in registrations that arrived DURING block/1's BLPOP before dispatching:
    # a consumer that went idle while the metronome held the single block sits in
    # the mailbox un-drained, so dispatching against the pre-block snapshot would
    # drop the poke and strand the admit for a full beat (the lost-wakeup, F-1).
    s = drain_mailbox(s)
    to_poke = Metronome.Core.dispatch(s.idle)
    Enum.each(to_poke, fn pid -> send(pid, {:claim_once, self()}) end)
    s = %{s | idle: []}
    s = drain_mailbox(s)

    if Metronome.Core.repoke?(poked: length(to_poke), idle: length(s.idle)) do
      poke_round(s)
    else
      s
    end
  end

  # Drain the mailbox at a settle point (the `consumer.ex:104-112` discipline):
  # a registration adds the consumer to idle and monitors it; a deregistration
  # or a monitored `:DOWN` removes it (no orphaned registration -- a dead
  # consumer is a registry removal, not a metronome crash); control is honored.
  # `after 0` returns the moment the mailbox is empty, so the beat is not
  # delayed by a quiet mailbox.
  defp drain_mailbox(s) do
    receive do
      {:register_idle, pid} when is_pid(pid) ->
        drain_mailbox(register(s, pid))

      {:deregister, pid} when is_pid(pid) ->
        drain_mailbox(deregister(s, pid))

      {:DOWN, _ref, :process, pid, _reason} ->
        drain_mailbox(forget(s, pid))

      {:emq_stop, _from, _ref} ->
        exit(:normal)

      {:EXIT, _from, :shutdown} ->
        exit(:shutdown)

      {:EXIT, _from, reason} ->
        exit(reason)
    after
      0 -> s
    end
  end

  # Register an idle consumer: monitor it (once -- a re-register from a pid
  # already monitored keeps the one ref) and append it to idle (append, so the
  # consumer idle longest sits at the head, the fair tie-break the pure
  # dispatch serves first). A pid already in idle is not duplicated.
  defp register(s, pid) do
    monitors =
      if Map.has_key?(s.monitors, pid),
        do: s.monitors,
        else: Map.put(s.monitors, pid, Process.monitor(pid))

    idle = if pid in s.idle, do: s.idle, else: s.idle ++ [pid]
    %{s | idle: idle, monitors: monitors}
  end

  # Deregister at the consumer's own request (its settle-point on stop/shutdown):
  # demonitor + drop from idle. A clean deregister, no orphaned registration.
  defp deregister(s, pid) do
    case Map.pop(s.monitors, pid) do
      {nil, _} -> %{s | idle: List.delete(s.idle, pid)}
      {ref, monitors} ->
        Process.demonitor(ref, [:flush])
        %{s | idle: List.delete(s.idle, pid), monitors: monitors}
    end
  end

  # Forget a consumer the monitor reported `:DOWN` (the ref is already spent --
  # no demonitor): drop it from idle and the monitor map. The next poke round
  # cannot poke a dead pid; the metronome survives.
  defp forget(s, pid) do
    %{s | idle: List.delete(s.idle, pid), monitors: Map.delete(s.monitors, pid)}
  end
end
