# The owned keyspace

> **Route:** `/echomq/substrate/the-opt-in-floor` · **Chapter:** E3 · EchoMQ 2.0 — the protocol break ·
> **Movement II** · tracks `emq.1` (**drafted — the 2.0 break**) · the orientation dive.
>
> The triangle: **pattern** `← redis-patterns R0` (foundations) + `R2` (atomicity) · **spec** `⇄ emq.1`
> (`specs/emq/emq.1.md` — D1, INV1, INV3) · **as-built code** the v1 line it forks from (`EchoMQ.Keys`
> interpolating the queue name verbatim, `keys.ex:85-86` / `:97-98`, the `emq:` prefix, `EchoMQ.Version` →
> `bullmq:5.65.1`), with the `emq:{q}:*` keyspace written as **"emq.1 ships …"**.

## The fact — emq.1 owns its keyspace

EchoMQ 2.0 drops BullMQ wire compatibility on the **first** rung. The most visible part of that break is the
keyspace. The v1 line (`echo/apps/echomq` v`1.3.0`, frozen here) speaks the `emq:` prefix and interpolates the
queue name **verbatim** — `EchoMQ.Keys.base/1` returns `"#{prefix}:#{name}"` (`keys.ex:97-98`),
`key_prefix/1` returns `"#{prefix}:#{name}:"` (`keys.ex:85-86`), no wrapping, no validation, no placement. So a
queue named `payments` produces `emq:payments:wait`, `emq:payments:active`, and the rest — flat strings with
nothing for a thread-per-shard datastore to balance on.

**emq.1 ships the owned keyspace.** Every per-queue key becomes `emq:{q}:<type>` — the `emq:` prefix replacing
`emq:`, the queue name **brace-wrapped by the core** (transparently — a caller still writes `Queue("orders")` and
the core places `emq:{orders}:*`). The wrap is **idempotent** (an already-braced caller name is not double-wrapped)
and **validated** (no colon inside a hashtag; `emq` is rejected as a queue name). The braced base prefix **`{emq}:`**
is **reserved** for the core's own cross-queue keys — the script-bundle version, the node registry, the fleet
bookkeeping — so the core's namespace and any queue's namespace cannot collide (INV3). Every queue is slot-local by
construction: every per-queue key carries the queue's one hashtag, and distinct queues carry distinct hashtags by
default.

The payoff is DragonflyDB-native multithreading: with every queue hashtagged by construction, `--lock_on_hashtags`
locks precisely — one queue per thread, distinct queues across cores — and never the whole-store escape hatch the
v1 line forces.

## The worked example — the v1→v2 key comparison, on the real grounding

Take the fixed queue `payments`. The v1 line, today, produces the `emq:` families — the verbatim-interpolated
builders in `EchoMQ.Keys`:

- `emq:payments:wait`, `emq:payments:active`, `emq:payments:paused` — LIST
- `emq:payments:delayed`, `emq:payments:prioritized`, `emq:payments:completed`,
  `emq:payments:failed`, `emq:payments:waiting-children` — ZSET
- `emq:payments:stalled` — SET
- `emq:payments:events` — STREAM
- `emq:payments:meta` — HASH
- `emq:payments:<jobId>:lock` — STRING + PX TTL, via `EchoMQ.Keys.lock/2`

These are flat: no hashtag, nothing to place across threads.

emq.1 ships the v2 form of each: `emq:payments:wait` → `emq:{payments}:wait`, `emq:payments:active` →
`emq:{payments}:active`, … `emq:payments:<jobId>:lock` → `emq:{payments}:<jobId>:lock`. The `emq:` prefix
replaces `emq:`; the queue name carries its `{…}` hashtag; the field set is otherwise the same. The v1 side is
the line the fork freezes at 1.3.0; the v2 side is always what **emq.1 ships**.

### Two slots, by construction

