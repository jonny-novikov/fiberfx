# BCS.3 · The Bus — EchoMQ, Valkey-native, taught

> The B3 chapter of the BCS course (`/bcs/bus`), teaching manuscript Part III — the bus on which identities
> and messages about identities travel: the connector substrate, jobs as entities, the Lua state machine, fair
> lanes, the stores closed into the loop, and the referee's table. One chapter landing, seven module hubs
> (B3.1–B3.7, with B3.7 teaching Appendix A), dives fixed per module in the ladder. Spec of record:
> [`bcs.3.specs.md`](bcs.3.specs.md) · agent guide: [`bcs.3.llms.md`](bcs.3.llms.md).

## Why

B2 gave the names a home; B3 puts them in motion. Part III is the manuscript's bus — EchoMQ 2.0, built
Valkey-native from the first byte by Decision D-1: a fresh `emq:` keyspace, a version-fenced Lua bundle, no
compatibility ballast from any predecessor wire. The Part is **fully written** (`content/bcs3.md` preface +
`bcs3.1.md`–`bcs3.6.md`, six chapters, plus the connector appendix `bcsA.md`), and its evidence is committed
and frozen: six rung records (`bcs_rung_3_1`…`3_6_check.out`, tallying `5/5 · 5/5 · 6/6 · 8/8 · 6/6 · 6/6`),
the connector gate (`emq_connector_check.out`, `PASS 8/8` against live Valkey 9.1.0), and the conformance
record's `CONFORMANCE 14/14`. So B3 is the course's third buildable chapter — the one where the cargo law
(*only identities cross*) rides onto a wire, and where the rival is measured with its advantage printed in its
own row.

The whole chapter is manuscript-ready: all seven modules build from written prose with frozen records. The
build is batched in waves (≤2 concurrent module agents) per `/bcs-write`; the ladder fixes structure for every
batch up front.

## What

The chapter, all seven modules:

1. **The chapter landing** — `/bcs/bus` (`html/bcs/bus/index.html`): Part III's teaching arc — the six laws of
   the part (one transition one script · the fence before the first command · jobs are entities · park don't
   poll · delivery semantics named per surface · rivals measured with advantages printed) over seven module
   cards, closing with an "Up next" grid. Orchestrator-only.
2. **B3.1 · The Fence and the Keyspace** — hub `fence-and-keyspace/` + three dives. Teaches `content/bcs3.1.md`
   (`PASS 5/5`, F1–F5): the `emq:{q}:<type>` grammar, the gate at the job position, the live fence read, binary
   discipline, the co-location law.
3. **B3.2 · Jobs Are Entities** — hub `jobs-are-entities/` + three dives. Teaches `content/bcs3.2.md`
   (`PASS 5/5`, J1–J5): the `JOB` registry (D-10), the three-field row, idempotent enqueue in one script, the
   `EMQKIND` wire class, the order theorem's dividend.
4. **B3.3 · The State Machine in Lua** — hub `state-machine/` + three dives. Teaches `content/bcs3.3.md`
   (`PASS 6/6`, L1–L6): claim as the token mint, `attempts` as the fencing token, the schedule, the morgue, the
   reaper.
5. **B3.4 · Fair Lanes** — hub `fair-lanes/` + three dives. Teaches `content/bcs3.4.md` (`PASS 8/8`, G1–G8):
   per-group lanes, the ring invariant, the rotating claim, ceilings and pauses, park-don't-poll, the loop, the
   reap window closed.
6. **B3.5 · The Bus Meets the Stores** — hub `bus-meets-stores/` + three dives. Teaches `content/bcs3.5.md`
   (`PASS 6/6`, B1–B6): the fill round trip, exactly-once effect by provenance, the consumer as one more owner,
   the audit dividend, stop-is-a-drain.
7. **B3.6 · Conformance and the Rival's Numbers** — hub `conformance/` + three dives. Teaches
   `content/bcs3.6.md` (`PASS 6/6`, C1–C6 + `CONFORMANCE 14/14`): the committed harness, the referee habit, and
   Oban 2.18.3 on PostgreSQL 16.14 measured with the asymmetry stated first.
8. **B3.7 · Appendix A — The Connector** — hub `the-connector/` + three dives. Teaches `content/bcsA.md`
   (`emq_connector_check.out`, `PASS 8/8`): one-pass RESP2, pipelining as the primitive, the typed fatal fence,
   EVALSHA-first declared-keys scripts, the measured wire.

Proof is mechanical: every page at STATUS: PASS across the ten gates (`--require-refs`), every figure traced to
its committed source, the md mirror authored first for every route.

## Who

- **The reader** — the engineer or agent who has B1's contract and B2's stores and now needs the bus: how work
  becomes a named entity, why every transition is one script, what the fencing token is, how fairness is
  constructed rather than hoped, and what the rival's durable row really costs.
- **The Operator** — reviews each batch against the frozen rung records and the referee's own asymmetry line.
- **The authoring agents** — one `bcs-expert` per module, briefed from [`bcs.3.llms.md`](bcs.3.llms.md), which
  carries the senior-verified grounding bank (agents cite from it and the named sources; they re-derive nothing
  and invent nothing).

## When

