# grandchildren-recursive-flow-tree  →  recursive add/3 over the byte-frozen @enqueue_flow/@hold_parent/@enqueue_flow_child/@complete

> Feature: **flows** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   grandchildren-recursive-flow-tree
--@feature   flows
--@status    BUILDING (`[RECONCILE]`)
--@rung      emq.3.5 — Arm A APPROVED 2026-06-15, building
--@v1        (no standalone v1 script)   (parity — no v1 script)
--@v3        recursive add/3 over the byte-frozen @enqueue_flow/@hold_parent/@enqueue_flow_child/@complete
```

## v1 source

_*(no raw `.lua` exists — the recursion is host/sweep-orchestrated over the byte-frozen scripts, so no `registry/*.lua` is linked)* — parity command, no raw script in the registry._

## v1 → v3 change ledger

| v1 (build_flow_commands, arbitrary depth) | v3 (PROPOSED, Arm A — byte-frozen scripts, host-orchestrated) |
|---|---|
| no recursive primitive on the v2 side yet | root ── intermediate (BOTH child↑ AND parent↓) ── grandchild |
| (flat fan-in only: a child's outcome reaches | # (1) recursive ENQUEUE: add/3 nested tree, host depth-first walk |
| its DIRECT parent and stops, one level) | # (2) multi-level COMPLETE: byte-frozen @complete composes FREE |
| parent_key -- v1 DATA VALUE, NOT lifted | # (3) recursive FAILURE: host/sweep RE-EMIT a node's death to ITS |
| — | # parent by policy; idempotent HSETNX, eventually-consistent/hop |

## Aligned flow (authoritative side-by-side)

```text
v1 (build_flow_commands, arbitrary depth)        v3 (PROPOSED, Arm A — byte-frozen scripts, host-orchestrated)
─────────────────────────────────────────       ─────────────────────────────────────────────────
no recursive primitive on the v2 side yet        root ── intermediate (BOTH child↑ AND parent↓) ── grandchild
(flat fan-in only: a child's outcome reaches     # (1) recursive ENQUEUE: add/3 nested tree, host depth-first walk
 its DIRECT parent and stops, one level)         # (2) multi-level COMPLETE: byte-frozen @complete composes FREE
parent_key  -- v1 DATA VALUE, NOT lifted         # (3) recursive FAILURE: host/sweep RE-EMIT a node's death to ITS
                                                 #     parent by policy; idempotent HSETNX, eventually-consistent/hop
```

## Decision & rationale

**Covers → v3.** Arbitrary-depth trees (the v1 recursive `build_flow_commands`) — a root → an intermediate node that is **BOTH** a child (carries `parent` up + its own `:dependencies` toward release) **AND** a parent (its own `:dependencies` over grandchildren) → the leaves. The flat family (emq.3.1–3.4) built only **one** parent level; emq.3.5 is the **sole remaining flow slice** (closing it closes Movement I). **PROPOSED — not asserted as shipped.**

**Decision.** `[RECONCILE]` · Arm A APPROVED 2026-06-15 (host/sweep-orchestrated, **NORMAL-risk**), building. The keystone fork **S2** (the recursive-failure mechanism) is RULED **= Arm A** — a host/sweep re-emit over the byte-frozen failure machinery (every shipped Lua unedited); this fixes **S1** (risk tier) = NORMAL-risk. Completion composes recursively for **free** over the byte-frozen `@complete`; the recursive FAILURE hook is the sole genuinely-new mechanism. **S3** (the recursive-enqueue shape — a unified `add/3` clause vs a separate `add_tree/3`) is the remaining Arm-A build-detail. Conformance `flow_grandchild` + `flow_grandchild_fail` are additive minor (**50 → 52**, the prior 50 byte-unchanged). *(Still `[RECONCILE]` — the approved build's claims, not yet the verified as-built; the row flips at ship.)*

**BCS** (prospective): a multi-leg settlement whose legs are themselves multi-venue sub-settlements — a tree, not a flat fan; *no TRD rung names flows today*. · **EchoMesh** consistency-first per same-queue subtree (atomic per hop); availability-leaning across queues (a D-deep cross-queue flow's fan-in is ≈ D × the sweep `:tick_ms`, never "atomic across queues"). · **[when]** a multi-leg settlement whose legs are themselves multi-venue sub-settlements.
