# R2.01 · Atomic updates — read-modify-write without a race

> Module hub · route `/redis-patterns/coordination/atomic-updates`
> Grounding: `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`enqueue/4` → the `@enqueue` script) ·
> `echo/apps/echo_wire/lib/echo_mq/script.ex` (`Script.new/2`) · `echo/apps/echo_wire/lib/echo_mq/connector.ex`
> (`eval/5`, EVALSHA-first, `@wire_version "echomq:2.0.0"`) · committed figures `docs/echo/bcs/content/bcs3.2.md`,
> `bcsA.md`. Engine: Valkey.

Ensure data integrity with atomic read-modify-write operations using WATCH/MULTI/EXEC for optimistic locking, Lua
scripts for complex logic, and shadow-key patterns for safe bulk updates.

A read-modify-write is two clients away from a lost update: each reads the same value, each writes its own answer,
and one write quietly overwrites the other. Redis offers tools that close that gap — a watched transaction, a Lua
script, and an atomic swap. EchoMQ moves a job between states with the second of them: every transition is one
inline Lua script, declared with `EchoMQ.Script.new/2`, run **EVALSHA-first** by `EchoMQ.Connector.eval/5`. The
whole read-modify-write happens on the server in one step and cannot interleave. That is where this chapter starts:
with the move that cannot be torn.

## The lost update

Two clients withdraw from one account. Each runs `GET balance`, subtracts its amount, and runs `SET balance`. With
a starting balance of 100 and two withdrawals of 30, the correct end is 40. But if the two interleave — both read
100 before either writes — the second `SET` overwrites the first, and the account ends at 70. One withdrawal is
gone, and no error was raised.

The fix is not a faster client; it is an indivisible move. Make the read and the write happen as one unit and
nothing can interleave between them.

## Pattern 1: Optimistic locking with WATCH

`WATCH` gives check-and-set semantics. A client watches a key, reads it, opens a `MULTI`/`EXEC` block, and queues
its writes. If any watched key changes between the `WATCH` and the `EXEC`, the transaction aborts — `EXEC` returns
nil — and the client retries the whole read-modify-write. It is optimistic: it holds no lock and assumes no
conflict, paying only when a conflict actually lands.

```
WATCH account:123:balance
balance = GET account:123:balance
MULTI
SET account:123:balance <balance - 100>
EXEC                                  # nil if balance changed since WATCH -> retry
```

A retry loop bounds the attempts (`max_retries`) and raises a conflict error if it runs out. **Multi-key WATCH**
watches several keys for one update across them — `WATCH inventory:sku123 order:456:status`, then `DECRBY` the
stock and `SET` the order status in the same `EXEC`. On a cluster all watched keys must sit on one slot; a hash tag
co-locates them. The first dive walks the loop and the multi-key case.

**Be honest about the applied form.** EchoMQ does not use `WATCH`/`MULTI`/`EXEC` for its state transitions. It
replaced the optimistic-locking loop with a single Lua script: one round trip, no retry. WATCH is taught here as
the contrast.

## Pattern 2: Lua scripts for atomic logic

A Lua script runs atomically — no other command runs between the script's start and its end. That removes the
retry loop entirely: the conditional check, the reads, and the writes happen as one indivisible unit. A
compare-and-set is four lines; an atomic transfer reads a balance, checks it, then runs `DECRBY` and `INCRBY`
across two keys; a conditional update writes a value and appends an audit record in the same call.

```lua
-- compare-and-set: set only if the current value matches the expected one
if redis.call('GET', KEYS[1]) == ARGV[1] then
  redis.call('SET', KEYS[1], ARGV[2])
  return 1
