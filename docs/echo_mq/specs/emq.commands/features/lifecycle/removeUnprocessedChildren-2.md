# removeUnprocessedChildren-2  →  (v3 TBD)

> Feature: **lifecycle** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   removeUnprocessedChildren-2
--@feature   lifecycle
--@status    NOT YET
--@rung      [removeUnprocessedChildren-2.lua](../registry/removeUnprocessedChildren-2.lua) → EchoMQ.Flows.remove_children/3 PROPOSED (FLAT first; grandchildren → emq.3.5). (also **flows**)
--@v1        registry/removeUnprocessedChildren-2.lua   (KEYS arity 2)
--@v3        
```

## v1 source

`registry/removeUnprocessedChildren-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
    Remove a job from all the statuses it may be in as well as all its data.
    In order to be able to remove a job, it cannot be active.

    Input:
      KEYS[1] jobKey
      KEYS[2] meta key
      
      ARGV[1] prefix
      ARGV[2] jobId

    Events:
      'removed' for every children removed
]]

-- Includes
--- @include "includes/removeJobWithChildren"

local prefix = ARGV[1]
local jobId = ARGV[2]

local jobKey = KEYS[1]
local metaKey = KEYS[2]

local options = {
  removeChildren = "1",
  ignoreProcessed = true,
  ignoreLocked = true
}

removeJobChildren(prefix, jobKey, options) 
```

## v1 → v3 change ledger

| v1 (removeUnprocessedChildren-2) | v3 (PROPOSED — EchoMQ.Flows.remove_children/3) |
|---|---|
| KEYS[1]=jobKey, KEYS[2]=meta ; ARGV prefix,id | walk parent's DECLARED §6 subkeys (:dependencies/ |
| removeJobChildren(prefix, jobKey, options) | :processed/:failed/:unsuccessful) to enumerate |
| SMEMBERS <jobKey>:dependencies | same-queue children, @remove_job each on the {q} slot |
| for each child KEY read from store: | cross-queue children via flow:outbox + sweep |
| recurse on the VALUE (A-1 ✗) | ignore_locked -> EMQLOCK skip ; bounded :more/:ok |
| — | -- FLAT first; grandchildren = the deferred emq.3.5 fork |

## Aligned flow (authoritative side-by-side)

```text
v1 (removeUnprocessedChildren-2)                 v3 (PROPOSED — EchoMQ.Flows.remove_children/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=jobKey, KEYS[2]=meta ; ARGV prefix,id    walk parent's DECLARED §6 subkeys (:dependencies/
removeJobChildren(prefix, jobKey, options)         :processed/:failed/:unsuccessful) to enumerate
  SMEMBERS <jobKey>:dependencies                   same-queue children, @remove_job each on the {q} slot
  for each child KEY read from store:             cross-queue children via flow:outbox + sweep
    recurse on the VALUE  (A-1 ✗)                  ignore_locked -> EMQLOCK skip ; bounded :more/:ok
                                                  -- FLAT first; grandchildren = the deferred emq.3.5 fork
```

## Decision & rationale

**Covers → v3.** Recursively remove a job's children, ignoring processed & locked → no recursive teardown verb on disk; v1's `removeJobChildren` is the data-value recursion design §11.10 declares structurally inexpressible.

**Decision.** A bounded `Flows.remove_children/3` walks the parent's declared §6 subkeys to enumerate same-queue children and `@remove_job` each on the parent's `{q}` slot; cross-queue via `flow:outbox` + sweep; FLAT first (grandchildren = emq.3.5 V-1). `ignore_locked` maps to the v2 `EMQLOCK` skip; bounded per call (the `obliterate` budget pattern).

**BCS** tearing down a cancelled fan-out's child legs without touching the parent's own state. · **EchoMesh** consistency-side — same-queue children mutated under one slot's gate, cross-queue via the outbox hop. · **[when]** tearing down a cancelled fan-out's child legs.
