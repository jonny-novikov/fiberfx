# EchoMQ — Program Progress Dashboard

**One-line state.** The foundation (EchoMQ protocol v2 + the BCS substrate) is **established**
(`emq.0`). **Movement I is CLOSED** — the opener `emq.1`, the **emq.2 parity cluster** (4/4), and the
**emq.3 flow family** (5/5); the bus is real, measured, conformance-gated at **52/52** at the close.
In Movement II (the 2.x extension) the two depth families landed: the **`emq.4` groups family is
CLOSED** (4.1 control plane · 4.2 group-aware recovery · 4.3 the park-don't-poll metronome · 4.4
weighted rotation + the starvation drill — live conformance **61**, wire fence `echomq:2.4.2`, rung
label `2.4.4`) and **the `emq.5` batches family is CLOSED** — `emq.5.1` spine + `emq.5.2` shaping +
`emq.5.3` group-affinity + `emq.5.4` the partitioned finish + dynamic delay SHIPPED (conformance
**73**, label `2.5.2`). **Re-sequenced (Operator-ruled 2026-06-22): EchoMQ 3.0 — the Stream Tier**
([`emq.streams.md`](./emq.streams.md)) — is the **ACTIVE next delivery** (it hard-gates on `emq.0`
only, met; ships additive-minor; the `echomq:3.0.0` major a deferred cutover ratification). The
remaining 2.x rungs — **`emq.6` lifecycle controls · `emq.7` the cache deepened · `emq.8` the proof
stack** — are **DEFERRED behind the Stream Tier** (a parked 2.x-runway continuation, Operator-revisable).
**`emq3.1`–`emq3.6` ALL SHIPPED — S1 the writer (the stream-verb floor + the writer law, conf 75) + S2 the readers (the reader law `EchoMQ.StreamConsumer` conf 76 `71ce78cc` + retention as policy `EchoMQ.Stream.trim/4` conf 77 `e5cd3ea0`) + S3 the memory (`emq3.5` the archive `EchoStore.StreamArchive` fold-then-trim into the native `EchoStore.Graft`, conf 78, `e2d73e23` + `emq3.6` time-travel `read_window/5`/`read_since/4` + Table hydration `EchoStore.StreamHydrator`, conf 79, label 2.6.5); the Stream Tier is WHOLE → the `echomq:3.0.0` cutover is declarable.** Per-rung shipped detail: the
[changelog](./emq.changelog.md).

---

## Legend

| Symbol | State | Meaning |
|---|---|---|
| ✅ | **SHIPPED** | committed, gate-green, BUILD-GRADE on this machine |
| 🔨 | **IN FLIGHT** | building now — partial artifacts on disk, not yet committed |
| 📋 | **PLANNED** | abstract fixed on the confirmed ladder, triad not yet authored |
| 🔒 | **PROPOSED** | awaiting Operator slot-ratification against the program ladder |

ANSI bars: `█` done · `░` remaining. A rung is one shippable increment.

---

## Development Progress

