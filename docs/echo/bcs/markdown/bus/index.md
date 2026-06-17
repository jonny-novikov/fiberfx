# B3 · The Bus — EchoMQ, Valkey-native

> Route: `/bcs/bus` · chapter landing · manuscript Part III (`content/bcs3.md` + `bcs3.1.md`–`bcs3.6.md` +
> `bcsA.md`). Md mirror of `html/bcs/bus/index.html`.

**The law, set in motion.** Part I gave every row a name and Part II gave the names a home; Part III puts them
in motion. EchoMQ 2.0 is the manuscript's bus — background work, control flow, and cross-process choreography —
built Valkey-native from the first byte by Decision D-1: a fresh `emq:` keyspace, a version-fenced Lua bundle
negotiated before any command runs, and no compatibility ballast from any predecessor wire. The cargo law is
the series' oldest: only identities cross. A job names the entities it concerns; it never carries their rows,
and everything the queue does — enqueue, claim, retry, browse — moves fourteen-byte names whose bytes are
already chronology.

This part inherits a standing substrate rather than a blank page. The connector shipped in Appendix A with its
committed record: a `10000-command pipeline returned 1..10000 in order` over the one-pass RESP codec, EVALSHA
holding `script_loads=1` across a busy session, and the version fence refusing a mismatched bundle as a typed
boot failure. Part III builds the queue on top of that floor.

## The arc — seven modules in reading order

The interactive arc figure carries the seven modules; selecting a node reads its thesis.

- **B3.1 · The Fence and the Keyspace** (`fence-and-keyspace`, `bcs3.1.md`) — the connector substrate as the
  part's working vocabulary: the `emq:{q}:<type>` grammar, the braced `{emq}:` base reserved for deployment
  facts, the boot fence as queue-grade gating, binary discipline, and the co-location law. Rung
  `bcs_rung_3_1_check.out`, `PASS 5/5`.
- **B3.2 · Jobs Are Entities** (`jobs-are-entities`, `bcs3.2.md`) — `JOB` registered under the D-8 bar; the
  three-field row (`state`, `attempts`, `payload`, and deliberately nothing more); enqueue as one idempotent
  script; the `EMQKIND` wire class; the order theorem's browsing dividend. Rung `PASS 5/5`.
- **B3.3 · The State Machine in Lua** (`state-machine`, `bcs3.3.md`) — claim, complete, retry, and dead-letter
  as single-script transitions; the server clock owns leases; `attempts` is the fencing token; the morgue and
  the reaper. Rung `PASS 6/6`.
- **B3.4 · Fair Lanes** (`fair-lanes`, `bcs3.4.md`) — per-group lanes, the ring invariant, the rotating claim,
  ceilings and pauses, and park-don't-poll on blocking primitives, with a starvation refusal as a gate. Rung
  `PASS 8/8`.
- **B3.5 · The Bus Meets the Stores** (`bus-meets-stores`, `bcs3.5.md`) — commands out of entities, results back
  into properties, ids the only cargo; exactly-once *effect* by a provenance guard; the consumer as one more
  owner in the Part II tree. Rung `PASS 6/6`.
- **B3.6 · Conformance and the Rival's Numbers** (`conformance`, `bcs3.6.md`) — fourteen wire-level contracts a
  port can drive verbatim, the referee habit, and Oban 2.18.3 on PostgreSQL 16.14 measured with the asymmetry
  stated first. Rung `PASS 6/6` and `CONFORMANCE 14/14`.
- **B3.7 · Appendix A — The Connector** (`the-connector`, `bcsA.md`) — one-pass RESP2, pipelining as the
  primitive, the typed fatal fence, EVALSHA-first declared-keys scripts, and the measured wire. Gate
  `emq_connector_check.out`, `PASS 8/8`.

## The laws of the part

Part III states six laws and holds every chapter to them.

