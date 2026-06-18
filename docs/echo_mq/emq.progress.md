# EchoMQ — Program Progress Dashboard

**One-line state.** The foundation (EchoMQ protocol v2 + the BCS substrate) is **established** (`emq.0`).
**Movement I is CLOSED** — the opener `emq.1` (scheduler + retry), the **emq.2 parity cluster** (read → operator
→ watch → close, 4/4), and the **emq.3 flow family** (single-queue → child-result reads → cross-queue →
failure-policy/bulk → grandchildren/deep recursion, 5/5). The bus is real, measured, and conformance-gated at
**52/52** (Movement I close; **55/55** live with emq.4.2). **Movement II (emq.4–emq.8) opens on a complete core**; its opener **emq.4 (groups deepened) is BUILDING** — **emq.4.1 the control plane SHIPPED** (HIGH-risk: `reassign/4` + the lane-scoped destructive drain `drain/3`) and **emq.4.2 group-aware recovery SHIPPED** (NORMAL-risk: the group-scoped stalled-sweep `reap_group/4` + `@greap_group`, on the climbing fence `echomq:2.4.2`); emq.4.3–4.4 build next. The build team is echo_mq-specialized (the
`echo-mq-{architect,implementor,evaluator}` skills + the tuned [`program/`](./program/) calibrations, driven by
the `echo-mq-ship` /x-mode binding).

---

## Legend

| Symbol | State | Meaning |
|---|---|---|
| ✅ | **SHIPPED** | committed, gate-green, BUILD-GRADE on this machine |
| 🔨 | **IN FLIGHT** | building now — partial artifacts on disk, not yet committed |
| 📐 | **SPECCED** | spec triad/quad authored & gate-checked, no build artifact yet |
| 📋 | **PLANNED** | abstract fixed on the confirmed ladder, triad not yet authored |
| 🔒 | **PROPOSED** | awaiting Operator slot-ratification against the program ladder |

ANSI bars: `█` done · `░` remaining. A rung is one shippable increment; a milestone ships when all its rungs do.

---

## Development Progress

```text
EchoMQ 2.x — the bus core · convergence target echo/apps/echo_mq

Foundation · land + prove
  emq.0     ✅ established  ████████████████████  EchoMQ protocol v2 + BCS substrate · wire extraction · the store's durable Graft engine · §5 pass

Movement I · scheduler + retry · the parity floor · flows   ✅ CLOSED (conformance 52/52)
  emq.1     ✅ shipped     ████████████████████  scheduler + retry vocabulary (delayed/repeatable · backoff · resubscribe)
  emq.2     ✅ CLOSED      ████████████████████  full-parity rewrite — read → operator → watch → close (2.1–2.4)
  emq.3     ✅ CLOSED      ████████████████████  parent/flow family — single-queue → reads → cross-queue → failure-policy/bulk → grandchildren (3.1–3.5)

Movement II · the extension family
  emq.4     🔨 building    ████████░░░░░░░░░░░░  groups deepened — 4.1 control plane ✅ + 4.2 group recovery ✅ SHIPPED (reap_group · 55/55 · echomq:2.4.2) · 4.3 metronome HIGH (Apollo) · 4.4 weighted/deficit+drill
  emq.5     📋 planned     ░░░░░░░░░░░░░░░░░░░░  batches · bulk consume · shaping · affinity · finish
  emq.6     📋 planned     ░░░░░░░░░░░░░░░░░░░░  lifecycle controls · TTL · distributed cancel · checkpoints
  emq.7     📋 planned     ░░░░░░░░░░░░░░░░░░░░  cache deepened · BCAST · compaction · FULL · invalidation
  emq.8     📋 planned     ░░░░░░░░░░░░░░░░░░░░  proof stack · conformance · engine matrix · telemetry · benchmark

EchoMQ 3.x stream tier · emq3.1–emq3.6 (NO dot — a SEPARATE next-major track, emq3.5 ≠ emq.3.5)   🔒 PROPOSED — Operator slot, hard-gated on emq.0

── roll-up ──
  established  emq.0 — the foundation
  shipped     Movement I — emq.1 · emq.2 (2.1–2.4) · emq.3 (3.1–3.5) · conformance 52/52
  building    emq.4 — groups deepened · 4.1 control plane ✅ SHIPPED (reassign + lane-drain) · 4.2–4.4 build next
  planned     emq.5 · emq.6 · emq.7 · emq.8
  ───────────────────────────────────────────
  Movement I CLOSED → Movement II (emq.4–emq.8) opens on a complete core
```

**Convergence target:** all EchoMQ code lands in `echo/apps/echo_mq` above `echo/apps/echo_wire`. The legacy v1
line was rewritten *fresh* into `echo_mq` (the emq.2 parity cluster + the family rungs), never migrated, then
removed — single source of truth, no compatibility layer.

---

## Milestones — required components per milestone

### EchoMQ 2.x · the foundation + two movements

