# Codemojex · EchoMQ backed by Valkey 9.x and what  does with the difference

For Codemojex the choice between the Valkey 8.1 line and the 9.1 line is not abstract: the `echo_mq` lock plane already issues a command that exists only on 9.x, so the version question is really whether to finish a cutover the code has half-written or hold it back. This article puts `8.1.8` and `9.1` side by side — what each line is, the pros and cons that matter to a money game on one small node — then reads the real `echo_mq` source to name the concrete operations 9.x lets the bus improve, and the one regression it introduces. As an architecture decision of record for the project: the playable entity is a **game** (`GAM`), a state machine living inside a room (`RMM`); it supersedes the earlier `round`/`RND` entity, and the keyspace and prose below use it. The committed modules still carry the `round` identifier pending that rename.

## Scope and method

The lines compared are Valkey `8.1.8`, the current patch on the 8.1 series, and `9.1.0`, the first stable release on the 9.1 series. Version capabilities and performance figures carry a numbered reference to the source that published them; statements about `echo_mq` are grounded in the committed modules under `echo/apps/echo_mq/lib` and cited by module and function, not by URL. No benchmark was run; no figure here is a measurement of this system. The verdict is a decision, argued from the code and the cited behaviour. Out of frame: the node sizing and configuration, which the companion article settles, and the operational walkthrough of the guess and notification paths, which the second article carries.

## The two lines, in one breath each

Valkey 8.1 is a memory-and-throughput release built on a rewritten hash table. That rewrite — used for the keyspace and for the Hash, Set, and Sorted Set types — cuts roughly twenty bytes per key-value pair without a time to live and up to thirty with one, and lifts pipeline throughput about ten percent over 8.0 when I/O threading is off [2]. The same line cut fork copy-on-write overhead up to forty-seven percent and made `ZRANK`, the sorted-set rank that leaderboards lean on, up to forty-five percent faster [2]. It also added a conditional write to the `SET` command, `IFEQ`, a compare-and-set for strings [3].

Valkey 9.1 is a features-and-scale release on top of that hash table: per-field expiration for hashes, a native compare-and-delete, atomic cluster-slot migration, numbered databases in cluster mode, and pipeline-memory prefetching reported up to forty percent higher throughput [4]. The 9.1 point release adds a lock-free I/O-threading queue model and a larger embedded-string threshold for throughput, reduces rehashing latency spikes by releasing pages incrementally, fixes a null-pointer crash in stream trim, and carries three security fixes [1][8]. The hash table memory win from 8.1 is inherited, not lost, by moving to 9.x — the two lines are a base and its successor, not a fork.

## Side by side

The table reads dimension by dimension; the rightmost column is the bearing on Codemojex and the EchoMQ bus, not a general verdict.

| Dimension | Valkey 8.1.8 | Valkey 9.1 | Bearing on Codemojex / EchoMQ |
|---|---|---|---|
| Hash-table memory | Rewritten table, ~20–30 bytes saved per pair [2] | Inherits the 8.1 table [2] | Lower resident size on the game's hashes; no loss moving up |
| Command threading | Single-threaded execution [10] | Single-threaded execution; lock-free I/O queue, 8–17% [8] | One core still the ceiling; the gain is single-thread, not parallel |
| Conditional string op | `SET … IFEQ` (compare-and-set) [3] | `IFEQ` plus `DELIFEQ` (compare-and-delete) [7] | A token-checked lock release without a script — see below |
| Hash-field expiration | Not present [11] | `HEXPIRE`/`HPEXPIRE` family [4] | The bus already calls `HPEXPIRE`; 9.x makes it live |
| Stream trim | Present | Null-deref in trim fixed [1] | Protects `EchoMQ.Stream.trim` on its `XTRIM` path |
| Cluster resharding | Key-by-key migration | Atomic slot migration [4] | Future shard-by-hash-tag is safe rather than lossy |
| Pipelining | Baseline | Memory prefetch, up to 40% [4] | Amplifies the connector's pipeline-depth dial |
| Single-thread headroom metric | CPU time only | `used_active_time_main_thread` [9] | True headroom under busy-wait, for the meter |
| Security | 8.1 patch line | Three fixes in 9.1.0 [1] | A money build wants the current fixes |
| Upgrade urgency | Mature line | First stable 9.1, marked low [1] | Fresh deploy: low risk; live migration: more caution |

