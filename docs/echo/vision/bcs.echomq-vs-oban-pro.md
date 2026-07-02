# BCS · The Bus Beside the Table — EchoMQ's Advantages over Oban Pro

This series' own roadmap is titled "to Oban Pro parity," so this article owes the reader its frame up front: Oban Pro is the strongest job system in the ecosystem EchoMQ inhabits, and several of its properties are ones EchoMQ is still building. What this appendix names is the other half of the ledger — **the advantages that fall out of EchoMQ's substrate rather than its feature list**: a volatile Valkey-native bus with durability at the edges and a floor beneath, against a durable Postgres table with speed engineered on top. Every EchoMQ surface cited here is shipped and conformance-gated at rung `2.6.5`; every Oban claim is read from Oban's own documentation this session; and the closing sections record, without flinching, what Pro holds today that this bus does not.

## Scope and method

The EchoMQ side is the committed tree at `0c0fd19`: the bus at conformance 79 (the ladder 52 → 61 → 73 → 79 across the closed movements, per the [Movements ledger](../../echo_mq/emq.roadmap.md)), proven end to end on this bench. 
The Oban side is cited, not run: the core documentation (Oban 2.18 line and the scaling guide) and the Pro documentation (the Smart engine at 1.6.1, the product surface) — all fetched and read this session. What is decided rather than measured: the comparisons of mechanism shape. 
**No performance figure is claimed in either direction** — no cross-engine benchmark exists in this tree, and a number measured on someone else's workload is not evidence; where Oban publishes its own figures they remain Oban's. Out of frame: Oban Web's UI against the EchoMQ [dashboard program](../../../echo_mq/dash.roadmap.md) (chartered, July rungs authored, not built), and licensing.

## The two designs, fairly

**Oban** stores every job as a row in Postgres and derives its strongest properties from that choice: a job can be inserted in the same transaction as the business data it belongs to; retained rows make history, stats, and introspection a query away — in the documentation's own words, "at the expense of storage and an unbounded table size"; and the whole system needs no second service. Around the table sit the mechanisms that make it fast: a leader node stages scheduled jobs and notifies queues over PubSub (Postgres LISTEN/NOTIFY or Distributed Erlang), with a one-second local poll as the fallback; a Pruner deletes terminal rows on an age policy; a Reindexer rebuilds indexes because Postgres' transactional model bloats them under queue churn. Pro's Smart engine adds cluster-wide concurrency and rate limits, queue partitioning, bulk unique inserts, and an accurate snooze that rolls back the attempt counter — and above it sit Workflows with cumulative context, Batches, Chains, and Relay.

**EchoMQ** inverts the substrate decision. The bus lives on Valkey and is deliberately volatile (decision D-2): the hot path is in-memory sets and hashes moved by atomic Lua, every key born braced (`emq:{q}:`), born branded (a `JOB` id gated at the key builder), born declared (in `KEYS[]` or grammar-derived). Durability is not absent — it is placed: the transactional outbox (`EchoStore.Journal`) at the writer's edge, and the Graft floor (single-writer commits on CubDB, streamed to Tigris) beneath, both opt-in. Fairness is a property of the claim's shape (per-group lanes on a rotating ring), liveness is a property of the substrate (a parked `BLPOP`), and the contract is the wire itself, pinned by a 79-scenario conformance suite rather than by a library's internals.

The advantages below are each an entailment of that inversion — which is why they are structural rather than roadmap items Pro could add in a release.

## History is a dial, not a tax

Oban's introspection is a consequence every deployment pays for: rows are retained so stats exist, the table grows unboundedly by design, and two plugins exist to fight the consequences — the Pruner deleting terminal rows on age, the Reindexer rebuilding what churn bloats. The cost is not a defect; it is the stated price of history-in-the-store.

EchoMQ separates the two concerns. The bus keeps only live state; a completed job settles and leaves the hot path. History, where a deployment wants it, is the floor's job: the [parity roadmap](../../../echo_mq/emq4.roadmap.md) lands completion records in a Graft volume as an opt-in tier, and the shipped Stream Tier already demonstrates the shape — a stream trims by declared policy, and `EchoStore.StreamArchive` folds the trimmed segments into the durable floor, readable beside the live tail. The entailment the bus roadmap states outright: history and recording become a choice with a storage cost, not a default tax. The queue never carries the archive's weight, and the archive never sits inside the queue's indexes.

## Fairness constructed, not queried

Pro's Smart engine governs multi-tenant load with partitioned queues, global concurrency, and rate limits — capable machinery, expressed as windowed queries and producer records over the job table, coordinated through advisory locks and leadership.

