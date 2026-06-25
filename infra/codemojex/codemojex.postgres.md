# Codemojex · PostgreSQL node on Fly: the system of record for money

Codemojex keeps its money in PostgreSQL — balances and a transaction ledger, mutated inside short ACID write transactions — so the database is tuned not for analytics but for a steady stream of small writes, a hot row that churns, and durability that never drops a committed payout. This article gives the approach and the configuration for a custom Postgres node on Fly: the official image stripped to a private machine, sized to the workload, with the one operational hazard this write pattern creates named and fixed. As an architecture decision of record for the project: the playable entity is a **game** (`GAM`), a state machine inside a room (`ROM`).

## Scope and method

The node is PostgreSQL 17 from the official image on a Fly `shared-cpu-2x` machine with two gigabytes of memory, reached by the `codemojex` umbrella over the private 6PN. Tuning values and platform behaviour carry a numbered reference to the source that published them; statements about Codemojex are grounded in the committed `echo/apps/codemojex` source — the wallet and the migration — and cited by module and file. No benchmark was run; nothing here is a measurement of this system. The configuration files are `postgres/postgresql.conf`, `postgres/Dockerfile`, and `postgres/fly.toml`. Out of frame: the Valkey node and the queue, which other articles settle.

## The workload

The money lives in Postgres because that is where it must be ACID. `Codemojex.Repo` is described in its own words as the floor of truth the other layers stand on: balances, the transaction ledger, games with their secret, guesses, rooms, and emoji sets, durable and transactional, while the branded ids remain the primary keys. The shape of the writes is what sizes the node.

`Codemojex.Wallet` mutates a balance inside one database transaction: it locks the player row with a `SELECT ... FOR UPDATE`, checks the non-negative invariant, writes the new balance, and inserts the paired ledger row — all or nothing. The row lock serializes only same-player mutations, so the field is never funnelled through a single process; the database does the work a single-writer process once did, and the `players_non_negative` CHECK is the backstop if application logic ever slips. The per-guess path through `charge_guess/3` is the common case: a primary-key `SELECT ... FOR UPDATE`, a balance `UPDATE`, and one `INSERT` into the append-only `transactions` ledger, committed. A payout through `deposit_prize/3` and a purchase through `purchase_keys/3` are the same short shape.

Three tables move at three rates. `players` is **update-heavy** — one balance `UPDATE` per money operation. The balance columns carry no index (only the branded `USR` primary key is indexed), which matters below. `transactions` is **append-only**, one row per operation, indexed by player and time for statements. `guesses` is the **fastest-growing** table, one row appended per scored guess by `Codemojex.ScoreWorker`, indexed by game and player. The working set that stays hot — active players' balances, recent ledger rows — is small; the tables that grow without bound are the ledger and the guesses.

## The approach: a custom node, candidly unmanaged

Fly's own unmanaged Postgres is deprecated in favour of a fully managed service [11][12], so a custom node here is a deliberate choice for control over the configuration. The Fly-blessed way to self-run it is plain: point at the official Postgres Docker image and remove the default services, since this is not a public app [10]. That is exactly the `Dockerfile` and `fly.toml` beside this article — a pinned `postgres:17`, the tuned conf layered on, the public services stripped so the node answers only on the private network.

The cost of that control is stated, not papered over. This is unmanaged Postgres: if it runs out of memory or disk it needs hands to recover, the daily volume snapshots are kept only five days, and off-site backups, a replica, and recovery are the operator's to build [11]. The managed alternative exists — Fly's Managed Postgres starts at a Shared-2x machine with two gigabytes and includes high availability, backups, and a connection pooler [12] — and for a money game that does not want to own those, it is the candid recommendation. The article below assumes the custom node and names the work that ownership entails.

## The machine and the memory

Two shared vCPUs, two gigabytes. The class is forced the same way the Valkey node's was: one gigabyte would be the floor, but Postgres has more memory consumers than a cache — shared buffers, per-backend memory, the OS page cache over the data files, autovacuum workers — so two gigabytes is the pragmatic floor, matching the managed service's own starter size [12]. One gigabyte cannot be a performance machine in any case, since Fly's minimum there is 2048 megabytes per vCPU [13]; the machine size and the graceful-shutdown window are set in the `fly.toml` vm and top-level sections [16].

`shared_buffers` is 512 megabytes, the 25-percent-of-RAM guideline for a dedicated server with a gigabyte or more [1]. `effective_cache_size` is 1536 megabytes — a hint to the planner about how much is cached between shared buffers and the OS, not an allocation, and at three-quarters of RAM it nudges the planner toward the index scans an OLTP workload wants [2]. `work_mem` is held low at 8 megabytes because it is allocated per operation per connection and a single query can take several; the discipline is a low global with a per-query raise where a real sort needs it [3]. `maintenance_work_mem` is 256 megabytes for vacuum and index builds. Huge pages are requested but optional; their benefit is marginal at this buffer size.

