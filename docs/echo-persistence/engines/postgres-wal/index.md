---
title: "Module 11 — Postgres WAL on the floor"
id: ep-m11-hub
status: proposed
route: "/echo-persistence/engines/postgres-wal"
kind: "module 11 hub — Chapter III, 3 dives (PROPOSED — a ruled-but-unbuilt design)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive ledger-joins-the-floor SVG; no machine numbers. Forward-tense: this module teaches a PROPOSED design, not shipped code."
grounded-in: "docs/graft/graft.pg-wal-archive.design.md (the surfaced fork, RULED A→B) · docs/echo-persistence/platform/bus-and-persistence (the one cursor) · docs/echo-persistence/engines/tigris+fence (the create-if-not-exists fence) · infra/codemojex/codemojex.postgres.md (the ledger's PITR prerequisite)"
renders-to: "engines/postgres-wal/index.html"
---

# Postgres WAL on the floor { id="ep-m11-hub" }

> _The engines chapter built one durable floor — Champ accepts, CubDB/Fjall holds, Graft commits one LSN to Tigris behind the fence. But that floor carries the **available-first** tier: the cache and the stream log. The money lives elsewhere — in Postgres, the **consistency-first** ledger — and its write-ahead log never reaches the floor. This module is the PROPOSED design (a surfaced fork, ruled A→B) for bringing the ledger's **WAL LSN** onto the same Tigris floor and the same one cursor, so point-in-time recovery for the money rides the engine the platform already runs._

> {style="note"}
> **Forward-tense.** Unlike Modules 7–10, nothing here is shipped. The design is recorded and ruled (`graft.pg-wal-archive.design.md`); the page teaches the proposal, not as-built code.

**Interactive figure (hub).** Two columns: the **Postgres ledger** (consistency-first, its own WAL LSN) on the left, the **Graft floor → Tigris** (available-first, its commit LSN) on the right, with the platform's **change-feed** running beneath both. Tapping ① _two LSN worlds_ shows them disjoint — the WAL never reaches the floor, and only the Graft commit LSN rides the feed; ② _the fence_ lights the archive path, where Postgres's `archive_command` writes WAL to Tigris under the **same create-if-not-exists** the engine commits with; ③ _the unified cursor_ publishes the WAL LSN onto the feed beside the commit LSN — the ledger's durability becomes the next meaning of the one cursor.

## §1 Why the ledger isn't on the floor — yet { id="gap" }

The platform segments its CAP trade per surface, and durability follows the split. The **available-first** tier — the near-cache and the EchoMQ stream log — rides the floor this chapter built: its pages and its trimmed stream slices become Graft commits replicated to Tigris, and the commit LSN binds replica, consumer, and store on one cursor (Module 13). The **consistency-first** ledger is a different surface: balances and an append-only transaction ledger in Postgres, mutated all-or-nothing, where a committed payout must never be lost. Its durable record is its own **write-ahead log**, with its own LSN — a different log over different bytes. Graft replicating its commit LSN to Tigris does not archive Postgres's WAL; the two are disjoint, and the money's off-site recovery is, today, unsolved on the floor.

That is the gap this module closes in design. Postgres point-in-time recovery and a streaming replica are the ledger's launch prerequisites (`codemojex.postgres.md`, "the work before real money"), and the question is whether to answer them with a parallel, off-platform backup tool or to bring the WAL onto the engine, the fence, the bucket, and the cursor the rest of the floor already shares. The design surfaces that as a four-arm fork and rules it; the dives walk the idea, the mechanism, and the decision.

## §2 The three dives { id="dives" }

- **Dive 11.1 — Two LSN worlds** — the Graft commit LSN and the Postgres WAL LSN, why they are disjoint logs over disjoint data, and what the ledger's durability gap actually is. → `/echo-persistence/engines/postgres-wal/two-lsn-worlds`
- **Dive 11.2 — The archive_command is the fence** — Postgres requires `archive_command` to be idempotent and to never clobber a same-named segment; that is exactly the create-if-not-exists the engine commits with (Module 9). One fence, reused; the WAL-archive manifest as the authoritative frontier. → `/echo-persistence/engines/postgres-wal/the-archive-command-fence`
- **Dive 11.3 — A then B, forward-tense** — the surfaced fork (four arms from off-the-shelf WAL-G to a Graft pageserver), the ruling A→B, and why borrowed restore correctness comes before engine elegance for money. → `/echo-persistence/engines/postgres-wal/the-fork-a-then-b`

## §3 Status & check { id="status" }

**Status.** PROPOSED. The fork is recorded and ruled in `graft.pg-wal-archive.design.md`: **Arm A** (WAL-G/pgBackRest → Tigris) then **Arm B** (a read-only Graft WAL-frontier lane on the change-feed); Arm C (a Graft-native WAL-archive Volume) is deferred, Arm D (a Graft pageserver under a replica) is declined at present scale. No arm is built.

**Check.** Without code: why doesn't the Graft+Tigris floor already cover Postgres PITR, and what single object-store primitive lets the WAL ride the *same* fence as a Graft commit? "Two disjoint logs; create-if-not-exists" means you have the module.

## §4 References & sources { id="refs" }

Echo records:
- graft.pg-wal-archive.design.md — the surfaced fork (four arms) and the ruling A→B — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.pg-wal-archive.design.md
- bus-and-persistence — the commit LSN as the one cursor the WAL LSN would join — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo-persistence/platform/bus-and-persistence/index.md
- graft.design.md — the commit, the LSN, the conditional-write fence reused here — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- codemojex.postgres.md — the ledger's PITR + replica prerequisite, the archive_mode hazard — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/infra/codemojex/codemojex.postgres.md

External:
- PostgreSQL — Continuous Archiving and PITR (archive_command, recovery_target_lsn, timelines) — https://www.postgresql.org/docs/current/continuous-archiving.html
- WAL-G — WAL archiving + base backups to S3-compatible storage — https://github.com/wal-g/wal-g
- pgBackRest — backup & restore with validation — https://pgbackrest.org/

---

_Pager: ← Module 10 — The BEAM↔Rust contract · Dive 11.1 — Two LSN worlds →_
