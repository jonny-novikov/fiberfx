# Recover self, then peers

> Route: `/echomq/bus/the-consumer-group/recover-self-then-peers` · Module 03 · dive 02.
> Grounds in `EchoMQ.StreamConsumer` — `drain_pel/1`, `loop/1`, `reclaim_peers/1`, `read_group_block/1`,
> `check_control/0` (`echo/apps/echo_mq`). No Lua — all group verbs issue direct.

A consumer group's reliability comes down to one question: **when a reader dies, what happens to the entries
it was holding?** A group answers with the PEL — the Pending Entries List — which records, per consumer,
every entry delivered but not yet acked. `EchoMQ.StreamConsumer` recovers held work with **two complementary
mechanisms**, and the difference between them is *who died and whether they came back*.

## Mechanism 1 — drain the PEL on (re)start recovers SELF

A consumer that crashes and **restarts with the same name** has its own backlog waiting in the PEL, keyed to
that name. So the very first thing the loop does, before reading anything new, is drain its **own** PEL to
exhaustion: `XREADGROUP GROUP g <self> … 0` reads the un-acked entries keyed to **this** consumer (cursor `0`
means "my pending," not "new"), settles each, and repeats until the read comes back empty. Then it switches
to `>`.

This is why a restarted consumer recovers its held work **the instant it restarts** — it does not wait for an
idle timeout, because the entries are its own. And a clean cold start costs nothing extra: a fresh consumer
has an empty PEL, so the first `0` read returns nothing and the loop goes straight to `>`. One code path
covers both the crash-restart and the cold-start case.

```elixir
# echo_mq — EchoMQ.StreamConsumer
# Drain the consumer's OWN PEL to exhaustion (recover SELF on (re)start):
# XREADGROUP ... 0 reads the un-acked backlog keyed to THIS consumer name; each
# entry is settled by the handler verdict, then the read repeats until the PEL
# returns empty. A clean cold start has an empty PEL -> one round-trip, then the
# steady loop. The `0` read is NON-blocking (the PEL is already in hand server-side).
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

The `0` read is **non-blocking** — the PEL is already known server-side, so there is nothing to wait for. The
drain runs to empty, then control passes to the steady loop.

## Mechanism 2 — the XAUTOCLAIM beat recovers dead PEERS

The PEL-drain only recovers a consumer that **came back**. But a consumer can die and **never restart** — the
machine is gone, the deploy removed it, the name retired. Its entries sit in its PEL with no one to self-drain
them. That is what `XAUTOCLAIM` is for. On each beat of the steady loop, a live consumer reclaims entries that
have been **idle past `:min_idle_ms`** — `XAUTOCLAIM <key> <group> <self> <min_idle_ms> 0` re-assigns those
entries to itself and hands them back to the same settle path as any other delivery.

The idle threshold is evaluated **server-side**, against Valkey's own `XPENDING` idle time — there is **no
host clock** in the decision. That matters: clocks on different machines disagree, so a host-side "how long
has it been idle" comparison would race; deferring to the server's idle measurement makes the reclaim
decision a single, coherent one. `:min_idle_ms` is the **one tunable** for *how long before a dead peer's work
is re-delivered* — long enough that a brief blip doesn't steal a healthy consumer's in-flight work, short
enough that a truly dead peer's backlog doesn't strand.

```elixir
# echo_mq — EchoMQ.StreamConsumer
# Reclaim a dead PEER's idle entries: XAUTOCLAIM <key> <group> <self> <min_idle_ms>
# 0 re-assigns to THIS consumer every entry idle past the threshold (server-side
# idle, no host clock). The reply is the [next-cursor, claimed-entries, deleted-ids]
# triple; the claimed entries are settled like any other delivery. One pass per beat
# (cursor 0); a deep peer backlog drains over successive beats.
defp reclaim_peers(s) do
  case Connector.command(s.conn, [
         "XAUTOCLAIM", s.key, s.group, s.consumer,
         Integer.to_string(s.min_idle_ms), "0",
         "COUNT", Integer.to_string(s.count)
       ]) do
    {:ok, [_cursor, claimed, _deleted]} when is_list(claimed) ->
      settle_each(s, claimed)

    {:ok, [_cursor, claimed]} when is_list(claimed) ->
      # some server builds answer a two-element [cursor, claimed] reply
      settle_each(s, claimed)

    _other ->
      :ok
  end
