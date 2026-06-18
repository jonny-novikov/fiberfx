# The door & the BCS family

> Route: `/echomq/overview/the-door` · Overview dive 3 (the *where*) · md source-of-record.
> Discipline: as-shipped (no version labels); extract-and-annotate (no `file:line`); `[RECONCILE]` in md only;
> no-invent (never the frozen `echo/apps/echomq` tree).

## The fact

EchoMQ does not sit on its own. It is the far side of a **door** from the **Redis Patterns Applied** course, and it
is the **wire underneath the BCS family of systems**. This dive places EchoMQ in that web: where its readers arrive
from, what owning the Queue, the Bus, and the Cache hands to the systems built on it, and how to read the rest of the
course.

The course you are in teaches the **system in depth**. The course next door — `/redis-patterns` — teaches each Redis
**pattern** applied, proves it with one real excerpt, then **doors here** for the system that runs the pattern at
depth. Read as a graph: every `→ EchoMQ` door in Redis Patterns Applied lands on a pillar in this course. This course
is the destination of all of them.

## The bidirectional door

The single source of truth for how the two courses link is the canonical edge table
`docs/redis-patterns/redis-patterns.echomq-doors.md`. It is **bidirectional**: every forward `R → EchoMQ` door has a
matching `EchoMQ ← R` reverse-link, and when a page and the map disagree, the map wins. As the pillars land, the doors
re-point to the **named pillar routes** — a caching chapter doors to the Cache; a reliable-queue chapter doors to the
Queue; a streams-and-events chapter doors to the Bus.

The door maps a **pattern** to the **pillar** that applies it:

| Redis Patterns chapter | The pillar it doors into | Why |
|---|---|---|
| Caching (R1) | the **Cache** | cache-aside, write-through, stampede control → the real L1/L2 near-cache |
| Coordination (R2) | the **Protocol** | atomic updates and locks → the atomic Lua / EVALSHA substrate |
| Reliable queues (R3) | the **Queue** | the wait → active → done → recover lifecycle → the worker loop |
| Time, delay & priority (R4) | the **Queue** | delay, promote, backoff-retry, intra-group priority → lifecycle + lanes |
| Streams & events (R5) | the **Bus** | event fan-out and a replayable log → pub/sub and the event log |
| Flow control & scale (R6) | the **Queue** | rate-limiting, fair lanes, batches → lanes + batches |
| Data modeling & memory (R7) | the **Protocol** | the job hash and its compressed fields → the owned data layer |
| Production & operations (R8) | the **Proof** | operating the tier at scale → conformance, telemetry, benchmark |

A door is a teaching hand-off, not a grounding claim: a Redis Patterns chapter can ground its excerpt in one system
yet door here for the system that applies the pattern in depth.

[RECONCILE: the R5 → Bus edge resolves a *replayable* event log. The Bus's pub/sub (`EchoMQ.Events`) is as-built in
`echo/apps/echo_mq`; the retained, replayable event log it doors into (append == mint order, read at offset,
time-travel) is CANON, grounded in `emq.roadmap.md` §"EchoMQ 3.x — the stream tier" + `emq3.specs.md` — not yet on
disk. The HTML names the Bus as shipped; sweep when the stream tier lands.]

## What the BCS family inherits

EchoMQ is the bus of the **Branded Component System** — the architecture taught in `/bcs`. A BCS system is a set of
components that talk only through branded identity over an owned wire. EchoMQ is that wire. Building a system on BCS
means the three pillars are already there:

- **The Queue is there.** Work distributes without a job framework. A producer calls `EchoMQ.Jobs.enqueue/4`; a
  consumer claims with `EchoMQ.Consumer` (lease default `30_000` ms) and the one-job-one-worker contract holds
  atomically in Lua. Fair lanes (`EchoMQ.Lanes`) and the full lifecycle are part of the wire, not bolted on.
- **The Bus is there.** Components broadcast signals over `EchoMQ.Events.subscribe/2` and `publish/5` on
  `emq:{queue}:events`, and a retained event log lets a late subscriber replay what it missed. [RECONCILE: the
  replayable event log is CANON (`emq.roadmap.md` §stream tier + `emq3.specs.md`); pub/sub is as-built. Reads as
  shipped in the HTML.]
- **The Cache is there.** Read-heavy components serve from a near-cache — `EchoStore.Table.fetch/3` /
  `put/3` — with single-flight and coherence by mint time, so a hot read does not become a hot key.

The worked consumer that rides the pillars is **codemojex** (`echo/apps/codemojex`) — a code-breaking game that
enqueues per-player guesses on `EchoMQ.Lanes`, drains them with `EchoMQ.Consumer`, broadcasts results over
`EchoMQ.Events`, and settles prizes on a second queue, all over the one wire. It is the proof that a real system
needs no other infrastructure between its components.

## How to read the course

The six sections fall into three arcs:

1. **The foundation** — the **Overview** (you are here) and the **Protocol**. The Overview frames the system; the
   Protocol teaches the substrate all three pillars share: the owned `emq:{q}:` keyspace, the record hash, the Lua
   layer, immutability and branded ids.
2. **The three pillars** — the **Queue** (distribute work), the **Bus** (broadcast signals + the event log), and the
   **Cache** (serve reads). Read the Protocol first, then take the pillar you need.
3. **The proof** — the **Proof** chapter shows the whole system holds: the conformance suite, telemetry and tracing,
   the benchmark gate.

The Queue, the Bus, the Cache, and the Proof are on the build front; the Protocol is ready to read alongside this
Overview.

## The bridge

- **The idea (the pattern):** Redis Patterns Applied teaches transferable patterns — cache-aside, reliable queues,
  streams — and proves each with one excerpt, then doors forward.
- **The implementation (EchoMQ):** each door lands on the pillar that runs the pattern in depth, over one owned wire
  — the same wire every BCS system inherits.

## The take

A door is one-way teaching; a wire is two-way infrastructure. Redis Patterns Applied hands its patterns to this
course; this course hands the Queue, the Bus, and the Cache to every system built on the Branded Component System.

## References

### Sources
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record EchoMQ is backed by.
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the load-once, run-by-SHA dispatch the wire runs its
  scripts with.
- DragonflyDB — Server flags (`https://www.dragonflydb.io/docs/managing-dragonfly/flags`) — the thread-per-shard
  engine the declared-key, per-queue-hashtag keyspace is built for.
- llmstxt.org — The llms.txt convention (`https://llmstxt.org/`) — the machine-readable map format the course follows.

### Related in this course
- `/echomq/overview` — the Overview landing (the chapter loop closes here).
- `/echomq/overview/the-three-pillars` — the first dive: what EchoMQ is.
- `/echomq/overview/the-protocol-below-the-line` — the previous dive: why the pillars interoperate.
- `/echomq/protocol` — the substrate all three pillars share.
- `/redis-patterns` — the course that doors here, pattern by pattern.
- `/redis-patterns/overview/patterns-become-protocol` — the near side of the door.
- `/bcs` — the Branded Component System; EchoMQ is its bus.
- `/elixir` — the Elixir the course is canonical in.
