# Graft — Postgres WAL archive & PITR (surfaced design fork)

> The design step for bringing the `echo-postgres` money ledger's off-site durability onto the Graft+Tigris
> floor. This document **surfaces a fork; it does not resolve one** — it argues four arms in the four-part form
> of [aaw.architect-approach.md](../aaw/aaw.architect-approach.md) and leaves the ruling to the Operator, who has **RULED Arm A → Arm B** (see [Ruling](#ruling)). Status:
> **RULED** (Arm A → Arm B) — no arm is built yet; every Graft surface named is verified against [graft.design.md](graft.design.md)
> and [graft.integration.md](graft.integration.md), and every new surface is written in the forward tense.

## Context — the gap and the opportunity

Two facts set the fork. First, the consistency-first ledger needs point-in-time recovery before it carries real
value: [`codemojex.postgres.md`](../../infra/codemojex/codemojex.postgres.md) ("The work before real money")
names continuous WAL archiving and a streaming replica as launch prerequisites, and ships `archive_mode = off`
until an archive command works. Second, that durability is **not** covered by the engine the rest of the floor
uses: the Module 12 loop ([bus-and-persistence](../echo-persistence/platform/bus-and-persistence/index.md))
carries the *available-first* tier — EchoStore pages and EchoMQ stream slices — into Graft+Tigris, while the
Postgres heap and WAL never enter it. Graft replicating its own commit LSN to Tigris does not archive Postgres's
WAL; they are disjoint logs over disjoint data.

The opportunity is the cursor. Graft's commit LSN already carries three meanings on one change-feed — a store
durability boundary, a replica position, a consumer offset ([graft.design.md](graft.design.md), "The commit LSN
is the synchronization cursor"). Bringing the Postgres **WAL LSN** onto that same feed would add a fourth — "the
money ledger's WAL is durable to here" — and let archive lag, replica position, and store durability be measured
on one axis.

## Common mechanism (shared by the Graft-touching arms)

Three properties are shared by every arm that touches Graft, and isolating them keeps the arms comparable:

- **The WAL LSN as a feed cursor.** Each archived WAL segment carries a start and end LSN and a timeline (TLI).
  Publishing the end LSN as a change-feed event — the shape `echo_graft_backend` already emits for engine commits
  (`{branded_id, lsn}`, [graft.integration.md](graft.integration.md) §3) — makes the ledger's durability frontier
  a platform metric rather than a private fact of a backup tool.
- **The fence coincidence.** Postgres requires `archive_command` to be idempotent and to refuse overwriting a
  same-named segment with different content. That is exactly the create-if-not-exists conditional put Graft already
  uses as its commit fence — OpenDAL's `ConditionNotMatch` ([graft.design.md](graft.design.md), the Tigris seam;
  [graft.integration.md](graft.integration.md) §4). The archive's hardest concurrency requirement is satisfied by
  a mechanism the engine ships.
- **Bytes-as-blobs, manifest-in-Graft.** WAL segments are opaque and do not deduplicate, so storing them as Graft
  pages would waste the page model. The shared shape is: segment/base-backup **blobs** under new Tigris keyspaces
  (`/wal/{cluster}/{tli}/...`, `/basebackups/...`) beside the engine's own `/segments` and `/logs`, with only the
  transactional **manifest** (segname, LSN range, timeline, object key, checksum) held in Graft.

One boundary holds across all four arms: this fork unifies the **durable transport and the cursor**, not the
databases. Postgres stays the consistency-first ACID engine; Graft is the archive/replication transport. The
`mesh.8.1` segmentation is preserved — each surface keeps its own CAP trade.

## The fork — four arms

### Arm A — Off-the-shelf PITR (WAL-G or pgBackRest → Tigris), Graft-independent

**Rationale.** The ledger needs arbitrary-point recovery at the lowest possible correctness risk. WAL-G and
pgBackRest are field-proven Postgres archive tools that target any S3-compatible store, including Tigris; adopting
one delivers PITR with no engine code and without betting payout recovery on a from-scratch restore path.

- **Why** — PITR is a launch prerequisite, and borrowed, validated restore correctness is the cheapest way to reach it.
- **What** — continuous WAL archiving plus periodic base backups to Tigris, with timeline-aware point-in-time restore.
- **Who** — the Operator/SRE configures and drills it; the codemojex ledger is the protected party; nothing reads its catalog over the bus.
- **When** — before real money; an infra-level change to `echo-postgres`, requiring no `echo_graft` rung.
- **Where** — `infra/postgres` (the `archive_command` / a sidecar) and a Tigris bucket; entirely outside `echo/apps/echo_graft`.

**Steelman.** WAL-G provides parallel, compressed, encrypted WAL and delta base backups with `backup-fetch` /
`wal-fetch` restore against an S3-compatible endpoint; pgBackRest offers the same class with strong validation.
Both handle the parts most easily gotten wrong by hand — timeline switches after promotion, gap detection,
retention expiry, parallel restore — and both are exercised across large production fleets. For a database whose
failure mode is a lost payout, the strongest argument is borrowed correctness: the restore path has been run and
validated by others at scale, and the only owned work is configuration plus a periodic restore drill. Tigris is
already the platform's object store, so the bytes land in the same provider and region as the durable floor.

**Steward.** The cost is a second durability substrate with its own cursor. WAL-G's catalog and LSN bookkeeping
sit outside the change-feed, so the ledger's durability frontier and archive lag are legible only through WAL-G's
own surface, not beside replica position and store durability on the platform's one cursor. It composes cleanly
with everything frozen — it touches nothing in `echo_graft` — and adds no platform invariant, but it leaves the
Module 12 "one system" thesis half-true: the available-first tier rides Graft+Tigris on a unified cursor while the
consistency-first ledger rides a parallel tool. One authority holds within each substrate, not across them.

### Arm B — Off-the-shelf bytes + a Graft WAL-frontier feed lane

**Rationale.** Keep Arm A's proven restore path for the correctness-critical bytes, and add only the missing
observability: publish the archived-WAL frontier (WAL LSN + timeline) onto the existing change-feed. This captures
the unified cursor — the one thing Arm A lacks — at minimal new surface and with no code on the recovery path.

- **Why** — the platform's distinctive value over stock tooling is the one-cursor observability of Module 12, not a re-implementation of PITR.
- **What** — a low-volume status feed: each archived segment's end LSN and timeline published as a change-feed event, so archive lag (current WAL LSN minus archived frontier) is a first-class platform metric.
- **Who** — the dashboard and alerting consume the frontier; the Operator/SRE still owns WAL-G; codemojex is the protected party.
- **When** — immediately after Arm A; a thin lane, no `echo_graft` engine change.
- **Where** — a read-only publisher beside `echo_graft_backend`'s change-feed lane ([graft.design.md](graft.design.md)), reading WAL-G's archive status or `pg_stat_archiver`; the bytes remain under WAL-G in Tigris.

**Steelman.** This separates the correctness-critical concern (restore) from the platform-integration concern
(observability) and sources each where it is strongest — restore from WAL-G, the cursor from the platform's own
feed. The frontier event reuses the exact shape `echo_graft_backend` publishes for engine commits
([graft.integration.md](graft.integration.md) §3), so a consumer subscribing "from this LSN" treats ledger
durability the way it treats store durability and stream offset. Archive lag — the earliest warning for the
`archive_mode` hazard [`codemojex.postgres.md`](../../infra/codemojex/codemojex.postgres.md) names, where a failing
`archive_command` fills `pg_wal` and halts the database — becomes a feed metric rather than a log scrape. The new
code is a read-only publisher; it cannot corrupt a backup because it never writes one.

**Steward.** The liability is small but real: a publisher that republishes WAL-G's status is a second
representation of one fact, and two representations can disagree if the publisher lags or mis-parses. The frontier
on the feed is advisory observability, never the restore authority — the contract and its consumers must state
this, or an operator may trust a stale feed value over WAL-G's catalog mid-recovery. It adds one low-volume lane to
maintain and freeze. It honors Thin but robust and Do no harm — read-only, off the money path — and it leaves the
door to Arm C open without committing to it: the feed contract is identical whether the frontier is published by a
WAL-G reader or, later, by a Graft commit.

### Arm C — Graft-native WAL-archive Volume

**Rationale.** Let Graft own the archive end to end. A per-cluster WAL-archive Volume holds the segment manifest
committed under Graft's fence; WAL and base-backup blobs land in the same Tigris bucket via OpenDAL; a new
`echo_graft_backend` verb records each segment and publishes the WAL LSN. One engine, one fence, one feed for both
tiers.

- **Why** — the deepest form of the Module 12 "one system" claim: the ledger's off-site durability uses the same engine, fence, bucket, and cursor as the rest of the floor.
- **What** — a forward-tense `WAL_COMMIT` lane on `echo_graft_backend` that, per archived segment, writes the blob to Tigris under the create-if-not-exists fence, commits a manifest entry to a branded WAL-archive Volume, and publishes `{VOL…wal, wal_lsn, tli}`; restore reads the manifest to verify a gap-free chain before replay.
- **Who** — `echo_graft_backend` operates it; a small `archive_command` shim on `echo-postgres` feeds it over `echo_graft_proto`; the Operator owns restore drills.
- **When** — a new rung beyond the current `echo_graft` ladder (eg.1–eg.6, [graft.roadmap.md](graft.roadmap.md)), after the engine's restore path holds the fault-suite bar.
- **Where** — `echo/apps/echo_graft` (the sidecar lane) plus a manifest Volume and new `/wal` + `/basebackups` Tigris keyspaces beside `/segments` and `/logs`.

**Steelman.** The fence the `archive_command` contract demands — refuse to clobber a same-named segment, idempotent
on retry — is the conditional put Graft already uses as its commit fence ([graft.design.md](graft.design.md);
[graft.integration.md](graft.integration.md) §4). The archive's hardest correctness requirement is met by the
mechanism the engine ships, not by new code. The manifest committed to a Graft Volume is the authoritative durable
frontier the same way the archive fold derives its watermark `W` from the engine's committed frontier
([the loop closes](../echo-persistence/platform/bus-and-persistence/the-loop-closes.md)) — the recovery cut cannot
drift from what is committed. And the payoff is total: the WAL LSN becomes the next meaning of the one cursor
([the commit LSN is the cursor](../echo-persistence/platform/bus-and-persistence/the-commit-lsn-is-the-cursor.md)),
so replica position, consumer offset, store durability, and ledger durability are measured on one axis, by one
feed, against one fence, in one bucket.

**Steward.** This is the most expensive arm to keep, and the cost lands on the part that must never be wrong. It
re-implements machinery WAL-G already provides — timeline tracking, gap detection, retention, parallel restore —
and every line of it is on the payout-recovery path, where a defect surfaces during a disaster. `WAL_COMMIT` is a
new public verb on `echo_graft_proto`; once consumed it freezes, joining the byte-frozen-protocol discipline the
platform already carries, and the restore path must earn the ≥100-iteration and `--test-threads=1` fault coverage
the rest of `echo_graft` holds before it can be trusted with money. It composes with the COEXIST law — native
`EchoStore.Graft.*` untouched, the new lane a peer — but it adds the largest new invariant surface of any arm, and
it ages against Postgres's WAL format and timeline rules. An arm that owns money recovery is a multi-year liability
priced in incidents, not commits.

### Arm D — Graft pageserver under a Postgres replica (Neon-style)

**Rationale.** Separate Postgres compute from storage. A Graft-backed pageserver materializes pages from the WAL
and serves them to a Postgres replica, so physical replication, near-instant replicas, and PITR all derive from one
WAL-driven engine — the ledger's storage becomes Graft.

- **Why** — the maximal unification: not only the archive but the live storage of the ledger rides the engine, dissolving the separate-substrate split entirely.
- **What** — a pageserver that ingests Postgres WAL, stores versioned pages in Graft/Tigris, and answers a replica's page requests at an LSN; PITR and branch-from-LSN fall out of versioned pages.
- **Who** — a new long-lived service the platform operates; the codemojex ledger is the tenant.
- **When** — far forward-tense, well beyond the current ladder, and only if multi-tenant Postgres-at-scale becomes a platform goal.
- **Where** — a new `echo/apps` component (a pageserver crate) plus a Postgres storage integration; the deepest reach into the tree of any arm.

**Steelman.** This makes "one engine for all durable state" literally true: the page-versioned, Tigris-replicated,
lazy-fault model Graft already implements ([graft.design.md](graft.design.md)) is the model a Postgres pageserver
needs, and Neon has shown the architecture sound for production Postgres. Instant replicas — a follower ready from a
log-head read plus lazy page faults rather than a full base-backup restore — would apply to the ledger exactly as
they apply to the store today, collapsing the replica and the PITR questions into one mechanism. For a future of
many Postgres tenants on the platform, separating compute from a shared page store is the architecture that scales.

**Steward.** The cost is disproportionate to a single-region money node and the liability is open-ended. It couples
the platform to Postgres's internal page format and WAL semantics — a coupling that breaks on major-version
page-format changes and must be maintained against an external project's internals. It is a pageserver: an
always-on, correctness-critical service on the ledger's read path, where a fault is a ledger outage, not a stale
cache. Against streaming replication — a built-in Postgres feature that delivers low-RTO failover for one node at
near-zero build cost — a bespoke pageserver is a large standing investment for a problem the workload does not yet
have. It belongs on the table as the honest end of the spectrum and, at present scale, as the arm the Operator can
reject with its cost named.

## The fork surface

The arms set side by side; the trade is along restore-correctness risk against unification reach:

| Arm | PITR | Restore-correctness risk | WAL LSN on the feed | Substrate | Failover it enables | New frozen surface | Reachable |
|---|---|---|---|---|---|---|---|
| **A** — WAL-G/pgBackRest → Tigris | yes | low (borrowed) | no | second (WAL-G catalog) | warm standby | none | now, infra-only |
| **B** — A + Graft WAL-frontier lane | yes (via A) | low | yes (advisory) | second + one feed lane | warm standby | one read-only lane | now, after A |
| **C** — Graft-native WAL-archive Volume | yes | high (new path) | yes (authoritative) | one (Tigris + Graft) | warm standby | `WAL_COMMIT` wire verb | forward, post-eg.6 rung |
| **D** — Graft pageserver under a replica | yes | very high | yes | one (storage *is* Graft) | instant replicas | pageserver + PG storage API | far forward |

No arm, by itself, supplies low-RTO hot-standby failover; A–C enable a warm cross-region standby that restores and
replays from the archive, and the streaming replica named in [`codemojex.postgres.md`](../../infra/codemojex/codemojex.postgres.md)
remains the separate answer for fast failover until Arm D.

**Recommendation (advice, not a decision).** The architect's recommendation is **A, then B**. The one reason that
carries it: for a money ledger, restore correctness outranks engine elegance — Arm A reaches money-grade PITR on
borrowed, validated correctness immediately, and Arm B then adds the unified cursor that motivates the whole fork
without placing any new code on the payout-recovery path. Arm C is the satisfying end-state to earn once
`echo_graft`'s restore path holds the fault-suite bar; Arm D is priced and, at present scale, recommended against.

**The choice is the Operator's.** "An agent surfaces forks; it never decides them"
([aaw.architect-approach.md](../aaw/aaw.architect-approach.md)). Deferred, this fork becomes a named decision in the
roadmap's "Seams & open decisions" ([aaw.rules.md](../aaw/aaw.rules.md)); ruled, the ruling lands in the decisions
channel and each losing arm keeps its `CHOSEN-AGAINST:` rationale so the path not taken stays inspectable. Given
the stakes — a money-recovery path, and a frozen wire verb in Arm C — this fork qualifies for the optional
**multi-architect debate** (an operability/developer-experience lens against a spec-steward/invariants lens) before
ruling ([aaw.architect-approach.md](../aaw/aaw.architect-approach.md), "The multi-architect debate").

## Ruling

**RULED (Operator, 2026-06-26): Arm A, then Arm B.** WAL-G or pgBackRest → Tigris delivers money-grade PITR on
borrowed, validated restore correctness now; the read-only Graft WAL-frontier lane then adds the unified cursor
without placing any code on the payout-recovery path. The path now flows to its build artifacts — Arm A as an
operational runbook on `echo-postgres` ([`codemojex.postgres.md`](../../infra/codemojex/codemojex.postgres.md),
"The work before real money"), and Arm B as a triad for the WAL-frontier lane on `echo_graft_backend`
([specs.approach.md](../elixir/specs/specs.approach.md)).

**CHOSEN-AGAINST — kept on record so the path not taken stays inspectable:**

- **Arm C — deferred, not rejected.** Its Steelman holds (one engine, one fence, one feed); its Steward sets the
  price of admission: a new `WAL_COMMIT` wire verb that freezes once consumed, and a from-scratch restore path on
  the money line that must first earn the ≥100-iteration and `--test-threads=1` fault coverage the rest of
  `echo_graft` carries. Re-open as a post-eg.6 rung once that bar is met. Arm B is built so as not to foreclose it —
  the feed contract is identical whether the frontier is published by a WAL-G reader or, later, by a Graft commit.
- **Arm D — declined at present scale.** A Graft pageserver is disproportionate to a single-region money node and
  couples the platform to Postgres's page format; streaming replication remains the failover answer named in
  [`codemojex.postgres.md`](../../infra/codemojex/codemojex.postgres.md). Re-open only if multi-tenant
  Postgres-at-scale becomes a platform goal.

Per [aaw.architect-approach.md](../aaw/aaw.architect-approach.md), this ruling also belongs in the program's
decisions channel (`RULED:`) and, if one is maintained for `echo_graft`, the roadmap's "Seams & open decisions"
([graft.roadmap.md](graft.roadmap.md)).

## References

- The four-part arm, the fork surface, the surface-forks boundary: [aaw.architect-approach.md](../aaw/aaw.architect-approach.md).
- The Decisions fence and the "Seams & open decisions" home for a deferred fork: [aaw.rules.md](../aaw/aaw.rules.md).
- The Graft engine surface argued against — Volume / commit / LSN / the OpenDAL conditional-put fence / the change-feed: [graft.design.md](graft.design.md), [graft.integration.md](graft.integration.md).
- The current `echo_graft` ladder (eg.1–eg.6) Arm C extends: [graft.roadmap.md](graft.roadmap.md).
- The ledger's PITR + replica prerequisite, and the `archive_mode`-off hazard: [`codemojex.postgres.md`](../../infra/codemojex/codemojex.postgres.md).
- The "one system / one cursor" thesis the arms unify toward: [bus-and-persistence](../echo-persistence/platform/bus-and-persistence/index.md).

---

_Status: RULED (2026-06-26) · Arm A → Arm B chosen, Arm C deferred, Arm D declined. No arm is built yet; the chosen path now flows to Arm A's runbook and Arm B's triad ([specs.approach.md](../elixir/specs/specs.approach.md))._