end
```

One pass per beat (cursor `0` each time); a deep peer backlog drains over successive beats rather than in one
greedy sweep, so a single reclaim never blocks the loop on a huge dead-peer queue.

## Then park on `>` — on the consumer's own private lane

With self drained and dead peers reclaimed, the loop parks for **new** entries:
`XREADGROUP GROUP g <self> BLOCK <beat_ms> COUNT <n> STREAMS key >`. This is the only blocking verb in the
consumer, and it rides the consumer's **own private connector lane** — the same `BLPOP`-on-its-own-lane
precedent the job consumer set. The single-owner socket the rest of the system shares is **never stalled** by
a parked reader; the block lives on a dedicated connection that exists only to serve this loop.

A `BLOCK` of `:beat_ms` (default `1_000`) sets the cadence: each beat, the loop wakes, reclaims dead peers,
and re-parks. So `:min_idle_ms` is *how long before a dead peer's work moves*, and `:beat_ms` is *how often
the loop checks*. The two compose into the recovery latency without any background timer.

```elixir
# echo_mq — EchoMQ.StreamConsumer
# The steady loop: on each beat reclaim dead PEERS' idle entries (XAUTOCLAIM), then
# park on the blocking `>` read for new entries. Control is honored at the settle
# points (between entries, never inside one). The lane dying takes the loop with it,
# for the supervisor to restart.
defp loop(s) do
  check_control()
  reclaim_peers(s)

  case read_group_block(s) do
    [] -> :ok
    entries -> settle_each(s, entries)
  end

  loop(s)
end
```

## Control is honored at the settle points

A stop or a supervisor shutdown is honored **between** entries, never inside one. The loop traps exits, so a
control message lands in the mailbox and `check_control` reads it at each settle point: a stop drains to
`:normal`, a `:shutdown` drains to `:shutdown`, and the entry in hand finishes first. So `stop/2` is bounded
by the beat plus the one entry being settled — a parked consumer notices the request when its `BLOCK`
returns. No entry is ever abandoned half-handled to honor a stop.

```elixir
# echo_mq — EchoMQ.StreamConsumer
# The loop traps exits, so control arrives as messages and is honored at the settle
# points — between entries, never inside one. A stop request drains to :normal; the
# supervisor's :shutdown drains to :shutdown; the dedicated lane dying takes the loop
# with it, for the tree to restart.
defp check_control do
  receive do
    {:emq_stop, _from, _ref} -> exit(:normal)
    {:EXIT, _from, :shutdown} -> exit(:shutdown)
    {:EXIT, _from, reason} -> exit(reason)
  after
    0 -> :ok
  end
end
```

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** a consumer group keeps a per-consumer PEL; a crashed reader's
  pending entries are reclaimed by another with `XAUTOCLAIM` after an idle period.
  `/redis-patterns/streams-events` teaches the recovery loop.
- **The implementation (echo_mq):** two mechanisms, sharply separated — a self-drain on (re)start for a
  consumer that came back (instant, no idle wait), and an `XAUTOCLAIM` beat for a peer that never did (idle
  past `:min_idle_ms`, server-clock). The blocking `>` read parks on a private lane so the shared socket is
  never stalled, and control is honored between entries.

## References

### Sources
- [Valkey — XREADGROUP](https://valkey.io/commands/xreadgroup/) — `>` for new entries, `0` to replay the consumer's own PEL.
- [Valkey — XAUTOCLAIM](https://valkey.io/commands/xautoclaim/) — reclaiming idle pending entries from a dead peer, server-side idle.
- [Valkey — XPENDING](https://valkey.io/commands/xpending/) — the idle time the reclaim threshold is measured against.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the PEL and consumer recovery.

### Related in this course
- `/echomq/bus/the-consumer-group` — the module this dive belongs to.
- `/echomq/bus/the-consumer-group/the-group-door` — opening the group the loop reads through.
- `/echomq/bus/the-consumer-group/at-least-once-and-the-handler` — what settling an entry does, and the cost.
- `/echomq/bus/the-stream-log` — the writer whose log the loop drains.
- `/redis-patterns/streams-events` — the streams pattern that doors here.
