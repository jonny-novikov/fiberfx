# R5.05 · Workshop — a codemojex activity feed

> Route: `/redis-patterns/streams-events/workshop` · the chapter capstone (single page, no dives) ·
> pattern: **every R5 stream technique composed once, end to end, into one live feed.**
>
> Grounding: EchoMQ's real shipped Stream Tier in `echo/apps/echo_mq` — `EchoMQ.Stream` (the writer + reader +
> retention), `EchoMQ.StreamConsumer` (the reader law), `EchoMQ.StreamRetention` (retention as policy) — plus
> `EchoStore.StreamArchive` (the durable fold), worked through the **codemojex** consumer
> (`echo/apps/codemojex` — `Codemojex.Guesses`, `Codemojex.ScoreWorker`, `Codemojex.Settle`). The manuscript
> figure home is `docs/echo/bcs/bcs.3.md §B3.3`. Engine: Valkey 9. Doors: `/echomq/bus`, `/bcs/bus`,
> `/echo-persistence`.

A workshop is not a new pattern. It is the chapter's patterns assembled into one working thing: a live activity
feed for codemojex, the Telegram code-breaking game, built on EchoMQ's real Stream Tier. Every game action becomes
an immutable entry on one append-only log; the feed is a fold of that log; a consumer group renders notifications
without re-sending on a restart; and retention bounds the live log while the deep history folds to a durable floor.
Four stages, every one a technique R5 already taught.

## The feed is a log seen sideways

A codemojex room is a sequence of moves: a guess submitted, that guess scored, a round settled. The activity feed
is the question "what just happened here?" — and the honest answer is the log. Append each action as an entry,
ordered by the instant it was minted, and the feed is no longer a row a worker overwrites: it is a fold of the log,
recomputed the same way every time. The append order is the truth order, and the branded `EVT` id each entry
carries is its receipt and its place in the sequence.

The four stages of the build, each a real EchoMQ surface verified on disk:

1. **Append** every domain event to one log — `EchoMQ.Stream.append/4` → `XADD emq:{cm}:stream:events`, minting a
   branded `EVT` id as the receipt (R5.01, the append-only log).
2. **Fold** the log to render the feed — `EchoMQ.Stream.read/6` → `XRANGE` hands the entries back in mint order; a
   windowed view is `EchoMQ.Stream.read_window/6` over a mint-instant window (R5.01 replay + R5.04 projection).
3. **Consume reliably** with a group — `EchoMQ.StreamConsumer` (`XREADGROUP`/`XACK`) reads, acks, and resumes; a
   restarted notification reader does not replay what it already delivered (R5.02, the reader law).
4. **Bound + archive** — `EchoMQ.Stream.trim/4` (`MAXLEN ~`/`MINID`) under the opt-in `EchoMQ.StreamRetention`
   driver; what is trimmed folds to the durable Graft floor via `EchoStore.StreamArchive.fold/3` (R5.02 + the
   archive frontier → `/echo-persistence`).

## Stage 1 — append the game's events to the log

codemojex already has the three actions the feed records, each a real surface in `echo/apps/codemojex`:

- A **guess submitted** — `Codemojex.Guesses.submit/3` validates the guess, charges the room's currency, and
  enqueues a branded `JOB` on the player's lane.
- A **guess scored** — `Codemojex.ScoreWorker` drains that lane, scores with the pure `Codemojex.Scoring.score/2`,
  writes a `GES` guess, and for a classic game publishes a `scored` event via `EchoMQ.Events.publish/5`.
- A **round settled** — `Codemojex.Settle.close/1` enqueues a settle `JOB`; the consumer runs
  `Codemojex.Rooms.close_game/1` and pays out.

The feed appends one stream entry per action. `EchoMQ.Stream.append(conn, "cm", "events", fields)` mints an
`EVT`-branded record id host-side, derives the explicit `XADD` id from that id by field correspondence, and issues
`XADD emq:{cm}:stream:events <xadd-id> id <branded> <fields…>`. It returns `{:ok, branded}` — the branded id **is**
the receipt. The writer owns the mint, so there is nothing to spoof, and because successive mints over a single
writer's monotone cell are strictly increasing, the stream stays strictly mint-ordered: the next id always exceeds
the stream top, so an `XADD` is never rejected on a single writer. A wrong-kind id (a stream admits one brand,
`EVT`) raises before any wire.