## The deciding fact in EchoMQ's own code

`EchoMQ.Locks` — the opt-in lease-keeper that extends the leases of jobs a consumer holds — already writes a lock both ways. On `track_job/3` it sets a string marker `emq:{q}:job:<id>:lock` with a `PX` time to live, and it also folds a `lock` field into the job hash and gives that field its own time to live with `HPEXPIRE`, so the lock self-clears inside the row. The module says as much in its own comment: the field rides the job-hash key, the string marker is kept alongside for now, and the cutover to a field-only lock is deferred to a later rung with the fence climb.

Hash-field expiration is a Valkey 9.0 capability, reclaimed by an active expiry scan rather than a per-read check [4][5][11]. On `8.1.8` the `HPEXPIRE` call is an unknown command: the connector returns an error, the lock plane discards it, and the marker survives on the string key alone — the field-TTL half is dead. On 9.x the call takes effect, and the deferred cutover becomes available: the lock collapses from a separate key plus a hash field to one self-expiring field, removing a key per held job and the paired `DEL` and `HDEL` on release. The mechanism for adopting it is already in the keyspace: `EchoMQ.Keyspace` reserves a cross-queue `{emq}:version` fence, and the lock plane's comment ties the field-only cutover to climbing it. Choosing 9.x is choosing to finish what the bus has started.

## What 9.x lets the bus do, and what it costs

Reading `echo_mq` against the 9.x surface, the opportunities are specific.

**Collapse the lock marker to one self-expiring field.** The win above is real, and it has a candid cost that belongs beside it: a hash stays in the compact listpack encoding until the first field gets a time to live, at which point Valkey 9.0 converts it to the hash-table encoding, which can cost up to about fifty percent more memory and does not revert when the field is removed [6]. The job hash is small, so folding a self-expiring `lock` field onto it trades a little per-job memory for one fewer key and one fewer write on release. On a node sized for a tiny working set that trade is worth making; it is not free, and the meter should watch for it.

**Release the lock by token with `DELIFEQ`.** The marker carries the worker's token as its value, but `untrack_job/2` clears it with an unconditional `DEL` and `HDEL`. A late untrack from a worker whose lease already lapsed and was reclaimed could clear a successor's marker. `DELIFEQ` — delete only if the value still equals my token [7] — closes that window without the Lua a guarded delete needed before, and keeps the release off the script path that serialises on the one command thread [10].

**Let prefetch carry the pipelined bursts.** The connector's lever is pipeline depth; the claim and complete transitions and `EchoMQ.Stream.append_batch` issue pipelined runs. The 9.0 prefetch raises the single thread's throughput on exactly those batches by fetching the keys they will touch ahead of execution [4].

**Take the 9.1 fixes on the paths the bus uses.** `EchoMQ.Stream.trim/4` bounds a stream with `XTRIM` over a keep-newest count or a Snowflake-derived minimum id; the 9.1 stream-trim null-deref fix is on that path [1]. The lane sorted sets, the active and pending sets, and the job-hash dictionary all rehash as load grows; the 9.1 incremental page release during rehashing trims the latency tail there [1]. And `EchoMQ.Meter` can read `used_active_time_main_thread` for true headroom, since with I/O threads the raw CPU figure busy-waits near full and hides spare capacity [9].

**What stays on Lua either way.** The admission, claim, complete, schedule, and flow transitions in `EchoMQ.Jobs` are byte-frozen idempotent scripts that write a row, a lane entry, and ring bookkeeping atomically, or move a member between sets, or settle a parent and child across slots in one evaluation. Those are truly multi-key atomic and remain scripts on either version; 9.x removes a guarded single-key operation from the script path, not the atomic core. The gain is narrow and worth taking, not a rewrite.

