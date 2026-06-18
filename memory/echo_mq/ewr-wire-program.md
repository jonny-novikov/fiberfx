---
name: ewr-wire-program
description: "EchoWire client-core spec program (docs/echo_mq/wire/, prefix ewr.) — ports valkey-go construction ergonomics onto the owned wire, additive; Arm A ruled; founding rung ewr.1.1 SPECCED not built"
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

**Roadmap:** Movement I (additive core) = `ewr.1.1` Pipe · `ewr.1.2` command vocabulary + immutable command
value (cf-flags ADVISORY) · `ewr.1.3` two-tier error split (NonValkeyError vs Error). Movement II =
**CLIENT TRACKING / client-side caching = a SEAM, a potential wire MAJOR** (the tracking handshake needs a
frozen-connector boot-step `connector.ex:436`) — gated until echo_store's L1 consumes it.

**Hard line (master invariant):** the new surface lives ABOVE the conformance boundary — `EchoWire` facade
stays 11 verbs, `Conformance.run/2 → {:ok,52}` byte-stable, Connector/RESP/Script/Pool frozen, no new Lua.
Grounded seam: `connector.ex` pipeline:56 / transaction_pipeline:130 / noreply_pipeline:125; `EchoMQ.Pool`
(echo_mq/pool.ex:48) has pipeline but NOT txn/noreply (pool round-robins per cmd) → `exec_txn`/`exec_noreply`
require a single Connector.

**State:** canon (roadmap/progress/features/testing/references) + founding triad
`specs/ewr.1/ewr.1.1.{md,stories,llms,prompt}` + seeded ledger `specs/progress/ewr-1-1.progress.md` AUTHORED
this session (forward-tense SPECCED). NOT built — next is a `/echo-mq-ship`-style Flat-L2 run (slug `ewr-1-1`,
risk LOW). Companion: the AAW method `docs/aaw/aaw.architect-approach.md` (Rationale/5W/Steelman/Steward) was
authored earlier in the same chain. NOTE: `store.design.md` (echo_cache→echo_store rename, Graft/CubDB/Tigris)
does NOT consume this surface — it rides the frozen `EchoMQ.Connector` PUB/SUB — so the wire program is NOT
store-forced. See [[echo-mq-three-movements]] · [[echo-mq-memory]].
