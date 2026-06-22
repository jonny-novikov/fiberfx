# The reserved tier

> Route: `/redis-patterns/overview/redis-under-portal/reserved-tier` · Module R0.2 · dive 3 · Source:
> ORIENTATION — the placement module, no single pattern source · Grounding: `docs/echo_mq/emq.roadmap.md` (the
> program) · `docs/echo_mq/emq.design.md` (the protocol canon) · `docs/echo/bcs/content/bcs3.3.md` (the claim
> script) · `bcs3.1.md` + `bcsA.md` (the slot figures) — every figure verbatim from a committed record. Reframed
> under [`specs/reframe-echomq/`](../../../specs/reframe-echomq/reframe-echomq.md).

The tier this module once placed in reserve is no longer a reservation. **EchoMQ is shipped, owned-protocol
code**: `echo/apps/echo_mq`, the BCS 2.0 Valkey-native bus — born braced (`emq:{q}:`), born branded (`JOB` ids
gated at the key builder), born declared (every Lua key declared or grammar-derived) — and it is **the
convergence target** of the EchoMQ program: one program, three movements, all EchoMQ code converging in that one
app. This dive retells the tier as it now stands, works the bus's defining move — the real `claim` script — and
opens the doors to the courses that teach the protocol and the architecture in depth.

## §1 · The tier, built

The earlier life of this page held a seat open: a multi-runtime layer the platform reserved for a bus to grow
into. The program has since filled the seat with code. `echo/apps/echo_mq` is the bus — `EchoMQ.*`, lib-only,
version `2.0.0` — re-derived from first principles by the Branded Component System and shipped as measured,
rung-gated code.

The fork behind it was ruled to happen exactly once. The v1 line carried two structural flaws that rode its wire
and could not be fixed under compatibility — operand keys built from an `ARGV` prefix inside script bodies, and
an open keyspace with no total parse — so the line froze, and the new bus was born under the v2 laws instead of
patched toward them. EchoMQ broke from that v1 line, now frozen at `1.3.0`. That frozen line,
`echo/apps/echomq`, is the program's **push source**: its capability surface is absorbed over the program's
movements, and the app dissolves when the movements complete.

The tier also has a named tenant now. **The Exchange Platform** (`docs/exchange/`) is the program's named
consumer: its specification records settlement, notifications, end-of-day reporting, and reconciliation as
`EchoMQ.Jobs` work drained by `EchoMQ.Consumer` and shaped by `EchoMQ.Lanes`.

## §2 · One atomic move, the real one

The defining move of the bus is claiming the next job to work, and the script is committed in `bcs3.3` —
quoted verbatim:

```lua
local popped = redis.call('ZPOPMIN', KEYS[1])
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id
local att = redis.call('HINCRBY', jk, 'attempts', 1)
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
return {id, redis.call('HGET', jk, 'payload'), att}
```

One script, one claim: `ZPOPMIN` pops the lex-oldest pending id — score-zero means lex order is mint order —
`HINCRBY` increments `attempts`, `HSET` marks the row `active`, and `TIME` stamps a lease on the *server's*
clock into the lease-scored `active` set. Atomic execution means the pop, the increment, and the lease land
together or not at all.

The quiet center is one integer doing two jobs: the `attempts` counter, incremented inside the claim, **is the
fencing token** every other transition verifies. The committed record stages both sides: a right-token
`complete with the right token retires the row -- nothing remains`, while an impostor's stale token earns
`EMQSTALE; the lease holder's work survives the zombie's complete`. A job's second life through the schedule
reads `one job, two lives, one counter` — the same integer counts the attempts and fences each life against the
last.

> Notes on Valkey · The clock inside the script is the server's: `TIME` reads a frozen value for the script's
> duration, and scripts replicate by effects — which is what makes a server-clock lease inside a write script
> sound, immune to client skew ([valkey.io/topics/replication](https://valkey.io/topics/replication/)).

## §3 · One queue, one slot, by grammar

The claim script touches two keys — the pending set and the active set — plus the job row built from a declared
prefix. What makes that multi-key move legal forever is the grammar: the hashtag *is* the queue name, so every
key of one queue answers one cluster slot. The committed line from `bcs3.1` F5 reads: `pending, active, meta,
and the job row of {orders} all answer slot 105; {fills} answers 4165`. The connector gate in `bcsA` holds the
same arithmetic client-side — `slot 105 == 105` against `8507` for the payments queue, with the CRC16
specification vector answering `12739`. Per-queue transition scripts are single-slot legal on the clustered day
by grammar, not by review.

## §4 · The protocol is the contract

The reason one bus serves more than one runtime is not a port. It is that **the protocol is the contract**: the
closed `emq:{q}:<type>` grammar plus the atomic Lua bundle. The same source string yields the same SHA1, and any
client on any runtime that loads it speaks identical semantics — the same pop, the same token mint, the same
lease arithmetic. A Go consumer is a loop around the same `EVALSHA` calls the Elixir reference makes (`bcs3.3`);
the program roadmap names a Go sibling in its cross-runtime fleet, and a Node runtime is strictly proposed —
not asserted.

**The pattern → its EchoMQ application.** Reserve a seam for the bus, then fill it with a contract rather than a
codebase: a closed grammar and a script bundle any conforming runtime can load. In the BCS build that is EchoMQ
at `echo/apps/echo_mq` over Valkey — the convergence target the program extends rung by rung, with the Exchange
Platform draining it.

## §5 · The doors

This closes R0.2. The depth on the far side is taught by two courses, both live routes:

- **/echomq** — the protocol, in depth. The program builds the extension ladder rung by rung: emq.0 lands the
  BCS migration; emq.1 (specced) is the scheduler + retry vocabulary; the families beyond — the migration path,
  parent/flow, groups, batches, lifecycle controls, the cache deepened, conformance — are planned.
- **/bcs** — the Branded Component System: the architecture the bus shipped inside, every figure from a frozen
  transcript.

## References

### Sources
- [Redis — ZPOPMIN](https://redis.io/commands/zpopmin/) — the pop that claims the lex-oldest pending id.
- [Redis — HINCRBY](https://redis.io/commands/hincrby/) — the increment that mints the `attempts` fencing token.
- [Valkey — Replication](https://valkey.io/topics/replication/) — the frozen-`TIME` rule and effects replication behind the server-clock lease.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic script execution: the pop, the increment, and the lease land together or not at all.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — hash slots, CRC16 modulo 16384, and hash tags as the same-slot mechanism.

### Related in this course
- [R0.2 · Valkey under the Exchange Platform](/redis-patterns/overview/redis-under-portal) — the module hub; the pager loops back here.
- [R0.2.2 · The two roles](/redis-patterns/overview/redis-under-portal/two-roles) — the previous dive; the bus role.
- [R0.3 · Patterns become protocol](/redis-patterns/overview/patterns-become-protocol) — the next module; why the contract holds for any runtime.
- [/echomq](/echomq) — the protocol in depth, rung by rung.
- [/bcs](/bcs) — the architecture, with the frozen transcripts.
