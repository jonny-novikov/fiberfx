# EchoMQ in Three Movements — the engineering program roadmap

Read [Echo References](./emq.references.md) before EXPANDING this roadmap. This roadmap is the
**forward** plan; the per-rung shipped deliverables live in the [changelog](./emq.changelog.md).
The destination is **EchoMQ 3.0 — Streams Support**.

## The epic

**One program, three movements: all EchoMQ code converges in `echo/apps/echo_mq`.**

- **Why.** The v1 line cannot become EchoMQ 2.0 in place. Its two structural flaws could not be
  fixed under compatibility — unauditable key access (operand keys built from an `ARGV` prefix
  inside script bodies) and an open keyspace (verbatim interpolation, no total parse) — so the fork
  was ruled to happen exactly once (design §0, §1 S-3), and the v1 line froze at `1.3.0`. The
  Branded Component System re-derived the protocol from first principles and shipped it as
  **measured, rung-gated code** — born braced (`emq:{q}:`), born branded (`JOB` ids gated at the key
  builder), born declared (every Lua key in `KEYS[]` or grammar-derived). A from-scratch convergence
  target inherits those proofs; extending v1 in place would inherit the debt.
- **What.** `echo/apps/echo_mq` (the BCS 2.0 Valkey-native bus, `EchoMQ.*`, lib-only) is THE single
  convergence target, with `echo/apps/echo_wire` (`EchoMQ.{RESP, Connector, Script}` frozen-named
  under the `EchoWire` facade) beside it. The **protocol version climbs per rung** — the wire fence
  and the `mix.exs` label move together — staying in the **2.x line** through Movement II
  (`echomq:2.4.1`→`2.4.2`→…); the **`echomq:3.0.0` MAJOR is EchoMQ 3.0 — the Stream Tier**, ratified
  when streams land. The legacy v1 line (frozen `1.3.0`) was **rewritten fresh into `echo_mq` and
  removed** — single source of truth.
- **Who.** The Operator owns the goal and every fork; the aaw lead team ships the rungs — **Venus**
  (spec-steward + strawman author) → **Director** (orchestrator; surfaces the design Arms and rules
  them with the Operator via the mandatory `AskUserQuestion`) → **Mars** (implementor) → **Director**
  (verifies code + invariants) → **Apollo** (the standing Mentor, who calibrates the agents). The
  worked consumer is **codemojex** (`echo/apps/codemojex` — drains `EchoMQ.Lanes`/`Consumer`,
  publishes `EchoMQ.Events`); the headline-planned consumer is **echo_bot** (`echo/apps/echo_bot` —
  Telegram notifications at scale; the seam is `EchoBot.Platform.Telegram.send_reply/3`).
- **When.** The foundation is **established** (`emq.0`). **Movement I is CLOSED** (emq.1 · the emq.2
  parity cluster · the emq.3 flow family — conformance **52/52**; deliverables in the
  [changelog](./emq.changelog.md)). **Movement II (emq.4–emq.8) is the 2.x extension**, one increment
  per run — **the emq.4 groups family is CLOSED** (4.1–4.4, conformance **61**); **emq.5 (batches) is
  next**. **EchoMQ 3.0 — the Stream Tier — is the headline delivery that follows**, landing the
  `3.0.0` major.
- **Where.** Code: `echo/apps/{echo_wire, echo_mq, echo_store, echo_data}`, `echo/rungs/`. Specs:
  `docs/echo_mq/` (this roadmap · the design canon `emq.design.md` · the stream tier
  `emq.streams.md` · the references · the rung triads under `specs/`).

## The movements

### Foundation · EchoMQ protocol v2 — established (emq.0)

The v2 protocol and the BCS substrate are **in place and proven on this machine**: the owned wire
(`echo_wire`), the bus (`echo_mq`), the store (`echo_store` — durable replication via the
`EchoStore.Graft` engine streamed to Tigris; the `EchoStore.Shadow` behaviour retired,
`store.design.md` §2), and the `EchoData` branded-id substrate. Detail: the
[`emq.0` triad](./specs/emq1/emq.0/emq.0.md); the shipped record is the
[changelog](./emq.changelog.md).

### Movement I · The Core — CLOSED (conformance 52/52)

