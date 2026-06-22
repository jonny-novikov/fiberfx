---
title: "The two-tier shape"
id: echo-persistence-dive-two-tier
status: established
route: "/echo-persistence/overview/the-two-tier-shape"
kind: "overview dive 2 of 3"
design: "html/redis-patterns sheet, re-themed amber/bronze persistence accent."
renders-to: "overview/the-two-tier-shape.html"
---

# Champ accepts, Graft commits { id="echo-persistence-dive-two-tier" }

> _The far corner of the spectrum — per-commit and replicated — is reached by splitting the job into two tiers. Champ accepts at in-heap speed with a fsync per K records; a transactional page-store commits each batch as one LSN replicated to Tigris. The batch is the seam, and the durable-records-per-fsync lever keeps the strict tier off the per-commit floor._

## §1 Tier one — Champ accepts { id="accept" }

Champ keeps the outbox in an in-memory `BrandedChamp` and writes a snapshot to disk every `checkpoint_every` records, so one fsync covers a whole interval and **K is exactly the loss window in records**. The call returns at in-heap speed; durability is bounded by the open interval.

| checkpoint_every (K) | rec/s (local) | loss window |
|---|---|---|
| 100 | 5,225 | ≤ 100 records |
| 1,000 | 36,889 | ≤ 1,000 records |
| 10,000 | 102,529 | ≤ 10,000 records |

Recovery (seed + restore): 3.63 ms at 1,000 entries, 8.53 ms at 10,000, 33.59 ms at 50,000; replay 1,044,659 intents/s. What Champ alone does **not** give is a per-commit guarantee or replication on commit: its snapshot ships asynchronously and at snapshot granularity, so a crash loses the records since the last checkpoint, and a follower sees whole snapshots. Champ is the bounded-loss accept tier; the guarantee comes from the second tier.

## §2 Tier two — Graft commits, Tigris replicates { id="commit" }

Graft is a transactional page-store that replicates at page granularity to object storage. Reads run lock-free against immutable LSN snapshots; a writer stages a segment and commits through optimistic concurrency control, appending a monotonic LSN; the commit is written with a **conditional write** that detects conflict. Two writers racing resolve by the loser's conditional write failing — the fence is the commit protocol, not a separate lease.

Replication rolls up rather than streams: a push snapshots an LSN range, dedupes pages, compresses into Zstd frames, uploads one segment, and commits the metadata conditionally. The Tigris seam is a configuration — the remote rides Apache OpenDAL, and create-if-not-exists is the fence. Recovery is a log-head read plus lazy page faults, not a full snapshot download.

## §3 The seam — one batch, one LSN { id="seam" }

The two tiers join at the batch. Champ's accept tier amortizes a local fsync over a batch; that same batch rolls up into one Graft transaction — one LSN — replicated to Tigris. The caller picks the guarantee per call:

```elixir
defp enqueue(job, mode) do
  :ok = Champ.record(Accept, job.id, job.queue, job.payload) # in-heap, fsync per K
  case mode do
    :async -> {:ok, :accepted}                  # loss bound = the open batch
    :sync  -> Graft.commit_batch(job.volume)     # one LSN, replicated to Tigris, then ack
  end
end
```

The commit LSN is the synchronization cursor: every advance is published on an EchoMQ lane, so replicas and the dashboard observe new versions without polling and a follower pulls from its SyncPoint forward. Sizing the commit batch to the consumer's claim batch makes enqueue, process, and record one durable, replicated unit keyed by a branded Snowflake.

The same model is built twice: native Elixir on CubDB (the canonical default) and Rust on Fjall + OpenDAL (for raw-page and replica-recovery workloads). They coexist by design — the course modules build the Elixir engine and read the Rust twin.

## §4 References & sources { id="refs" }

- graft.design.md — the two-tier design, the seam, the measured numbers — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — the two coexisting engines — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- orbitinghail/graft — OCC, LSN log, conditional-write commit (idea source) — https://github.com/orbitinghail/graft
- Apache OpenDAL — the remote backend behind the Tigris seam — https://opendal.apache.org
- Tigris object conditionals — create-if-not-exists, the fence — https://www.tigrisdata.com/docs/objects/conditionals/
- lucaong/cubdb — the native engine's local store — https://github.com/lucaong/cubdb

---

_Pager: ← Dive 1 — The durability spectrum · Dive 3 — Persistence in the platform →_
