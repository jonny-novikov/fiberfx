# Workshop — The retained event log, end to end

> Route: `/echomq/bus/workshop` · Pillar II (the Bus) · the closing capstone (single page, no dives).
> Dark-editorial. Stamp `EMQ0OGUWI87UdF`. This page folds the **whole Bus pillar** — it links all five
> built modules (01 the-events-channel · 02 the-stream-log · 03 the-consumer-group · 04 time-travel · 05
> retention-and-archive). Every surface is **real shipped code** in `echo/apps/echo_mq` +
> `echo/apps/echo_store` — there are **no `[RECONCILE]` markers** here.

## The thesis (one paragraph)

The Bus pillar taught five surfaces over one wire. This workshop builds **one thing** out of all five: a
retained **codemojex** activity feed, end to end — a live game whose every guess, score, and settlement is
broadcast now *and* remembered forever. It is a staged construction. **Publish** the live signal so a screen
reacts the instant a guess is scored (`EchoMQ.Events.publish/5`). **Append** the same fact to a durable,
replayable log so nothing is lost when nobody is watching (`EchoMQ.Stream.append/4`). **Consume** that log
reliably from a worker that resumes — never replays — after a crash (`EchoMQ.StreamConsumer`). **Replay** any
past window by a wall-clock instant for a backtest or an audit (`EchoMQ.Stream.read_window/6`). And **bound**
the live log to a fixed size while **folding** everything trimmed to the durable Graft floor, so the deep feed
survives without resident memory (`EchoMQ.Stream.trim/4` under `EchoMQ.StreamRetention`, then
`EchoStore.StreamArchive.fold/3`). The thread through all five is the branded `EVT` id: minted once at the
append, carried unchanged to the consumer's dedup key, the time-travel bound, and the archive watermark.

## The worked domain — codemojex, one round's life

codemojex is the six-emoji code-breaking game on the same stack. A player submits a guess; a single authority
scores it; a round settles. We want a feed that records all of it — `guessed`, `scored`, `settled` — that a
live screen can follow *and* an auditor can replay months later.

The real lifecycle (verified on disk, `echo/apps/codemojex/lib/codemojex/`):

- `Codemojex.Guesses.submit/3` (`game.ex`) — validates a six-emoji guess, charges the player's currency, and
  enqueues a branded `JOB` on the **player's `PLR` lane** (`EchoMQ.Lanes.enqueue/5`). *The host never scores.*
- `Codemojex.ScoreWorker` (`game.ex`) — the authority. `EchoMQ.Consumer` drains the guess queue; it reads the
  game secret, scores with the pure engine, writes a branded `GES` guess, and — for a classic game —
  `EchoMQ.Events.publish/5`'s a `scored` event with fields `game · player · pct · eff`.
- `Codemojex.Scoring.score/2` (`scoring.ex`) — the pure linear engine: `points = 100 - 20*d` per position,
  total out of `600`, the percentage computed and never stored. A re-delivered guess re-scores **identically**
  (the property that makes the at-least-once stream side safe).
- `Codemojex.Settle.close/1` (`game.ex`) — settlement as a second-queue job: enqueues a `JOB` on the settle
  lane, whose consumer runs `Codemojex.Rooms.close_game/1`.
- `Codemojex.Rooms.close_game/1` (`rooms.ex`) — the exactly-once payout (`SET NX` claims the close), then
  winner-take-all (classic) or the sealed top-K split (golden).

The feed is one stream — `emq:{q}:stream:feed` for the `cm` queue — and every lifecycle moment is one `append`
to it. The **redis** course's R5.05 workshop builds this same feed from the *pattern* side; this one builds it
from the *pillar-depth* side.

---

## Stage 1 — Publish the live signal (module 01)

The screen wants to react the instant a guess is scored, without polling any set. That is fire-and-forget
pub/sub: `EchoMQ.Events.publish/5` issues `PUBLISH emq:{q}:events` **host-side, after the scoring verdict**.
The byte-frozen transition scripts stay byte-unchanged — the publish is a host-side message *about* the
verdict, not part of it.

This is exactly what `Codemojex.ScoreWorker` already does once a guess is scored:

```elixir
# echo/apps/codemojex — Codemojex.ScoreWorker (the scoring authority)
# After scoring, publish a `scored` event so the room channel reacts live. This
# is HOST-SIDE pub/sub — fire-and-forget; the score is already written, the
# event is just a signal. No secret, no guess content crosses the wire.
Events.publish(conn, @queue, "scored", job_id,
  game: game,
  player: name,
  pct: to_string(s.percentage),
  eff: to_string(eff)
)
```

