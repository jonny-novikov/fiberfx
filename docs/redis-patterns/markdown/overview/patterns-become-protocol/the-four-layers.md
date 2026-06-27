# The four layers

> Route: `/redis-patterns/overview/patterns-become-protocol/the-four-layers` · Module R0.3 · dive 1 ·
> Grounding: `docs/echo/bcs/content/bcs3.3.md` (the claim script, verbatim) · `bcs3.2.md` (the script is the
> contract) · `bcsA.md` (the connector gate, Valkey) · `docs/echo_mq/emq.design.md` (the layer facts).

Five layers, one boundary. Below the boundary sits the owned protocol — the grammar and the versioned script
bundle; above it, each runtime writes its own connector and API. EchoMQ's machine reads as a stack: **L0**
Valkey, **L1** the grammar and the four sets, **L2** the versioned bundle, **L3** the connector, **L4**
the runtime API. The boundary between L2 and L3 is held by the version fence — a typed boot check, not a pinned
commit. This dive names the layers; the heart of it is one script, quoted verbatim, that carries a whole
transition.

## §1 · Five layers, engine up

**L0 is Valkey** — the engine, external to EchoMQ, and not merely a default: the conformance truth row runs on
Valkey, current stable line, and the committed gate record was taken against live Valkey **9.1.0**. **L1** is
the grammar and the sets: every per-queue key parses as `emq:{q}:<type>`, the job position carries a branded
id, and four sorted sets carry the lifecycle — `pending` (score-zero), `active` (lease-scored), `schedule`
(run-at-scored), `dead`. **L2** is the versioned bundle: six Lua scripts, eight verbs, every key declared in
`KEYS[]` or derived from a declared root.

**L3 is the connector** — per runtime: RESP encoding in one pass, pipelining as the primitive, EVALSHA-first
dispatch that loads a script's source exactly once on a `NOSCRIPT` miss. **L4 is the runtime API** — the eight
verbs a caller uses: `enqueue`, `browse`, `pending_size`, `claim`, `complete`, `retry`, `promote`, `reap`.
L3 and L4 vary per runtime; the layers below them are the owned protocol.

| Layer | Scope | Status |
|---|---|---|
| L4 · runtime API | the eight verbs a caller invokes | varies per runtime |
| L3 · the connector | RESP, pipelining, EVALSHA-first dispatch; reads the fence at every connect | varies per runtime; gated `PASS 8/8` |
| L2 · the bundle | six Lua scripts, eight verbs; declared-or-rooted keys | **owned · versioned behind the fence** |
| L1 · the grammar | `emq:{q}:<type>` · the three-field hash · the four sorted sets | **owned · versioned behind the fence** |
| L0 · Valkey | the engine | external — an enforced conformance gate |

## §2 · One script, one transition — the claim, verbatim

The whole layered argument compresses into one L2 script. The claim script pops the lex-oldest pending id,
increments `attempts`, stamps the lease on the server's clock, and returns the job — atomically, as one unit
(`bcs3.3`, verbatim):

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

Each layer is visible in those ten lines. `ZPOPMIN` off the pending set and `ZADD` onto the active set are L1
moves over the grammar. The script itself is L2 — one atomic transition. The `EVALSHA` call that dispatched it
is L3. And the `claim` verb the caller invoked is L4. The clock is the server's: `TIME` inside the script means
leases never read client skew.

> **Notes on Valkey.** `TIME` inside a write script is sound here: the engine freezes the clock for the
> script's duration and replicates effects rather than the script text, so the lease stamp reads one stable
> now — [valkey.io/topics/replication](https://valkey.io/topics/replication/).

## §3 · What stays the same — the script is the contract

Across runtimes, nothing ports because nothing needs to: **the script is the contract**. The same source string
yields the same SHA1, and any client on any runtime that loads it speaks identical semantics — same pop, same
token mint, same lease arithmetic. What varies is only the plumbing above the boundary: an Elixir connector
pattern-matches typed replies; a Go consumer is a loop around the same EVALSHA calls.

The connector that carries that dispatch is itself gated, against live Valkey (`bcsA`): EVALSHA-first
recorded `script_loads=1` — exactly one `NOSCRIPT` load before the cache served; pipelined EVALSHA ran at
`161192 ops/s`; a `10000-command pipeline returned 1..10000 in order`; the record ends `PASS 8/8`.

**The pattern → its EchoMQ application.** Put the rules that must agree below a boundary and the plumbing that
may differ above it. EchoMQ's claim is one Lua script over the braced grammar — same bytes, same SHA1, same
semantics from any connector; the runtimes differ only in how they dispatch it.

## References

### Sources
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic script execution: a script's effects land together or not at all.
- [Valkey — Replication](https://valkey.io/topics/replication/) — the frozen-time rule that makes `TIME` inside a write script sound.
- [Valkey — Scripting with Lua](https://valkey.io/topics/eval-intro/) — `EVAL`, `EVALSHA`, and the declared-keys discipline the bundle obeys.
- [Redis — Documentation](https://redis.io/docs/) — the sorted-set and hash commands the script composes.

### Related in this course
- [R0.3 · Patterns become protocol](/redis-patterns/overview/patterns-become-protocol) — the module hub.
- [R0.3.2 · The immutable core](/redis-patterns/overview/patterns-become-protocol/the-immutable-core) — the next dive: the owned core and its governance.
- [R0.2 · Valkey under codemojex](/redis-patterns/overview/redis-under-game) — where Valkey sits in the build.
- [/echomq](/echomq) — the protocol in depth: the bundle, rung by rung.
- [/bcs](/bcs) — the architecture the bus is built inside.
