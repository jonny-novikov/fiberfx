# BCS · Part III — EchoMQ: the Valkey-native bus

<show-structure depth="2"/>

Part I gave every row a name and Part II gave the names a home; Part III puts them in motion. EchoMQ 2.0 is the bus — background work, control flow, and cross-process choreography — built Valkey-native from the first byte by Decision D-1: a fresh `emq:` keyspace, a version-fenced Lua bundle negotiated before any command runs, and no compatibility ballast from any predecessor wire. The cargo law is the series' oldest: only identities cross. A job names the entities it concerns; it never carries their rows, and everything the queue does — enqueue, claim, retry, browse — moves fourteen-byte names whose bytes are already chronology.

This part inherits a standing substrate rather than a blank page. The connector shipped in [Appendix A](bcsA.md) with its committed record: a `10000-command pipeline returned 1..10000 in order` over the one-pass RESP codec; EVALSHA-first dispatch holding `script_loads=1` across a busy session; the version fence refusing a mismatched bundle as a typed boot failure and re-fencing after supervised restart; key shapes like `emq:{orders}:job:ORD0NsVQMCRgHI` with a gated id in the job position and `prefix = 17 bytes` of fixed overhead; and a client-side slot function answering `slot 105 == 105` against the keyspace's hashtags, committed for the clustered day this part does not need. Part III builds the queue on top of that floor.

## The laws of the part

**One transition, one script.** Every job state change — enqueue, claim, complete, retry, dead-letter — is a single `EVALSHA` against the versioned bundle. Atomicity is not assembled from client-side sequences; partial states are unrepresentable on the wire because no wire sequence exists that could produce one.

**The fence before the first command.** The `echomq:2.0.0` handshake runs at connect and again at every reconnect; a bundle-version mismatch is a typed refusal at boot, never a degraded session. The fence is the queue's namespace gate: wrong-kind servers are refused the way wrong-kind ids are.

**Jobs are entities.** Chapter 3.2 registers `JOB` under the D-8 bar — jobs are minted, gated, paged, and audited like any kind, and the order theorem gives queue browsing for free because job ids sort by submission. Payloads carry entity ids and parameters, never rows: the boundary law rides onto the bus unchanged.

**Park, don't poll.** Idle consumers block on keys and cost nothing; readiness arrives as a wake, not a discovered flag. Fairness across groups is constructed — round-robin lanes by assignment — never hashed, which is the placement contract's own consumer norm applied where it was always heading.

**Delivery semantics are named per surface.** At-least-once is stated where it holds and made cheap to honor: enqueue is idempotent by job id, and checkpoints survive consumer crashes so a redelivery resumes instead of repeating. No surface implies a guarantee its record does not gate.

**Rivals are measured with their advantages printed.** The closing chapter benchmarks against the ecosystem's transactional-enqueue class — Oban's same-transaction enqueue is a real advantage and its number appears beside ours — because a gate that hides the rival's win is decoration.

## The chapters

**Chapter 3.1. The Fence and the Keyspace** — consolidates the connector substrate into the part's working vocabulary: the RESP discipline, the boot fence as queue-grade gating, every key shape including the reserve and version keys, and the slot function held in reserve for the clustered day.

**Chapter 3.2. Jobs Are Entities** — registers `JOB`, defines the job row (identity, queue, state, attempts, a payload of ids), lands enqueue as one idempotent script, and collects the order theorem's dividend: newest-first browsing with no index.

**Chapter 3.3. The State Machine in Lua** — claim, complete, retry, and dead-letter as single-script transitions over the versioned bundle, with the two-clocks law applied to the bus: server time drives leases, mint time stays history.

**Chapter 3.4. Fair Lanes** — groups with per-group concurrency and pause/resume; park-don't-poll mechanics on blocking primitives; round-robin construction with a starvation refusal as a gate, not a paragraph.

**Chapter 3.5. The Bus Meets the Stores** — commands flow out of entities and results flow back into properties with ids as the only cargo; the supervised consumer takes its place as one more owner in the Part II tree.

**Chapter 3.6. Conformance and the Rival's Numbers** — the part's referee habit (a from-scratch check of any formula the part leaned on), throughput and latency under the committed harness, and the transactional-enqueue comparison with the rival's advantage stated in its own row.

## What this part will not do

No Streams and no PubSub: eventing is EMQ 3.0 by Decision D-3, and this part will not preempt it. No cluster routing: the slot function is committed and waiting, and single-instance Valkey is the part's stated topology. No durability story for the server itself: persistence configuration is an operations topic, and the part measures what the wire guarantees, not what the disk might.

## Evidence policy

Unchanged and inherited whole: every chapter lands with a rung, every rung commits its record the day it runs, figures in prose are verbatim strings from those records, and the records freeze — later chapters re-read them rather than re-running them. The referee habit instituted at Part II's close applies here from the start.
