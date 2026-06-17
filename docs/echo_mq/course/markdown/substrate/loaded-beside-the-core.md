# The versioned break

> **Route:** `/echomq/substrate/loaded-beside-the-core`
> **Movement II · The Extension · E3 · EchoMQ 2.0 — the protocol break · orientation dive**
> **Tracks `emq.1` — drafted (the 2.0 break), taught from its spec.**
> ← redis-patterns R0 (foundations) · R2 (atomicity)

## The fact — the break is versioned and fenced

The owned keyspace (the previous dive) is *what* changes on the wire. This dive is *how the change is governed*: once,
versioned, and fenced — so a v2 worker and a v1 keyspace never touch silently. emq.1 ships three pieces of the
governance:

1. **The version bump** — `meta.version` becomes `echomq:2.0.0`. Today the v1 line records `bullmq:5.65.1`:
   `EchoMQ.Version.full_version/0` returns `"bullmq:#{@bullmq_version}"` (`version.ex:54`), value `bullmq:5.65.1`.
   emq.1 ships `EchoMQ.Version` recording `echomq:2.0.0` (D3). The v1 line freezes at `1.3.0` — a maintenance branch,
   not deleted code.
2. **The two-way typed boot fence** — emq.1 ships a fence (D3): a v2 worker booting against a keyspace whose
   `meta.version` reads `bullmq:*` (or whose keys are `emq:*`) refuses with a typed error; and the converse — a v1
   worker against a v2 (`echomq:2.0.0`) keyspace refuses too. No silent cross-version read or write, ever (INV1).
3. **The v1→v2 migration path** — emq.1 ships the explicit path (D7): the drain-and-switch runbook plus an at-rest
   key-migration tool. The runbook names honestly what cannot migrate live.

The dispatch itself is *not* new. emq.1 ships the v2 script set — every key declared — dispatched the same proven
way the shipped `EchoMQ.Scripts.execute_raw/4` dispatches the v1 scripts today.

## The worked example — the dispatch the v2 set rides

The shipped core loads its 50 Lua scripts under `priv/scripts/` by a single rule, and `EchoMQ.Scripts.execute_raw/4`
is that rule in code (`@spec execute_raw(atom(), String.t(), [String.t()], [any()])`). On every call it computes the
script's SHA, then issues `EVALSHA <sha> <numkeys> <keys…> <argv…>` over the pooled `EchoMQ.RedisConnection`. If
Redis has the script cached, that one round trip runs it. If Redis answers `NOSCRIPT` — the script is not in the
cache — `execute_raw/4` falls back to `EVAL <source> <numkeys> <keys…> <argv…>`, which both runs the script *and*
caches it, so the next `EVALSHA` hits. Two commands at most, a warm cache after the first miss. That is load-once,
dispatch-by-SHA — the R0 foundation. This dispatch is real and shipped today.

emq.1 ships the v2 script set dispatched the same way. The difference is *not* in the dispatch — `EVALSHA`-first,
`EVAL` on `NOSCRIPT`, on the same pooled connection — it is in the scripts themselves: every v2 script declares
every operand key in `KEYS[]`, so the v1 pattern `local jobKey = keyPrefix .. jobId` (`moveToActive-11.lua:148`,
from an ARGV prefix) is gone (D2). The hero figure steps the real two-command sequence over a fixed call.

### The two-way fence

Once a queue is initialised, its `meta.version` is on record. emq.1 ships a boot fence on both directions. A v2
worker reads the queue's `meta.version`: if it sees `bullmq:*` (or `emq:*` keys), it refuses to boot with a typed
error rather than write `emq:{q}:*` keys into a v1 keyspace. A v1 worker, conversely, refuses an
`echomq:2.0.0` keyspace. Neither version contacts the other silently — a mixed deployment fails fast at boot, not
at runtime (INV1). The fence-decision interactive below shows each (worker × keyspace) pairing resolve.

### The migration path

A v1→v2 cutover is not automatic, and emq.1 ships it as an explicit path (D7). The drain-and-switch runbook: stop
producers; drain the v1 queues with v1 workers; start v2. The at-rest key-migration tool rewrites jobs that are not
in flight — `emq:q:*` → `emq:{q}:*`, the job field set preserved modulo the versioned meta. The runbook names what
cannot migrate live: in-flight active jobs hold v1 locks and must drain on v1 workers first. The honesty is the
point — the migration is a procedure, not a silent swap.

### The branded ids

emq.1 ships `EchoMQ.Ext.ID` to mint identifiers for extension state (D4). The id is an integer Snowflake: epoch
2024-01-01, layout `ts(41)<<22 | node(10)<<12 | seq(12)`. Decoding is shift-and-mask — `ts = id >> 22`,
`node = (id >> 12) & 0x3FF`, `seq = id & 0xFFF` — over the verified pair `274557032793636864`, which yields
ts = 65459497641, node = 0, seq = 0.