```
# Codemojex.Guesses.submit/3 — the play API (echo/apps/codemojex/lib/codemojex/game.ex)
job = EchoData.BrandedId.generate!("JOB")
Lanes.enqueue(Bus.conn(), "cm", player, job, payload)   # a guess JOB on the player's lane

# the feed appends each action to ONE log — EchoMQ.Stream.append/4
EchoMQ.Stream.append(conn, "cm", "events", [{"kind", "guess"}, {"room", "RMM0…"}, {"player", "alex"}])
#=> {:ok, "EVT0…"}   the branded EVT id IS the receipt; XADD emq:{cm}:stream:events
```

The append order is the truth order. Nothing in the feed is a value held in place; every action is one more
immutable entry on the log.

## Stage 2 — fold the log to render the feed

To show the feed, read the log and fold it. `EchoMQ.Stream.read(conn, "cm", "events", "-", "+")` issues
`XRANGE emq:{cm}:stream:events - +` and parses each entry back into `{branded, fields_map}` tuples **in mint
order** — the branded `EVT` id recovered from the stored `id` field, the remaining pairs the payload. The feed is
that list reduced to rendered lines: a fold, not a row a worker overwrites, so the same log always renders the same
feed. A reader at the tail and a reader replaying from the start see the same entries; a read moves a cursor, it
does not remove an entry.

A windowed view — "the activity of the last five minutes" — is a fold scoped to a slice. Because a stream entry id
carries the millisecond it was minted, a `DateTime` becomes a range bound: `EchoMQ.Stream.read_window(conn, "cm",
"events", t0, t1)` computes `from = minid_floor(t0)` and `to = maxid_ceil(t1)` host-side and reads `[t0, t1]`
inclusive both edges, and `EchoMQ.Stream.read_since(conn, "cm", "events", t0)` reads `[t0, ∞)`. Time as a range
bound is the cursor of R5.01 reapplied: a `t0` entry reads back, a `t0 - 1ms` entry does not.

```
EchoMQ.Stream.read(conn, "cm", "events", "-", "+")
#=> {:ok, [{"EVT0…a", %{"kind" => "guess",  "player" => "alex"}},
#          {"EVT0…b", %{"kind" => "scored", "player" => "alex", "pct" => "80"}},
#          {"EVT0…c", %{"kind" => "settled", "winner" => "alex"}}]}   in mint order

EchoMQ.Stream.read_window(conn, "cm", "events", five_min_ago, now)   # the last 5 minutes, a fold
```

## Stage 3 — consume reliably with a group

The visible feed is a fold of the log; the notification side is a consumer. When the feed posts "alex cracked the
code", a notification reader must deliver that to the room — once, and not again on a restart. That is the reader
law: `EchoMQ.StreamConsumer` is a BEAM consumer group over the events stream that reads new entries with
`XREADGROUP`, acks each with `XACK`, and resumes where it left off. A reader that crashes and restarts with the
same name drains its own un-acked backlog first (its PEL, `XREADGROUP … 0`), then switches to new entries (`>`) —
so it recovers exactly what it held, and a clean cold start has an empty backlog and goes straight to new entries.
A dead peer's held work is reclaimed by the `XAUTOCLAIM` beat after an idle threshold.

The handler shape is `fun(%{id, payload, attempts, group})` — `id` the branded `EVT` receipt, `payload` the entry's
fields, `attempts` the per-entry delivery count. The posture is at-least-once: on `:ok` the entry is `XACK`ed; on
`{:error, reason}` or a raise it is left un-acked and re-delivered. Exactly-once is not claimed, so a re-claimed
entry can arrive after a newer one — its branded id is older. The consequence is the one rule the handler must
keep: **it must be idempotent**, and the branded `EVT` id is the dedup key. Render the feed line for an `EVT` id
once, record that it was sent, and a second delivery of the same id is a no-op. Resume, not replay.

```
EchoMQ.StreamConsumer.start_link(
  queue: "cm", stream: "events", group: "feed-notify",
  consumer: "node-1", group_start: :new,         # :new -> $ (tail), declared, no default
  handler: fn %{id: evt_id, payload: p, group: _} ->
    if not already_sent?(evt_id) do              # idempotent on the EVT id — the dedup key
      Codemojex.Notifier.notify(p["chat"], render(p))
      mark_sent(evt_id)
    end
    :ok                                          # :ok -> XACK; {:error, _} -> left un-acked, re-delivered
  end
)
```

## Stage 4 — bound the live log, keep the deep history

