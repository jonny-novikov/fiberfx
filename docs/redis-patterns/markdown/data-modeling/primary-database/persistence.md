# R7.01.3 — Persistence (RDB / AOF)

> Route: `/redis-patterns/data-modeling/primary-database/persistence` · dive C of R7.01 ·
> source-of-record for the HTML page of the same route.

**Two durability mechanisms, one question: after a crash, how much do you lose?** RDB writes a
point-in-time snapshot via `fork()` — compact and fast to restart, but everything written since the last
snapshot is gone. AOF writes an append-only log of every operation, and the `appendfsync` policy sets the
loss bound. A datum whose truth has no second home wants AOF `everysec`: a worst-case loss of about one
second, not a whole snapshot interval.

The applied half: EchoMQ's real config diverges from the textbook "enable both." It runs **AOF-only**
(`save ""`, so RDB snapshotting never competes for a second fork) with **`aof-use-rdb-preamble yes`** (the
AOF rewrite still uses the compact RDB format). One fork source, a ~1s loss bound — and EchoMQ's checkpoints
are designed against exactly that bound. That ~1s is one rung of a longer dial; the next rungs replicate the
record off the box.

## RDB — point-in-time snapshots via fork()

RDB takes a point-in-time snapshot: the server forks, the child writes the whole dataset to one compact
file, and the parent keeps serving. The file is small and restarts from it are fast, which makes RDB a good
fit for disaster-recovery backups, fast instance bootstrapping, and development environments. The cost is the
window: a snapshot taken every K seconds means a crash loses up to K seconds of writes — the whole interval
since the last snapshot, not a bounded slice of it.

The author source enables RDB with the staircase `save 900 1` / `save 300 10` / `save 60 10000` — snapshot if
1 key changed in 900 s, or 10 in 300 s, or 10000 in 60 s. The tighter the rule, the smaller the loss window
and the more often the box pays the fork. RDB alone is a backup mechanism, not a durability guarantee.

## AOF — the append-only log, and the fsync policy

AOF writes a log of every operation that changes the dataset. On restart the server replays the log and the
dataset is rebuilt. The loss bound is set by `appendfsync` — how often the log is flushed to the disk:

| Policy | Durability | Latency | Use case |
|---|---|---|---|
| `always` | maximum — ~0 loss | high | financial transactions |
| `everysec` | ~1 second loss | low | most production workloads |
| `no` | OS-dependent | minimal | a caching layer |

`always` fsyncs on every write — no loss, but the disk is on the critical path of every command. `no` hands
the decision to the operating system — fast, but the loss bound is whatever the kernel's flush interval
happens to be. `everysec` flushes once a second on a background thread: the worst case is about one second of
writes, paid off the command path. For a primary store, `everysec` is the standard choice.

Hybrid persistence (Redis/Valkey 4.0+) sets `aof-use-rdb-preamble yes`: the AOF file starts with a compact
RDB-format snapshot, then the incremental commands since. The rewrite is small and the restart is fast, while
the log still bounds loss to the `appendfsync` window. It is not "RDB snapshotting on a timer" — it is the
AOF *rewrite* borrowing the RDB encoding.

## EchoMQ's applied choice — AOF-only, one fork source

The textbook says enable both. EchoMQ's real `infra/valkey/conf/valkey.conf` does the opposite, and on
purpose. The persistence block:

```
# ---- Persistence: AOF is the single source of durability ---------------------
# One fork source. AOF everysec bounds worst-case loss to about one second and
# fsyncs on a background thread. RDB snapshotting is disabled so it does not
# compete for a second fork; the AOF still uses an RDB preamble for fast rewrite.
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-use-rdb-preamble yes
save ""
```

