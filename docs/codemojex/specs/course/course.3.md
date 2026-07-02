# Codemojex course · C3 — Guesses on Fair Lanes

> **Route** `/codemojex/guesses-on-fair-lanes` · **stub shipped** — this manuscript is the chapter
> brief; the C3 authoring rung deepens both.
> **Sources** B7.3 · cm.1 · design §Messaging: the EchoMQ bus / §Core flows (a guess, end to end).

The play path is the bus's showcase: a guess is validated against the game's keyboard, has the
player's locked positions overlaid, is charged through the wallet, and only then is enqueued — a
branded job on the player's own `PLR` lane, ridden to one scoring consumer. The chapter teaches
admission before enqueue, per-player fairness, and at-least-once delivery made harmless by
idempotent, pure scoring.

## C3.1 · The guess and the lock

A `GES` is six codes validated against the game's snapshotted keyboard; the player's locked
positions, held in Valkey, are overlaid so a confirmed cell is guaranteed. The surface answers
accepted-and-on-its-way — the scoring happens behind the bus. Dive route:
`/codemojex/guesses-on-fair-lanes/the-guess-and-the-lock` (planned).

## C3.2 · Charged, then enqueued

The wallet charges the room's currency path *before* the guess is accepted; only a charged guess
becomes a job. Idempotent enqueue and the paired `TXN` row mean a re-delivery can never double-charge
and a crash between charge and score can never lose the attempt. Dive route:
`/codemojex/guesses-on-fair-lanes/charged-then-enqueued` (planned).

## C3.3 · Fair lanes and the worker

Four lanes carry the game — guesses per-`PLR`, settle per-`GAM`, notify, bot commands — and the bus
rotates service across lanes so one masher cannot starve the field: paying for speed buys a turn, not
the field. One consumer (`:cm_score`) scores; each consumer leases the job it works, so a crashed
consumer's in-flight job becomes visible again rather than lost. Live mode broadcasts the result;
blind mode stores it and reveals nothing. Dive route:
`/codemojex/guesses-on-fair-lanes/fair-lanes-and-the-worker` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/game.ex` (`Codemojex.Guesses`, the ScoreWorker) · `locks.ex` ·
  `rate_limiter.ex` · the `:cm_score`/`:cm_settle`/`:cm_notify`/`:cm_commands` consumers in
  `application.ex`.
- [`codemojex.design.md`](../../codemojex.design.md) §Messaging: the EchoMQ bus / §Core flows /
  §Privacy and fairness (procedural fairness).
- [`stories/scoring.stories.md`](../../stories/scoring.stories.md) (the submit path).

## Doors

[/echomq](/echomq) — the bus in depth · [/redis-patterns](/redis-patterns) — the queue patterns ·
[`C2`](course.2.md) ← · → [`C4`](course.4.md).
