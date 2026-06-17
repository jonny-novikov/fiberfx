# getDependencyCounts-4  →  EchoMQ.Flows.dependencies/3 (flows.ex:332) + children_values/3/ignored_failures/3; aggregate child_counts/3 PROPOSED

> Feature: **flows** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getDependencyCounts-4
--@feature   flows
--@status    PARTIAL (split, not aggregated)
--@rung      emq.3.2/3.4
--@v1        registry/getDependencyCounts-4.lua   (KEYS arity 4)
--@v3        EchoMQ.Flows.dependencies/3 (flows.ex:332) + children_values/3/ignored_failures/3; aggregate child_counts/3 PROPOSED
```

## v1 source

`registry/getDependencyCounts-4.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get counts per child states

    Input:
      KEYS[1]    processed key
      KEYS[2]    unprocessed key
      KEYS[3]    ignored key
      KEYS[4]    failed key

      ARGV[1...] types
]]
local rcall = redis.call;
local processedKey = KEYS[1]
local unprocessedKey = KEYS[2]
local ignoredKey = KEYS[3]
local failedKey = KEYS[4]
local results = {}

for i = 1, #ARGV do
  if ARGV[i] == "processed" then
    results[#results+1] = rcall("HLEN", processedKey)
  elseif ARGV[i] == "unprocessed" then
    results[#results+1] = rcall("SCARD", unprocessedKey)
  elseif ARGV[i] == "ignored" then
    results[#results+1] = rcall("HLEN", ignoredKey)
  else
    results[#results+1] = rcall("ZCARD", failedKey)
  end
end

return results
```

## v1 → v3 change ledger

| v1 (getDependencyCounts-4) | v3 (PARTIAL — split across EchoMQ.Flows; no single verb) |
|---|---|
| 'processed' -> HLEN KEYS[1] -- HASH+results | dependencies/3 (flows.ex:332) GET :dependencies -- STRING counter |
| 'unprocessed' -> SCARD KEYS[2] -- SET of KEYS | children_values/3 (flows.ex:261) HGETALL :processed |
| 'ignored' -> HLEN KEYS[3] | ignored_failures/3 (flows.ex:295) :unsuccessful -- SHIPPED emq.3.4 |
| 'failed' -> ZCARD KEYS[4] | # PROPOSED child_counts/3: compose counter + HLEN :processed/ |
| — | # :failed/:unsuccessful; NO unprocessed SET (Fork R2.A counter) |

## Aligned flow (authoritative side-by-side)

```text
v1 (getDependencyCounts-4)                       v3 (PARTIAL — split across EchoMQ.Flows; no single verb)
─────────────────────────────────────────       ─────────────────────────────────────────────────
'processed'   -> HLEN  KEYS[1]   -- HASH+results dependencies/3   (flows.ex:332) GET :dependencies -- STRING counter
'unprocessed' -> SCARD KEYS[2]   -- SET of KEYS  children_values/3 (flows.ex:261) HGETALL :processed
'ignored'     -> HLEN  KEYS[3]                   ignored_failures/3 (flows.ex:295) :unsuccessful -- SHIPPED emq.3.4
'failed'      -> ZCARD KEYS[4]                   # PROPOSED child_counts/3: compose counter + HLEN :processed/
                                                 #   :failed/:unsuccessful; NO unprocessed SET (Fork R2.A counter)
```

## Decision & rationale

**Covers → v3.** Count per child state (processed/unprocessed/ignored/failed) for a flow parent → the pieces are **split** across `Flows`: `dependencies/3` (the outstanding `:dependencies` counter), `children_values/3` (the `:processed` results), `ignored_failures/3` (the `:unsuccessful`/ignored reads, SHIPPED emq.3.4) — there is **no single aggregate verb** returning all four counts at once. (Also a **metrics** read; its dominant role is the flow fan-in read.)

**Decision.** A `Flows.child_counts/3` composing — on the parent's `{q}` slot — the declared `:dependencies` counter + `HLEN` of `:processed`/`:failed`/`:unsuccessful` into one read (every key declared or composed from the gated parent `Keyspace.job_key/2`, the `parent` field read host-side). **Not** a v1 SET-cardinality lift (v2 `:dependencies` is a STRING counter, Fork **R2.A**), an aggregate over the already-declared §6 subkeys. *(Prose until authored.)*

**BCS** the fan-in progress a multi-leg/saga parent reads before proceeding or compensating. · **EchoMesh** consistency-first — a flow parent's child-state read is on the strong-consistency (matching/ledger) axis. · **[when]** the fan-in progress a multi-leg/saga parent reads before proceeding or compensating.
