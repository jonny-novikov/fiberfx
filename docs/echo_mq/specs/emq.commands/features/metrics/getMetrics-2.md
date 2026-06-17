# getMetrics-2  →  EchoMQ.Metrics.get_metrics/3 (metrics.ex:173)

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getMetrics-2
--@feature   metrics
--@status    PARTIAL
--@rung      emq.2.1 7d98ef86
--@v1        registry/getMetrics-2.lua   (KEYS arity 2)
--@v3        EchoMQ.Metrics.get_metrics/3 (metrics.ex:173)
```

## v1 source

`registry/getMetrics-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get metrics

  Input:
    KEYS[1] 'metrics' key
    KEYS[2] 'metrics data' key

    ARGV[1] start index
    ARGV[2] end index
]]
local rcall = redis.call;
local metricsKey = KEYS[1]
local dataKey = KEYS[2]

local metrics = rcall("HMGET", metricsKey, "count", "prevTS", "prevCount")
local data = rcall("LRANGE", dataKey, tonumber(ARGV[1]), tonumber(ARGV[2]))
local numPoints = rcall("LLEN", dataKey)

return {metrics, data, numPoints}
```

## v1 → v3 change ledger

| v1 (getMetrics-2) | v3 (PARTIAL — get_metrics/3 + counter on @complete) |
|---|---|
| KEYS[1]=metrics hash, KEYS[2]=data list | counter rides the EXISTING terminal transition: |
| ARGV[1..2]=slice [start,end] | HINCRBY p..'metrics:completed' 'count' 1 (@complete) |
| HMGET KEYS[1] count/prevTS/prevCount | get_metrics/3 reads: |
| LRANGE KEYS[2] start end | HGET emq:{q}:metrics:<which> 'count' |
| return {metrics, data, LLEN KEYS[2]} | + LLEN …:<which>:data -> 0 (honest, ring unwritten) |

## Aligned flow (authoritative side-by-side)

```text
v1 (getMetrics-2)                                v3 (PARTIAL — get_metrics/3 + counter on @complete)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=metrics hash, KEYS[2]=data list          counter rides the EXISTING terminal transition:
ARGV[1..2]=slice [start,end]                      HINCRBY p..'metrics:completed' 'count' 1  (@complete)
HMGET KEYS[1] count/prevTS/prevCount             get_metrics/3 reads:
LRANGE KEYS[2] start end                           HGET emq:{q}:metrics:<which> 'count'
return {metrics, data, LLEN KEYS[2]}               + LLEN …:<which>:data  -> 0 (honest, ring unwritten)
```

## Decision & rationale

**Covers → v3.** The throughput block → the terminal-outcome **counter** at `metrics:completed`/`:failed` (`count` field), written by the *existing* terminal transitions (`@complete`/`@retry` each `HINCRBY` once), so a read is never a phantom. **Gap:** the `:data` time-series ring is unwritten this rung (honestly `data_points: 0`); the Prometheus *format* wrapper defers to **emq.8**.

**Decision.** Keep the honest counter read. **PROPOSED**: write the `metrics:<which>:data` series as a bounded ring on the same terminal transitions (trimmed by count/age) so the v1 `{metrics, data, numPoints}` slice is re-derivable; the Prometheus/OpenTelemetry **format** wrapper stays emq.8 (the raw read is the floor). The live `:telemetry` surface (`EchoMQ.Meter`, `[:emq, :job, …]`, zero-cost when absent) already ships.

**BCS** the completed/failed throughput a capacity/SLO dashboard reads. · **EchoMesh** availability-first — a metered observation off the side, never on the record-of-write path; a stale/absent metric degrades, never blocks. · **[when]** the throughput a capacity/SLO dashboard reads.
