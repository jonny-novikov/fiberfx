# The consumer loop — park, don't poll

**Route:** `/echomq/queue/jobs-lanes-consumer/the-consumer-loop` · **Pillar:** The Queue · **Surface:** dive

> All real code in `echo/apps/echo_mq/lib/echo_mq/consumer.ex` + `keyspace.ex`. No `[RECONCILE]` markers.

## The fact

The consumer is the loop that owns the rhythm. A supervised process holding a **dedicated connector** beats on a
cadence: **reap → promote → drain → park**. It does not spin asking "is there work" — it **parks** on the wake key
with `BLPOP` until readiness arrives or the beat elapses. A parked consumer costs the wire nothing.

## Hero interactive — the four-beat loop

A stepper around the beat: reap (expired leases → pending), promote (due schedules → pending), drain (rotating
claims until empty), park (`BLPOP wake`). Step it and read what each beat does. Pure; live `.geo-readout`.

## The loop (real, `consumer.ex`)

```elixir
defp loop(s) do
  check_control()
  {:ok, _} = Jobs.reap(s.conn, s.queue)               # expired leases → pending
  {:ok, _} = Jobs.promote(s.conn, s.queue, s.pump_batch)  # due schedules → pending
  drain(s)                                             # claim and run until the ring is empty
  park(s)                                              # BLPOP the wake key, or the beat elapses
  loop(s)
end
```

## Park, don't poll (real, `consumer.ex`)

```elixir
defp park(s) do
  secs = :erlang.float_to_binary(s.beat_ms / 1000, decimals: 3)
  wake = Keyspace.queue_key(s.queue, "wake")
  _ = Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)
  :ok
end
```

`BLPOP` blocks on `emq:{q}:wake` for up to one beat. When a producer or a completion makes a lane serviceable, the
script that returns it to the ring also `LPUSH`es a wake — so the parked consumer returns at once. No readiness, no
wake: the block elapses after the beat and the loop runs anyway (the beat doubles as the pump cadence). The blocking
verb runs on a **dedicated connector lane** so a parked `BLPOP` never stalls another caller.

## The drain — the raising handler becomes a typed retry (real, `consumer.ex`)

```elixir
defp drain(s) do
  check_control()

  case Lanes.claim(s.conn, s.queue, s.lease_ms) do
    :empty ->
      :ok

    {:ok, {id, payload, att, group}} ->
      verdict =
        try do
          s.handler.(%{id: id, payload: payload, attempts: att, group: group})
        rescue
          e -> {:error, Exception.message(e)}
        catch
          :exit, reason -> {:error, "exit: " <> inspect(reason)}
          :throw, value -> {:error, "throw: " <> inspect(value)}
        end

      case verdict do
        :ok -> Jobs.complete(s.conn, s.queue, id, att)
        {:error, reason} ->
          Jobs.retry(s.conn, s.queue, id, att, s.retry_delay_ms, s.max_attempts, to_string(reason))
      end

      drain(s)
  end
end
```

The handler takes `%{id:, payload:, attempts:, group:}` and answers `:ok | {:error, reason}`. A handler that
**raises, exits, or throws** is caught and converted to a typed retry — the loop survives a bad job. `:ok` completes
(token-fenced on `att`); `{:error, reason}` retries with backoff or dies at max attempts.

## Main interactive — verdict → transition

Pick a handler outcome (`:ok` / `{:error, …}` / raises) and read which transition the loop runs — `complete` or
`retry` — and that a raise becomes a typed retry, not a crash. Pure; live `.geo-readout`.

## Drain and stop (real, `consumer.ex`)

```elixir
def stop(pid, timeout \\ 5_000) when is_pid(pid) do
  ref = Process.monitor(pid)
  send(pid, {:emq_stop, self(), ref})
  receive do
    {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
  after
    timeout -> Process.demonitor(ref, [:flush]); {:error, :timeout}
  end
end
```

`stop/2` drains: the loop settles the job in hand, claims nothing more, and exits `:normal`. Control arrives as
messages honored at the settle points (between jobs, never inside one), because the loop traps exits.

## The rhythm defaults (real, `consumer.ex` — `start_link/1`)

`:lease_ms` 30_000 · `:beat_ms` 1_000 · `:retry_delay_ms` 1_000 · `:max_attempts` 3 · `:pump_batch` 100. The
consumer is a permanent child (`child_spec/1`); its self-started connector lane dies and returns with it.

> `EchoMQ.Pump` is the optional dedicated cadence twin — a separate process that runs the same reap/promote sweep on
> its own schedule, so the pump cadence can be tuned apart from the drain. Named here; its depth lives in the
> lifecycle-controls module.

## Bridge

- the pattern (Redis Patterns Applied): a reliable consumer claims, runs, and acknowledges work, blocking for the
  next item rather than busy-polling — R3 `/redis-patterns/queues` (built).
- the implementation (echo_mq): `EchoMQ.Consumer` runs reap → promote → drain → park, blocking on the wake key with
  `BLPOP`, and converts a raising handler to a typed retry.

## Take

A consumer that parks costs the wire nothing while it waits, and survives a bad job: reap, promote, drain, park —
and a raise becomes a typed retry, not a crash.

## References

### Sources
- Valkey — `BLPOP` — https://valkey.io/commands/blpop/
- Valkey — `LMOVE` — https://valkey.io/commands/lmove/
- Redis — `EVALSHA` — https://redis.io/commands/evalsha/
- Valkey — Documentation — https://valkey.io/docs/

### Related in this course
- `/echomq/queue/jobs-lanes-consumer` — the module hub
- `/echomq/queue/jobs-lanes-consumer/fair-lanes-and-the-ring` — the ring the loop drains
- `/redis-patterns/queues` — R3, the reliable-queue / consumer pattern
