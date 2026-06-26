# R8.02.1 · RDB and AOF — the durability dial

> Dive · `/redis-patterns/production-operations/persistence-pooling-failover/rdb-and-aof`

A job store that loses acknowledged work on a restart is not a record of truth. The first guarantee of
operating the bus as a primary database (R7.01) is durability at the engine level: the data outlives the
process. Valkey offers two persistence mechanisms — point-in-time snapshots (RDB) and an append-only log
(AOF) — and the real `infra/valkey/conf/valkey.conf` chooses one of them on purpose. This dive reads that
choice line by line.

## The two mechanisms, and the choice

RDB writes a compact point-in-time snapshot of the whole dataset by forking a child that serializes
memory to disk. It is fast to load and small on disk, but a crash loses everything written since the last
snapshot — minutes of work, not seconds. AOF appends every keyspace-changing write to a log; on restart
the log replays to rebuild the dataset. With a once-a-second fsync, a crash loses at most about a second.

For a cache, RDB's snapshot-interval loss is fine. For a job store it is silent data loss: a job that was
enqueued and acknowledged, then lost in the gap before the next snapshot. So `valkey.conf` makes AOF the
single source of durability and turns RDB off.

## The persistence block, verbatim

The real config, from `infra/valkey/conf/valkey.conf`:

```
# ---- Persistence: AOF is the single source of durability ----
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-use-rdb-preamble yes
save ""
dir /data
propagation-error-behavior panic
```

Line by line:

- **`appendonly yes`** turns the append-only file on — every write that changes the keyspace is appended
  to a log on disk.
- **`appendfsync everysec`** flushes that log to disk once a second on a background thread. The
  worst-case loss bound after a crash is about one second of writes — not a whole snapshot interval, and
  the fsync stays off the command thread.
- **`save ""`** disables RDB snapshotting. With AOF as the single durability mechanism there is no reason
  to keep a second snapshot fork competing for the machine. One fork source, not two.
- **`aof-use-rdb-preamble yes`** lets the periodic AOF rewrite start from a compact RDB-format preamble
  rather than replaying every command, so the rewrite is fast and the file stays small — RDB's fast load
  with AOF's low loss.
- **`auto-aof-rewrite-percentage 100`** / **`auto-aof-rewrite-min-size 64mb`** trigger that rewrite when
  the log has doubled and is at least 64 MB, keeping the file from growing without bound.
- **`propagation-error-behavior panic`** fails a write rather than acknowledge data that may not survive.
  A false acknowledgement is worse than a visible error: the caller that hears OK stops worrying about
  the job.

## The single-threaded premise

The config's own load-bearing comment names why the persistence work has to stay off the command thread:
*"command execution is single-threaded, so the second shared vCPU is reserved for background work — AOF
fsync, fork copy-on-write."* The once-a-second `appendfsync` and the rewrite fork both run on that second
vCPU; the one command thread keeps serving. This is why `save ""` matters beyond avoiding duplicate work:
a second snapshot fork would contend for the same background budget the AOF fsync needs.

## Reject, do not evict — the R7.01 tie

Durability has a second failure mode besides a crash: memory pressure. `maxmemory-policy noeviction`
makes a write that would exceed `maxmemory` return an error to the caller instead of evicting a key. For
a queue, an evicted key is silently lost work — a job something already enqueued, gone. `noeviction`
turns memory pressure into a rejected write and an alert, the loud failure R7.01 requires of a record of
truth.

## The bridge

| The pattern — AOF as the durability dial | Its EchoMQ application |
|---|---|
| Choose the append-only log as the single source of durability; bound crash loss with `everysec`; turn snapshotting off so one fork serves; fail loudly on un-survivable data | The committed `valkey.conf` fronts the codemojex queue's `emq:{q}:` keyspace with `appendonly yes` + `appendfsync everysec` + `save ""` + `propagation-error-behavior panic`, so in-flight `JOB` state survives a restart |

The take: durability is a dial, and this config sets it for a volatile work tier — keep the last second,
loudly, with one fork. Deep, off-box history is a separate tier on the persistence floor.

## Distinct from R8.01, and the floor beneath

R8.01's `persistence-safe-settings` covers the *kernel* layer — `vm.overcommit_memory=1` so the save
fork is not refused, THP off so copy-on-write does not amplify. That is the host making room for the
fork. This dive is the *Valkey persistence policy* the host leaves room for. They are two halves of one
posture; read R8.01 for the kernel half.

The AOF bounds the queue's crash loss to about a second. That is the right floor for a volatile tier, but
not the whole durability story — deep history and off-box durability live one tier down on the
persistence floor (ETS → Valkey → CubDB → Tigris). The `/echo-persistence` course carries that dial.

## References

### Sources

- [Valkey — *Persistence*](https://valkey.io/topics/persistence/) — RDB and AOF, the fsync policies, and
  the durability trade the append-only file makes.
- [Valkey — *BGREWRITEAOF*](https://valkey.io/commands/bgrewriteaof/) — the rewrite the
  `auto-aof-rewrite-*` thresholds trigger, compacted via the RDB preamble.
- [Redis — *Persistence*](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/) —
  the canonical RDB-vs-AOF comparison and the `everysec` recommendation.
- [Redis — *Documentation*](https://redis.io/docs/) — the management topics the persistence policy draws
  on.

### Related in this course

- [R8.02 · Persistence, pooling & failover](/redis-patterns/production-operations/persistence-pooling-failover) — the module hub.
- [R8.01.3 · Persistence-safe settings](/redis-patterns/production-operations/kernel-tuning/persistence-safe-settings) — the kernel half of this posture.
- [R7.01 · Redis as a primary database](/redis-patterns/data-modeling/primary-database) — the pattern this durability serves.
- [/echomq · the Proof pillar](/echomq/proof) — the production evidence the bus carries.
- [/bcs · Production on Fly](/bcs/fly) — where this `valkey.conf` runs.
- [/echo-persistence](/echo-persistence) — the durability floor beneath the volatile tier.