```text
EchoMQ · convergence target echo/apps/echo_mq · destination EchoMQ 3.0 (Streams)

Foundation · land + prove
  emq.0     ✅ established  ████████████████████  EchoMQ protocol v2 + BCS substrate · wire extraction · the store's Graft engine · §5 pass

Movement I · the core (scheduler+retry · parity floor · flows)   ✅ CLOSED (52/52)
  emq.1     ✅ shipped     ████████████████████  scheduler + retry (delayed/repeatable · backoff · resubscribe)
  emq.2     ✅ CLOSED      ████████████████████  full-parity rewrite — read → operator → watch → close (2.1–2.4)
  emq.3     ✅ CLOSED      ████████████████████  parent/flow family — single-queue → reads → cross-queue → failure-policy/bulk → grandchildren (3.1–3.5)

Movement II · the 2.x extension family — the two depth families CLOSED
  emq.4     ✅ CLOSED      ████████████████████  groups deepened — 4.1 control plane ✅ · 4.2 recovery ✅ · 4.3 metronome ✅ (HIGH/Apollo · 174e1d7f) · 4.4 weighted rotation + drill ✅ (361fd663) · conformance 61 · fence 2.4.2 / label 2.4.4
  emq.5     ✅ CLOSED      ████████████████████  batches · 5.1 batch-claim spine ✅ · 5.2 min_size/timeout shaping ✅ · 5.3 group-affinity ✅ · 5.4 partitioned finish + dynamic delay ✅ (conf 73 · 2.5.2)

EchoMQ 3.0 · the Stream Tier — ✅ COMPLETE (the tier is WHOLE)   S1 the writer COMPLETE (emq3.1–3.2) · S2 the readers COMPLETE (emq3.3–3.4) · S3 the memory COMPLETE (emq3.5 the archive conf 78 + emq3.6 time-travel + hydration conf 79) → the echomq:3.0.0 cutover ratification is the next frontier (Operator-ruled 2026-06-22); gated on emq.0 (met)
  emq3.1    ✅ SHIPPED     ████████████████████  S1 writer · the stream-verb floor (XADD/XRANGE/XREADGROUP/XACK/XAUTOCLAIM ride-generic on the certified connector) — conf 74 · label 2.6.0 · 7b44dc97
  emq3.2    ✅ SHIPPED     ████████████████████  S1 the writer LAW — EchoMQ.Stream (branded record ids · append == mint, the order theorem by construction) — conf 75 · label 2.6.1 · b6ff483b
  emq3.3    ✅ SHIPPED     ████████████████████  S2 the readers part 1 — EchoMQ.StreamConsumer (a BEAM consumer group + the polyglot seam · crash re-delivery via XAUTOCLAIM · at-least-once) — conf 76 · label 2.6.2 · 71ce78cc
  emq3.4    ✅ SHIPPED     ████████████████████  S2 the readers part 2 — retention as policy (EchoMQ.Stream.trim/4 · MAXLEN approx + mint-time MINID via min_for/1 · the BEAM-side policy + the named/opt-in StreamRetention driver) — conf 77 · label 2.6.3 · e5cd3ea0
  emq3.5    ✅ SHIPPED     ████████████████████  S3 memory · the archive — store-side fold-then-trim into EchoStore.Graft (CubDB, reserved @archive_base) · merge-read over branded W · box-loss restore · bus :archived seam — conf 78 · label 2.6.4 · e2d73e23
  emq3.6    ✅ SHIPPED     ████████████████████  S3 memory · time-travel (read_window/5 + read_since/4 · mint-instant → XRANGE) + Table hydration (EchoStore.StreamHydrator · one-shot fold · no compactor) — conf 79 · label 2.6.5

2.x runway — DEFERRED behind the Stream Tier (parked, Operator-revisable)
  emq.6     🅿️ deferred    ░░░░░░░░░░░░░░░░░░░░  lifecycle controls · TTL · distributed cancel · checkpoints
  emq.7     🅿️ deferred    ░░░░░░░░░░░░░░░░░░░░  cache deepened · BCAST · compaction · FULL · invalidation — most pull-forward-able (Operator call)
  emq.8     🅿️ deferred    ░░░░░░░░░░░░░░░░░░░░  proof stack · conformance · engine matrix · telemetry · benchmark — defers the formal 2.x consolidation (per-rung gates still hold)

── roll-up ──
  established  emq.0 — the foundation
  shipped     Movement I (emq.1 · emq.2 · emq.3, 52/52) + the emq.4 groups family (4.1–4.4, 61) + the emq.5 batches family (5.1–5.4, 73) + EchoMQ 3.0 the Stream Tier WHOLE (S1 the writer emq3.1–3.2 conf 75 · S2 the readers emq3.3–3.4 conf 77 · S3 the memory emq3.5 the archive conf 78 e2d73e23 + emq3.6 time-travel + hydration conf 79 label 2.6.5) — see emq.changelog.md
  next        the echomq:3.0.0 MAJOR cutover ratification — the Stream Tier is WHOLE (emq3.1–3.6 SHIPPED, conf 79); OR the parked 2.x runway (emq.6 · emq.7 · emq.8, Operator-revisable)
  deferred    emq.6 · emq.7 · emq.8 (the 2.x runway, parked behind the Stream Tier · Operator-revisable)
  next major  EchoMQ 3.0 — the Stream Tier (emq3.1–emq3.6) · echomq:3.0.0 a deferred cutover ratification
```

---

## Milestones — required components per milestone

### EchoMQ 2.x · the foundation + two movements

| Stage | Required components | Rungs | State |
|---|---|---|---|
| **Foundation** | `echo_wire` (extracted wire) · `echo_mq` (the bus) · `echo_store` (durable replication via the `Graft` engine, `Shadow` retired) · the `EchoData.Bcs*` subtree · the `echo/rungs/` gate ladder · the §5 pass | `emq.0` | ✅ established |
| **I · The Core** | the v1 surface rewritten inside `echo_mq`: scheduler + retry (emq.1) · the read/operator/watch/close floor (emq.2.1–2.4) · the parent/flow family (emq.3.1–3.5) | `emq.1`–`emq.3` | ✅ CLOSED (52/52) |
| **II · The Extension** | the 2.x family ladder: groups deepened · batches · lifecycle controls · cache deepened · the three-layer proof stack | `emq.4`–`emq.8` | **groups CLOSED (4.1–4.4 · 61); batches CLOSED (5.1–5.4 · 73); lifecycle/cache/proof (emq.6/7/8) 🅿️ DEFERRED behind the Stream Tier (Operator-ruled 2026-06-22)** |