## The verdict

Opt in `9.1` for a fresh Codemojex deploy. 
It loses none of 8.1's memory work, it makes the lock plane's already-written `HPEXPIRE` path live so the field-only cutover can ship behind the version fence, it gives `DELIFEQ` for a token-checked release, and its 9.1 fixes sit on the stream-trim and rehashing paths the bus exercises. 
The one regression to hold in view is the listpack-to-hash-table conversion the first field time to live forces on small hashes [6] — a per-job memory cost, not a correctness one, and bounded on a node whose working set is small.

Stay on `8.1.8` only if a managed platform pins you there, or if you are upgrading a large live dataset and want more patch soak before the major step. In that case keep the lock on the string marker, leave the `HPEXPIRE` half as the no-op it already is on 8.x, and do not climb the version fence. Nothing in Codemojex requires the 8.1 line; everything the bus is reaching for is on 9.x.

## Boundaries

This article measures nothing; the memory, throughput, and latency figures are cited to their publishers, and the claims about Codemojex and EchoMQ are read from the committed source, not benchmarked. 
The `HPEXPIRE` behaviour on 8.1.8 — an error the lock plane discards — is described from the code path, not observed on an 8.1.8 server. 
The encoding-conversion cost is the published 9.0 behaviour for small hashes [6]; its exact size on Codemojex's job hashes is unmeasured. 
The verdict is for the single-node deploy this project ships; a managed or clustered deployment changes the calculus the cited platform behaviour describes.

## References

1. Valkey — Release 9.1.0 (rehashing page release, stream-trim null fix, security fixes): [github.com/valkey-io/valkey/releases/tag/9.1.0](https://github.com/valkey-io/valkey/releases/tag/9.1.0)
2. Valkey — Valkey 8.1 GA (rewritten hash table, per-pair savings, fork copy-on-write, ZRANK): [valkey.io/blog/valkey-8-1-0-ga](https://valkey.io/blog/valkey-8-1-0-ga/)
3. Valkey — Release 8.1.0 (SET IFEQ compare-and-set, I/O-thread changes): [github.com/valkey-io/valkey/releases/tag/8.1.0](https://github.com/valkey-io/valkey/releases/tag/8.1.0)
4. Valkey — Introducing Valkey 9.0 (hash-field expiration, prefetch, atomic slot migration): [valkey.io/blog/introducing-valkey-9](https://valkey.io/blog/introducing-valkey-9/)
5. Valkey — Introducing Hash Field Expirations (the 9.0 API and active expiry): [valkey.io/blog/hash-fields-expiration](https://valkey.io/blog/hash-fields-expiration/)
6. Valkey — HFE backlog, issue #2618 (first field TTL converts listpack to hash table, non-revertible): [github.com/valkey-io/valkey/issues/2618](https://github.com/valkey-io/valkey/issues/2618)
7. Google Cloud — Memorystore for Valkey 9.0 (DELIFEQ guarded delete, previously Lua): [cloud.google.com](https://cloud.google.com/blog/products/databases/memorystore-for-valkey-9-0-is-now-ga)
8. Valkey — Releases (9.1 candidates: lock-free I/O queues, embedded-string threshold): [github.com/valkey-io/valkey/releases](https://github.com/valkey-io/valkey/releases)
9. Valkey — INFO command (used_active_time_main_thread on 9.1, I/O-thread busy-wait): [valkey.io/commands/info](https://valkey.io/commands/info/)
10. Valkey — Benchmarking (single-threaded command execution): [valkey.io/topics/benchmark](https://valkey.io/topics/benchmark/)
11. AWS — ElastiCache engine versions (hash-field expiration introduced in 9.0): [docs.aws.amazon.com](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/engine-versions.html)