EchoMQ's fairness is not a policy applied to a queue; it is the shape of the claim. A queue is a set of per-group lanes, each named by an identity; the ring holds exactly the lanes serviceable now; and the atomic `@gclaim` rotates the ring one step (`LMOVE`) before serving, so no tenant starves another as a property of rotation, with nothing to query and no window to compute. On top of the same rotation, shipped and byte-frozen beside the original: `gweight` gives a lane a throughput share per turn (`@gwclaim`, the share clamped by the lane's `glimit` headroom so a weight can never breach a concurrency ceiling), and `@gbclaim` serves an affinity batch — a homogeneous batch from one rotated lane in one atomic turn. Group-aware pause and resume act on a lane without touching the queue. The comparison in one line: Pro *limits* tenants accurately; EchoMQ *rotates* them fairly, and limits are the ceiling on the rotation rather than the mechanism of it.

## Park, don't poll

Oban minimizes polling well: the leader stages due jobs and notifies queues over PubSub, and only degraded environments fall back to the one-second local poll. But the fetch itself is a query, staging is a leader's periodic work, and the notifier is a tradeoff surface of its own — the Postgres notifier pays a query per notification at scale, the PG notifier trades transactional consistency for cheaper delivery.

An EchoMQ consumer parks. The loop reaps expired leases, promotes due schedules, drains the ring, then blocks on the queue's wake key — `BLPOP` on the consumer's own connector lane, so the blocking verb never stalls the system's shared socket. A parked consumer costs the wire nothing; an enqueue pushes a wake token and the sleeper is claiming in one round trip. Where a pool of consumers would herd on one key, the shipped `Metronome` mode holds the single block per queue and pokes idle consumers one claim at a time — one blocker, no herd, readiness fanned out fairly. Liveness here is not a plugin's cadence; it is what the substrate's blocking read is for.

## The fenced settle

A volatile store forces the split-brain question early, and EchoMQ answers it with fencing rather than hope: every claim carries a server-clock lease and a token, and every settle — `complete`, `retry`, `delay`, `extend_lock`, `extend_locks` — is token-fenced on the wire, refusing a stale holder with a typed `EMQSTALE`. A worker that lost its lease cannot complete the job its successor now holds; the reap that re-rings an expired job is the same server clock that granted the lease, so no host timestamp ever crosses the boundary. Oban's executor is protected by the database's own locking and by `attempted_by` bookkeeping — sturdy in the common case — but the fenced token is the stronger contract precisely where a queue is weakest: the worker that went quiet and came back convinced it still owns the work.

The candid caveat on this bus's own side: the extension verbs exist and no shipped consumer loop spends them yet — the lease heartbeat is the first runway rung on the [parity roadmap](../../../echo_mq/emq4.roadmap.md), proposed, not built.

## Identity on the wire

An Oban job's identity is a bigserial the table assigned; everything the system knows about the job lives in columns beside it, and uniqueness is a policy engine over args, keys, and periods — rich in Pro in particular, where index-backed uniqueness survives bulk inserts.

An EchoMQ job's identity is a branded `JOB` id, and the id itself carries the contract: typed (the namespace is gated where the key is built, so a wrong-kind id never reaches the wire), ordered (mint order is the sort key — the pending set is scored zero and the id's own bytes order it, so there is no second ordering scheme and no `scheduled_at` index), and placed (`hash32` locates a row from the identity alone, the property the slot-routing direction spends). Deduplication follows from identity rather than policy: `enqueue` refuses an existing id atomically (`EXISTS → 0`), which is exactly what makes producer retries and the Journal's replay safe with no policy configuration at all. Where Pro's uniqueness answers "have I seen these args lately," EchoMQ's answers "is this the same job" — a narrower question, answered structurally. The loss beside the win: Pro's args-and-period uniqueness expresses intents this bus's identity dedup does not, and a deployment that needs them writes them above the wire today.

## One signal plane

Oban is a queue with notifications. EchoMQ is four uses of one substrate under one keyspace grammar: the **queue** (jobs, lanes, flows, batches), the **stream** (`EchoMQ.Stream` and its reader law — consumer groups that drain their own PEL on restart and reclaim dead peers via `XAUTOCLAIM`, retention as a declared policy, the archive fold, and time-travel reads with hydration — shipped whole, conformance 79), the **broadcast** (`EchoMQ.Events`, the per-queue lifecycle pub/sub a dashboard or a cache rides), and the **meter** (`EchoMQ.Meter`, the `[:emq, …]` telemetry surface at zero cost when `:telemetry` is absent). Pro's Relay — insert and await a result across nodes — is a pattern this plane carries as a correlation id awaited on a durable, replayable stream, which is a stronger footing than a notification that a late awaiter can miss. Nothing in Oban's substrate offers an append-log tier at all; a team that needs one beside its queue runs a second system. Here the second system is the same system.

## The wire is the contract

Oban's contract is an Elixir library (and, credit where due, Pro now ships Python as a supported second language — the product surface says Elixir and Python plainly). The engine, however, remains the library pair over the table.