`save ""` turns RDB snapshotting off. `appendonly yes` + `appendfsync everysec` make the append-only log the
single source of durability, with the ~1s bound paid on a background thread. `aof-use-rdb-preamble yes` keeps
the compact RDB format for the AOF rewrite, so a restart is still fast. The reason both are not on is the
fork: command execution is single-threaded, and a fork's copy-on-write spike must be budgeted under the
machine's RAM. Two independent fork sources — an RDB snapshot timer and an AOF rewrite — can collide.
Disabling RDB leaves **one fork source**, the AOF rewrite, scheduled by `auto-aof-rewrite-percentage`.

The bridge: the pattern is "RDB vs AOF — pick a loss bound." The application is "AOF `everysec` + the RDB
preamble, RDB snapshotting off — one fork source, a ~1s bound the checkpoints assume."

> The manuscript states it directly (BCS, B8.2): *"With `appendonly` on and `appendfsync everysec`, the
> volume holds an append-only log and the loss bound after a crash is roughly one second of writes, not a
> whole snapshot interval — and EchoMQ's checkpoints are designed against exactly that bound."*

**Note on Valkey.** `appendfsync everysec` flushes the append-only file once a second on a background
thread, so a crash loses at most about one second of writes; `always` fsyncs every write and `no` defers to
the OS — [valkey.io/topics/persistence](https://valkey.io/topics/persistence/).

## The durability dial — the ~1s bound is one rung

AOF `everysec` is one setting on a dial, not the end of it. Durability is a choice a system turns up or down,
rung by rung: hold nothing in the volatile tier; keep an append-only log on the local volume with a bounded
loss window; replicate the record off the box so a lost machine is not a lost record. The ~1s AOF bound is
the second rung — the record survives a crash, but it lives on one machine's volume.

The next rung is off-box. `EchoStore.Graft` is the native-BEAM replication engine: a single-writer
`VolumeServer` commits pages to a local CubDB store, and `EchoStore.Graft.Remote.Tigris` ships segments and
conditional commit objects to Tigris S3 in real time, behind a create-only commit fence — exactly one writer
claims a slot. The commit drives the bus; the archive fold drives the commit. That is the durability frontier
the AOF bound opens onto: the local log is rung two; commit-per-record replicated to Tigris is rung three.

The take: a system of record turns the durability dial to the bound its data needs. EchoMQ holds the
~1s-loss-tolerant job HASH on an AOF `everysec` volume; the frontier beyond is the off-box record, where the
local commit is replicated to Tigris and a lost machine is no longer a lost record.

## References

### Sources

- [Valkey — Persistence](https://valkey.io/topics/persistence/) — RDB snapshotting, the append-only file,
  and the `appendfsync` loss bounds (`always` / `everysec` / `no`).
- [Valkey — BGREWRITEAOF](https://valkey.io/commands/bgrewriteaof/) — the background AOF rewrite that
  `auto-aof-rewrite-percentage` schedules; the one fork source under an AOF-only posture.
- [Valkey — BGSAVE](https://valkey.io/commands/bgsave/) — the forked RDB snapshot, disabled here by
  `save ""`.
- [Valkey — CONFIG SET](https://valkey.io/commands/config-set/) — reading and changing `appendonly`,
  `appendfsync`, and `save` at runtime.
- [Redis design notes — antirez](https://antirez.com/) — the creator's notes on the snapshot-vs-log
  trade-off and the fork copy-on-write cost.

### Related in this course

- `/redis-patterns/data-modeling/primary-database` — R7.01 · the module hub: Redis as a system of record.
- `/redis-patterns/data-modeling/primary-database/noeviction` — R7.01.2 · the eviction posture that pairs
  with persistence: refuse the write, do not drop the record.
- `/redis-patterns/data-modeling/primary-database/system-of-record` — R7.01.1 · the row is the record, and
  the per-datum decision.
- `/bcs/persistence` — B5 · the durability dial in depth: the single-writer engine, the lazy reader, the
  portable remote.
- `/bcs/fly/valkey-on-a-fly-machine` — B8.2 · the production posture of this exact config.
- `/echo-persistence` — the durable floor beneath the ~1s AOF bound: ETS → Valkey → the page engine → Tigris.