- **One transition, one script.** Every job state change — enqueue, claim, complete, retry, dead-letter — is a
  single `EVALSHA` against the versioned bundle. Partial states are unrepresentable because no wire sequence
  exists that could produce one.
- **The fence before the first command.** The `echomq:2.0.0` handshake runs at connect and at every reconnect;
  a bundle-version mismatch is a typed refusal at boot, never a degraded session.
- **Jobs are entities.** Chapter 3.2 registers `JOB` under the D-8 bar — jobs are minted, gated, paged, and
  audited like any kind, and the order theorem gives queue browsing for free.
- **Park, don't poll.** Idle consumers block on keys and cost nothing; readiness arrives as a wake, not a
  discovered flag. Fairness across groups is constructed — round-robin lanes by assignment — never hashed.
- **Delivery semantics are named per surface.** At-least-once is stated where it holds and made cheap to honor:
  enqueue is idempotent by job id, and checkpoints survive consumer crashes.
- **Rivals are measured with their advantages printed.** The closing chapter benchmarks against the
  transactional-enqueue class — Oban's same-transaction enqueue is a real advantage, and its number appears
  beside the bus's.

## The floor under the floor — the evidence

Part III is fully written, and every chapter lands with a rung — an executable check and a frozen transcript,
committed beside the prose. The six chapter rungs, the conformance record, and the connector gate on file:

```
bcs_rung_3_1_check.out   the fence and the keyspace        PASS 5/5
bcs_rung_3_2_check.out   jobs are entities                 PASS 5/5
bcs_rung_3_3_check.out   the state machine in Lua          PASS 6/6
bcs_rung_3_4_check.out   fair lanes                        PASS 8/8
bcs_rung_3_5_check.out   the bus meets the stores          PASS 6/6
bcs_rung_3_6_check.out   conformance and the rival         PASS 6/6   CONFORMANCE 14/14
emq_connector_check.out  the connector (Appendix A)        PASS 8/8
```

The connector gate ran against live Valkey 9.1.0; the conformance bench measured the bus against Oban 2.18.3 on
PostgreSQL 16.14, with the asymmetry — the rival's enqueue is durable and transactional, the bus's is volatile
by Decision D-2 — stated before the first ratio.

## What this part will not do

No Streams and no PubSub: eventing is EMQ 3.0 by Decision D-3, and Part III does not preempt it. No cluster
routing: the slot function is committed and parked, and single-instance Valkey is the part's stated topology. No
durability story for the server itself: the part measures what the wire guarantees, not what the disk might.

## Up next

B4 · EchoCache (Part IV — the near-cache), then Parts V–VIII: the Go and Node runtimes, production on Fly, and
the trading capstone, built as the manuscript ships.

## The doors

- `/echomq` — the bus B3 narrates, taught rung by rung: the keyspace, the Lua inventory, conformance on Valkey.
- `/redis-patterns` — the substrate patterns under the bus: sorted sets, atomic Lua moves, list rotation,
  blocking pops.
- `/elixir` — the Portal engine and the umbrella where `echo_data`, the production identity library, lives.

## References

### Sources

- Valkey — the RESP protocol: <https://valkey.io/topics/protocol/> — the wire EchoMQ is built on, length-prefixed
  bulk strings and inline replies.
- Valkey — programmability: <https://valkey.io/topics/programmability/> — atomic script execution, the basis of
  one-transition-one-script.
- Valkey 8.1.0 GA: <https://valkey.io/blog/valkey-8-1-0-ga/> — the substrate the connector gate and the
  conformance bench measured against (Valkey 9.1.0).

### Related

- `/bcs` — the course home: the law, the id anatomy, the chapter map.
- `/bcs/elixir-core` — B2 · The Elixir BCS Core: the stores Part III puts in motion.
- `/echomq` — the far side of the B3 door, the bus taught in rung-level depth.
- `/redis-patterns` — the substrate patterns under the bus.
- `/elixir` — the umbrella where `echo_data` lives.
