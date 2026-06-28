---
title: "Two LSN worlds"
id: ep-m11-d1
status: proposed
route: "/echo-persistence/engines/postgres-wal/two-lsn-worlds"
kind: "module 11 · dive 11.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive two-tracks SVG; no machine numbers. Forward-tense: the gap is real today; the close is PROPOSED, not shipped."
grounded-in: "docs/graft/graft.pg-wal-archive.design.md (§Context — the gap and the opportunity · §Common mechanism) · docs/echo-persistence/platform/bus-and-persistence (the one cursor, Module 12–13) · infra/codemojex/codemojex.postgres.md (the work before real money — PITR + replica prerequisite, archive_mode-off hazard)"
renders-to: "engines/postgres-wal/two-lsn-worlds.html"
---

# Two LSN worlds { id="ep-m11-d1" }

> _The engines chapter taught one word — LSN — as the floor's cursor: Graft's commit LSN already means three things on one change-feed. But the consistency-first ledger uses the same word for a different log over different bytes. Graft never reads Postgres's heap or its write-ahead log, so the money's durable record never reaches Tigris — it lives only in `pg_data` on one Fly volume. The ledger is off the floor. This dive names the gap before the next two dives close it._

**Interactive figure.** Two horizontal log tracks. The top track — **Graft · commit LSN** — has an arrow up to a Tigris box (its pages and trimmed stream slices replicate off-site) and an arrow down onto a change-feed bar (it rides the one cursor). The bottom track — **Postgres · WAL LSN** — has an arrow only to a local **pg_data (one volume)** box: no arrow off the box, nothing on the feed. Tapping _host loss?_ lights the Graft track green (recoverable from Tigris) and the ledger red (only local — gone). Tapping _the cursor_ shows only the commit LSN on the feed, the WAL LSN absent. Tapping _two logs_ rests on the disjointness: same word, different log, different bytes.

## §1 The same word, two logs { id="two-logs" }

The engines chapter spent its last modules on one number. Graft's **commit LSN** is the available-first floor's cursor, and it already carries three meanings on one change-feed: a store-durability boundary, a replica position, and a consumer offset (Module 12–13, the one cursor). What it replicates to Tigris is the available-first tier's durable record — EchoStore's pages and the Stream Tier's trimmed slices become Graft commits behind the create-if-not-exists fence (Module 9). Postgres uses the same three letters for something else entirely. Its **WAL LSN** is the consistency-first ledger's write-ahead-log position — the byte offset into the log that records every change to balances and the append-only transaction ledger before it touches the heap, the log against which a committed payout must never be lost. Same word, different log over different bytes: Graft's LSN counts engine commits to Tigris; Postgres's LSN counts heap changes to its own WAL. Reading "LSN" on the feed and assuming it covers both is the mistake this module exists to prevent.

## §2 Disjoint, by construction { id="disjoint" }

The two logs are not merely different — they are disjoint, and disjoint by construction. Graft commits the pages it is given and replicates them to Tigris; it never reads Postgres's heap files and never reads its WAL. So when the floor's commit LSN advances and a new segment lands in the bucket, not one byte of the ledger went with it. The ledger's durable record stays where Postgres put it: in `pg_data`, on the single Fly volume the database runs on. That is the gap stated plainly — a host or volume loss takes the money with it, because nothing of the ledger is off-site. The available-first tier survives such a loss by reading its head back from Tigris (Module 9); the consistency-first ledger has no Tigris to read from. The floor this chapter built does not cover Postgres point-in-time recovery, and it cannot, because Graft never sees the bytes that would need recovering. The ledger is off the floor — and `infra/codemojex/codemojex.postgres.md` ships `archive_mode = off` until that is fixed, naming continuous WAL archiving and a streaming replica as the launch prerequisites: "the work before real money."

## §3 What the module proposes { id="proposes" }

Naming the gap sets the module's job, which is PROPOSED and forward-tense: bring the WAL LSN onto the **same floor** and the **same cursor** the available-first tier already rides. Two facts make that more than a hope. First, an archived WAL segment carries a start LSN, an end LSN, and a timeline — the end LSN is a frontier that can ride the change-feed in the exact shape the engine already publishes for its commits, so the ledger's durability becomes a platform metric beside replica position and store durability rather than a private fact of a backup tool. Second, Postgres requires its archive step to be idempotent and to refuse overwriting a same-named segment with different content — which is the create-if-not-exists conditional put Graft already uses as its commit fence (the next dive walks exactly this coincidence). Nothing here is built: the design doc surfaces a four-arm fork and the Operator has ruled it Arm A → Arm B — proven off-the-shelf restore for the bytes, then a read-only frontier lane for the cursor. This dive only names the two worlds; Dive 11.2 reuses the fence, and Dive 11.3 walks the ruling.

## §4 References & sources { id="refs" }

Echo records:
- graft.pg-wal-archive.design.md — §Context (the gap: Graft never archives Postgres's WAL; disjoint logs over disjoint data) and §Common mechanism (the WAL LSN as a feed cursor; the fence coincidence) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.pg-wal-archive.design.md
- bus-and-persistence — the commit LSN as the one cursor (store-durability boundary, replica position, consumer offset) the WAL LSN would join — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo-persistence/platform/bus-and-persistence/index.md
- codemojex.postgres.md — "the work before real money": PITR + streaming replica as launch prerequisites, the archive_mode-off hazard, the ledger on one Fly volume — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/infra/codemojex/codemojex.postgres.md

External:
- PostgreSQL — Write-Ahead Logging (the WAL, the LSN as a log position) — https://www.postgresql.org/docs/current/wal-intro.html
- PostgreSQL — Continuous Archiving and PITR (archive_command, archive_mode, timelines) — https://www.postgresql.org/docs/current/continuous-archiving.html

---

_Pager: ← Module 11 — Postgres WAL on the floor · Dive 11.2 — The archive_command is the fence →_