The wire form is a decimal string; the *branded* form is the 11-char base62 of the integer under the `BAT` namespace.
The codec is the same base62 Snowflake codec the page's build stamp uses, so the verification is direct:
`274557032793636864` base62-encodes to `0KHTOWnGLuC`, and the spec's known pair `TSK0KHTOWnGLuC ⇄ 274557032793636864`
shares that exact 11-char body — `BAT0KHTOWnGLuC` and `TSK0KHTOWnGLuC` differ only at the three-letter namespace edge.
The discipline (INV5): ids cross every boundary as decimal integer strings, branding exists only at the API edge, and
`decode(brand(x)) == x` holds by property. The id figure round-trips a small fixed set to show that identity.

## The triangle

- **The pattern (← redis-patterns R0 / R2):** R0 — scripts load once and dispatch by SHA over a pooled connection;
  R2 — atomicity, every transition pure over `KEYS`/`ARGV`.
- **The implementation spec (⇄ emq.1, drafted — the 2.0 break):** `specs/emq/emq.1.md` — D2 (the declared-keys v2
  script set), D3 (the version bump + two-way fence), D4 (branded ids), D7 (the v1→v2 migration path); INV1 (the
  break is total and versioned), INV4 (the atomicity floor), INV5 (id discipline).
- **The as-built code:** the shipped `EchoMQ.Scripts.execute_raw/4` (the EVALSHA→EVAL dispatch the v2 set rides) and
  `EchoMQ.Version` recording `bullmq:5.65.1` (`version.ex:54`) — the v1 line, present-tense, the line the fork
  freezes at 1.3.0.

The bridge: R0 says scripts load once and dispatch by SHA over a pooled connection. emq.1 ships the v2 script set
dispatched the same EVALSHA→EVAL way the shipped `EchoMQ.Scripts.execute_raw/4` dispatches the v1 scripts today — the
dispatch is unchanged; the break is in the version, the fence, and the declared-keys scripts.

The atomicity floor carries through (INV4): every v2 script is pure over `KEYS`/`ARGV`, with all time passed as an
ARGV millisecond value — no script reads the Redis clock — so every transition stays replayable and testable,
exactly as the v1 scripts are.

## The 2.0 fork

`bullmq:5.65.1` is the v1 line's `meta.version`, frozen at 1.3.0. emq.1 ships the break: `meta.version` becomes
`echomq:2.0.0`, a two-way typed boot fence refuses any cross-version contact, and an explicit drain-and-switch
runbook plus an at-rest key-migration tool carry a deployment over — once, versioned, never silently.

## Recap

emq.1 ships the governance of the break. `EchoMQ.Version` records `echomq:2.0.0` (the v1 line frozen at `1.3.0`,
recording `bullmq:5.65.1` today). A two-way typed boot fence refuses any cross-version contact — a v2 worker against
a v1 keyspace and a v1 worker against a v2 one both fail fast at boot (INV1). An explicit v1→v2 migration path —
drain-and-switch plus an at-rest key-migration tool — carries a deployment over, naming honestly that in-flight
active jobs cannot migrate live. The v2 script set is dispatched the proven way `EchoMQ.Scripts.execute_raw/4`
dispatches the v1 scripts today; the difference is that every v2 script declares every key.

The rung is drafted: `lib/echomq/ext/` and the v2 script set do not exist yet, so every v2 surface here is taught
from `specs/emq/emq.1.md`, written "emq.1 ships …" — never asserted as shipped. `EchoMQ.Scripts.execute_raw/4` and
`EchoMQ.Version` (`bullmq:5.65.1`) are shipped and real, taught in the present tense.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the reference implementation whose wire the v1 line speaks
  (`bullmq:5.65.1`) and the 2.0 break leaves behind.
- Redis — *EVALSHA* (`https://redis.io/commands/evalsha/`) — the run-by-SHA dispatch the v2 set rides, exactly as
  `execute_raw/4` does today.
- Redis — *SCRIPT LOAD* (`https://redis.io/commands/script-load/`) — how a script is cached at init for SHA dispatch.
- Redis — *Documentation* (`https://redis.io/docs/`) — the scripting and data-structure reference under the dispatch.

### Related in this course

- `/echomq/substrate` — E3 · EchoMQ 2.0 (the chapter this dive sits in).
- `/echomq/core` — E2 · The core (the v1 line the fork freezes).
- `/redis-patterns/overview` — R0 · Overview (foundations: load-once, SHA-dispatched scripts).
- `/redis-patterns/coordination` — R2 · Coordination (atomicity, the floor the v2 scripts keep).
