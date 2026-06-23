# BCS · B3 — The Bus
<show-structure depth="2"/>

B3 is the bus: EchoMQ, the Valkey-native message bus where the BCS law meets the network. Three dives carry it — the keyspace as the contract on the wire, jobs and fair lanes as the entities it moves, and the EchoMQ 3.0 Stream Tier beside the queue. The chapter is served at `/bcs/bus`; its dives at `/bcs/bus/the-keyspace`, `/bcs/bus/jobs-and-lanes`, and `/bcs/bus/the-stream-tier`.

EchoMQ is the bus, and a bus is the place the BCS law meets the network: between systems, only branded identities and messages about them cross. A job is a branded entity — a `JOB` id with a property bundle — so `orders` can hand work to `codemojex` without either reaching into the other's state. The bus is Valkey-native, lib-only, and re-derived from first principles: the v1 line could not become 2.0 in place, so it was rewritten fresh and removed.

Every surface here is real source under `echo_mq` (v2.6.3); the movements and shipped rungs are read from `docs/echo_mq/emq.roadmap.md`. No engine number is cited that the committed tree does not assert.

## B3.1 · The keyspace

EchoMQ is the bus, and a bus is where the BCS law meets the wire: only branded identities and messages about them cross between systems. The discipline is in the key. Every EchoMQ key is born braced — `emq:{queue}:` — born branded — a `JOB` id gated at the key builder — and born declared — named in a Lua script's `KEYS[]`, never interpolated into the body. The v1 line could not become 2.0 in place because its keys were built from an `ARGV` prefix inside script bodies and interpolated verbatim; the rewrite drew the keyspace from first principles instead.

The braces are a hash-slot tag. `{queue}` tells Valkey to place every key for one queue on the same slot, so a multi-key script touches one node and stays atomic on a cluster. The brace is not decoration; it is the difference between a script that runs and a `CROSSSLOT` error. The queue name is the slot, and the slot is chosen by the name.

The id inside the key is a branded `JOB` id, gated where the key is built, so a malformed or wrong-kind id is refused before it reaches Valkey. And every key a script reads or writes is passed in `KEYS[]`, so the set of keys a script touches is declared and auditable, not assembled from string fragments at run time. Braced, branded, declared: the key is the contract, and the contract is checked before the wire.

## B3.2 · Jobs and lanes

A job is a branded entity — a `JOB` id with a property bundle — and its life is a small, leased state machine. `Jobs.enqueue` writes a waiting job; `Jobs.claim` leases it to a worker and makes it active; `Jobs.complete` finishes it, `Jobs.retry` returns it to waiting with a backoff, and a job that exhausts its tries fails. The lease is what makes the bus safe: a worker that dies holding a job loses the lease, and the job is reclaimable rather than lost.

A queue is not one line; it is a set of lanes, each named by a branded id, drained fairly. `Lanes.claim` is how every consumer takes work, and it spreads claims across lanes so no one lane starves the rest — the fair-lanes property. Group-aware pause and resume act on a lane without touching the queue, so one tenant can be held while the others run. Work that should ride a lane and is enqueued ungrouped is never claimed; the lane is the unit of fairness and of control.

Jobs depend on jobs, and a dependency is a relation, not a field. `Flows.add` records that a parent waits on its children; when the last child completes, the parent is released, its children's values readable from the parent. A flow is a small graph of branded ids with its own rules — fan-in, failure policy, grandchildren — owned by the bus, the same move B2 made for edges: the relation is a system, referenced by id, not embedded in either job.

## B3.3 · The Stream Tier

EchoMQ's program runs in three movements, and its destination is EchoMQ 3.0 — a Stream Tier beside the job queue. A queue is for work that is claimed and completed once; a stream is an append-only log that many readers consume at their own pace. The tier is built additively: the writer, the readers, and retention each shipped as a rung with its own conformance probe, and the stream keys are born braced and branded like every other key on the bus.

`EchoMQ.Stream` is the writer — it appends an entry to the log and returns its id, the log ordered by append the way the property store is ordered by mint. `EchoMQ.StreamConsumer` is the reader law: a consumer group reads new entries, acknowledges them, and resumes where it left off, so a reader that restarts does not replay what it has already handled. A deliberate polyglot seam keeps the read side reachable from any language that speaks the wire, not only the BEAM.

A log that only grows is a leak, so retention is a policy, not a default. `EchoMQ.Stream.trim` bounds the log by length or age, and the trimming driver is named and opt-in — a queue keeps its history until a system decides how much of it to keep. The stream is the same idea as the store seen sideways: identity orders the entries, the boundary owns them, and what survives is a choice the system makes, not an accident of volume.

## References

- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — hash tags force a queue's keys onto one of the 16384 slots.
- [Valkey — Scripting with Lua](https://valkey.io/topics/eval-intro/) — keys must be passed as arguments, never programmatically generated.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the roughly-sortable id the JOB key carries.
- [Oban — Robust job processing in Elixir](https://hexdocs.pm/oban/Oban.html) — the Postgres-backed prior art for jobs, queues, and workflows.
- [Valkey — Sorted Sets](https://valkey.io/topics/sorted-sets/) — the scored structure a scheduler and the lanes are built on.
- [Lamport — Time, Clocks, and the Ordering of Events (1978)](https://dl.acm.org/doi/10.1145/359545.359563) — the happens-before a lease and a queue order by.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log and consumer groups the tier is built on.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the log as the shared abstraction beneath a stream.
- [Tigris — Conditional operations](https://www.tigrisdata.com/docs/objects/conditionals/) — the create-only fence an archived stream lands behind.