`publish/5` gates the job id at the key builder (`Keyspace.job_key/2`, INV5) before the wire, then encodes the
flat cjson `{"event":"scored","job":"<id>","game":…,"player":…,"pct":…,"eff":…}` object and `PUBLISH`es it on
`channel(queue)` = `emq:{q}:events`. A subscriber reads the name back by **substring scan** (`event_name/1`) —
the bus carries no JSON parser, and an unknown name answers `:unknown`, never minting an atom from the wire.

The cost is named, not papered over: **at-most-once.** A `PUBLISH` with no live subscriber — or one issued in
the window between a socket drop and the resubscribe — is **lost**. The `emq.1` resubscribe `MapSet` keeps the
feed live across a reconnect, but the *durable* receipt is the next stage. The screen sees it now; the log
remembers it forever.

## Stage 2 — Append + replay the durable log (module 02)

The same fact that fans out to live screens is **appended** to a retained, replayable log. `EchoMQ.Stream.append/4`:

```elixir
# echo/apps/echo_mq — EchoMQ.Stream.append/4 (the writer's whole point)
# 1. mint an EVT-branded record id host-side — the writer OWNS the mint, so
#    there is nothing to spoof;
# 2. derive the explicit XADD id by field correspondence (Stream.Id.xadd_id/1);
# 3. XADD <key> <xadd_id> id <branded> <fields…> — issued DIRECT (no Lua), the
#    14-byte branded string stored as the stream `id` FIELD (the claims-only
#    contract: a polyglot reader gets the canonical id without re-encoding);
# 4. return {:ok, branded} — the branded id IS the receipt.
def append(conn, queue, name, fields)
    when is_binary(queue) and is_binary(name) and is_list(fields) do
  branded = EchoData.Snowflake.next_branded(Id.kind())
  append_id(conn, queue, name, branded, fields)
end
```

For the feed, the worker appends a `scored` record beside the publish:

```elixir
# the same scored fact, appended to the durable feed (a page-OWN composition)
{:ok, evt} =
  EchoMQ.Stream.append(conn, "cm", "feed",
    [{"event", "scored"}, {"game", game}, {"player", name},
     {"pct", Integer.to_string(s.percentage)}, {"guess", gid}])
# evt :: "EVT…" — the branded receipt; gid :: "GES…" — the written guess id
```

The **order theorem** holds the log: stream order == id sort == mint order, proven *by construction* in
`EchoMQ.Stream.Id` — the `EVT` brand admits one namespace per stream (so base62 byte-order equals
snowflake-order), and a single writer's strictly-monotone `:atomics` cell means the next id always exceeds the
stream top, so no `XADD` rejection is possible. A multi-writer violation surfaces honestly as
`{:error, :nonmonotonic}` — never swallowed, never retried with `*`.

`read/6` (`XRANGE`) folds the whole log back in mint order — the minimal un-grouped read-back, the
order-theorem proof surface:

```elixir
# fold the feed back, oldest-first — the receipt becomes the canonical id, the
# rest the payload map. {:ok, [{branded, fields_map}]} in mint order.
{:ok, entries} = EchoMQ.Stream.read(conn, "cm", "feed")
# [{"EVT…", %{"event" => "guessed", …}}, {"EVT…", %{"event" => "scored", …}}, …]
```

The stream *remembers* what the publish forgets.

## Stage 3 — Consume reliably (module 03)

The live screen reads off the publish. But the notification worker — the one that pushes a "you were beaten"
message — must read the log **reliably**: each entry handled once, resumable after a crash, never re-running
the whole feed. That is a consumer group, `EchoMQ.StreamConsumer`.

The handler is **byte-identical in shape** to the job `Consumer`'s handler — one portable handler across job
and stream:

```elixir
# echo/apps/echo_mq — the EchoMQ.StreamConsumer handler shape (the exact mirror)
# id       :: the stored branded record id (the append/4 receipt) — the dedup key
# payload  :: the entry's remaining fields as a map
# attempts :: the XPENDING per-entry DELIVERY-count (NOT a failure count), so a
#             poison threshold attempts >= N calibrates correctly
# group    :: the consumer-group name
# :ok        -> XACK (the entry retires from the PEL)
# {:error,_} -> LEFT un-acked (survives in the PEL, re-delivered) — at-least-once
fn %{id: evt, payload: fields, attempts: attempts, group: _g} ->
  case notify_feed(evt, fields) do
    :ok -> :ok            # XACK
    err -> err            # leave un-acked → re-delivered
  end
end
```

Two mechanisms recover work. **PEL-drain-on-(re)start recovers SELF**: `XREADGROUP GROUP g <self> … 0` reads
the consumer's own un-acked backlog to exhaustion, *then* switches to `>` — a crashed consumer that restarts
with the same name recovers its held work the instant it restarts. **The `XAUTOCLAIM` beat recovers dead
PEERS**: entries idle past `:min_idle_ms` (evaluated server-side against `XPENDING` idle — no host clock) held
by consumers that died and never restarted are re-assigned, one pass per beat. The blocking
`XREADGROUP … BLOCK` parks on the consumer's **own private lane**, so the single-owner socket of the rest of
the system is never stalled.