## Durability: a committed payout must survive a crash

This is the section that does not bend for a money database. Commit in Postgres is synchronous by default: the server waits for the transaction's write-ahead-log records to reach durable storage before it tells the client the commit succeeded, so a transaction reported committed is preserved even if the server crashes the instant after [4]. Turning `synchronous_commit` off would buy a little throughput at the risk of losing the last fraction of a second of committed transactions on a crash — a trade an event log can make and a wallet cannot [5]. `fsync` stays on; turning it off risks not lost transactions but a corrupt cluster, advisable only when the database can be recreated from elsewhere [5][6]. `full_page_writes` stays on, the torn-page protection that lets recovery rebuild a page half-written during a crash [5]. The conf sets all three to the safe value and leaves them there.

## Write-ahead log and checkpoints

The log settings trade recovery time for steadier writes. `max_wal_size` is two gigabytes so checkpoints fire less often; the cost is more disk and a longer crash recovery, and the benefit is fewer full-page-write storms, since each checkpoint forces the next change to every page to carry a full image [5]. `checkpoint_completion_target` at 0.9 smears that checkpoint I/O across the interval rather than spiking it. `wal_compression` is on, trading a little CPU for less WAL volume on a small volume [9]. The level is `replica`, enough to attach a streaming replica and to take a base backup when the backup story below is wired.

## The hazard this write pattern creates

The operational risk for Codemojex is the same in spirit as the Valkey node's lingering keys, and it lives in the hot `players` row. Every per-guess balance `UPDATE` leaves the old row version behind as a dead tuple, because Postgres never updates in place. Two things decide whether that dead tuple is cheap or expensive. First, a Heap-Only-Tuple update — one that writes the new version on the same page and touches no index — is possible only when no modified column is indexed and the page has free space [7]. Codemojex's balance columns are not indexed, so the first condition holds; the second does not by default, because pages are packed full at the default fillfactor of 100, so the update spills to a new page and every index entry for the row must be rewritten [7]. Second, those dead tuples are reclaimed by vacuum, and the default autovacuum waits until a fifth of the table has died before it runs [8][9].

The fix is two settings, applied per table in a migration rather than globally. Lower the `players` fillfactor to about 90, leaving room on each page for the update to stay there as a HOT update, which keeps the primary-key index from bloating and lets even a plain read reclaim the dead version in passing [7]. And tighten that table's autovacuum so it triggers near one or two percent dead rather than twenty, so bloat never compounds [8][9]. The conf already sets the cluster-wide autovacuum aggressively — a short nap, a five-percent scale factor, insert-driven vacuuming for the append tables so their rows are frozen ahead of transaction-id wraparound, and a raised cost limit so vacuum keeps pace — and the conf comments carry the two per-table `ALTER TABLE` statements. One more guardrail matters: a session left idle in a transaction holds back the cleanup horizon and stalls vacuum across the whole database, so `idle_in_transaction_session_timeout` is set to bound a leaked connection [8]. Codemojex's wallet transactions are short by construction, which keeps this rare, but the guardrail is cheap insurance.

## Planner, I/O, and parallelism

The volume is NVMe, so `random_page_cost` is 1.1 rather than the default 4.0 that assumes a spinning disk; with random reads nearly as cheap as sequential, the planner picks index scans where it should [9]. `effective_io_concurrency` is raised so the storage's concurrency is used on the rare bitmap scan. JIT is off, because compiling a plan does not repay itself on the one-row lookups this workload runs, and parallel query is disabled for gathers, because a point read does not parallelize and a parallel worker would only contend for the two shared vCPUs. These are OLTP choices; an analytics node would set them the other way.

## Connections and pooling

A Postgres connection is a process and costs memory, so the node caps `max_connections` at 100 for headroom while the real control sits on the client: the Ecto pool should be bounded so the application never opens more than the node can afford, and a transaction-mode pooler in front is the scaling answer when app machines multiply. `password_encryption` is the modern SCRAM scheme, and `superuser_reserved_connections` keeps a few slots for an operator when the pool is saturated.

## The work before real money

Two pieces of the ownership the custom node entails are not optional for a wallet, and both should land before launch. First, point-in-time recovery: wire continuous WAL archiving to object storage — WAL-G or pgBackRest to Tigris — so a volume or host failure is a restore rather than a loss, because Fly's five-day volume snapshots are a floor, not a backup strategy [11]. This is why `archive_mode` ships off: enabling it without a working archive target fills the write-ahead-log directory and stops the database, so it is turned on only once the archive command is in place. Second, availability: a single Fly volume lives on one host in one region and is not network storage, so that host or disk failing takes the node down [15]; a streaming replica in the primary region, promotable on failure, is the step that turns an outage into a failover.

