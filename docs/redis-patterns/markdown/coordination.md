# R2 · Coordination & Consistency — atomicity first

> Route: `/redis-patterns/coordination` (chapter landing) · Source of structure: the chapter spec
> `specs/coordination/coordination.md` + the TOC · Grounding: EchoMQ's inline Lua transitions, the claim lease and
> its `attempts` fencing token, and the braced `emq:{q}:` keyspace (`echo/apps/echo_mq`). The first chapter with a
> `→ EchoMQ` door.

The foundation every later chapter builds on: a reliable queue is made of atomic moves and a lock lease. Five
patterns for getting concurrent access right — atomic read-modify-write, distributed locking, the Redlock contrast,
cross-shard consistency, and hash-tag co-location — grounded in EchoMQ's real code, closing by making an Exchange
Platform order placement atomic across runtimes.

## Why & when

Concurrency breaks data in quiet ways: two writers read-modify-write the same key and one update vanishes; a job
meant for one worker runs on three; a multi-key change lands half-applied across cluster slots. Coordination is the
discipline of making concurrent access correct — an atomic operation that admits no interleaving, a lock that admits
one holder, or a key layout that keeps related data together.

- **Lost update** — two writers read-modify-write one key and an update disappears → one inline Lua move (R2.01).
- **One worker at a time** — a claimed job must run on exactly one node → the claim lease (R2.02).
- **Surviving a failover** — a lock that must outlive a node failure → Redlock's majority-of-N, weighed against its cost (R2.03, contrast).
- **Multi-key on a cluster** — related keys that must change together → hash-tag co-location (R2.05).

## The patterns

| Module | Pattern | Grounding |
| --- | --- | --- |
| R2.01 Atomic updates | `atomic-updates` | every EchoMQ state move is one inline Lua script (`EchoMQ.Script.new/2` run EVALSHA-first; `EchoMQ.Jobs.enqueue`/`claim`/`complete`) |
| R2.02 Distributed locking | `distributed-locking` | the claim lease (`ZADD active now+lease_ms`) + `attempts` (`HINCRBY`) as the fencing token; `EMQSTALE` on a stale token |
| R2.03 The Redlock algorithm | `redlock` *(contrast)* | a majority-of-N lock vs EchoMQ's single-Valkey lease |
| R2.04 Cross-shard consistency | `cross-shard-consistency` | a multi-key Lua EVAL requires one slot; `attempts` the monotone version token |
| R2.05 Hash-tag co-location | `hash-tag-colocation` | `EchoMQ.Keyspace.queue_key` → `emq:{q}:*`; `slot/1` = CRC16 mod 16384 (vector `12739`) |
| R2.06 Workshop | — | make an Exchange Platform order placement atomic across runtimes |

## How to apply

Match the coordination primitive to the failure you are guarding against:

- **Read-modify-write** → atomic updates: one inline Lua script run EVALSHA-first, so no client interleaves — the way every EchoMQ transition moves a job.
- **One worker at a time** → distributed lock: the claim leases the job to one worker (`ZADD active now+lease_ms`); `attempts` is the fencing token, so a holder whose lease lapsed is refused at complete.
- **Survive a node failure** → Redlock (contrast): a majority of N independent masters; heavier and contested — EchoMQ's single-Valkey lease is enough for most.
- **Detect a torn write** → cross-shard consistency: keep every key of one change on one slot so a multi-key Lua EVAL is atomic; `attempts` is the monotone version token a stale writer fails against.
- **Multi-key on a cluster** → hash-tag co-location: the braced `{q}` hashtag forces related keys to one slot so multi-key Lua stays legal.

## The workshop

R2.06 makes an Exchange Platform order placement atomic across runtimes: `Exchange.Gateway.parse_place/1` turns an
untrusted request into a typed place command, minting a branded `ORD` id at acceptance; the order is then admitted
onto the `{orders}` queue as one inline Lua script — a kind check, a duplicate refusal, the row write, and the
pending insertion happening on the server in one atomic step. It is idempotent on retry, never a torn write, and
needs no lock and no Redlock because the script is the serialization.

**→ EchoMQ.** Coordination is where the EchoMQ grounding begins. The atomic-Lua transaction model is the heart of
EchoMQ's protocol; the full Lua bundle, the EVALSHA / NOSCRIPT dispatch, and the worker-side lock plane belong to the
dedicated EchoMQ course this chapter opens the door to.

## References

### Sources
- [Redis — Distributed locks](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) — SET NX PX locking, fencing tokens, and Redlock.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — atomic multi-key transitions via EVAL / EVALSHA, the way every EchoMQ move runs.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — CRC16 mod 16384 slots and the `{hashtag}` that co-locates a queue's keys.
- [Salvatore Sanfilippo — Is Redlock safe?](https://antirez.com/news/101) — the Redis creator's defence of Redlock.

### Related in this course
- [R1 · Caching](/redis-patterns/caching) — the previous chapter.
- [R0.2 · Valkey under the Exchange Platform](/redis-patterns/overview/redis-under-portal) — the EchoMQ bus these patterns ground in.
- [EchoMQ — the protocol](/echomq) — the atomic-Lua transaction model, taught in depth.
- [The Branded Component System](/bcs) — Part III builds the branded EchoMQ bus these patterns apply.