| Stage | Required components (what it must ship) | Rungs | State |
|---|---|---|---|
| **Foundation** | the measured drop in the production umbrella: `echo_wire` (extracted wire), `echo_mq` (the bus modules), `echo_store` (the store; durable replication via the `EchoStore.Graft` engine, the `Shadow` behaviour retired — `store.design.md` §2), the `EchoData.Bcs*` subtree, the `echo/rungs/` gate ladder, the §5 test/coverage pass | `emq.0` | ✅ established |
| **I · The Core** | the v1 capability surface rewritten state-of-the-art inside `echo_mq`: scheduler + retry (emq.1) · the full-parity read/operator/watch/close floor (emq.2.1–2.4) · the parent/flow family (emq.3.1–3.5) | `emq.1`–`emq.3` | ✅ CLOSED |
| **II · The Extension** | the family ladder: groups deepened · batches · lifecycle controls · cache deepened · the three-layer proof stack (conformance + engine matrix + telemetry + benchmark gate) | `emq.4`–`emq.8` | 📋 planned · **emq.4 🔨 BUILDING (4.1 ✅ · 4.2 ✅)** |

### EchoMQ 3.x · the stream tier

Event streams on the certified wire, under the v2 laws, no second protocol. Hard-gates on `emq.0`.

| Milestone | Required components | Rungs | State |
|---|---|---|---|
| **S1 · the writer** | stream verbs on the connector (`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`); `EchoMQ.Stream` — hash-tagged, branded record ids, append == mint order | `emq3.1`–`emq3.2` | 🔒 PROPOSED |
| **S2 · the readers** | BEAM consumer group + one non-BEAM reader, crash re-delivery; retention as declared policy (`MAXLEN` approx, mint-time `MINID` windows) | `emq3.3`–`emq3.4` | 🔒 PROPOSED |
| **S3 · the memory** | the archive — segments folded into the `EchoStore.Graft` engine (local CubDB → Tigris), box-loss restore, merge reads; time-travel (mint-instant → `XRANGE` bound) + Table hydration | `emq3.5`–`emq3.6` | 🔒 PROPOSED |

### The consumers

- **codemojex** (`echo/apps/codemojex`) — the **worked consumer today**. The Mastermind-style game mints branded
  ids (`RND`/`USR`/`JOB`/`GES`), enqueues guesses on per-player `EchoMQ.Lanes`, drains them with two
  `EchoMQ.Consumer` instances, scores under a single authority, publishes `EchoMQ.Events`, holds a Valkey
  sorted-set leaderboard, and settles prizes on a second queue (the move-then-settle pattern). A live exercise
  of the bus + the `EchoData.Bcs` property stores.
- **echo_bot** (`echo/apps/echo_bot`) — the **headline-planned consumer**. Telegram-bot notifications at scale;
  the integration seam is `EchoBot.Platform.Telegram.send_reply/3`. As built today echo_bot sends Telegram
  replies synchronously with no bus coupling — forward-tense: a planned `EchoMQ` enqueue/drain in front of the
  notification fan-out.

---

## Master invariant (held at every rung)

> The fork happened exactly once — the v2 key universe is grammar-total (braced `emq:{q}:`, the
> first-byte-disjoint `{emq}:` reserve, the gated branded `job:` position), every Lua key
> declared-or-rooted, the version record (`{emq}:version` = `echomq:2.0.0`) monotone behind the
> five-code fence — and **no later rung re-breaks the wire**. Additive registration is a protocol
> minor; a wire break or computed-floor raise is a major. Claims are phrased against **Valkey,
> current stable line**, enforced as a gate, with honest-row reporting. Process laws: per-app
> testing only (umbrella-wide `mix test` banned), agents run no git, the Director commits by pathspec.

---

## Sources

- **Design canon:** [`emq.design.md`](./emq.design.md) (Operator-approved, S-1…S-7) · **References:** [`emq.references.md`](./emq.references.md)
- **Roadmap (single, consolidated):** [`emq.roadmap.md`](./emq.roadmap.md) — the program ladder + the 2.x line view + the 3.x stream tier; the binding line laws are the design canon [`emq.design.md`](./emq.design.md)
- **Rung triads / ledgers:** the triads under [`specs/`](./specs/) (`emq.0`/`emq.1`/`emq.2`/`emq.3` shipped); the per-rung ship ledgers under [`specs/progress/`](./specs/progress/)
- **Build-team tooling:** `.claude/skills/echo-mq-{program,surface}.md` + `.claude/skills/echo-mq-{architect,implementor,evaluator}/SKILL.md` · the tuned [`program/`](./program/) calibrations (`emq.{venus,mars,apollo}.md`)
- **BCS grounding:** [`../echo/bcs/bcs.toc.md`](../echo/bcs/bcs.toc.md) · [`../echo/bcs/bcs.roadmap.md`](../echo/bcs/bcs.roadmap.md)
- **As-built:** `echo/apps/echo_mq` · `echo/apps/echo_wire` · `echo/apps/echo_store` · `echo/apps/echo_data` · the consumers `echo/apps/codemojex` · `echo/apps/echo_bot`