The v1 capability surface, **rewritten state-of-the-art inside `echo_mq`** under the v2 laws —
nothing migrated, every capability rewritten fresh, the v1 app then removed. Three planes landed:
**scheduler & retry** (emq.1), **the parity floor** (emq.2.1–2.4: read → operator → watch → close),
and **the flow family** (emq.3.1–3.5: single-queue → child-result reads → cross-queue fan-in →
failure-policy/bulk → grandchildren). The per-rung deliverables, conformance deltas, and commit shas
are in the [changelog](./emq.changelog.md); the wire/keyspace/lease invariants in
[`emq.design.md`](./emq.design.md).

#### Implementation index — methods only (the live API surface; re-probe the tree, line numbers drift)

| Plane | Module(s) | Public surface |
|---|---|---|
| scheduler | `EchoMQ.Jobs` | `enqueue/4` · `enqueue_at/5` · `enqueue_in/5` · `enqueue_many/3` · `claim/3` · `complete/4,5` · `retry/7` · `promote/3` · `reap/2` · `browse/3` · `pending_size/2` |
| scheduler | `EchoMQ.Repeat` · `EchoMQ.Backoff` · `EchoMQ.Pump` | `Repeat`: `register`·`cancel`·`due`·`advance`·`count` — `Backoff.delay_ms/2` — `Pump`: `sweep/1`·`start_link/1` |
| read | `EchoMQ.Metrics` | `get_counts/3` · `get_job/3` · `get_job_state/3` · `get_metrics/3` · `get_rate_limit_ttl/2,3` · `get_global_rate_limit/2` · `is_maxed/2` · `lane_depth/3` · `lane_depths/3` |
| operator | `EchoMQ.Admin` · `EchoMQ.Jobs` | `Admin`: `pause/2`·`resume/2`·`drain/2,3`·`obliterate/2,3` — `Jobs`: `update_data/4`·`update_progress/4`·`add_log/4,5`·`get_job_logs/3`·`remove_job/3,4`·`reprocess_job/3` |
| watch | `EchoMQ.Events` · `EchoMQ.Meter` · `EchoMQ.Locks` · `EchoMQ.Stalled` · `EchoMQ.Cancel` | `Events`: `subscribe`·`publish`·`close` — `Meter`: `attach`·`emit`·`span` — `Locks`: `track_job/3`·`untrack_job/2`·`is_tracked?/2` — `Stalled.check/2,3` — `Cancel`: `new/0`·`cancel/2,3`·`check/1` — `Jobs`: `extend_lock/5`·`extend_locks/4` |
| flows | `EchoMQ.Flows` · `EchoMQ.Pump` | `Flows`: `add/3`·`add_bulk/3`·`children_values/3`·`ignored_failures/3`·`dependencies/3` — `Pump`: `deliver_flow_completions/3`·`maybe_reemit_parent_death/4`·`on_same_queue_child_death/4` |
| groups | `EchoMQ.Lanes` · `EchoMQ.Metronome` · `EchoMQ.Metrics` | `reassign/4` · `drain/3` (lane-scoped) · `reap_group/4` · `wclaim/3` · `weight/4` · `lane_depths/3` — `EchoMQ.Metronome` (park-don't-poll dispatch: `start_link`/`register_idle`) *(Movement II · emq.4 CLOSED)* |

### Movement II · The Extension — the 2.x runway (emq.4–emq.8)

- **Why** — a multi-tenant production bus needs the pattern depth the established queueing systems
  proved at scale (groups, batches, lifecycle controls), the near-cache deepening, and the proof
  stack that turns engine claims into a parse.
- **What** — five families, one rung each: **groups** (fair-lanes: control plane · group-aware
  recovery · the park-don't-poll metronome · weighted/deficit rotation); **batches** (bulk
  consumption, `min_size`/`timeout` shaping, affinity, the partitioned finish); **lifecycle
  controls** (TTL per worker/name, distributed cancel, checkpoints); **the cache deepened** (BCAST
  tracking, absorbed-fills compaction, `synchronous=FULL` per group, the invalidation-transport
  evaluation — design §12.3's named reopening); **conformance + telemetry + the benchmark gate** (the
  three-layer proof stack; the engine matrix; the published table with the rival's numbers recorded
  beside EchoMQ's).
- **Version** — each rung is an **additive minor** in the **2.x line** (the conformance count grows +
  host verbs, no new wire class) **+ the one-line `@wire_version` + `mix.exs` bump**. The connector's
  fence **logic** stays frozen (only the `@wire_version` **constant** moves); the **single-owner
  wire** makes per-rung climbing safe (no external clients — connector + server deploy as a unit).
  The `:fence` conformance scenario + `connector_test` are **version-agnostic** (assert the live key
  `== Connector.wire_version()`). emq.8 closes the 2.x line; the `3.0.0` major is reserved for the
  Stream Tier. *(Supersedes the earlier "two-planes / fence frozen at 2.0.0" framing — emq.4.2-D3.)*
- **When** — after Movement I. The cache-deepening rung is least coupled to the machine and may be
  pulled forward — an Operator call, recorded so it is a decision, not drift.

### EchoMQ 3.0 · The Stream Tier — the headline delivery

**EchoMQ 3.0 = Streams Support** — event streams on the certified wire, under the v2 laws, no second
protocol. The `echomq:3.0.0` MAJOR is ratified when this tier lands. It **hard-gates on `emq.0`**
(its verbs land on the extracted `echo_wire`; its archive lives in the `EchoStore.Graft` engine →
Tigris — both closed at emq.0) and is **sequenced after Movement II** (the 2.x runway). Six rungs in
three milestones — **S1 the writer** (`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`, then
`EchoMQ.Stream`: hash-tagged keys, branded record ids, append == mint order) → **S2 the readers** (a
BEAM consumer group beside a non-BEAM reader, crash re-delivery, retention as declared `MAXLEN`/
`MINID` policy) → **S3 the memory** (segments folded into the Graft engine, box-loss restore,
time-travel via mint-instant → `XRANGE`).

> The full ladder, the derived needs, and the durable-archive answer live in the high-level spec:
> **[`emq.streams.md`](./emq.streams.md)**.

## The rung ladder (CONFIRMED at the Stage-1b checkpoint)

| Rung | Movement | Ships (the slice) | Status |
| --- | --- | --- | --- |
| **emq.0** | Foundation | EchoMQ protocol v2 + the BCS substrate (wire extraction · the store's `Graft` engine · §5 suite) | ✅ **established** |
| **emq.1** | I | scheduler + retry (delayed / repeatable jobs · attempts-with-backoff · auto-resubscribe) | ✅ CLOSED |
| **emq.2** | I | the **parity floor** — read → operator → watch → close (emq.2.1 · 2.2 · 2.3 · 2.4) | ✅ CLOSED |
| **emq.3** | I | the **parent/flow family** — single-queue → reads → cross-queue → failure-policy → grandchildren (emq.3.1–3.5) | ✅ CLOSED |
| emq.4 | II | groups deepened: control plane, group-aware recovery, the park-don't-poll metronome, weighted/deficit rotation + the starvation drill | ✅ **CLOSED (4.1–4.4)** — control plane `@greassign`/`@gdrain` (`6bca0d6d`, HIGH) + group recovery `@greap_group` (`echomq:2.4.2`) + the **metronome** `EchoMQ.Metronome` (the metronome-as-system: one `BLPOP`-blocker per queue fans readiness to N pooled consumers over BEAM messages, `@gclaim` byte-frozen, no wire/§6 edit; `174e1d7f`, HIGH/Apollo — [decision](./kb/metronome-design/metronome-fork-decision.md)) + **weighted rotation** `@gwclaim`/`weight/4` + the starvation drill (`361fd663`, Fork B → Arm 2 additive, NORMAL+); **conformance 61**, wire fence `echomq:2.4.2`, label `2.4.4` |
| emq.5 | II | batches: bulk consumption, `min_size`/`timeout` shaping, affinity, the partitioned finish | 📋 **SPECCED — 5.1–5.4 carved** (spine → shaping → affinity → finish; uniform NORMAL, Apollo recommended at 5.3) → [carve](./specs/emq2/emq.5/emq.5.md) |
| emq.6 | II | lifecycle controls: TTL per worker/name, distributed cancel, checkpoints | 📋 planned abstract |
| emq.7 | II | the cache deepened: BCAST tracking, absorbed-fills compaction, `synchronous=FULL` per group, the invalidation-transport evaluation | 📋 planned abstract — may be pulled forward (Operator call) |
| emq.8 | II | conformance + the engine matrix + the telemetry contract + the benchmark gate (the three-layer proof stack); **closes the 2.x line** | 📋 planned abstract |
| **emq3.1–emq3.6** | **3.0** | **EchoMQ 3.0 — the Stream Tier** (S1 writer → S2 readers → S3 memory); lands the `echomq:3.0.0` major | 🔒 PROPOSED — gated on emq.0 (met), after Movement II ([`emq.streams.md`](./emq.streams.md)) |

Rungs are one-increment-one-run; every rung's pre-build reconcile re-trues its abstract against the
as-built tree before its triad is authored. **The old ladder → this ladder** (the design's §4/§10
name the OLD, pre-program ladder): old emq.3 batches → emq.5 · old emq.4 lifecycle → emq.6 · old
emq.5 EchoStore → the near-cache landed in the foundation, deepening is emq.7 · old emq.6
conformance/proof → emq.8 · the displaced groups family → emq.4 (RULED Stage-1b).

## How the program runs

The aaw lead team turns each rung into a spec triad and a build at the established quality bar; the
Operator reviews the increment and returns feedback; **feedback edits the spec**. Per rung: sharpen →
build → ship → demo → review → feedback → adapt. **Grounding law:** every EchoMQ reference is a real
module or file; engine claims cite valkey.io; surfaces a rung builds are written "emq.N builds" —
never asserted-as-shipped. **"Thin but robust":** opt-in families; one Lua script per transition,
atomic on the truth row; every new process supervised with a pure decision core; harnessed (pure
ExUnit + `:valkey`-tagged wire suites); honest (at-least-once stays at-least-once; partial coverage
reported with the reason).

## The master invariant

The fork happened exactly once — the v2 key universe is grammar-total (braced `emq:{q}:`, the
first-byte-disjoint `{emq}:` reserve, the gated branded `job:` position), every Lua key
declared-or-rooted, and the version record (`{emq}:version`) **climbs per rung behind the five-code
fence** — born `echomq:2.0.0` at the emq.1 fork, advancing one minor each Movement II rung
(`echomq:2.4.2` live), reaching the **`echomq:3.0.0` major with the Stream Tier**. **No later rung
re-breaks the wire**: additive registration is a protocol minor; a wire break or computed-floor raise
is a major (design §1 S-3, §6). Claims are phrased against **Valkey, current stable line**, enforced
as a gate, with honest-row reporting (§1 S-4). Process laws bind every rung: per-app testing only
(umbrella-wide `mix test` BANNED — D7), agents run no git (D8), the Director commits by pathspec.

## Seams & open decisions

1. **Carried family knobs** (each belongs to its family rung's first feedback loop): limiter window
   mode · the batch processor contract · cache eviction beyond TTL · dogfooding EchoStore in the
   scheduler · cross-runtime adoption order · the benchmark gate numbers · `{emq}:queues` ships only
   WITH its registry⇄keyspace coherence probe · `{emq}:locks` stays registered reserved-by-name.
2. **The unslotted proposals** (engine framing on the design's Valkey canon): the transport rung (the
   connector over unix sockets and TLS); FLAME ephemeral execution (consumers as runners that exist
   only for the drain); the Go-driven conformance harness and the Go store/keyspace ports; the MCP
   surface over bus + cache + journal. Held at the program's seam, slotted only by a checkpoint ruling.
3. **Toolchain** — build briefs RE-PROBE `asdf current erlang` rather than hardcoding; a toolchain
   switch implies a full rebuild before gates.

## Dependencies, recorded

- **emq.0 is the spine.** The extracted wire (`echo_wire`) and the store's durable engine
  (`EchoStore.Graft` → Tigris) are the universal predecessors — Movement I, Movement II, and the
  entire Stream Tier stand on them.
- **The Stream Tier (EchoMQ 3.0) hard-gates on emq.0** (verbs on the extracted wire; archive in the
  `Graft` engine) and is sequenced after Movement II. The ladder + the derived needs are in
  [`emq.streams.md`](./emq.streams.md).

---

The binding design: [`./emq.design.md`](./emq.design.md) (the 2.x line, S-1..S-7). The EchoMQ 3.0
stream tier: [`./emq.streams.md`](./emq.streams.md). The references:
[`./emq.references.md`](./emq.references.md). The program front door: [`./echo_mq.md`](./echo_mq.md).
The progress dashboard: [`./emq.progress.md`](./emq.progress.md). The shipped deliverables:
[`./emq.changelog.md`](./emq.changelog.md). The forward-feature catalog:
[`./emq.features.md`](./emq.features.md). Rung triads: [`./specs/`](./specs/).