After B2 (built to its manuscript edge) and before B4 — the landing's "Up next" assumes B0–B2 live. Within the
chapter: the landing first (orchestrator-only), then module waves of ≤2 (suggested: B3.1+B3.2 → B3.3+B3.4 →
B3.5+B3.6 → B3.7), deferred cross-module links restored after each wave's siblings land, the course-landing
relink as the chapter's last act.

## Where

- Pages: `html/bcs/bus/` (landing + seven module dirs, three dives each); md mirrors:
  `docs/echo/bcs/markdown/bus/**`.
- Grounding (read-only): `content/bcs3.md`, `bcs3.1.md`–`bcs3.6.md`, `bcsA.md`, with the rung records under
  `content/echo_data/runtimes/elixir/` (`bcs_rung_3_1`…`3_6_check.out`, `emq_connector_check.out`) — the
  per-module map is in [`bcs.3.llms.md`](bcs.3.llms.md).
- Relink targets (orchestrator-only): `html/bcs/index.html` (the B3 card + footer column), `html/bcs/bus/index.html`
  (module cards), `docs/echo/bcs/bcs.toc.md`.

## How

Orchestrated by `/bcs-write bus …`: the orchestrator authors the chapter landing from this triad (bootstrapped
from the built B2 chapter landing `html/bcs/elixir-core/index.html`), fans out one `bcs-expert` per module with
the [`bcs.3.llms.md`](bcs.3.llms.md) brief, adversarially verifies every page (gates + figure provenance +
identity leak + voice), then relinks the manifests and syncs the TOC. No git anywhere; the Operator commits
out-of-band.

## Decisions

- **D-B3.1 — The dive partition slices the chapter's own gates.** Each module's dives follow the manuscript
  chapter's gate structure (B3.1's F1–F5, B3.3's L1–L6, B3.4's G1–G8 …), recorded in the spec's module ladder;
  agents do not redesign them. (The D-B2.1 discipline, applied to Part III.)
- **D-B3.2 — B3.7 teaches Appendix A; Appendix B stays living-status.** The connector appendix (`bcsA.md`) is a
  written manuscript appendix with a frozen `PASS 8/8` record, so it is a course module (the B1.6 precedent for
  appendices). The **production connector appendix (Appendix B)** has a committed spec (`content/bcsB.specs.md`)
  and two committed rungs (`emq_connector_prod_check.out`, `emq_connector_resp3_check.out`) but **no prose
  `bcsB.md`** — the course teaches prose chapters, not bare rungs (the D-B2.2 rule), so Appendix B is referenced
  by name in living-status voice ("the manuscript plans…") and becomes a module only when its prose ships.
- **D-B3.3 — The referee's asymmetry line travels with the numbers.** Any page quoting a B3.6 rival figure also
  quotes the record's asymmetry statement (*the rival's enqueue is durable and transactional … the bus's
  enqueue is volatile by decision D-2*) — the manuscript's own discipline, made a course rule so no excerpt
  becomes marketing.
- **D-B3.4 — References extend the vetted registry with Part III's own citations.** The Valkey documentation
  family (protocol, cluster-spec, zrange, sorted-sets, programmability, replication, lmove, blpop), Kleppmann's
  fencing-token analysis, Shreedhar & Varghese (DRR), Helland (CIDR 2007), the Erlang/OTP `supervisor` docs, the
  Oban module docs, PostgreSQL's async-commit and NOTIFY pages, and the Valkey 8.1.0 GA announcement. These URLs
  are vetted for B3 pages; nothing outside the union of this list and the B0–B2 registry.
- **D-B3.5 — Protocol depth doors to `/echomq`.** Part III narrates the bus the `/echomq` course teaches in
  rung-level depth; where a dive meets the emq keyspace, Lua inventory, or conformance suite beyond the
  manuscript's own text, it doors to `/echomq` rather than teaching it. The substrate patterns door to
  `/redis-patterns`; the umbrella to `/elixir`.

## Boundaries

This chapter builds Part III's pages only. It does not author B4+ pages, does not edit the manuscript or its
ledger (`content/**`), does not touch shared assets, other courses, or the server wiring, and does not deploy.
Streams/PubSub eventing is EMQ 3.0 by D-3 — named, never asserted-as-built. Cluster routing is parked exactly as
the manuscript parks it. The bus's volatility (D-2) is taught as a decision with a price, not smoothed over.

## Companion files

[`bcs.3.specs.md`](bcs.3.specs.md) (the spec of record: the module ladder, invariants, stories, DoD) ·
[`bcs.3.llms.md`](bcs.3.llms.md) (the agent guide: the verified grounding bank, per-module briefs, commands) ·
the course docs ([`../bcs.md`](../bcs.md) · [`../bcs.toc.md`](../bcs.toc.md) ·
[`../bcs.roadmap.md`](../bcs.roadmap.md)) · the B2 exemplar triad ([`bcs.2.md`](bcs.2.md)) · the manuscript
(`../content/bcs3.md`, `bcs3.1.md`–`bcs3.6.md`, `bcsA.md`) and the committed evidence under
`../content/echo_data/runtimes/elixir/`.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Manuscript: ../content/bcs.toc.md
