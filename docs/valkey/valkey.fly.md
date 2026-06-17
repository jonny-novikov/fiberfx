# EchoMQ backend. Valkey: Two Topologies on Fly.io

The Fly.io primitives: machines, host-pinned volumes, the 6PN private mesh with `<app>.internal` names, and so are the two natural shapes: a dedicated datastore machine, and a colocated replica beside the web service. 
What changes with Valkey is the durability story, the replication mechanics under deploy churn, and the memory economics that decide whether a colocated replica is affordable at all.

## Topology A: the dedicated machine

```toml
# fly.toml for the datastore app
app = "echo-valkey"
primary_region = "fra"

[build]
image = "valkey/valkey:9.1"

[experimental]
cmd = [
  "valkey-server",
  "--io-threads", "4",
  "--maxmemory", "6gb",
  "--maxmemory-policy", "noeviction",
  "--appendonly", "yes",
  "--appendfsync", "everysec",
  "--repl-diskless-sync", "yes",
  "--dir", "/data"
]

[[mounts]]
source = "valkey_data"
destination = "/data"

[[services]]
internal_port = 6379
protocol = "tcp"
auto_stop_machines = false
auto_start_machines = false
min_machines_running = 1
```

The flags carry the chapter's argument. Size `--io-threads` to the machine's cores, the lever from chapter 2; one main thread executes, the rest feed it. `noeviction` is the queue posture: a job store that silently evicts is a job store that silently loses work, so memory pressure must surface as write errors and alerts, never as eviction. And `appendonly yes` with `everysec` is the headline difference from the Dragonfly topology: the volume holds an append-only log, so the durability bound after a crash is roughly one second of fsync window, not one snapshot interval. For EchoMQ's lifecycle rung, whose checkpoints assume the store's loss bound as a design input, this is the single strongest reason a deployment chooses the Valkey posture.

Everything else transfers from the Dragonfly chapter unchanged: auto-stop off, a password via secrets even on 6PN, performance CPUs over shared ones, applications connecting at `redis://echo-valkey.internal:6379`. 
Memory headroom deserves one Valkey-specific note: AOF rewrites fork, so the copy-on-write spike the Dragonfly series cited as that engine's selling point against Redis applies here too, budget `maxmemory` conservatively against machine RAM and schedule rewrites off-peak.

## Topology B: the colocated local replica

Fly process groups create separate machines, so one image runs both processes under a supervising entrypoint, but the replica itself is more pleasant to operate, for three reasons.

```bash
# entrypoint.sh, invoked as CMD ["sh", "/entrypoint.sh"]
# read-only replica beside the app; reads stay on-machine
valkey-server \
  --replicaof echo-valkey.internal 6379 \
  --replica-read-only yes \
  --maxmemory 1gb \
  --io-threads 2 &

exec bin/echo start
```

First, footprint. A replica holds the full dataset, which is the pattern's standing tax, but the 8.1 hashtable cut roughly 20 bytes per key, up to 30 with TTL [1][2], and for cache-shaped data, many small keys with TTLs, that lands exactly where it helps. The viability threshold for "the replicated dataset fits beside the BEAM heap" sits meaningfully lower on Valkey 9 than it did on the engines the pattern was first costed against.

Second, sync behavior under deploy churn. Every web-machine rollout still restarts its replica into a resync, and an ephemeral machine arrives stateless, so plan for full syncs across the fleet on deploy. Two flags bound the damage: `repl-diskless-sync` on the primary streams the snapshot without touching the volume, and a generous `repl-backlog-size` lets replicas that merely blipped, network hiccups, brief restarts with state, partially resync instead of pulling the world. Valkey 8.1 additionally cut full-sync costs under TLS substantially [1]. Stagger deploys regardless; ten machines full-syncing at once is self-inflicted load on the primary.

Third, the read path states its semantics plainly. `replica-read-only` is the default contract, replication is asynchronous, and read-your-writes does not hold locally, so the application keeps two pools, writes and read-sensitive reads to `echo-valkey.internal`, staleness-tolerant reads to localhost, with EchoCache's Snowflake-versioned newer-wins making lag detectable rather than dangerous, exactly as the Dragonfly chapter argued. What Valkey adds is the other end of the lever: WAIT on the primary lets a critical write demand replica acknowledgment, so the rare flow that needs stronger guarantees buys them per-operation instead of forcing the whole topology synchronous.

### Failure modes, revisited for this engine

Primary down: replicas keep serving last-known data, fine for the cache tier, wrong for queues, unchanged. What changes is the recovery story, the primary restarts from its AOF with a tight loss bound, so the strategy of one well-kept primary plus cold-standby restore is more defensible here than on a snapshot-only engine. If automated failover is required, Sentinel is the lineage's native answer and Valkey supports it, but promoting a replica that shares a machine with a web process remains the wrong move, a promotion target should be a dedicated standby in the datastore app, not a sidecar.

Auto-stop: still incompatible with topology B's value. A stopped machine returns with a cold replica and a full sync; if the fleet must scale to zero, the local-replica pattern is the feature to cut.

## The verdict per workload

Queues, locks, counters, checkpoints: topology A, where AOF plus optional WAIT gives the strongest loss bound available in either series. 
The EchoCache L2 and read-mostly reference data: A plus B, with the replica's footprint costed against the 8.1+ memory plane. 
Single-region apps with modest read volume: A alone, until per-request read multiplication is measured, not assumed. The remaining question of the series is what client carries these semantics, the fence, the lanes, the WAIT lever, the push frames, and that is chapter 4.

## References

1. https://valkey.io/blog/valkey-8-1-0-ga/
2. https://valkey.io/blog/new-hash-table/
