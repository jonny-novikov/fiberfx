# grandchildren-recursive-flow-tree  →  recursive add/3 over the byte-frozen @enqueue_flow/@hold_parent/@enqueue_flow_child/@complete

> Feature: **flows** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   grandchildren-recursive-flow-tree
--@feature   flows
--@status    SHIPPED (Arm A, NORMAL-risk)
--@rung      emq.3.5
--@v1        (no standalone v1 script)   (parity — no v1 script)
--@v3        recursive add/3 over the byte-frozen @enqueue_flow/@hold_parent/@enqueue_flow_child/@complete
```

## v1 source

_*(no raw `.lua` exists — the recursion is host/sweep-orchestrated over the byte-frozen scripts, so no `registry/*.lua` is linked)* — parity command, no raw script in the registry._

## v1 → v3 change ledger

| v1 (build_flow_commands, arbitrary depth) | v3 (SHIPPED, Arm A — byte-frozen scripts, host-orchestrated) |
|---|---|
| no recursive primitive on the v2 side yet | root ── intermediate (BOTH child↑ AND parent↓) ── grandchild |
| (flat fan-in only: a child's outcome reaches | # (1) recursive ENQUEUE: add/3 nested tree, host depth-first walk |
| its DIRECT parent and stops, one level) | # (2) multi-level COMPLETE: byte-frozen @complete composes FREE |
| parent_key -- v1 DATA VALUE, NOT lifted | # (3) recursive FAILURE: host/sweep RE-EMIT a node's death to ITS |
| — | # parent by policy; idempotent HSETNX, eventually-consistent/hop |

## Aligned flow (authoritative side-by-side)

```text
v1 (build_flow_commands, arbitrary depth)        v3 (SHIPPED, Arm A — byte-frozen scripts, host-orchestrated)
─────────────────────────────────────────       ─────────────────────────────────────────────────
no recursive primitive on the v2 side yet        root ── intermediate (BOTH child↑ AND parent↓) ── grandchild
(flat fan-in only: a child's outcome reaches     # (1) recursive ENQUEUE: add/3 nested tree, host depth-first walk
 its DIRECT parent and stops, one level)         # (2) multi-level COMPLETE: byte-frozen @complete composes FREE
parent_key  -- v1 DATA VALUE, NOT lifted         # (3) recursive FAILURE: host/sweep RE-EMIT a node's death to ITS
                                                 #     parent by policy; idempotent HSETNX, eventually-consistent/hop
```

## Decision & rationale

**Covers → v3.** Arbitrary-depth trees (the v1 recursive `build_flow_commands`) — a root → an intermediate node that is **BOTH** a child (carries `parent` up + its own `:dependencies` toward release) **AND** a parent (its own `:dependencies` over grandchildren) → the leaves. The flat family (emq.3.1–3.4) built only **one** parent level; emq.3.5 added arbitrary depth and **closed Movement I**. **SHIPPED — BUILD-GRADE, Arm A, NORMAL-risk.**

**Decision.** Shipped to **Arm A** (Operator-ruled **D-1**, 2026-06-15): a host/sweep re-emit over the byte-frozen failure machinery (every shipped Lua unedited), so **S1** (risk tier) = **NORMAL-risk**. Completion composes recursively for **free** over the byte-frozen `@complete`; the recursive FAILURE hook — `retry/7` triggers a host re-emit and the `Pump` sweep propagates a node's death up each hop (idempotent `HSETNX`, eventually-consistent) — is the sole genuinely-new mechanism. **S3** (the recursive-enqueue shape) shipped as the unified `add/3` nested-tree clause (`add_tree`), depth-capped at **8** (S-Bound). Conformance `flow_grandchild` + `flow_grandchild_fail` landed additive-minor (**50 → 52**, the prior 50 byte-unchanged); the ≥100 determinism loop ran green. *(Reconciled to as-built: the Director's review returned BUILD-GRADE; Apollo's post-build reconcile confirmed every D1–D6 deliverable + INV1–INV11 invariant MATCH.)*

**BCS** (prospective): a multi-stage job whose legs are themselves sub-pipelines — a tree, not a flat fan; *no consumer names flows today*. · **EchoMesh** consistency-first per same-queue subtree (atomic per hop); availability-leaning across queues (a D-deep cross-queue flow's fan-in is ≈ D × the sweep `:tick_ms`, never "atomic across queues"). · **[when]** a multi-stage job whose legs are themselves sub-pipelines.
