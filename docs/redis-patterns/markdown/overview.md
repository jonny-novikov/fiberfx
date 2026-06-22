# R0 · Overview — Redis Patterns Applied, to the BCS architecture

> Route: `/redis-patterns/overview` (chapter landing) · Source of structure: the R0 orientation spec
> (`specs/overview/`) + the TOC · Grounding: the BCS build — EchoMQ backed by Valkey, EchoCache in front
> (`docs/echo/bcs/content/`). Reframed under [`specs/reframe-echomq/`](../specs/reframe-echomq/reframe-echomq.md).

Orientation before the patterns. The running system is the BCS build: **EchoMQ** backed by **Valkey**, Valkey
under the hood, **EchoCache** in front. One Valkey carries two surfaces — the EchoMQ bus behind the braced
`emq:{q}:` keyspace, and the EchoCache near-cache reading through an L1 of ETS tables — and the two surfaces
ground the two halves of the catalog. Two orientation modules set that up before the pattern chapters begin.

## The seam, retold — two surfaces over one Valkey

One Valkey — `9.1.0`, listening on `:6390` in the committed record (`bcsA.md`) — carries two surfaces, and the
two surfaces ground the two halves of the catalog.

**The EchoMQ bus.** EchoMQ owns its protocol: the braced `emq:{q}:` keyspace, jobs as entities, and a Lua state
machine. The committed key map reads `emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs | {emq}:version |
{emq}:locks -- 17 bytes before the payload` (`bcs3.1.md`). A job's row is a hash of three fields (`bcs3.2.md`);
four sorted sets per queue carry the lifecycle — `pending` score-zero, `active` scored by lease deadline,
`schedule` scored by run-at, `dead` score-zero — and every transition is a single atomic script (`bcs3.3.md`).
The coordination, queue, time, streams, and flow families (R2–R6) and the operations chapter (R8) ground here.

**The EchoCache near-cache.** EchoCache is "branded keys, local speed, bus-driven coherence" (`bcs4.md`): an L1
of declared ETS tables in front of the shared L2 Valkey. The committed figure: `1311621 hit reads per second
(762 ns each)` against `31 us per L2 GET` on the same wire — the L1 hit is `40 times cheaper` than the round
trip it replaces (`bcs4.1.md`). The caching family (R1) and the R7 read-models ground here.

> **Notes on Valkey.** Hash tags force every key sharing a braced tag into one CRC16-mod-16384 cluster slot —
> `pending, active, meta, and the job row of {orders} all answer slot 105; {fills} answers 4165` (`bcs3.1.md`) —
> which is what keeps every multi-key EchoMQ script single-slot legal. Source:
> [valkey.io/topics/cluster-spec](https://valkey.io/topics/cluster-spec/).

## Pick a surface

The split is the catalog's map. The read path grounds in EchoCache; the bus families ground in the `emq:{q}:`
keyspace and its scripts. Each chapter names its surface up front.

- **The EchoMQ bus** — the braced `emq:{q}:` keyspace; a job row is a hash of three fields, moved across four
  sorted sets, every transition a single script. Committed: `emq:{orders}:job:ORD0NgWEfAEJfs`, 17 bytes of
  grammar before the payload. Grounds R2–R6 and R8. (bcs3.1–3.3)
- **The EchoCache near-cache** — an L1 of declared ETS tables over the shared L2 Valkey. Committed: `1311621`
  hit reads per second (`762 ns` each) against `31 us` per L2 GET — the L1 hit is 40 times cheaper than the
  round trip it replaces. Grounds R1 and the R7 read-models. (bcs4.1)

## The fence, and the door

Before a single pattern runs, the keyspace states which protocol it speaks. The version fence lives at
`{emq}:version` — the one key that is about the deployment rather than about any queue — and the connector reads
it on every connect, first boot and every reconnect, refusing to serve against any other value. The committed
read is self-referential — it travels through a connection that could not exist had the fence not held:

```
GET {emq}:version              answers echomq:2.0.0   ← through the fenced connector itself
rung record                    PASS 5/5
```

(`content/bcs3.1.md`, frozen.) The wire string is the only place the version number appears; the protocol is
named **EchoMQ**. Its depth — the full keyspace grammar, the script inventory, conformance on Valkey — is the
dedicated course on the far side of this door: [/echomq](/echomq).

## The R0 modules

Two orientation modules set up the grounding the pattern chapters reuse.

| Module | Title | What it sets up |
| --- | --- | --- |
| R0.2 | Valkey under the Exchange Platform | The placement — the two roles Valkey plays below the one owned wire facade (`EchoWire`) the Exchange Platform calls: the EchoMQ bus and EchoCache. Dives: the facade seam · the two roles · the reserved tier. |
| R0.3 | Patterns become protocol | The four-layer model and the immutable core — why the data model is the contract, and the door to the EchoMQ course. Dives: the four layers · the immutable core · the door to EchoMQ. |

## Up next — the pattern chapters

The eight pattern chapters, sequenced along the EchoMQ build. Each opens with its use cases and closes with a
workshop that builds one slice of the BCS Redis tier: R1 Caching → R2 Coordination → R3 Reliable Queues → R4
Time, Delay & Priority → R5 Streams & Events → R6 Flow Control → R7 Data Modeling → R8 Production & Operations.
R1–R4 link through; R5–R8 are specified and link through when their chapters ship.

## References

### Sources
- [Redis — Documentation](https://redis.io/docs/) — the command and data-type reference behind the catalog.
- [Valkey — Topics](https://valkey.io/topics/) — the engine the EchoMQ connector is gated against.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — hash slots, CRC16 mod 16384, and hash tags as the same-slot mechanism behind the co-location law.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — EVALSHA and atomic scripts, the discipline the bus rides.
- [llmstxt.org — The llms.txt convention](https://llmstxt.org/) — the machine-readable map format the course follows.

### Related in this course
- [Course home](/redis-patterns) — the full chapter→module map.
- [R1 · Caching](/redis-patterns/caching) — the read path; grounds in EchoCache.
- [R0.2 · Valkey under the Exchange Platform](/redis-patterns/overview/redis-under-portal) — the placement, in detail.
- [/echomq](/echomq) — EchoMQ, the protocol in depth — the far side of the door.
- [/bcs](/bcs) — the Branded Component System — the architecture these patterns run inside.
