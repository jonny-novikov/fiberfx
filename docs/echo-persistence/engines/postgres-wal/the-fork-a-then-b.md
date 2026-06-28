---
title: "A then B, forward-tense"
id: ep-m11-d3
status: proposed
route: "/echo-persistence/engines/postgres-wal/the-fork-a-then-b"
kind: "module 11 · dive 11.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive risk×unification fork-plane SVG; no machine numbers. Forward-tense: this dive teaches a PROPOSED, ruled design — the four surfaced arms and the ruling A→B — not shipped code."
grounded-in: "docs/graft/graft.pg-wal-archive.design.md (the surfaced fork — four arms — and the §Ruling A→B) · docs/aaw/aaw.architect-approach.md (the four-part arm; an agent surfaces forks, the Operator rules; losing arms keep their CHOSEN-AGAINST rationale)"
renders-to: "engines/postgres-wal/the-fork-a-then-b.html"
---

# A then B, forward-tense { id="ep-m11-d3" }

> _The gap is named and the mechanism is found: the WAL would ride the same fence, the same bucket, the same cursor. So how far should the unification reach? The design does not guess — it surfaces a **fork of four arms**, from off-the-shelf WAL-G archiving to a Graft pageserver under the ledger, argues each at its best and its true long-game cost, and leaves the ruling to the Operator. This dive reports what was ruled: **Arm A, then Arm B**. The one reason that carries it is small and it is everything — for a money ledger, **restore correctness outranks engine elegance**._

> {style="note"}
> **Forward-tense.** Nothing here is built. The design is recorded and ruled (`graft.pg-wal-archive.design.md`, the four arms and the §Ruling); this dive teaches the decision — what was surfaced and what was chosen — not as-built code. The losing arms keep their `CHOSEN-AGAINST` rationale on record.

**Interactive figure.** A risk × unification plane. The vertical axis is restore-correctness risk (low at the bottom, very high at the top); the horizontal axis is unification reach (least at the left, most — one engine, one fence, one cursor — at the right). Four arms sit on it: **Arm A** (WAL-G/pgBackRest → Tigris) bottom-left, low risk and least unified, _chosen_; **Arm B** (A plus a Graft WAL-frontier feed lane) just right of it at low risk with the unified cursor, _chosen_; **Arm C** (a Graft-native WAL-archive Volume) high and right, high risk and fully unified, _deferred_; **Arm D** (a Graft pageserver under a Postgres replica) top-right, very high risk and total unification, _declined_. A green arrow connects A→B as the chosen path. Tapping an arm shows its one-line steelman, its steward, and its disposition; the chosen path lights when a chosen arm is in focus.

## §1 The fork — four arms on a spectrum { id="fork" }

One boundary holds across all four arms, and naming it keeps them comparable: the fork would unify the **durable transport and the cursor**, never the databases. Postgres stays the consistency-first ACID engine that owns the money; Graft stays the archive and replication transport. Every arm preserves the `mesh.8.1` segmentation — each surface keeps its own CAP trade. What the arms differ on is a single axis: how much off-site recovery for the ledger should ride the same engine, fence, bucket, and cursor as the rest of the floor, traded against how much new, correctness-critical code that costs. The design plots them from least to most unified.

**Arm A — WAL-G or pgBackRest → Tigris.** Off-the-shelf, Graft-independent point-in-time recovery: continuous WAL archiving plus periodic base backups to the same Tigris bucket, with timeline-aware restore. Its steelman is **borrowed correctness** — WAL-G and pgBackRest handle the parts most easily gotten wrong by hand (timeline switches after promotion, gap detection, retention, parallel restore), and their restore paths have been run and validated by others at scale. Its steward names the cost honestly: a second durability substrate with its own catalog and LSN bookkeeping that sits *outside* the change-feed, so the ledger's durability frontier is legible only through WAL-G's own surface. It composes cleanly with everything frozen because it touches nothing in `echo_graft`, but it would leave the "one system" thesis half-true.

**Arm B — A, plus a Graft WAL-frontier feed lane.** Keep Arm A's proven restore path for the correctness-critical bytes, and add only the missing observability: a read-only publisher that puts each archived segment's end LSN and timeline onto the existing change-feed, so archive lag becomes a first-class platform metric beside replica position and store durability. The steelman separates the two concerns and sources each where it is strongest — restore from WAL-G, the cursor from the platform's own feed — reusing the exact event shape `echo_graft_backend` already publishes for engine commits; the new code is read-only and **cannot corrupt a backup because it never writes one**. The steward's liability is small but real: a publisher is a second representation of one fact, so the frontier on the feed must be declared *advisory observability, never the restore authority*, lest an operator trust a stale feed value over WAL-G's catalog mid-recovery.

**Arm C — a Graft-native WAL-archive Volume.** Let Graft own the archive end to end: a forward-tense `WAL_COMMIT` lane that, per archived segment, writes the blob to Tigris under the create-if-not-exists fence, commits a manifest entry to a branded WAL-archive Volume, and publishes the WAL LSN — one engine, one fence, one feed for both tiers. Its steelman is the deepest form of the "one system" claim, and the fence the `archive_command` contract demands is precisely the conditional put the engine already commits with. Its steward is the heaviest of any arm and lands on the part that must never be wrong: it would re-implement machinery WAL-G already provides, every line of it on the payout-recovery path, and `WAL_COMMIT` is a new public wire verb that **freezes once consumed**. An arm that owns money recovery is a multi-year liability priced in incidents, not commits.