A log that only grows is a leak, so retention is a policy, not a default. `EchoMQ.Stream.trim(conn, "cm", "events",
{:maxlen, 10_000, true})` issues `XTRIM emq:{cm}:stream:events MAXLEN ~ 10000` — keep the ten thousand newest feed
entries, remove the older. The `~` approximate form trims in whole macro-nodes: it may under-trim but can never
over-trim, so it never deletes inside the window — the safe default. A `{:minid, dt, true}` window trims by age
instead, removing entries minted before `dt`. The named, opt-in `EchoMQ.StreamRetention` driver re-applies a
declared `:policy` on a beat through that same public verb; a stream nobody declares is never silently trimmed, and
a manual `trim/4` call is the equally-supported cadence.

What is trimmed is not lost. `EchoStore.StreamArchive.fold/3` folds a mint-ordered slice of the trimmed segment
into the native `EchoStore.Graft` engine's CubDB — one page per record, in a reserved high page range disjoint from
business pages — and advances a watermark `W` (the branded `EVT` id of the highest-folded record). The deep feed is
then readable beside the live tail: a merge-read splits on `W`, records with an id at or below `W` coming from the
archive, records above it from the live stream. The fold runs **before** the trim, so no entry is dropped before it
is durable. With a remote configured, the engine replicates the CubDB pages off-box to Tigris behind a create-only
commit fence — the durability dial taught end to end, from the volatile bus to the durable floor.

> **Notes on Valkey.** Every stream key the feed touches carries the queue's `{cm}` hash tag, so all of codemojex's
> stream keys hash (CRC16 of the brace bytes) to one of the 16384 cluster slots and co-locate. That co-location is
> what keeps a multi-key operation legal — a stream and its archive cursor live on one slot, never a `CROSSSLOT`
> error — and it is why the keyspace is braced by design. See
> [valkey.io/topics/cluster-spec](https://valkey.io/topics/cluster-spec/).

## The activity feed is the log seen sideways

Read back through the four stages and one structure stands behind the feed: an append-only log of branded entries.
The append makes each action immutable and ordered; the fold renders the present from the past; the consumer group
delivers without replaying; retention bounds the live log and the archive keeps the deep history. The same Stream
Tier, read four ways — the feed is the log seen sideways. Identity orders the entries, the boundary owns them, and
what survives is a choice the system makes, not an accident of volume.

The bus pillar carries the broadcast, the consumer groups, time-travel, and the archive in depth; the manuscript's
bus chapter is where these figures are drawn from; and the durable floor is where a trimmed or archived segment
comes to rest.

## References

### Sources

- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log, entry ids,
  consumer groups, and the range read the whole feed is built on.
- [Valkey — `XADD`](https://valkey.io/commands/xadd/) — the append behind `EchoMQ.Stream.append/4`; the entry id
  the feed reads back as its receipt.
- [Valkey — `XRANGE`](https://valkey.io/commands/xrange/) — the mint-ordered read behind `EchoMQ.Stream.read/6`
  and the windowed `read_window/6`; the feed is a fold of this.
- [Valkey — `XREADGROUP`](https://valkey.io/commands/xreadgroup/) — the consumer-group read behind
  `EchoMQ.StreamConsumer`; read, ack, and resume, so a restart does not replay.
- [Valkey — `XTRIM`](https://valkey.io/commands/xtrim/) — the bounded trim behind `EchoMQ.Stream.trim/4`; the
  `MAXLEN ~` form the retention driver applies.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{cm}` hash tag forces the feed's
  stream keys onto one of the 16384 slots so a multi-key operation stays legal.
- [Kreps, J. — The Log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the log as the shared abstraction beneath a stream and a feed.

### Related in this course

- [R5.01 · Event sourcing on Streams](/redis-patterns/streams-events/streams-event-sourcing) — the append-only log
  as the source of truth, replay to rebuild; stage one and two of the build.
- [R5.02 · Stream consumer patterns](/redis-patterns/streams-events/streams-consumer-patterns) — block, resume,
  trim, archive; the reader law the notification side uses.
- [R5.03 · Pub/Sub vs Streams](/redis-patterns/streams-events/pubsub) — fire-and-forget against the durable log;
  why the feed is a stream, not a channel.
- [R5.04 · Custom events & projections](/redis-patterns/streams-events/custom-events) — domain events on a named
  stream and the windowed fold the feed reuses.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the sorted set as a clock; the chapter
  before this one.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar: the broadcast and the retained, replayable log, consumer
  groups, time-travel, and the archive in depth.
- [/bcs/bus](/bcs/bus) — the manuscript bus chapter (B3) the Stream Tier figures are drawn from.
- [/echo-persistence](/echo-persistence) — the durable floor a trimmed or archived feed segment folds into.