## Networking

The node is private by construction. The `fly.toml` declares no public service, and the conf binds the wildcard, so on Fly the machine has no public address and answers only on the organization's 6PN, on by default for apps in one organization [14]. The Phoenix app reaches it at `echo-postgres.internal:5432`, and nothing outside the organization can. The password is injected at first boot from a Fly secret, never written into an image layer.

## Boundaries

This article measures nothing; the tuning and platform figures are cited to their publishers, and the workload is read from the committed wallet and migration, not benchmarked. The memory split is the conventional starting point for two gigabytes [1][2] and wants revisiting against the buffer-cache hit ratio once the node has run. The autovacuum and fillfactor values are sound defaults for an update-heavy table [7][8][9]; the right numbers for Codemojex's `players` table come from watching its HOT-update ratio and dead-tuple trend in production. The single-node, single-volume shape is adequate for launch and not for the availability a money database needs, which the replica and the off-site PITR above address.

## Companion files

- `postgres/postgresql.conf` — the tuned configuration: durability fixed, the NVMe planner, the aggressive autovacuum, the observability surface.
- `postgres/Dockerfile` — the official `postgres:17` image with the conf layered and `PGDATA` placed inside the volume mount.
- `postgres/fly.toml` — the private `shared-cpu-2x`, two-gigabyte machine with a mounted volume, a TCP check, and a fast-shutdown signal.

## References

1. PostgreSQL — Resource Consumption (shared_buffers 25% on 1GB+, maintenance_work_mem): [postgresql.org/docs/current/runtime-config-resource.html](https://www.postgresql.org/docs/current/runtime-config-resource.html)
2. PostgreSQL wiki — Tuning Your PostgreSQL Server (effective_cache_size as a planner hint): [wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
3. Crunchy Data — Optimize PostgreSQL Server Performance (work_mem per operation, low global): [crunchydata.com](https://www.crunchydata.com/blog/optimize-postgresql-server-performance)
4. PostgreSQL — Asynchronous Commit (synchronous commit preserves a reported commit across a crash): [postgresql.org/docs/current/wal-async-commit.html](https://www.postgresql.org/docs/current/wal-async-commit.html)
5. PostgreSQL — Write Ahead Log (synchronous_commit modes, fsync, full_page_writes, checkpoint interval): [postgresql.org/docs/current/runtime-config-wal.html](https://www.postgresql.org/docs/current/runtime-config-wal.html)
6. PostgreSQL — Non-Durable Settings (the durability-for-speed trade): [postgresql.org/docs/current/non-durability.html](https://www.postgresql.org/docs/current/non-durability.html)
7. CYBERTEC — HOT updates in PostgreSQL (the two HOT conditions, fillfactor below 100): [cybertec-postgresql.com](https://www.cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance/)
8. CYBERTEC — Tuning autovacuum (per-table scale factor, idle-in-transaction stalls vacuum): [cybertec-postgresql.com](https://www.cybertec-postgresql.com/en/tuning-autovacuum-postgresql/)
9. Bun — Tuning PostgreSQL performance (aggressive autovacuum, wal_compression, SSD random_page_cost): [bun.uptrace.dev/postgres/performance-tuning.html](https://bun.uptrace.dev/postgres/performance-tuning.html)
10. Fly.io — How We Built Fly Postgres (point at the official image, remove the default services): [fly.io/blog/how-we-built-fly-postgres](https://fly.io/blog/how-we-built-fly-postgres/)
11. Fly.io — This Is Not Managed Postgres (unmanaged ownership, five-day volume snapshots): [fly.io/docs/postgres/getting-started/what-you-should-know](https://fly.io/docs/postgres/getting-started/what-you-should-know/)
12. Fly.io — Managed Postgres (the managed alternative, Shared-2x / 2GB starter): [fly.io/docs/mpg](https://fly.io/docs/mpg/)
13. Fly.io — Machine sizing (shared minimum 256 and maximum 2048 per vCPU): [fly.io/docs/machines/guides-examples/machine-sizing](https://fly.io/docs/machines/guides-examples/machine-sizing/)
14. Fly.io — Private Networking (6PN on by default, internal addresses): [fly.io/docs/networking/private-networking](https://fly.io/docs/networking/private-networking/)
15. Fly.io — Volumes overview (one volume to one machine, single region, NVMe): [fly.io/docs/volumes/overview](https://fly.io/docs/volumes/overview/)
16. Fly.io — App configuration (the vm section, kill signal and timeout): [fly.io/docs/reference/configuration](https://fly.io/docs/reference/configuration/)
