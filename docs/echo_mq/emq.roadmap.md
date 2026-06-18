# EchoMQ in Three Movements — the engineering program roadmap

Read [Echo References](./emq.references.md) before EXPANDING this roadmap.

## The epic

**One program, three movements: all EchoMQ code converges in `echo/apps/echo_mq`.**

- **Why.** The v1 line cannot become EchoMQ 2.0 in place. Its two structural flaws in v1 
  could not be fixed under compatibility — unauditable key access (operand keys built from an `ARGV` prefix
  inside script bodies) and an open keyspace (verbatim interpolation, no total parse) — so the fork was ruled
  to happen exactly once (design §0, §1 S-3), and the v1 line froze at `1.3.0`. Extending v1 further would
  stack v2 semantics onto a tree whose real deployments still write the `bull`-default keyspace. The
  alternative landed instead: the Branded Component System re-derived the protocol from first principles and
  shipped it as **measured, rung-gated code** — born braced (`emq:{q}:`), born branded (`JOB` ids gated at the
  key builder), born declared (every Lua key in `KEYS[]` or grammar-derived), with committed records and
  derive-before-measure gates. A from-scratch convergence target inherits those proofs; extending v1 in place
  would inherit the debt.
- **What.** `echo/apps/echo_mq` (the BCS 2.0 Valkey-native bus, `EchoMQ.*`, lib-only, release label `2.4.1`, wire fence frozen at `echomq:2.0.0`) is THE
  single convergence target, with `echo/apps/echo_wire` (the extracted wire layer — `EchoMQ.{RESP, Connector,
  Script}` frozen-named under the `EchoWire` facade) beside it. The legacy v1 line (frozen at `1.3.0`) has been
  **rewritten fresh into `echo_mq` and removed** — single source of truth; the /echomq and /redis-patterns
  course re-grounding is a dissolution-time operator concern, not a program blocker.