EchoMQ's contract is the wire: the `emq:{q}:` grammar, the branded ids, and the atomic scripts *are* the protocol, and the 79-scenario conformance suite pins the protocol rather than any host. A runtime that speaks RESP and honors the grammar is a client — the Go surface exists on exactly those terms, and the roadmap's polyglot phase is an SDK passing the same suite, not a port of an engine. The structural difference: adding a language to Oban is vendor work on the engine's inside; adding a language to EchoMQ is conformance work on the wire's outside. For a platform whose stated direction is BEAM cores beside Go tooling and TypeScript surfaces, the open wire is the property that compounds.

## Deep history off the heap

The end state of the two retention stories differs in kind. Oban's deep history is more retained rows — queryable, and paid for in table size, vacuum pressure, and index bloat, which is why the pruning and reindexing plugins exist and why the scaling guide counsels aggressive pruning. EchoMQ's deep history leaves the hot store entirely: trimmed stream segments fold into the Graft floor's CubDB pages at a reserved range and stream on to Tigris; a reader merges archived pages with the live tail on a watermark, and `read_window` and `read_since` make the past queryable beside the present. The floor's commit-LSN is a cursor any replica can follow, so the archive is also the read-replica story — dashboards and analytics reading at a commit, off the bus, with the bus carrying only the commit notices. History deepens without the queue feeling it.

## What Oban Pro holds today

Recorded plainly, because the parity roadmap exists for these exact rows:

- **Transactional enqueue with business data.** Enqueue in the same Postgres transaction as the write it belongs to is Oban's single strongest property, and EchoMQ does not have it yet — Phase 2's BCS-native answer (one single-writer `echo_store` commit carrying datum and intent, drained by a committer) has its design landed and its forks parked, and is planned, not shipped.
- **Cross-queue Workflows.** Pro's DAGs carry cumulative context, nest sub-workflows, and cancel as a unit, distributed across nodes. EchoMQ's shipped `Flows` are single-queue and atomic on one slot by design; the cross-queue saga over a `WFL` volume is Phase 3.
- **The verdict vocabulary and accurate snooze.** Oban core speaks `{:snooze, period}` and `{:cancel, reason}`; the Smart engine's snooze rolls back the attempt so backoff stays truthful. This bus's consumer speaks two verdicts today; the widening is runway rung R3, proposed — and Pro's attempt-rollback refinement is a detail worth stealing when it lands.
- **The operator UI.** Oban Web is mature; this program's dashboard is an ANSI alpha plus a chartered Phoenix program whose July rungs were authored this month and are not yet built.
- **One database, and years of it.** Oban adds no second service to a Postgres application, and it has been hardening in production since 2019 with commercial support behind Pro. EchoMQ requires a Valkey and is young; its discipline (byte-frozen scripts, conformance per rung, the bench e2e) is the answer it offers to youth, not a substitute for years.

## The chooser

Choose **Oban Pro today** when the application is Postgres-resident and the deciding requirements are transactional enqueue with business writes, cross-queue workflows now, SQL-queryable history, and a mature web console — those are Pro's home ground and this bus's open phases.

Choose **EchoMQ** when the deciding requirements are the substrate's: many tenants on shared queues where fairness must be constructed rather than rate-shaped; a queue and an append-log and a broadcast plane on one store, one grammar, one conformance gate; an open wire that Go, TypeScript, and whatever comes next can speak as first-class clients; a hot path shaped like memory with durability as a dial (outbox at the edge, Graft beneath, archive off-heap); and operator verbs — pause, resume, drain, weight — that act on an identity-named lane, not a table scan. The worked proof that the composition holds is not a benchmark but a running system: codemojex charges a wallet in Postgres, enqueues on a player's lane, scores through a parked consumer, and settles — the e2e this bench replays on demand.

## Boundaries

No throughput or latency figure is asserted here in either direction; none is committed in this tree, and the article treats mechanism shape, not speed, as the comparison surface. The Oban and Oban Pro claims are read from the documentation versions named in scope as of this session and will drift as those products do — Pro in particular ships quickly. The EchoMQ advantages cite shipped, conformance-gated surfaces at `0c0fd19`; the three places this article leans on its own roadmaps (the lease heartbeat, transactional enqueue, cross-queue workflows) are marked planned or proposed where they appear, and the losses section is part of the thesis, not a footnote to it.

## References

- Oban — Oban module documentation (retained rows and introspection, the Pruner, staging via the leader and PubSub with the local-poll fallback, the engines): `https://hexdocs.pm/oban/2.18.2/Oban.html`
- Oban — Scaling Applications (notifier tradeoffs at scale, the Reindexer against index bloat, aggressive pruning, the dedicated pool): `https://hexdocs.pm/oban/scaling.html`
- Oban — Oban.Worker (the verdict contract: ok, error, cancel, snooze): `https://hexdocs.pm/oban/Oban.Worker.html`
- Oban Pro — the product surface (Workflows with cumulative context and nesting, the Smart engine, Chains, Relay; Elixir and Python): `https://oban.pro/`
- Oban Pro — the Smart engine (global concurrency, rate limiting, partitioning, bulk unique inserts, accurate snooze): `https://oban.pro/docs/pro/1.6.1/Oban.Pro.Engines.Smart.html`
