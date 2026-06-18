---
name: ewr-wire-program
description: "EchoWire client-core (docs/echo_mq/wire/, prefix ewr.) — valkey-go client ported onto the owned wire, additive; MOVEMENT I SHIPPED+committed (ewr.1.1 Pipe · 1.2 Cmd/Command builder · 1.3 Result classifier); NEXT RUN = wire it onto the Codemoji Game as the first consumer"
metadata: 
  node_type: memory
  type: project
  originSessionId: 085e673b-4f13-4292-ad73-3cb2f3aed7b6
---

The **EchoWire client-core** spec program — a NEW program opened under `docs/echo_mq/wire/` (prefix `ewr.`,
sibling to `emq.*`), source of truth on-disk. Goal: port the **valkey-go / rueidis CONSTRUCTION ergonomics**
(the fluent command builder + functional pipelining) onto the owned wire (`echo/apps/echo_wire`) as a brand-new
`EchoWire.*` surface, **purely additive over `EchoMQ.Connector.pipeline/3`** — the connector ALREADY
auto-pipelines, so the program adds construction sugar, never pipelining.

**Ruling (Operator, this session):** design fork [`ewr.design.md`](docs/echo_mq/wire/design/ewr.design.md)
**RULED Arm A = `EchoWire.Pipe`** (the threaded `|>` pipeline; `%Pipe{conn,cmds}` accumulator → `exec/1` =
`Connector.pipeline/3`), with the **curated-verbs + `Pipe.command/2` escape-hatch** sub-fork. Arms B
(`EchoWire.Cmd` command-value) and C (`EchoWire.Query` macro) chosen-against but LAYERABLE onto A later (B's
cf-flag value → ewr.1.2; C's block → sugar over A).

**Roadmap:** Movement I (the additive core, ALL SHIPPED) = `ewr.1.1` **EchoWire.Pipe** (threaded `|>` batch +
curated verbs + `command/2` escape) · `ewr.1.2` **EchoWire.Cmd** (fluent builder) + **EchoWire.Command**
(immutable `%Command{parts,flags,slot}`, FULL `cf` bitfield w/ bit-inclusion + CRC16 slot, advisory — Operator
ruled **Arm 3 standalone-builder + full-cf**, over the recommended minimal; `run/2` on `Cmd`, NOT a 12th facade
verb) · `ewr.1.3` **EchoWire.Result** (two-tier classifier: `classify`/`non_valkey_error`/`error`/`server_errors`,
a pure reader over `exec`'s return; server tier = in-band `{:error_reply,_}`, transport = `{:error,term}`).
Movement II =
**CLIENT TRACKING / client-side caching = a SEAM, a potential wire MAJOR** (the tracking handshake needs a
frozen-connector boot-step `connector.ex:436`) — gated until echo_store's L1 consumes it.

**Hard line (master invariant):** the new surface lives ABOVE the conformance boundary — `EchoWire` facade
stays 11 verbs, conformance byte-stable (the wire registers NO scenario — cite the emq-owned count VALUE-FREE, never pin a number: it drifted 52→53→54 within one session from emq's active out-of-band work), Connector/RESP/Script/Pool frozen, no new Lua.
Grounded seam: `connector.ex` pipeline:56 / transaction_pipeline:130 / noreply_pipeline:125; `EchoMQ.Pool`
(echo_mq/pool.ex:48) has pipeline but NOT txn/noreply (pool round-robins per cmd) → `exec_txn`/`exec_noreply`
require a single Connector.

**State (2026-06-18): MOVEMENT I COMPLETE — ewr.1.1 + 1.2 + 1.3 all SHIPPED + committed** via the recalibrated
Flat-L2 pipeline (Venus frames forks as 4-part Arms → Director rules each with the Operator via the MANDATORY
`AskUserQuestion` gate + independently verifies + consolidates findings → Mars builds + is the primary code gate
→ Apollo mentors OUT of pipeline, PROPOSE-ONLY). Every rung additive (facade 11, `EchoWire.run` absent, frozen
Connector/RESP/Script/Pool untouched, conformance byte-stable); BDD `:valkey` stories live in
`echo_mq/test/stories/` (dep direction) generated via `mix echo_mq.stories --match wire_pipe`; ledgers
`specs/progress/ewr-1-N.progress.md`; program manual + Venus/Mars/Apollo calibrations at
`docs/echo_mq/wire/program/` (Apollo-authored). **NEXT RUN (Operator-directed): wire the new ValKey client onto
the Codemoji Game** (`echo/apps/codemojex`) — Codemoji = the FIRST real consumer of EchoWire (Pipe/Cmd/Command/
Result). Movement II (CLIENT TRACKING client-side caching) remains a seam until a consumer makes the wire-MAJOR
trade real. Apollo follow-up: value-free conformance sweep of the living floor docs (roadmap/program/testing
still cite `{:ok,52}`). GIT lesson: with the Operator staging out-of-band concurrently, commit with
`git commit -- <pathspec>` (pathspec on the COMMIT), never `git add <p>` + bare `git commit` (sweeps in
concurrent staging). The AAW method = `docs/aaw/aaw.architect-approach.md`. See [[echo-mq-three-movements]] ·
[[echo-mq-memory]].
