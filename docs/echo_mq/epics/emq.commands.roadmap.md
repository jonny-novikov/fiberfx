# EMQ1 · the v1 to v3 EchoMQ command matrix

> **PROPOSED** — the v1 BullMQ-derived Lua command corpus mapped to its state-of-the-art v3 (BCS + EchoMesh ready) reimplementation.

## Rationale

The 50 v1 Lua commands under `docs/echo_mq/specs/commands` are the valuable, near-complete job-system command surface that arrived in v1: 
a full admission / scheduling / claim / finish / flow / lock / metrics / removal grammar, hardened in BullMQ and lifted into the frozen v1 bus. 
The v2 `echo_mq` bus ported a **subset** of that surface under the v2 laws — re-derived, never copied — leaving the rest unbuilt or deliberately retired. 
This matrix maps **all 50** of them v1 → v3, so the state-of-the-art EchoMQ Bus is **BCS + EchoMesh ready**: every command either holds as-shipped, gets a PROPOSED re-derivation, or is honestly named as retired/folded.

The structural spine that governs every row: **v1 Lua roots keys in data values** — a `parentKey` read out of a job hash (`HMGET jobKey "parentKey"`), a per-job key spliced from an `ARGV` prefix inside the script body (`prefix .. jobId`), a scheduler-occurrence id built from a `ZSCORE`-returned millisecond (`repeat:<id>:<millis>`), a `<base><jobId>:lock` string built from a `cmsgpack`-unpacked base. Under the v2 **declared-keys law (A-1 / S-6)** a key must be in `KEYS[]` or grammar-rooted from a declared `KEYS[n]`; a key sourced from a data value is structurally illegal. Therefore **every v3 form is a re-derivation, never a lift** — the value of v1 is the *grammar of capabilities* it enumerates, not the Lua that implements them.

## 5W

- **Why** — the v1 corpus is the most complete statement of *what a job system must do*; the v2 bus is the most complete statement of *how it must be done lawfully*. The gap between them is unmapped. This spec closes it, so the bus that BCS and EchoMesh build on has a single, audited command surface with every v1 capability accounted for.
- **What** — a command-by-command matrix: each of the 50 v1 Lua scripts, its purpose, its v2 as-built status (PORTED / PARTIAL / NOT YET / retired-folded), its PROPOSED v3 decision under the declared-keys laws, and what each integration target (BCS, EchoMesh) needs from it.
- **Who** — authored for the EchoMQ program (the architect/implementor/evaluator triad over `docs/echo_mq/`), and for the two consuming courses: BCS (`/bcs`) and EchoMesh (`/mesh`, `/art`).
- **When** — after the v2 bus reached its operator/flow/lock/metrics plane (emq.2.x / emq.3.x as-built) and before the stream-tier and lanes-deepened rungs (emq.3.x stream / emq.4) that BCS + EchoMesh demand; the PROPOSED column is the forward ladder.
- **Where** — the v1 corpus `docs/echo_mq/specs/commands` → the v2 bus `echo/apps/echo_mq` → the v3 BCS/EchoMesh-ready EchoMQ 3.0. wired onto `echo_store`

## Motivation — the integration targets

Two real consumers shape every v3 decision in this matrix. Neither is satisfied by a lift of v1; each needs the command surface re-derived to a specific property.

**BCS — the Branded Component System architecture.** BCS makes the **14-byte branded id** the one addressable entity across every surface: "a fill matched on a consistency-first book is the same addressable entity in the availability-first cache that serves it, the stream that logs it, the object store that retains it, and the worker that prices it" (`docs/echo/mesh/markdown/index.md`). From the command surface BCS needs: **the order theorem** (byte order = mint order, no second index) as the deterministic-admission floor a consumer's hot path stands on — for codemojex, the per-player guess stream; **single-writer claim** with the lease as the only ownership proof (codemojex scores each guess under a single authority); **fair lanes** (per-player / per-tenant, one Lanes group per player) replacing per-job priority so a many-tenants-one-queue surface has no noisy-neighbour starvation; **flows** as the composite work unit (a parent job whose children are fanned in by branded id); and an **operator plane** (remove / reprocess / drain / clean / pause) over branded ids for a consumer's runbook.

**EchoMesh — CAP segmented across a BCS stack on the BEAM.** EchoMesh treats CAP as "a menu to read, not a wall to scale," and **segments** the consistency↔availability trade subsystem by subsystem (`docs/echo/art/markdown/echomesh/index.md`). From the command surface it needs each verb placed on the dial: the **consistency-first** surfaces — single-writer claim, single-id state-of-record reads, flow fan-in, destructive control-plane acts — "refuse rather than risk a second writer" under partition; the **availability-first** surfaces — counts, metrics, set/hash-shaped reads, paged retention reads — "degrade rather than stop," served from the nearest replica with a bounded staleness budget. The segmentation only coheres because the branded id is shared across the dial, and the substrate is **transparent** (the same code from a laptop to a fleet, placement by the branded id over a consistent-hashing ring). The matrix's **BCS** and **EchoMesh** columns record, per command, which property the v3 form must carry. (EchoMesh is a forward concept — every EchoMesh claim here is in proposed voice, never asserted as shipped.)

## The deliverables [RECONCILE]

[emq.commands.registry.md](emq.commands.registry.md)
[emq.commands.md](../specs/emq.commands/emq.commands.md)


