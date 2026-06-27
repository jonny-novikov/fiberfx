# Version tokens — detect AND order a torn write

> Route: `/redis-patterns/coordination/cross-shard-consistency/version-tokens` · Dive R2.04.2 · Source:
> `content/coordination/cross-shard-consistency.md.txt` (slice: *Pattern 2: Version-Stamped Values* + the
> accept-newest recovery rule).
> · Grounding: EchoMQ's applied version token is `attempts` — a monotone counter advanced by `HINCRBY <jobkey>
> attempts 1` in the `@claim` script (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:131`). A worker holding a stale
> `attempts` is refused at `EchoMQ.Jobs.complete/4` / `retry/7` with `EMQSTALE … token mismatch`
> (jobs.ex:143, jobs.ex:177). The protocol version fence is a separate concern — `{emq}:version` → `echomq:3.0.0`,
> claimed by `EchoMQ.Connector` (`echo/apps/echo_wire/lib/echo_mq/connector.ex:33`).

A bare shared token catches a tear but cannot say which side is newer. Pattern 2 stamps each value with a version, so
a mismatch resolves to last-write-wins — accept the higher version, rebuild the lower from it. A wall-clock timestamp
is the cheapest version field, but it orders by clocks and breaks under skew; a monotonic `INCR` counter orders by one
source and resolves correctly every time.

## From detect to order

The shared-token detector from the previous dive returns one bit: the tokens are equal, or they are not. That catches
a torn write, but it is not enough to repair one without help. On a mismatch the tokens alone do not name which write
landed last, so the application has to consult the source of truth to pick a winner. Two random tokens carry no order.

Stamp the values with something ordered and the read gains a second answer. Prefix each value with a version field
ahead of the token:

```
SET user:123:profile  "{timestamp}:{token}:{payload}"
SET user:123:settings "{timestamp}:{token}:{payload}"
```

On read, parse the version off each value. Equal tokens still mean the pair is whole. On a mismatch, the higher
version names the write to keep — accept it, and regenerate the lower-versioned side from it. The tear is still
detected; now it is also ordered.

## Accept newest

A version turns the recovery policy from *consult the source of truth* into *accept newest* — last-write-wins,
resolved at read time with no extra round trip. The source's recovery rule is a single comparison:

```
if profile_version > settings_version:
    regenerate_settings_from_profile()   # profile is newer — keep it, rebuild settings
else:
    regenerate_profile_from_settings()   # settings is newer — keep it, rebuild profile
```

Accept-newest assumes the higher-versioned side is a complete, correct write the lower side can be rebuilt from. Where
both sides hold partial state, the safer recovery is to re-fetch the authoritative source and rewrite both, which the
version does not replace.

## Timestamps order by wall-clock

A wall-clock timestamp is the cheapest version field: every host already has a clock, and minting one needs no extra
call. Its guarantee is only as good as those clocks. Two hosts that disagree by a few hundred milliseconds can stamp
writes in the wrong relative order — a write that truly happened second can carry the *lower* timestamp because the
host that issued it ran behind. Under skew the accept-newest rule then keeps the value written first, which is the
wrong one. Clock skew across a fleet is the normal condition; NTP narrows it but never to zero, and a clock can step
backwards during a correction.

## Monotonic versions with INCR

For ordering that does not depend on any clock, mint the version from one monotonic source. `INCR user:123:version`
returns a counter that rises by exactly one on every call and is served by a single key, so two writes can never
receive the same version and a later write always receives a higher one:

```
version = INCR user:123:version
SET user:123:profile  "{version}:{payload}"
SET user:123:settings "{version}:{payload}"
```

`INCR` is atomic and the value lives on one key, so the order it imposes is total and independent of every host's
clock. The cost is one extra round trip per logical write to fetch the version. The trade is explicit — a timestamp
costs nothing and orders correctly only while clocks agree; an `INCR` version costs one round trip and orders
correctly always.

## The pattern, applied — `attempts` is the version token

EchoMQ does not stamp a free-standing version on its colocated queue keys, because the tear a version would resolve
cannot occur there: a queue's keys share one slot and the move runs as one Lua `EVAL` (the previous dive). But the
same idea — a monotone field that names the current writer — is exactly how EchoMQ fences a stale worker, and it is
real code.

When `EchoMQ.Jobs.claim/3` leases a job, the `@claim` script advances the job's `attempts` field by one with
`HINCRBY` and returns the new value to the worker:

```lua
local att = redis.call('HINCRBY', jk, 'attempts', 1)
redis.call('HSET', jk, 'state', 'active')
...
return {id, redis.call('HGET', jk, 'payload'), att}
```

`attempts` is the **fencing token**: it only ever rises, by one, per claim. A worker carries the `att` it was handed.
When it finishes, `EchoMQ.Jobs.complete/4` runs the `@complete` script (jobs.ex:139), which compares the stored
`attempts` against the token the worker presents:

```lua
local att = redis.call('HGET', KEYS[2], 'attempts')
if not att then return 0 end
if att ~= ARGV[2] then
  return redis.error_reply('EMQSTALE complete token mismatch')
end
```

If a worker's lease expired and the job was re-claimed by another, the row's `attempts` has advanced; the first
worker's token is now stale, and its `complete` is refused with `EMQSTALE complete token mismatch` (the same fence
guards `@retry`, jobs.ex:177). That is "detect-and-order" applied to a queue: the higher `attempts` is the current
holder, the lower one is the stale writer, and the engine resolves the conflict by rejecting the stale side rather
than silently overwriting.

The protocol's own version fence is a different number on a different key: `{emq}:version` → `echomq:3.0.0`, claimed
or verified by `EchoMQ.Connector` before the first command (`connector.ex:33`). It guards the protocol, not a single
job; the in-depth treatment of both belongs to the dedicated EchoMQ course.

Where the application-level version stamp from this dive earns its place is the write that colocation cannot cover: a
single logical update that spans two systems — a Valkey read-model and codemojex's database of record.
Those keys live in different stores by definition, so no hash tag can put them on one slot, and a crash between the
two writes leaves them disagreeing. A version field on each side turns that into accept-newest.

## References

### Sources
- [Redis — INCR](https://redis.io/commands/incr/) — the atomic monotonic counter; `INCR user:version` mints a version
  that orders writes correctly regardless of any host's clock.
- [Valkey — INCR](https://valkey.io/commands/incr/) — the engine's own atomic increment; the same monotone source
  EchoMQ's `HINCRBY attempts` fence is built on.
- [Redis — SET](https://redis.io/commands/set/) — the per-value stamped write `SET key "{version}:{payload}"`.
- [Redis — Cluster specification](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/) — hash
  tags, the 16384 slots, and `CROSSSLOT` for multi-key commands that span slots.

### Related in this course
- [R2.04 · Cross-shard consistency](/redis-patterns/coordination/cross-shard-consistency) — the module hub: all four
  detection patterns and the prevention comparison.
- [R2.04.1 · Torn writes](/redis-patterns/coordination/cross-shard-consistency/torn-writes) — the previous dive: the
  bare shared token this version field upgrades.
- [R2.04.3 · Commit markers](/redis-patterns/coordination/cross-shard-consistency/commit-markers) — the next dive: the
  visibility gate, which composes with a version field.
- [/echomq/protocol](/echomq/protocol) — the dedicated EchoMQ course: the `attempts` fence and the version fence in depth.
- [/elixir · CQRS](/elixir/pragmatic/cqrs) — the single-writer engine that serializes a read-model against the
  database of record.