emq.1 ships the transparent hashtag so a queue's keys are placed precisely. A datastore that locks on the hashtag
routes a key by the substring inside the first `{…}`. So every v2 key of the `payments` queue —
`emq:{payments}:wait`, `emq:{payments}:active`, `emq:{payments}:<jobId>:lock`, … — carries the same tag,
`payments`, and lands in the **same slot**. The core's own cross-queue keys live under the reserved `{emq}:` base
— `{emq}:version`, `{emq}:nodes` — and group into a **second, distinct slot**: the queue's and the core's. They
cannot collide, because `emq` is rejected as a queue name. A property test over arbitrary queue names checks the
rule holds: `wrap∘wrap = wrap`, and every per-queue key shares exactly the queue's one hashtag (emq.1-D1).

## The triangle — pattern → implementation

- **The pattern** (`← redis-patterns R0`, `R2`): the keyspace and the scripts *are* the protocol (R0); a multi-key
  change is one indivisible move, foreign to other state (R2 atomicity). A single hashtag per transition keeps a
  transition single-slot, so it stays atomic.
- **The implementation** (`⇄ emq.1`, drafted — the 2.0 break): emq.1 ships the `emq:{q}:*` keyspace with the
  transparent, idempotent, validated brace (INV3 — placement by construction) and the reserved `{emq}:` base.
  Every key declared, every queue placed.
- **The as-built code:** the v1 line `EchoMQ.Keys` interpolates the queue name verbatim (`keys.ex:85-86`,
  `:97-98`) under the `emq:` prefix, `EchoMQ.Version` records `bullmq:5.65.1` — this is the line the fork freezes
  at 1.3.0, taught present-tense. The `emq:{q}:*` builders and the `{emq}:` reserve are what **emq.1 ships**; the
  surfaces below are taught from the spec, written "emq.1 ships …", because the rung is drafted
  (`lib/echomq/ext/` and the v2 script set do not exist yet).

The bridge: R0/R2 say the keyspace is the protocol and a change is one indivisible, single-slot move. emq.1 ships
the owned keyspace — `emq:{q}:*` with the brace applied by the core — so every queue is placed by construction and
the core's own keys live, alone, under the reserved `{emq}:`.

## The 2.0 fork

The verbatim `emq:payments:*` keyspace is the v1 line's, frozen at 1.3.0. emq.1 ships the break: `emq:` replaces
`emq:`, the per-queue `{q}` hashtag is applied transparently by the core, and `{emq}:` is reserved for the core's
own keys — so DragonflyDB can lock on the hashtag precisely instead of the whole store.

## Recap

emq.1 owns its keyspace. The v1 line interpolates the queue name verbatim under `emq:` (`EchoMQ.Keys`,
`keys.ex:85-86`) — flat, unplaced, frozen at 1.3.0. emq.1 ships `emq:{q}:<type>`: the `emq:` prefix replacing
`emq:`, the per-queue `{q}` hashtag applied transparently (idempotent, validated), the braced base `{emq}:`
reserved for the core's own cross-queue keys, and `emq` rejected as a queue name so the namespaces cannot collide
(INV3). Every queue is slot-local by construction, so a hashtag-locking datastore places one queue per thread and
distinct queues across cores. Next, the substrate shows how the break is versioned and fenced.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the reference implementation whose `emq:` key layout the
  v1 line speaks and the 2.0 fork leaves behind.
- DragonflyDB — *Server flags* (`https://www.dragonflydb.io/docs/managing-dragonfly/flags`) — `--lock_on_hashtags`
  ("locks are done at the `{hashtag}` level"), the mechanism the transparent `{q}` hashtag targets.
- DragonflyDB — *BullMQ on Dragonfly* (`https://www.dragonflydb.io/docs/integrations/bullmq`) — the multithreading
  ceiling of an unplaced keyspace that the owned keyspace removes.
- Redis — *Cluster specification* (`https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/`) —
  the hash-tag rule (`{…}` decides the slot) the transparent brace relies on.

### Related in this course

- `/echomq/substrate` — E3 · EchoMQ 2.0 (the chapter this dive opens).
- `/echomq/core` — E2 · The core, the v1 line the fork forks from.
- `/redis-patterns/coordination` — R2 · atomicity, the pattern this dive applies.
- `/redis-patterns/overview` — R0 · foundations, why the keyspace and scripts are the protocol.