### EchoMQ 3.0 · the Stream Tier (the active near-term delivery)

Event streams on the certified wire, under the v2 laws, no second protocol. **Re-sequenced ahead of
the 2.x-runway remainder (Operator-ruled 2026-06-22)** — the active next delivery. Hard-gates on
`emq.0` ONLY (met); ships **additive-minor** (stream verbs additive → MINOR); the `echomq:3.0.0` major
is a **deferred cutover ratification** (declared when the tier is whole). Full ladder:
[`emq.streams.md`](./emq.streams.md).

| Milestone | Required components | Rungs | State |
|---|---|---|---|
| **S1 · the writer** | stream verbs (`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`); `EchoMQ.Stream` — hash-tagged, branded record ids, append == mint order | `emq3.1`–`emq3.2` | ✅ **COMPLETE** — `emq3.1` the verb floor (`7b44dc97`) + `emq3.2` the writer law (conf 75 · `b6ff483b`) |
| **S2 · the readers** | a BEAM consumer group + one non-BEAM reader, crash re-delivery; retention as declared policy (`MAXLEN` approx, mint-time `MINID`) | `emq3.3`–`emq3.4` | ✅ **COMPLETE** — `emq3.3` the reader law (`EchoMQ.StreamConsumer`, conf 76 · `71ce78cc`) + `emq3.4` retention as policy (`EchoMQ.Stream.trim/4` + the named/opt-in driver, conf 77 · `e5cd3ea0`) |
| **S3 · the memory** | the archive — segments folded into the `Graft` engine (CubDB → Tigris), box-loss restore, merge reads; time-travel (mint-instant → `XRANGE`) + Table hydration | `emq3.5`–`emq3.6` | ✅ **COMPLETE** — emq3.5 the archive (conf 78) + emq3.6 time-travel + hydration (`EchoStore.StreamHydrator`, conf 79); the tier is WHOLE |

### The consumers

- **codemojex** (`echo/apps/codemojex`) — the **worked consumer today**: a Mastermind-style game that
  mints branded ids, enqueues guesses on per-player `EchoMQ.Lanes`, drains them with two
  `EchoMQ.Consumer` instances, scores under a single authority, and publishes `EchoMQ.Events`.
- **echo_bot** (`echo/apps/echo_bot`) — the **headline-planned consumer**: Telegram notifications at
  scale; the seam is `EchoBot.Platform.Telegram.send_reply/3` (forward-tense — a planned `EchoMQ`
  enqueue/drain in front of the notification fan-out).

---

## Master invariant (held at every rung)

> The fork happened exactly once — the v2 key universe is grammar-total (braced `emq:{q}:`, the
> first-byte-disjoint `{emq}:` reserve, the gated branded `job:` position), every Lua key
> declared-or-rooted, and every rung is an **additive minor** — the `mix.exs` rung label climbs (born
> `echomq:2.0.0`, `echomq:2.5.2` live) while the connector's wire fence **logic** stays frozen. The
> Stream Tier ships on this same additive plane; the **`echomq:3.0.0` major is a deferred cutover
> ratification**, declared when the tier is whole. **No later rung re-breaks the wire**: additive
> registration is a minor; a wire break or computed-floor raise is a major. Claims are phrased against
> **Valkey, current stable line**, enforced as a gate, with honest-row reporting. Process laws: per-app
> testing only (umbrella-wide `mix test` banned), agents run no git, the Director commits by pathspec.

---

## Sources

- **Design canon:** [`emq.design.md`](./emq.design.md) (S-1…S-7, the 2.x line) · **Stream tier:** [`emq.streams.md`](./emq.streams.md) (EchoMQ 3.0) · **References:** [`emq.references.md`](./emq.references.md)
- **Roadmap (forward):** [`emq.roadmap.md`](./emq.roadmap.md) · **Changelog (shipped):** [`emq.changelog.md`](./emq.changelog.md)
- **Rung triads / ledgers:** the triads under [`specs/`](./specs/); the frozen per-rung ship ledgers under [`specs/progress/`](./specs/progress/)
- **Build-team tooling:** `.claude/skills/echo-mq-{program,surface}.md` + the role skills · the tuned [`program/`](./program/) calibrations
- **As-built:** `echo/apps/{echo_mq, echo_wire, echo_store, echo_data}` · the consumers `echo/apps/{codemojex, echo_bot}`