end
return 0
```

This is the tool a busy queue reaches for, because its state moves are conditional and span several keys. The
script becomes the lock — the second dive grounds this hardest in EchoMQ's real code.

### How EchoMQ admits a job — one atomic script

EchoMQ's admission law is one inline Lua script. `EchoMQ.Jobs.enqueue/4` runs `@enqueue` through
`EchoMQ.Connector.eval/5`: a kind check, an `EXISTS` duplicate refusal, the row write, and the pending insertion
land on the server in one atomic step or not at all.

```lua
-- @enqueue (echo_mq/lib/echo_mq/jobs.ex:14) — admit by kind, refuse duplicates, write the row + pending entry.
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

The script declares both keys it touches — `KEYS[1]` the job row, `KEYS[2]` the pending set — in KEYS; ARGV carries
values only. That is the v2 law (`EchoMQ.Script.new/2`): every key a script touches is declared. Because both keys
share the `{orders}` hashtag (`EchoMQ.Keyspace.queue_key/2` braces the queue), they land on one slot, so the
multi-key write is single-slot legal by grammar — no `CROSSSLOT`.

The committed manuscript record reads the keyspace verbatim: `emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs
| {emq}:version | {emq}:locks -- 17 bytes before the payload` (`docs/echo/bcs/content/bcs3.1.md`), and the wire
class is `an ORD id in the job position answers EMQKIND on the wire -- the key let it pass, the law did not`
(`bcs3.2.md`).

## Pattern 3: Shadow key + RENAME

To replace a large, multi-field value without a concurrent read landing on a half-written state, build the new
value in a temporary key, then swap it in with one atomic `RENAME`. `RENAME` is atomic: a concurrent read returns
either the old complete value or the new complete value, never a partial one.

```
DEL tmp:user:123:cache
HSET tmp:user:123:cache field1 value1
HSET tmp:user:123:cache field2 value2
HSET tmp:user:123:cache field3 value3
RENAME tmp:user:123:cache user:123:cache   # the swap is all-or-nothing
```

`RENAME` preserves the source key's TTL; `EXPIRE` after the rename sets a fresh one, or `COPY … REPLACE` copies in
place. Both keys of a `RENAME` or `COPY` must share a slot. The third dive pairs this with **bulk admission** —
`EchoMQ.Jobs.enqueue_many/3`, which loads the `@enqueue` script once with `SCRIPT LOAD` and then pipelines
`EVALSHA` per item, with per-item verdicts (`:enqueued`, `:duplicate`, `{:error, :kind}`) returned in input order.

## Pattern 4: Idempotency keys

`SET idempotency:{request_id} "processing" NX PX …` runs an operation exactly once: the first caller takes the key,
a later duplicate finds it set and returns the stored result instead of re-running the work. EchoMQ folds the same
idea into `@enqueue` directly: the `EXISTS` check returns 0 on a duplicate, so a producer can fire the same enqueue
twice on any doubt and the second call answers `:duplicate` without touching the row.

## Pattern 5: Increment with bounds

A short Lua script caps a counter at a maximum (`math.min(current + n, max)`) or refuses a decrement that would
drop below zero, so a bounded counter stays correct under concurrency. EchoMQ's own monotone counter is the
`attempts` field — incremented with `HINCRBY` inside the claim script, never decremented, so it is the fencing
token every later transition verifies.

## Pattern 6: SET … GET / GETDEL / GETEX

Get-and-modify in one round trip: read-and-replace, read-and-delete, and read-and-re-expire, each a single atomic
command rather than a read followed by a separate write.

## Pattern 7: List rotation

`LMOVE source destination RIGHT LEFT` (and the blocking `BLMOVE`) pops from one list and pushes to another
atomically — the backbone of a reliable queue, which R3 builds on.

## When to use each

The choice turns on contention and shape. A single-key check-and-set is a Lua one-liner or `SET … GET`; a
same-slot multi-key update is `WATCH` with a retry; conditional or multi-step logic is a script, where the script
is the lock.

| Scenario | Pattern |
|---|---|
| Simple CAS on one key | `SET … GET` or a Lua script |
| Multi-key transaction (same slot) | `WATCH` + `MULTI`/`EXEC` |
| Complex conditional logic | a Lua script |
| Large value replacement | shadow key + `RENAME` |
| Request deduplication | idempotency keys |
| Counter with bounds | a Lua script |
| Queue operations | `LMOVE` / `BLMOVE` |

