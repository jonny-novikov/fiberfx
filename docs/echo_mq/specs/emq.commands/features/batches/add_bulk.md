# add_bulk  →  EchoMQ.Flows.add_bulk/3 (flows.ex) + EchoMQ.Jobs.enqueue_many/3

> Feature: **batches** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   add_bulk
--@feature   batches
--@status    SHIPPED (ported)
--@rung      emq.3.4
--@v1        (no standalone v1 script)   (parity — no v1 script)
--@v3        EchoMQ.Flows.add_bulk/3 (flows.ex) + EchoMQ.Jobs.enqueue_many/3
```

## v1 source

_flow parity (no standalone v1 script) — parity command, no raw script in the registry._

## v1 → v3 change ledger

| v1 (flow_producer.add_bulk/2) | v3 (SHIPPED — Flows.add_bulk/3 + Jobs.enqueue_many/3) |
|---|---|
| submit many flows at once | Flows.add_bulk/3 — N flows |
| loop addParentJob per flow | fail-closed per flow -- one fail holds its own parent |
| job-level bulk add = queue.add_bulk | job-level bulk = Jobs.enqueue_many/3 (emq.1) |
| — | -- already declared-keys, branded, honest-row |

## Aligned flow (authoritative side-by-side)

```text
v1 (flow_producer.add_bulk/2)                    v3 (SHIPPED — Flows.add_bulk/3 + Jobs.enqueue_many/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
submit many flows at once                        Flows.add_bulk/3 — N flows
  loop addParentJob per flow                        fail-closed per flow            -- one fail holds its own parent
job-level bulk add = queue.add_bulk              job-level bulk = Jobs.enqueue_many/3 (emq.1)
                                                 -- already declared-keys, branded, honest-row
```

## Decision & rationale

**Covers → v3.** Submit many flows in one call (the v1 batch producer verb) → `Flows.add_bulk/3` (N flows, fail-closed per flow: a flow that fails to land leaves its own parent held, the others unaffected); the bulk **job**-enqueue producer half is `Jobs.enqueue_many/3` (emq.1). `emq.features.md` Part B.1 binds `flow_producer.ex` `add_bulk/2` → `Flows.add_bulk/3`. Full mechanism: the flows family.

**Decision.** Keep `add_bulk/3` (N flows, fail-closed per flow) + `enqueue_many/3` — both already declared-keys, branded, honest-row. No re-derivation owed.

**BCS** bulk submission of N multi-leg flows in one call. · **EchoMesh** consistency-side per flow (each flow's same-queue subtree atomic); availability-side for any cross-queue leg. · **[when]** a consumer submitting N multi-leg flows at once.