The cost is the **order-theorem PEL exception**: new entries stay id-ordered (the writer's theorem is
untouched), but a **re-claimed** entry returns *out* of real-time delivery order — its branded id is *older*
than entries already handled. This is the irreducible cost of at-least-once (exactly-once is **not** claimed),
so the handler **must be idempotent** — the branded `EVT` id is the dedup key, the BCS newer-wins discipline.
codemojex's scoring is already pure and deterministic (`Codemojex.Scoring.score/2`: the same secret and guess
always yield the same score), so re-handling a feed entry is safe by construction.

The screen reacts *now* (stage 1); the worker *resumes, not replays* (stage 3).

## Stage 4 — Replay by instant (module 04)

"What did the feed look like between 14:30 and 14:32?" — for a backtest, an audit, or a debug — is a **range
read, not a scan**, because the log is mint-ordered. A wall-clock `%DateTime{}` is an exact id position, so
`EchoMQ.Stream.read_window/6` computes its `XRANGE` bounds host-side and delegates to the byte-frozen `read/6`
— **zero new Lua**:

```elixir
# echo/apps/echo_mq — EchoMQ.Stream.read_window/6 (the time-travel read)
# A CLOSED mint-time window [t0, t1], both edges inclusive. from = minid_floor(t0)
# (the smallest id at/after t0), to = maxid_ceil(t1) (the largest id mintable
# at/before t1) — exact because the stream is mint-ordered. RAISES before any
# wire on an inverted window (t1 strictly before t0). Delegates to read/6.
def read_window(conn, queue, name, %DateTime{} = t0, %DateTime{} = t1, count \\ nil)
    when is_binary(queue) and is_binary(name) do
  if DateTime.compare(t1, t0) == :lt do
    raise ArgumentError, "read_window requires t0 <= t1; …"
  end
  read(conn, queue, name, minid_floor(t0), maxid_ceil(t1), count)
end
```

For the feed, replay one round's life over its open→settle interval:

```elixir
# replay the round's feed over its open→settle interval (a page-OWN example)
{:ok, slice} = EchoMQ.Stream.read_window(conn, "cm", "feed", opened_at, settled_at)
# every GES guess + scored + settled EVT entry in [opened_at, settled_at], mint order
```

`read_since/5` is the half-open `[t0, ∞)` analogue. Both return `{:ok, [{branded, fields_map}]}` in mint
order; both are pure id-math over the shipped `read/6`. Never a raw snowflake integer to the wire — the wire
wants `ms-seq` (the `minid_floor/1` discipline).

## Stage 5 — Bound + fold to disk (module 05)

A log that only grows is a leak. Retention bounds the **live** log; what is trimmed is **not lost** — it folds
to the durable Graft floor.

`EchoMQ.Stream.trim/4` bounds the log by length (`MAXLEN`) or age (`MINID`), issued direct over `XTRIM`:

```elixir
# echo/apps/echo_mq — EchoMQ.Stream.trim/4 (the destructive verb, no Lua)
# {:maxlen, count, approx?} -> XTRIM <key> MAXLEN [~|=] <count>  (keep newest count)
# {:minid,  dt,    approx?} -> XTRIM <key> MINID  [~|=] "<ms>-0" (remove < instant)
# approx? true -> `~` the SAFE default: trims in whole macro-nodes, may UNDER-trim
# but NEVER OVER-trim, so a trim can never delete an entry INSIDE the window (INV4).
# Answers {:ok, removed_count}; a WRONGTYPE is surfaced, not swallowed.
{:ok, removed} = EchoMQ.Stream.trim(conn, "cm", "feed", {:maxlen, 10_000, true})
```

Retention is a **policy**, not a default — coupling a *safety* property (bounded memory) to a *liveness* fact
(a consumer is up) is the silent-no-op class the design refuses, so the trim cadence lives on its own beat. The
named opt-in driver `EchoMQ.StreamRetention` — a `:transient` GenServer beating on `:tick_ms` — re-applies a
**declared** BEAM-side `:policy` of `{queue, name, window}` via `trim/4`, decoupled from consumer liveness (a
stream nobody drains still trims). A manual `trim/4` is the equally-supported cadence; the driver is sugar.

What is trimmed folds to the archive. `EchoStore.StreamArchive.fold/3` folds a mint-ordered `{branded, fields}`
slice into the native `EchoStore.Graft` engine's CubDB — one page per record at a **reserved high range**
(`@archive_base = 2^49`, disjoint from business pages by construction) — through the **public**
`VolumeServer.commit/3`, advancing the watermark `W` to the branded `EVT` id of the highest-folded record:

```elixir
# echo/apps/echo_store — EchoStore.StreamArchive.fold/3 (the durable floor)
# Fold a mint-ordered slice into the Graft engine at @archive_base + n — one page
# per record — and advance the watermark W to the highest-folded EVT id (W is a
# branded id, NEVER the integer head_lsn). Fold-before-trim is the no-loss
# ordering: on a fold error the caller does NOT trim (the safe direction).
{:ok, w} = EchoStore.StreamArchive.fold(volume_id, slice, db)
```

`W` splits the **merge-read**: id ≤ `W` comes from the archive, id > `W` from the live `Stream.read/6` tail.
No-gap/no-overlap is a *consequence* of fold-before-trim + the order theorem, never a per-read check. The page
axis is branded-id-monotone (records fold in mint order — the order theorem reaching disk), so a forward scan
reads oldest-first with no second index. The deep feed survives **without resident memory**.

This is the **durability dial** — a system turns it: hold nothing · a bounded in-heap window + a checkpoint per
K · commit-per-record + replicate off-box (Graft → Tigris). The comparison is **Oban**, which keeps jobs in
the same Postgres as the data (a job + a row commit in one transaction); the bus *separates* the log from the
store and buys an in-memory hot path + the dial, **giving up** Oban's one-transaction coupling — the trade
stated beside the win. The door out is `/echo-persistence`.

## The whole pillar, one feed

| Stage | Surface | Wire | Guarantee | The feed's moment |
|---|---|---|---|---|
| 1 Publish | `EchoMQ.Events.publish/5` | `PUBLISH emq:{q}:events` | at-most-once | the screen reacts the instant a guess is scored |
| 2 Append | `EchoMQ.Stream.append/4` | `XADD emq:{q}:stream:feed` | ordered by mint | the same fact, remembered as an `EVT` record |
| 3 Consume | `EchoMQ.StreamConsumer` | `XREADGROUP … >` / `XACK` | at-least-once | the notifier resumes, not replays — idempotent on the `EVT` id |
| 4 Replay | `EchoMQ.Stream.read_window/6` | `XRANGE <t0> <t1>` | a mint-instant window | a round's feed replayed for a backtest / audit |
| 5 Fold | `EchoMQ.Stream.trim/4` + `EchoStore.StreamArchive.fold/3` | `XTRIM` + CubDB → Tigris | durable, no loss | the deep feed survives without resident memory |

The thread through all five rows is one branded `EVT` id: the append's receipt is the consumer's dedup key, the
time-travel bound, and the archive watermark — minted once, carried unchanged.

## Pattern → implementation

The *pattern* — an event log that is broadcast, replayed, consumed reliably, and tiered to durable storage — is
what the **Redis Patterns Applied** course frames in its streams-and-events chapter, and its R5.05 workshop
builds this *same* codemojex feed from the pattern side. Here it is built from the *implementation* side: the
real `EchoMQ.{Events, Stream, StreamConsumer, StreamRetention}` + `EchoStore.StreamArchive` surfaces, the
branded `EVT` id the thread through all of them.

## Recap — the pillar, exercised

The Bus pillar taught five surfaces over one wire; this workshop built one retained codemojex feed out of all
five. **Publish** for the live screen, **append** for the durable receipt, **consume** to resume-not-replay,
**read by instant** to replay any window, **trim + fold** so the deep feed outlives memory. Events say it once;
the stream remembers. The next floor down — the durability dial in full — is `/echo-persistence`.

## References

### Sources

- Valkey — *Introduction to Streams* — the append-only log primitive (`XADD`/`XRANGE`/`XREADGROUP`) the stream
  tier issues direct.
- Valkey — *Cluster specification* — the hash-slot routing the `{q}` hashtag co-locates a queue's keys onto.
- Valkey — *XADD* / *XRANGE* / *PUBLISH* / *XTRIM* — the exact commands each stage runs.
- Kreps — *The Log: What every software engineer should know about real-time data's unifying abstraction* — the
  log as the system's backbone.
- Lamport — *Time, Clocks, and the Ordering of Events in a Distributed System* — why a single writer's monotone
  clock makes order legible.

### Related in this course

- `/echomq/bus/the-events-channel` — stage 1: the fire-and-forget pub/sub surface.
- `/echomq/bus/the-stream-log` — stage 2: the append-only writer + the order theorem.
- `/echomq/bus/the-consumer-group` — stage 3: the reliable, resumable read.
- `/echomq/bus/time-travel` — stage 4: reading the log by a mint instant.
- `/echomq/bus/retention-and-archive` — stage 5: bound the log, fold what is trimmed.
- `/echomq/bus` — the Bus pillar landing.
- `/redis-patterns/streams-events` — the pattern side of the door; its R5.05 workshop builds the same feed.
- `/bcs/bus` — the manuscript chapter (B3) these figures realize.
- `/echo-persistence` — the durable floor: the durability dial in full.