**Arm D — a Graft pageserver under a Postgres replica.** The honest end of the spectrum: a Neon-style pageserver that materializes pages from the WAL and serves them to a replica, so physical replication, near-instant replicas, and PITR all derive from one WAL-driven engine — the ledger's *storage* becomes Graft. Its steelman is total unification and an architecture Neon has shown sound for production Postgres at many tenants. Its steward is decisive at present scale: a pageserver is an always-on, correctness-critical service on the ledger's read path, coupled to Postgres's internal page format, and disproportionate to a single-region money node when streaming replication already delivers low-RTO failover at near-zero build cost.

## §2 The ruling — A then B { id="ruling" }

The Operator ruled **Arm A, then Arm B**. The one reason that carries it is the dive's whole lesson restated as a priority: **for a money ledger, restore correctness outranks engine elegance.** Arm A reaches money-grade PITR on borrowed, validated correctness immediately — the restore path the recovery depends on has already been run and proven by others — and Arm B then adds the unified cursor that motivates the entire fork *without placing any new code on the payout-recovery path*. The platform's distinctive value over stock tooling is the one-cursor observability, not a re-implementation of PITR; A buys the recovery, B buys the observability, and neither bets the money on a from-scratch restore path. The build artifacts follow the ruling: Arm A becomes an operational runbook on `echo-postgres`, Arm B a triad for the WAL-frontier lane on `echo_graft_backend`.

**Arm C is deferred, not rejected.** Its steelman holds — one engine, one fence, one feed — but its steward sets the price of admission, and the price is a fault bar: the from-scratch restore path on the money line must first earn the `≥100-iteration` and `--test-threads=1` fault coverage the rest of `echo_graft` already carries, and `WAL_COMMIT` freezes the moment it is consumed. The re-open condition is explicit — a post-eg.6 rung, once that bar is met. Arm B is deliberately built so as not to foreclose it: the feed contract is identical whether the frontier is published by a WAL-G reader now or by a Graft commit later, so choosing B today keeps the door to C open without committing to it.

**Arm D is declined at present scale** — not wrong, disproportionate. A bespoke pageserver is a large standing investment for a problem the single-region money node does not yet have; streaming replication remains the named failover answer. It is re-openable only if multi-tenant Postgres-at-scale becomes a platform goal. No arm is built; the ruling sets the order of work, and the losing arms keep their best case on record so the path not taken stays inspectable a year from now.

## §3 The method — surface, don't decide { id="method" }

The shape of this decision is not incidental — it is the architect's method of record. A fork is a set of **arms**, and each arm is argued in four parts in a load-bearing order: the **Rationale** earns it a place on the table as a credible answer (never a strawman), the **5W** — Why · What · Who · When · Where — frames it as something locatable and schedulable, the **Steelman** is the strongest case *for* it argued by an advocate who wants it to win, and the **Steward** is the long-game counterweight: what the arm costs to keep for years. The Steward is honest even about the arm the architect favors; the design's recommendation of A→B carried a steward that named A's second-substrate cost plainly.

After the arms, the fork is **surfaced, not resolved**: the arms are set side by side in a table so the trade is legible at a glance, the architect *may* note a recommendation with the one reason that carries it, but the choice is the Operator's without exception. **"An agent surfaces forks; it never decides them"** — an architect that picks the winner has stopped being a steward and become an unaccountable author. Once ruled, the ruling is recorded and the losing arms keep their `CHOSEN-AGAINST` rationale — which is exactly why C carries its re-open condition and D carries its named cost on this page rather than vanishing. This dive is the downstream half of that arc: the architect surfaced the four arms, the Operator ruled, and the chosen arm now flows into a triad.

## §4 Status & check { id="status" }

**Status.** PROPOSED & RULED. The fork is recorded and ruled in `graft.pg-wal-archive.design.md`: **Arm A** (WAL-G/pgBackRest → Tigris) then **Arm B** (a read-only Graft WAL-frontier lane on the change-feed); Arm C (a Graft-native WAL-archive Volume) is deferred behind the fault bar, Arm D (a Graft pageserver under a replica) is declined at present scale. No arm is built; WAL-G and pgBackRest are real off-the-shelf tools, while the Graft-native Volume, the `WAL_COMMIT` verb, and the pageserver are forward-tense.

**Check.** Without code: name the one reason A→B was ruled over the more unified arms, and the re-open condition that keeps C on the table. "Restore correctness outranks engine elegance; C re-opens once the restore path earns the fault bar and `WAL_COMMIT` can freeze" means you have the dive.

## §5 References & sources { id="refs" }

Echo records:
- graft.pg-wal-archive.design.md — the surfaced fork (four arms) and the ruling A→B — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.pg-wal-archive.design.md
- aaw.architect-approach.md — the four-part arm; surface, never decide — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/aaw/aaw.architect-approach.md
- Module 11 · Postgres WAL on the floor — the gap, the mechanism, this dive's hub — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo-persistence/engines/postgres-wal/index.md
- the create-if-not-exists fence — the fence the WAL-archive would reuse — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo-persistence/engines/tigris+fence/the-create-if-not-exists-fence.md
- codemojex.postgres.md — the ledger's PITR + replica prerequisite — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/infra/codemojex/codemojex.postgres.md

External:
- PostgreSQL — Continuous Archiving and PITR (archive_command, recovery_target_lsn, timelines) — https://www.postgresql.org/docs/current/continuous-archiving.html
- WAL-G — Arm A — WAL archiving + base backups to S3-compatible storage — https://github.com/wal-g/wal-g
- pgBackRest — Arm A — backup & restore with validation — https://pgbackrest.org/
- Neon — storage architecture — Arm D — the pageserver model declined at present scale — https://neon.tech/blog/architecture-decisions-in-neon

---

_Pager: ← Dive 11.2 — The archive_command is the fence · Module 12 — EchoMQ Bus →_
