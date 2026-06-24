# BCS · B6 — Putting It All Together
<show-structure depth="2"/>

B6 composes the course: the four libraries — `echo_wire`, `echo_data`, `echo_mq`, `echo_store` — as one dependency-ordered umbrella, then a write all the way down and a read all the way up. Three dives carry it — the umbrella and its boot, one write through the outbox and lanes, one read up the four-tier ladder. The chapter is served at `/bcs/together`; its dives at `/bcs/together/the-umbrella`, `/bcs/together/the-write-path`, and `/bcs/together/the-read-path`.

B6 puts the course together: the four libraries — `echo_wire`, `echo_data`, `echo_mq`, `echo_store` — compose into one dependency-ordered umbrella, `wire ← data ← mq ← store`, that boots only after the identity contract proves itself. A write begins at a system's store and fans out through a transactional outbox: record the intent, enqueue on a lane, mark it enqueued, with replay covering every crash window; multi-step work rides an atomic Flow, settlement rides a lane, and the write ends durable on the floor and announced by coherence. A read climbs the same stack in reverse — a caller-side L1 hit, or a miss filling down through Valkey, the store, and the floor — ETS to Tigris, one branded id keying every tier. The pieces are not merged; they are composed, fast at the top and durable at the bottom.

Every surface here is real: the inter-app dependencies in `apps/*/mix.exs`, the boot self-check in `echo_data`, the transactional outbox `EchoStore.Journal`, the atomic `EchoMQ.Flows`, and the read ladder ETS → Valkey → CubDB → Tigris. No number is cited that the committed tree does not assert.

## B6.1 · One umbrella, four systems

The course has built four libraries, and they compose into one tree. `echo_wire` is the wire — RESP framing, the single-owner socket connector, the script registry behind the version fence. `echo_data` is the id, the property stores, and the CHAMP forest. `echo_mq` is the bus, built on the wire and the data layer. `echo_store` is the cache and the floor, built on all three plus CubDB and exqlite. The dependencies point one way — wire ← data ← mq ← store — a closed set with no cycle, so the umbrella has a boot order and a deployment has choices.

Boot runs in dependency order, and the first thing that happens is a proof. `echo_data` seeds the Snowflake node into `persistent_term` and runs the contract self-check, comparing the native and pure code paths against the committed vectors; if they disagree, the application refuses to start. Nothing downstream mints an id, frames a key, or fills a cache until the name the whole system trades in has been proven trustworthy.

Each library is a system in the sense Part I gave the word: a boundary that owns its state and trades only in identities and messages about them. The umbrella is not a monolith with four modules; it is four systems that happen to deploy together, and the same code runs whether they share a node or sit on four. Putting it together is choosing which boundaries share a machine, not erasing the boundaries.

## B6.2 · One write, all the way down

A write begins inside one system, at its store: a `put` of a value under a branded id and a mint-time version. If that were the whole story, persistence would be a single call. But a real write fans out — it must settle work on the bus and survive a crash between the two — and that is what the rest of the path is for.

The seam is a transactional outbox. `EchoStore.Journal` records the writer's intent, enqueues the job on a lane, and marks it enqueued; every crash window between those three steps is covered by replay, and the bus deduplicates a job that replay re-enqueues. The bus itself stays on Valkey, fast and volatile, while only the low-volume intent lands in the journal — so durability is a small, mostly idle dependency, not a tax on every step.

Multi-step work travels as a flow, and a flow is atomic. `EchoMQ.Flows` lands a parent and its children on one slot in one operation, so either the whole flow is enqueued or none of it is; the parent is held back until its last child completes. Settlement rides a lane, never an ungrouped enqueue, so a draining consumer always finds it. When the work is done the floor has the bytes and coherence has invalidated the cache by the same version — one write, made durable and announced, all the way down.

## B6.3 · One read, all the way up

A read climbs the same stack in reverse, and most reads stop at the first rung. A hit is a caller-side `:ets.lookup` against the L1 table — it never enters a process and never leaves the node. The cheapest read is the common read, and the tiers beneath exist for the times the answer is not yet in the heap.

A miss fills from below, one rung at a time. L2 is the shared Valkey at `ecc:{table}:id`; beneath it the declared loader reads the system's store; beneath that the floor reads pages from CubDB and, if they are not local, from Tigris — fetching only the pages the read touches. Each tier answers before the one beneath is asked, so a read pays for exactly the depth it needs and no more: ETS, then Valkey, then CubDB, then Tigris.

What ties the rungs together is the name. The same branded id keys the cache row, the store entry, the page on the floor, and the object in the bucket — a read is one question asked at four depths, not four lookups translated between four schemes. And coherence keeps the climb current: when a write lands, its mint-time version invalidates the cached row, so the next reader either finds the new value or misses cleanly and fills it. The stack is fast at the top, durable at the bottom, and consistent by the id that runs through all of it.

## References

- [Erlang/OTP — the supervisor behaviour](https://www.erlang.org/doc/apps/stdlib/supervisor.html) — the dependency-ordered tree the umbrella boots.
- [Erlang/OTP — the gen_server behaviour](https://www.erlang.org/doc/apps/stdlib/gen_server.html) — each library as a system: a process with a boundary and a mailbox.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the node singleton seeded and proven at boot, keying every tier.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — the outbox of activities that makes a multi-step write recoverable.
- [Kreps — The Log (LinkedIn Engineering)](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the bus as the log a write fans out onto.
- [Valkey — Scripting with EVAL](https://valkey.io/topics/eval-intro/) — the one atomic operation that lands a whole flow or none of it.
- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — the L1 table a read hits caller-side before any tier beneath.
- [Tigris — conditional object operations](https://www.tigrisdata.com/docs/objects/conditionals/) — the durable floor at the bottom of the read ladder.
