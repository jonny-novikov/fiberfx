# EchoMQ.StreamConsumer — the BEAM consumer group over an event stream

`EchoMQ.StreamConsumer` is the reader law of EchoMQ 3.0's Stream Tier: a supervised
BEAM consumer group over a per-key event stream, **at-least-once with idempotent
handlers, crash → re-delivery**. It is the reading half of the writer
`EchoMQ.Stream.append/4` — a non-BEAM reader on the same group sees the same group
state, because the canonical id travels in the stream entry's `id` field (the
polyglot seam).

It is a **sibling** of `EchoMQ.Consumer` (the single-job lane consumer), not a mode
on it: a different claim path (`XREADGROUP` group read, not `Lanes.claim/3`) and a
different settle (`XACK` / leave-un-acked, not `Jobs.complete`/`Jobs.retry`) earn a
separate module — the `EchoMQ.BatchConsumer` precedent. The blocking
`XREADGROUP … BLOCK` read rides the consumer's **own private connector lane**, so it
never stalls the single-owner socket the rest of the system shares ("blocking verbs
get their own lane").

## Starting one — `start_link/1`

```elixir
{:ok, pid} =
  EchoMQ.StreamConsumer.start_link(
    queue:        "orders",          # the queue whose stream this reads
    stream:       "events",          # emq:{orders}:stream:events
    group:        "projector",       # the consumer-group name
    consumer:     "node-a",          # THIS consumer's name within the group
    group_start:  :head,             # :new -> "$" (only new) | :head -> "0" (from head)
    handler:      &MyApp.handle/1,   # %{id, payload, attempts, group} -> :ok | {:error, reason}
    connector:    [port: 6390]       # opts for the consumer's OWN lane (or pass :conn)
  )
```

| Option | Required | Default | Meaning |
|---|---|---|---|
| `:queue` | yes | — | the queue whose stream this reads |
| `:stream` | yes | — | the stream name; the key is `EchoMQ.Stream.stream_key(queue, stream)` = `emq:{queue}:stream:<stream>` |
| `:group` | yes | — | the consumer-group name |
| `:consumer` | yes | — | this consumer's name within the group (the PEL is keyed to it; a restart with the **same** name recovers its own backlog) |
| `:group_start` | yes | — (no default) | `:new` → `$` (only entries appended after group creation) or `:head` → `0` (from the stream head); a missing/malformed value **raises at start** |
| `:handler` | yes | — | a fun taking `%{id, payload, attempts, group}` answering `:ok` or `{:error, reason}` |
| `:conn` / `:connector` | one | — | `:conn` a connector this consumer treats as its own exclusive lane, or `:connector` opts to start one linked to the loop |
| `:min_idle_ms` | no | `30_000` | the `XAUTOCLAIM` min-idle threshold (a dead peer's entries idle past this are reclaimed; evaluated server-side) |
| `:beat_ms` | no | `1_000` | the `XREADGROUP … BLOCK` block time (the beat cadence) |
| `:count` | no | `100` | the per-read `COUNT` (the batch size of one `XREADGROUP` / `XAUTOCLAIM` pull) |

`start_link/1` returns `{:ok, pid}`; `stop/2` drains the entry in hand and stops
(synchronous); the module also exports `child_spec/1` (a `:permanent` child — the
loop restarts whole, and a self-started lane dies and returns with it).

## The group door — lazy ensure-on-start

On `start_link` the consumer issues `XGROUP CREATE <key> <group> <start> MKSTREAM`
and swallows **only** the `BUSYGROUP` reply (the group already exists — an
idempotent no-op start; restart-storms never error). A `WRONGTYPE` (a non-stream key
collision) or any other error is **loud** — the consumer fails to start. There is no
destructive group-tear-down verb at this tier; the door creates and
swallows-on-exists, never destroys.

The start position is the declared `:group_start` option, never a default, so the
replay-vs-tail decision is forced into the open without a second verb.

## The loop — drain-PEL-first → `>` → XAUTOCLAIM

Recovery is two complementary mechanisms, both named:

- **PEL-drain-on-(re)start recovers SELF.** On the first pass the consumer reads its
  own PEL (`XREADGROUP GROUP g <self> … 0`, the un-acked backlog keyed to its own
  consumer name) to exhaustion, settling each, then switches to `>`. A crashed
  consumer that restarts with the same name recovers its own held work **the instant
  it restarts** — not "eventually, after the idle threshold." A clean cold start has
  an empty PEL (`0` returns nothing) → straight to `>` (one code path covers both).
- **The `XAUTOCLAIM` beat recovers dead PEERS.** On each beat the consumer reclaims
  entries idle past `:min_idle_ms` — the entries held by **other** consumers that
  died and never restarted (so their PEL is never self-drained). The min-idle
  threshold is the single tunable for "how long before a dead peer's work is
  re-delivered."

Then the blocking `XREADGROUP … BLOCK <beat_ms> … >` parks on the private lane for
new entries. A `stop/2` or a supervisor `:shutdown` is honored at the settle points
(between entries, never inside one). A raising handler converts to a typed
`{:error, reason}` and the loop survives.

## The handler — the exact mirror

The handler is `fun(%{id, payload, attempts, group}) :: :ok | {:error, reason}` —
byte-identical in shape to the job `EchoMQ.Consumer`'s handler, so **one handler
discipline spans job and stream consumers**:

| Key | Value |
|---|---|
| `id` | the stored branded record id (the `EchoMQ.Stream.append/4` receipt, recovered from the entry's `id` field) |
| `payload` | the entry's remaining fields as a map |
| `group` | the consumer-group name |
| `attempts` | the `XPENDING` per-entry **delivery-count** — how many times **this** entry has been delivered, **not** a handler-failure count |

The `attempts` field is the one whose meaning differs from the job side, so it is
specced, not assumed: a first `>` delivery is `1`; a re-claim (an `XAUTOCLAIM` or a
PEL-drain after a prior delivery) increments it. A poison threshold
(`attempts >= N`) therefore calibrates against real delivery count.

- On `:ok` the entry is `XACK`ed (it retires from the PEL).
- On `{:error, reason}` (or a raise) it is **left un-acked** — it survives in the PEL
  and is re-delivered by the `XAUTOCLAIM` beat or the next PEL-drain. This is the
  at-least-once posture: acking is the only thing that retires an entry.

## Order under a consumer group — the PEL exception

The writer's order theorem (stream order == id sort == mint order) holds for the
stream itself: `XRANGE` and `XREADGROUP … >` hand **new** entries in mint order. But
a consumer group adds a second ordering axis — per-consumer delivery order under
re-claim — where it cannot hold:

| | Holds | Cannot hold |
|---|---|---|
| **The stream's own order** | new entries in mint order (the consumer reads, it does not re-append) | — |
| **A consumer's delivery order** | first delivery of each entry is in mint order | a **re-claimed** entry returns **after** newer entries already delivered — out of real-time delivery order |

This is the irreducible cost of at-least-once: an entry delivered-but-not-acked is
re-delivered later, after the consumer has moved on to newer (higher-id) entries, so
its *delivery* arrives out of *mint* order. Exactly-once is not claimed.

**The consequence:** the handler **must be idempotent**. Handling the same entry
twice (the second on re-claim), or an older entry after a newer one, must be safe —
the branded `id` is the dedup key (the BCS newer-wins discipline).

## The polyglot seam

The branded id the BEAM writer minted is stored in the entry's `id` field, so a
non-BEAM reader holding only a stock Redis client recovers the canonical id from a
raw read — and a raw `XACK` settles the **same** group state the BEAM consumer
reads. The BEAM and non-BEAM sides share one group; there is no second index and no
re-encoding.

```elixir
# a stock-client read of the same group, through the bare Connector
{:ok, reply} =
  EchoMQ.Connector.command(conn, [
    "XREADGROUP", "GROUP", "projector", "polyglot", "STREAMS", key, ">"
  ])
# the entry's stored "id" field == the branded receipt EchoMQ.Stream.append/4 returned
```

## Acceptance criteria & conformance

The behaviour above is proven by the BDD story catalogue
([`docs/echo_mq/stories/stream-consumer.stories.md`](../../../docs/echo_mq/stories/stream-consumer.stories.md),
generated from `test/stories/stream_consumer_story_test.exs`) and the exhaustive
`:valkey` suite (`test/stream_consumer_test.exs`). The `stream_group` conformance
scenario (`EchoMQ.Conformance`) is a **positive re-delivery proof**: two records are
group-read, one acked and one left un-acked, then a forced `XAUTOCLAIM` re-delivers
the same un-acked branded receipt while the acked one is not re-claimed — an
ack-everything pass is a loud failure.

> Built on the shipped `EchoMQ.Connector` generic command path — the group verbs
> (`XGROUP` / `XREADGROUP` / `XACK` / `XAUTOCLAIM` / `XPENDING`) are issued directly,
> with no new Lua and no `echo_wire` change.