## The three dives

Each dive takes one of the three tools, in the source's order: optimistic locking with a retry loop, the whole
transition as one script, and the atomic swap with bulk writes.

- **R2.01.1 · WATCH / MULTI / EXEC** — optimistic locking: watch a key, read it, queue the write, and on a
  conflicting change retry the loop; the account-balance and multi-key inventory cases. The contrast EchoMQ
  replaced with one Lua script.
- **R2.01.2 · Lua for logic** — the whole transition as one Lua script, no interleaving, no retry — the real
  `@claim` / `@complete` / `@retry` branching scripts (`ZPOPMIN` + conditional `HINCRBY` + dead-letter past max
  attempts), and the `EVALSHA → NOSCRIPT → SCRIPT LOAD` dispatch.
- **R2.01.3 · Shadow key + bulk** — build the new value in `tmp:` then atomic `RENAME`; admit many jobs in one wire
  flush with `EchoMQ.Jobs.enqueue_many/3` — `SCRIPT LOAD` once, then pipelined `EVALSHA`.

### Bridge — the pattern, and its echo_mq application

| The pattern | Its EchoMQ application |
|---|---|
| A read-modify-write across several keys must be one indivisible move. WATCH/MULTI/EXEC, a Lua script, and an atomic swap are the three tools. | Every state transition is **one inline Lua EVAL** — `EchoMQ.Jobs.enqueue/4` runs `@enqueue` through `EchoMQ.Connector.eval/5`, EVALSHA-first, every key declared in KEYS. No watch, no retry loop. |

The take: Redis offers three atomic read-modify-write tools; EchoMQ chose the single Lua EVAL per transition, and
proves the pattern is real.

### Door — the EchoMQ course

This module cites one excerpt — the `@enqueue` script — as proof the pattern ships. The full transition bundle
(`@claim` / `@complete` / `@retry` / `@promote` / `@reap`), the EVALSHA/NOSCRIPT dispatch internals, and the
`echomq:2.0.0` version fence are the subject of the dedicated **EchoMQ course** at `/echomq`. The Exchange Platform
consumer (`echo/apps/exchange`) is the worked application: `Exchange.Gateway.parse_place/1` mints a branded `ORD`
id at acceptance, and the order is admitted onto the `{orders}` queue as that one atomic script.

After R2.01, the Coordination chapter continues with distributed locking, the Redlock contrast, cross-shard
consistency, and hash-tag colocation, closing with a workshop that makes an Exchange Platform order placement
atomic across runtimes.

## References

### Sources

- [Redis — Transactions](https://redis.io/docs/latest/develop/interact/transactions/) — how `MULTI`/`EXEC` batches
  commands and how a watched-key change aborts the transaction.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — why a
  script runs atomically and how the `EVALSHA` SHA1 cache works.
- [Valkey — EVALSHA](https://valkey.io/commands/evalsha/) — run a cached script by its SHA1; the dispatch
  `EchoMQ.Connector.eval/5` runs EVALSHA-first against.
- [Valkey — SET](https://valkey.io/commands/set/) — the `NX`/`PX`/`GET` options behind idempotency keys and
  single-key CAS.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — hash tags keep a queue's multi-key
  script on one slot; CRC16 mod 16384.

### Related in this course

- R2.01.1 · WATCH / MULTI / EXEC — optimistic locking, the contrast.
- R2.01.2 · Lua for logic — the script is the lock.
- R2.01.3 · Shadow key + bulk — atomic swap, atomic batch admission.
- R2 · Coordination & Consistency — the chapter.
- R1 · Caching — the prior chapter.
- `/echomq` — the EchoMQ protocol, where the transition bundle is taught in depth.
- `/elixir` — the functional-Elixir & OTP craft behind the echo umbrella.
