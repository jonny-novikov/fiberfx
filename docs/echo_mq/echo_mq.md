# EchoMQ — the program

> **Status: LIVING DOCUMENT — Operator-governed.** The front door of the EchoMQ program: what it is, how
> its spec home reads, the complete roadmap — the ratified program ladder and the proposed 3.x stream
> tier — and the milestone layer that binds each Movement's completion to the capability a real consumer
> needs. The milestone layer is what this file ADDS (the
> Operator's directive, recorded in the run ledger as D-11/D-12); everything else links to where it
> already lives. This file PLANS; [`./emq.design.md`](./emq.design.md) and the [`./specs/`](./specs/)
> triads DEFINE. Corrections ride Operator checkpoints; feedback edits this file, never an
> implementation past it.

## The program in one screen

**One program, three movements: all EchoMQ code converges in `echo/apps/echo_mq`.** The full 5W per
movement lives in [`./emq.roadmap.md`](./emq.roadmap.md); one line each here:

- **Movement 0 · BCS Migration** — the measured, rung-gated BCS drop lands in the production umbrella
  and is re-proven there: `echo_wire` (the extracted wire layer under the `EchoWire` facade), `echo_mq`
  (the bus), `echo_cache` (with the pluggable `EchoCache.Shadow`), the `EchoData` BCS subtree, the rung
  gates tracked. Rung **emq.0 — shipped** (`a2d599c8`).
- **Movement I · The Core** — the v1 capability surface pushed to state of the art inside `echo_mq`:
  the scheduler + retry vocabulary (**emq.1**, shipped), the **full-parity rewrite of the v1
  capability floor** `echo_mq` lacks — introspection & metrics, the operator lifecycle verbs, the
  observability & recovery plane, decomposed into **emq.2.1 / emq.2.2 / emq.2.3** (**emq.2**, cluster
  2/3 shipped — emq.2.3 watch next), the parent/flow family (**emq.3**). The frozen v1 line (`apps/echomq`, `1.3.0`) is a
  **capability reference** (the surfaces to port); it dissolves when absorption completes (timing
  Operator-owned). echo_mq is the single source of truth — built fresh, never migrated from.
- **Movement II · The Extension** — the family depth a multi-tenant production bus needs: groups
  deepened, batches, lifecycle controls, the cache deepened, the proof stack (**emq.4–emq.8**).

**The delivery thesis.** The movements exist to carry real consumers. The worked consumer that already
rides this program as its substrate is **codemoji** (`echo/apps/codemoji`) — a code-breaking game that
mints branded `RND`/`USR`/`JOB`/`GES` ids, enqueues per-player guesses on `EchoMQ.Lanes`, drains them
with two `EchoMQ.Consumer` instances (a score queue then a settle queue), scores under a single
authority, publishes `EchoMQ.Events`, holds a Valkey sorted-set leaderboard, and settles prizes on a
second queue (move-then-settle). The forward-looking headline consumer is **echo_bot**
(`echo/apps/echo_bot`): the Telegram-bot notifications at scale that *could* enqueue Telegram sends onto
the bus once its notification path moves off the direct synchronous `sendMessage` it ships with today —
a planned consumer, not a shipped integration. Each Movement done is a milestone that unblocks the
capability such a consumer needs (the milestone blocks below).

## The spec home — how to read it

| Surface                           | File                                                                                                             | Role                                                                                                                                                                                                                                                                                                                               |
|-----------------------------------|------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| The design canon                  | [`./emq.design.md`](./emq.design.md)                                                                             | Operator-approved, reconcile-only, never redesigned: genesis, the S-1…S-7 locks (braced `emq:{q}:` grammar, branded `JOB` ids, the one-time fork, Valkey-as-gate, declared keys), the ADRs, the deferred families                                                                                                                  |
| The engineering roadmap           | [`./emq.roadmap.md`](./emq.roadmap.md)                                                                           | **the single, consolidated roadmap** — the program "EchoMQ in Three Movements" (the epic, per-movement 5W, the rung ladder emq.0–emq.8 incl. the emq.2 parity cluster, seams 1–9, the course bridge) AND the 3.x stream tier (§EchoMQ 3.x); the former `emq2.roadmap.md`/`emq3.roadmap.md` were consolidated into it and removed   |
| The 2.x line specification        | [`./specs/emq.2.specs.md`](./emq2.specs.md)                                                                      | the BCS-side specification of the 2.x line's laws and surfaces — aligned with the program, never redesigning what the canon owns (the delivery view is the consolidated [`./emq.roadmap.md`](./emq.roadmap.md))                                                                                                                    |
| The 3.x stream tier specification | [`./specs/emq.3.specs.md`](./emq3.specs.md)                                                                      | the PROPOSED next major: event streams, retention as declared policy, the archive under a shadow, time-travel by mint instant — awaiting Operator slot ratification (the delivery view is [`./emq.roadmap.md` §EchoMQ 3.x](./emq.roadmap.md))                                                                                      |
| The bibliography                  | [`./emq.references.md`](./emq.references.md)                                                                     | read-first before expanding the roadmap: the consolidated BCS bibliography                                                                                                                                                                                                                                                         |
| The run ledger                    | [`./specs/emq-0.progress.md`](./specs/progress/emq-0.progress.md)                                                | the emq-0 run's thinking/decisions/learnings/report channels                                                                                                                                                                                                                                                                       |

## The complete roadmap, with milestones

*Interpretation, recorded:* the Operator's "complete roadmap based on `emq*.roadmap.md` current, 2, 3"
named three roadmap files — the program ladder, the 2.x line view, and the 3.x stream tier. They are now
**consolidated into one** — [`./emq.roadmap.md`](./emq.roadmap.md); the former `emq.2.roadmap.md`/`emq.3.roadmap.md`
were consolidated into it and removed (history in git). The ladder therefore appears once below; the 3.x tier enters as its own section with
its status carried, never re-decided here.