- **Who.** The Operator owns the goal and every fork; the aaw lead team ships the rungs — **Venus** (spec-steward
  + strawman spec author) → **Director** (orchestrator; surfaces the design Arms and rules them with the Operator
  via the mandatory `AskUserQuestion`) → **Mars** (implementor) → **Director** (verifies code + invariants) → the
  Director consolidates findings + learnings to **Apollo** (the standing Mentor, who calibrates the agents and
  drives remediation). Downstream consumers: **codemoji** (`echo/apps/codemoji` — the Mastermind-style game that
  drains `EchoMQ.Lanes`/`Consumer` and publishes `EchoMQ.Events` today, the program's worked consumer) and,
  headline-planned, **echo_bot** (`echo/apps/echo_bot` — Telegram-bot notifications at scale; the seam is
  `EchoBot.Platform.Telegram.send_reply/3`); plus the /bcs · /echomq · /redis-patterns courses as teaching
  surfaces.
- **When.** The foundation (EchoMQ protocol v2 + the BCS substrate) is **established** — shipped as `emq.0`.
  **Movement I is CLOSED** (emq.1 · the emq.2 parity cluster · the emq.3 flow family; conformance **52/52**).
  Movement II (emq.4–emq.8) opens on a complete core — one increment per run.
- **Where.** Code: `echo/apps/echo_wire`, `echo/apps/echo_mq`, `echo/apps/echo_store`, `echo/apps/echo_data`
  (the additive `bcs/` subtree), `echo/rungs/{bus,cache,journal}`. Specs: `docs/echo_mq/` (this roadmap, the
  design canon, the references, `specs/emq.N.*`).

## The movements

### Foundation · EchoMQ protocol v2 — established

The v2 protocol and the BCS substrate are **in place and proven on this machine**, shipped as **`emq.0`**: the
owned wire (`echo/apps/echo_wire` — `EchoMQ.{RESP, Connector, Script}` under the `EchoWire` facade), the bus
(`echo/apps/echo_mq`), the store (`echo/apps/echo_store` — its durable replication since grown into the
`EchoStore.Graft` engine streamed to Tigris; the `EchoStore.Shadow` behaviour emq.0 first imported is now retired,
`store.design.md` §2), and the `EchoData` branded-id substrate (the additive `bcs/` subtree) — gated by the
`echo/rungs/` ladder and the §5
pure + `:valkey` test pass. Movement I builds on it.

> Implementation detail (the import delta, the manifests-as-executed, the as-built notes) lives in the
> [`emq.0` triad](./specs/emq.0/emq.0.md) + the frozen
> [`specs/progress/emq-0.progress.md`](./specs/progress/emq-0.progress.md) ledger.

### Movement I · The Core — CLOSED (conformance 52/52)

The v1 capability surface, **rewritten state-of-the-art inside `echo_mq`** under the v2 laws (declared keys ·
branded `JOB` ids · the closed wire-class registry · the server-clock lease law). Nothing was migrated from the
legacy v1 line — every capability was rewritten fresh, and the v1 app was then removed. Three planes landed on
the foundation, with **codemoji the worked consumer** (`echo/apps/codemoji` — `EchoMQ.Jobs`/`Lanes` work drained
by `EchoMQ.Consumer`, scored by a single authority, results published on `EchoMQ.Events`):

- **Scheduler & retry** (emq.1) — delayed / repeatable jobs, attempts-with-backoff + the poison-job drill,
  connector auto-resubscribe.
- **The parity floor** (emq.2.1–2.4) — the **read** plane (introspection & metrics), the **operator** plane
  (lifecycle & mutation verbs), the **watch** plane (events / telemetry / locks / stalled / cancel), and the
  **closer** (the v1↔v2 depth suite).
- **The flow family** (emq.3.1–3.5) — parent/child DAGs: single-queue → child-result reads → cross-queue
  (eventually-consistent fan-in via the `flow:outbox` + the `Pump` sweep) → failure-policy + bulk →
  grandchildren / deep recursion.

#### Implementation index — methods only (re-probe the tree; line numbers drift under AAW)

| Plane | Module(s) | Public surface |
|---|---|---|
| scheduler | `EchoMQ.Jobs` | `enqueue/4` · `enqueue_at/5` · `enqueue_in/5` · `enqueue_many/3` · `claim/3` · `complete/4,5` · `retry/7` · `promote/3` · `reap/2` · `browse/3` · `pending_size/2` |
| scheduler | `EchoMQ.Repeat` · `EchoMQ.Backoff` · `EchoMQ.Pump` (+ `.Core`) | `Repeat`: `register` · `cancel` · `due` · `advance` · `count` — `Backoff.delay_ms/2` — `Pump`: `sweep/1` · `start_link/1` |
| read | `EchoMQ.Metrics` | `get_counts/3` · `get_job/3` · `get_job_state/3` · `get_metrics/3` · `get_deduplication_job_id/3` · `get_rate_limit_ttl/2,3` · `get_global_rate_limit/2` · `is_maxed/2` · `lane_depth/3` · `lane_depths/3` |
| operator | `EchoMQ.Admin` · `EchoMQ.Jobs` | `Admin`: `pause/2` · `resume/2` · `drain/2,3` · `obliterate/2,3` — `Jobs`: `update_data/4` · `update_progress/4` · `add_log/4,5` · `get_job_logs/3` · `remove_job/3,4` · `reprocess_job/3` |
| watch | `EchoMQ.Events` · `EchoMQ.Meter` · `EchoMQ.Locks` (+ `.Core`) · `EchoMQ.Stalled` · `EchoMQ.Cancel` | `Events`: `subscribe` · `publish` · `close` — `Meter`: `attach` · `emit` · `span` — `Locks`: `track_job/3` · `untrack_job/2` · `is_tracked?/2` — `Stalled.check/2,3` — `Cancel`: `new/0` · `cancel/2,3` · `check/1` — `Jobs`: `extend_lock/5` · `extend_locks/4` |
| flows | `EchoMQ.Flows` · `EchoMQ.Pump` | `Flows`: `add/3` · `add_bulk/3` · `children_values/3` · `ignored_failures/3` · `dependencies/3` — `Pump`: `deliver_flow_completions/3` · `maybe_reemit_parent_death/4` · `on_same_queue_child_death/4` |

> Per-rung build detail — conformance deltas (14→52), fork rulings, gate tallies, risk grades — lives in the
> frozen [`specs/progress/`](./specs/progress/) ledgers and the [`emq.1`](./specs/emq.1/emq.1.md) ·
> [`emq.2`](./specs/emq.2/emq.2.md) · [`emq.3`](./specs/emq.3/emq.3.md) triads. The wire/keyspace/lease invariants are in
> [`emq.design.md`](./emq.design.md); the v1→v2 parity proof in [`emq.features.md`](./emq.features.md).

### Movement II · The Extension — the EMQ family ladder

- **Why** — a multi-tenant production bus needs the pattern depth the established queueing systems proved at
  scale (groups, batches, lifecycle controls), the near-cache the chapter invented (landed structurally in
  the foundation; its deepening knobs are recorded), and the proof stack that turns engine claims into a parse
  (the conformance suite, the matrix, the benchmark with honest rival numbers).
- **What** — five families, one rung each: **groups** (the displaced fair-lanes family: the control plane,
  group-aware recovery, the park-don't-poll metronome, weighted/deficit rotation — the basics shipped in
  the foundation as `EchoMQ.Lanes`, gated G1–G8); **batches** (bulk consumption, `min_size`/`timeout` shaping,
  affinity, the partitioned finish); **lifecycle controls** (TTL per worker/name, distributed cancel,
  checkpoints); **the cache deepened** (BCAST tracking option, absorbed-fills compaction, journal
  `synchronous=FULL` per group, the invalidation-transport evaluation — design §12.3's named reopening);
  **conformance + telemetry + the benchmark gate** (the three-layer proof stack; the engine matrix;
  the published table with the rival's strengths recorded beside EchoMQ's).
- **Who** — multi-tenant operators of the bus; the /echomq course's Movement II teaches each family from its
  rung's spec and re-grounds when it ships.
- **When** — after Movement I's parity. The cache-deepening rung is least coupled to the machine and may be
  pulled forward — an Operator call, recorded here so it is a decision, not drift (carried from the old
  roadmap's same note).
- **Where** — `echo/apps/echo_mq`, `echo/apps/echo_store`, and the conformance/test surfaces beside them.
- **Wire version — TWO planes, never conflate.** The wire **FENCE** (`@wire_version` in the FROZEN connector, the `{emq}:version` boot key) holds at **`echomq:2.0.0`** and **advances exactly once** — the sanctioned `echomq:3.0.0` MAJOR at the horizon's end (emq.8); **no capability rung touches it** (editing the frozen connector + re-freezing the `:fence` scenario every rung is what the additive-minor law forbids). The **release LABEL** (`echo/apps/echo_mq/mix.exs` `version:`) **climbs per rung** `2.<N>.<M>` — emq.4.1 = `2.4.1`, emq.4.2 = `2.4.2`, … reaching `3.0.0` at emq.8 (where it meets the fence). Each rung ships an **additive minor** (new conformance scenarios + host verbs, **no fence code, no new wire class, no wire break** — the count grows, the protocol does not break) **+ one mix.exs version bump**. ("current: echomq:2.4.1" = the release label; the per-rung-climb rule supersedes emq.4.1-D1's "holds at 2.0.0" framing.)

## The rung ladder (CONFIRMED at the Stage-1b checkpoint)

| Rung | Movement | Ships (the slice) | Status |
| --- | --- | --- | --- |
| **emq.0** | Foundation | EchoMQ protocol v2 + the BCS substrate (wire extraction · the store's durable `Graft` engine · §5 suite) | ✅ **established** |
| **emq.1** | I | scheduler + retry vocabulary (delayed / repeatable jobs · attempts-with-backoff · auto-resubscribe) | ✅ CLOSED |
| **emq.2** | I | the **parity floor** — read → operator → watch → close (emq.2.1 · 2.2 · 2.3 · 2.4) | ✅ CLOSED |
| **emq.3** | I | the **parent/flow family** — single-queue → reads → cross-queue → failure-policy → grandchildren (emq.3.1–3.5) | ✅ CLOSED |
| emq.4 | II | groups deepened: the control plane, group-aware recovery, the park-don't-poll metronome, weighted/deficit rotation + the starvation drill | 🔨 BUILDING — emq.4.1 the control plane ✅ SHIPPED (reassign + lane-drain, HIGH-risk); 4.2–4.4 next |
| emq.5 | II | batches: bulk consumption, `min_size`/`timeout` shaping, affinity, the partitioned finish | planned abstract |
| emq.6 | II | lifecycle controls: TTL per worker/name, distributed cancel, checkpoints | planned abstract |
| emq.7 | II | the cache deepened: BCAST tracking, absorbed-fills compaction, `synchronous=FULL` per group, the invalidation-transport evaluation | planned abstract — may be pulled forward (Operator call) |
| emq.8 | II | conformance + the engine matrix + the telemetry contract + the benchmark gate (the three-layer proof stack) | planned abstract |

The ladder is confirmed ("confirmed emq.N", Stage-1b). Rungs are one-increment-one-run; every rung's
pre-build reconcile re-trues its abstract against the as-built tree before its triad is authored.

**The old ladder → this ladder** (the design's §4/§10 rung references name the OLD, pre-program ladder; read
them through this map):

| Old rung (the design's §4/§10 references) | Disposition in this program |
|---|---|
| old emq.2 — the BCS state machine | CLOSED in Movement I (the as-built `echo_mq`: three-field row · four sets · attempts-as-token `EMQSTALE` · completion-deletes · server-clock reap · REV BYLEX browse) |
| old emq.3 — batches | emq.5 |
| old emq.4 — lifecycle | emq.6 |
| old emq.5 — EchoStore | the near-cache landed structurally in the foundation (`echo/apps/echo_store`); the deepening is emq.7 |
| old emq.6 — conformance/proof | emq.8 |
| the displaced groups family (the old open seam) | emq.4 — RULED (Stage-1b; seam 2 closed) |

## How the program runs

Two roles, the loop every chapter uses:
the Author (the aaw lead team: Venus authors the strawman spec, Mars builds, the Director verifies + ratifies,
and Apollo calibrates the team — the [`program/`](./program/) calibrations)
turns each rung into a spec triad and a build at the established quality bar; the Operator reviews the increment and
returns feedback; **feedback edits the spec**. Per rung: sharpen → build → ship → demo → review → feedback →
adapt. Grounding law: every EchoMQ reference is a real module or file; every BCS requirement cites its
chapter; engine claims cite official docs (valkey.io); surfaces a rung builds are written "emq.N builds" —
never asserted-as-shipped.

**"Thin but robust" for this program** (carried, restated for the new target): opt-in families; one Lua
script per transition, atomic on the truth row; every new process a supervised or caller-started child with
stated restart semantics and a pure decision core; harnessed (pure ExUnit + `:valkey`-tagged wire suites +
the rung gates' derived bands); honest (at-least-once stays at-least-once; partial coverage reported with the
reason, never padded).

## The master invariant

The fork happened exactly once — the v2 key universe is grammar-total (braced `emq:{q}:`, the first-byte-
disjoint `{emq}:` reserve, the gated branded `job:` position), every Lua key declared-or-rooted, the version
record (`{emq}:version` = `echomq:2.0.0`) monotone behind the five-code fence — and **no later rung re-breaks
the wire**: additive registration is a protocol minor; a wire break or computed-floor raise is a major
(design §1 S-3, §6). Claims are phrased against **Valkey, current stable line**, enforced as a gate, with
honest-row reporting (§1 S-4). Process laws bind every rung in this repo: per-app testing only (umbrella-wide
`mix test` BANNED — the record's D7), agents run no git (D8), the Director commits by pathspec.

## Seams & open decisions

1. **The displaced groups family's rung slot** (design §10 seam 2) — **RULED (Stage-1b): emq.4**, with the
   confirmed ladder. CLOSED.
2. **F-§13** — **RULED (Stage-1b): leave trimmed.** The fork is CLOSED; no restoration edit. §13's content
   (the three-layer proof stack) re-derives inside the emq.8 triad when that rung is specced (the history
   stays recoverable via `git show 1f03d579:docs/echomq/specs/emq/design/emq.design.md`).
3. **Commit packaging** — **RULED (Stage-1b): one commit, full pivot** (the Director's Stage-5 concern).
   CLOSED for planning purposes.
4. **The v1-line dissolution** — DONE: the legacy line was rewritten fresh into `echo_mq` and removed. The one
   remaining operator-owned concern is the /echomq · /redis-patterns course re-grounding it triggers (the record §1).
5. **Toolchain + umbrella root** — superseded environment facts (Stage-1c): erlang `28.5.0.1` is installed
   and the `mercury_cms` phantom dep is fixed (the umbrella root compile is viable; mercury_cms's cms gate
   needs Postgres and its admin needs epmd — both outside this rung's gates). Build briefs RE-PROBE the
   toolchain (`asdf current erlang`) rather than hardcoding a version; a toolchain switch implies a full
   rebuild before gates. The recorded rung-gate flags stand.
6. **Carried family knobs** (from the old roadmap, owners unchanged — each belongs to its family rung's
   first feedback loop): limiter window mode · the batch processor contract · cache eviction beyond TTL ·
   dogfooding EchoStore in the scheduler · cross-runtime adoption order (Go, node; echomq-node strictly
   PROPOSED) · the benchmark gate numbers · `{emq}:queues` ships only WITH its registry⇄keyspace coherence
   probe, at the rung that consumes it · `{emq}:locks` stays registered reserved-by-name, populated by the
   rung that needs it.
7. **The drop's proposal-ladder items not yet slotted** (ROADMAP 2.3/3.0, engine framing corrected to the
   design's Valkey canon): the transport rung (the connector over unix sockets and TLS, priced against the
   committed loopback rows); FLAME ephemeral execution (consumers as runners that exist only for the drain;
   the journal-beside-consumer pattern makes the consumer disposable); the Go-driven conformance harness and
   the Go store/keyspace ports; the MCP surface over bus + cache + journal.

## Dependencies, recorded

The hard edges and the recorded consumer traces, in one place (folded from the BCS-side 2.x mirror so every
document points at one truth):

- **emq.0 is the spine.** The extracted wire (`echo/apps/echo_wire`) and the store's durable engine
  (`EchoStore.Graft` → Tigris) are the universal predecessors — Movement I, Movement II, and the entire 3.x stream
  tier stand on them.

- **The 3.x stream tier hard-gates on emq.0** (its verbs land on the extracted wire; its archive lives in the
  `EchoStore.Graft` engine — EchoMQ 3.x below). It is slot-ratified by the Operator against this ladder;
  emq3.1–emq3.2 carry their own recorded pull-forward call.
- **The unslotted proposals** — the transport rung (unix/TLS), FLAME ephemeral consumers, the Go-driven
  conformance harness and the Go store/keyspace ports, the MCP surface over bus + cache + journal — are held
  at the program's seam (§Seams item 8), owners unchanged, slotted only by a checkpoint ruling.

## EchoMQ 3.x — the stream tier

> **Status: PROPOSED

### Where this tier starts

On this program's foundation: the extracted wire (`echo_wire`) is the hard dependency — emq3.1's verbs land
there and nowhere else — and the store's durable engine (`EchoStore.Graft` → Tigris) is the second (emq3.5's
archive lives in it). Both closed with rung emq.0. Beyond those, the tier stands on committed records only: the
connector referee (BCS App. H), the journal's fold (BCS Chapter 4.4), the Graft engine (`store.design.md`), the
staleness fence and Tables (4.1–4.2), and the canon's id law (BCS App. F).

### Where this tier ends [RECONCILE]

### The stream-tier milestones [RECONCILE]

Which Movement is stream-tier? What is N rung wave number depends on deliver ordering? [RECONCILE]

| Milestone         | Rungs           | At the end you can |
|-------------------|-----------------|---|
| S1 · the writer   | emq.N.1–emq.N.2 | append events to a hash-tagged stream through the certified connector and read them back in mint order, with the append-order property gated |
| S2 · the readers  | emq.N.3–emq.N.4 | run a BEAM consumer group beside a non-BEAM reader with crash re-delivery, and declare a retention window the trim provably honors |
| S3 · the memory   | emq.N.5–emq.N.6 | fold trimmed segments into the `EchoStore.Graft` engine (local CubDB → Tigris), survive box loss, merge-read segment plus tail, and answer a mint-time window query from either |

### The stream-tier rungs

| Rung    | Ships | Gate sketch | Feedback asked |
|---------|---|---|---|
| emq.N.1 | the stream verbs on the connector: `XADD`, `XRANGE`, `XREADGROUP`, `XACK`, `XAUTOCLAIM` | verb round-trips; pipelined `XADD` batch; push-safe under RESP3 | the verb set's floor — is `XINFO` in scope for depth observability |
| emq.N.2 | `EchoMQ.Stream`, the writer law: hash-tagged per key, branded record ids, append is mint order | stream order == id sort, every time; wrong-kind refused at the door | the stream-naming grammar under the braced keyspace |
| emq.N.3 | groups + the polyglot seam: BEAM consumer and one non-BEAM reader on one group | at-least-once with idempotent handlers; crash → `XAUTOCLAIM` re-delivery; replay parity with the journal fold | the non-BEAM reference reader's runtime (Go or Python) |
| emq.N.4 | retention as declared policy: `MAXLEN` (approx) and mint-time `MINID` windows per stream | trim honors the window; inside-window reads never miss; outside answers truthfully | the default window per stream kind, decided not assumed |
| emq.N.5 | the archive: segments folded into the `EchoStore.Graft` engine (local CubDB → Tigris); merge reads | segment fold == stream slice; box-loss restore; the merge-read property | segment size and cadence; the archive's retention of its own |
| emq.N.6 | time-travel + hydration: mint-instant → `XRANGE` bounds; Table hydration from a tail | window read equals id-filtered truth; hydrate-then-fence equals loader truth | which Tables hydrate from streams first |

### The stream-tier conventions

One increment per run; spec-triad-first; the pre-build reconcile re-trues each rung against the as-built
tree; feedback edits the spec; figures verbatim from committed records; no number claimed before its rung
commits it.

---

The binding design: [`./emq.design.md`](./emq.design.md). The references:
[`./emq.references.md`](./emq.references.md). The program front door:
[`./echo_mq.md`](./echo_mq.md). The progress dashboard: [`./emq.progress.md`](./emq.progress.md). The
binding line laws: the design canon [`./emq.design.md`](./emq.design.md) (the 2.x line, S-1..S-7); the 3.x
stream tier is §EchoMQ 3.x above (PROPOSED). Rung triads: [`./specs/`](./specs/) — `emq.0`/`emq.1`/`emq.2`/`emq.3`
shipped.

The forward-feature 5-section catalog: [`./emq.features.md`](./emq.features.md) 
