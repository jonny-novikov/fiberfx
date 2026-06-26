# R5.02.2 · Consumer groups

> Route: `/redis-patterns/streams-events/streams-consumer-patterns/consumer-groups` · dive
> Grounding: `echo/apps/echo_mq/lib/echo_mq/stream_consumer.ex` — the loop
> (drain-PEL-first → `>` → `XAUTOCLAIM`), the handler map, and the `XACK` / leave-un-acked settle.

A blocking read on its own gives you delivery, not reliability. If the reader crashes between receiving an
entry and finishing the work, the entry is gone — `XREADGROUP ... >` only ever returns entries newer than the
cursor. A consumer group adds the missing piece: the server tracks, per consumer, which entries were delivered
and not yet acknowledged, so a crash does not lose them. This is the reader law — read new entries,
acknowledge them, and resume where you left off — and `EchoMQ.StreamConsumer` is its worked form.

## At-least-once, with resume

`XREADGROUP GROUP <group> <consumer> STREAMS <key> >` delivers entries the group has not yet delivered to
anyone, and records each as **pending** for the consumer that received it. The entry stays pending until that
consumer calls `XACK`. Two facts follow. First, delivery is at-least-once: an entry is re-delivered until it is
acknowledged, so a handler must be idempotent. Second, the group resumes: a consumer that restarts with the
same name still owns its un-acked entries, and reading from cursor `0` hands them back.

EchoMQ's settle is that rule in two branches: on `:ok` the entry is `XACK`ed and retires from the pending
list; on `{:error, reason}` — or a handler that raises, which the loop converts to `{:error, reason}` and
survives — it is **left un-acked**, surviving in the pending list to be re-delivered. The only way an entry
leaves the group's pending list is a handler that returns `:ok`.

## The handler map

`EchoMQ.StreamConsumer` hands every entry to one handler with a fixed shape, byte-identical to the job
consumer's handler so one portable handler serves both:

```elixir
fun(%{id: branded, payload: payload, attempts: attempts, group: group}) :: :ok | {:error, reason}
```

`id` is the stored branded `EVT` record id — the writer's receipt, recovered from the entry's `id` field, not
the wire position. `payload` is the entry's remaining fields as a map. `group` is the consumer-group name. And
`attempts` carries the `XPENDING` per-entry **delivery count** — how many times this entry has been delivered
to a consumer — specified, not assumed, so a poison threshold (`attempts >= N`) calibrates against the
quantity that actually grows on each re-claim, never against a handler-failure count it would confuse for it.

## The loop — recover self, then recover peers

Recovery is two complementary mechanisms, both named, and the loop runs them in order before it ever blocks
for new entries.

**Drain own PEL — recover self.** On the first pass the consumer reads its own pending list from cursor `0` to
exhaustion (`XREADGROUP GROUP g <self> ... 0`), settling each entry, then switches to `>`. A consumer that
crashed and restarted with the same name recovers its own held work the instant it restarts; a clean cold
start has an empty pending list, so the `0` read returns nothing and one code path covers both:

```elixir
defp drain_pel(s) do
  check_control()

  case read_group(s, "0") do
    [] ->
      :ok

    entries ->
      settle_each(s, entries)
      drain_pel(s)
  end
end
```

**`XAUTOCLAIM` beat — recover peers.** A consumer that dies and never restarts has a pending list nobody
drains. On every beat the loop reclaims entries idle past `:min_idle_ms` —
`XAUTOCLAIM <key> <group> <self> <min_idle_ms> 0` re-assigns to this consumer every entry a dead peer left
idle past the threshold. The min-idle is evaluated server-side against `XPENDING` idle time, never a host
clock, so the clock that recorded the idle time and the clock that reads it are one clock. The result is
decentralised work-stealing — each consumer picks up the slack of failed peers, with no coordinator.

Then the blocking `>` read parks on the private lane for new entries, and the cycle repeats.

## The order theorem under a group

New entries arrive in mint order — the writer mints monotone `EVT` ids, so `XREADGROUP ... >` preserves the
writer's order theorem. A **re-claimed** entry does not: recovered by `XAUTOCLAIM` or a PEL drain after newer
entries were already handled, it returns with a branded id older (lower) than entries already handled. This is
the irreducible cost of at-least-once — exactly-once is not claimed — and it makes the idempotence rule
non-negotiable. Handling the same entry twice, or an older entry after a newer one, must be safe; the branded
id is the dedup key, the BCS newer-wins discipline.

## The group door

The group has to exist before a read. On start, `EchoMQ.StreamConsumer` issues
`XGROUP CREATE <key> <group> <start> MKSTREAM` and swallows only the `BUSYGROUP` reply — the group already
exists, an idempotent start, so a restart storm never errors. A `WRONGTYPE` (a non-stream key collision) or any
other error is loud: the consumer fails to start. The start position is the declared `:group_start` option
(`:new` → `$` for only new entries, `:head` → `0` from the stream head) with no default, so the
replay-versus-tail decision is forced into the open rather than guessed.

## The pattern, applied

A codemojex activity feed (`echo/apps/codemojex`) joins a game's stream as a consumer group. Several feed
renderers can share the group, each draining its own backlog on restart and reclaiming a crashed renderer's
entries on the next beat — the timeline is rendered at-least-once across all of them, and because each event is
keyed by its branded `EVT` id, a re-claimed event re-rendered after a newer one is a no-op rather than a
double line.

## References

### Sources

- [Valkey — XREADGROUP](https://valkey.io/commands/xreadgroup/) — the group read, the `>` cursor for new
  entries, and the `0` cursor that drains a consumer's pending list.
- [Valkey — XACK](https://valkey.io/commands/xack/) — the acknowledgement that retires an entry from the
  pending list.
- [Valkey — XAUTOCLAIM](https://valkey.io/commands/xautoclaim/) — the atomic reclaim of entries idle past a
  threshold, the dead-peer recovery.
- [Valkey — XPENDING](https://valkey.io/commands/xpending/) — the per-entry delivery count the `attempts`
  field carries, and the idle time the reclaim reads.

### Related in this course

- [R5.02 · Stream consumer patterns](/redis-patterns/streams-events/streams-consumer-patterns) — the module
  hub.
- [R5.02.1 · The blocking read](/redis-patterns/streams-events/streams-consumer-patterns/the-blocking-read) —
  the blocking `>` read this loop parks on.
- [R5.02.3 · MAXLEN trimming](/redis-patterns/streams-events/streams-consumer-patterns/maxlen-trimming) —
  retention on the log the group reads.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar, the reader law in depth.
- [/bcs/bus](/bcs/bus) — the manuscript bus chapter the Stream Tier figures are drawn from.
