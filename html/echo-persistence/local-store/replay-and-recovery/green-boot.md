---
title: "Green boot"
id: ep-m6-d2
status: established
route: "/echo-persistence/local-store/replay-and-recovery/green-boot"
kind: "module 6 · dive 6.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive blue/green cutover stepper SVG; no machine numbers."
renders-to: "local-store/replay-and-recovery/green-boot.html"
---

# Green boot { id="ep-m6-d2" }

> _A deploy is recovery you choose to do. Blue keeps serving while green — the new build — boots: it seeds from the latest snapshot, replays the tail to reach blue's head, and announces itself ready. Only then does traffic cut over, and blue retires. No request waits, because the log was the source of truth all along._

**Interactive figure.** Clients at the top route traffic to a blue process serving at the head LSN. A six-step stepper walks the deploy: green boots and seeds from the snapshot (its LSN bar jumps to the snapshot point), green replays the tail (the bar climbs toward the head), green reaches the head and is ready, traffic flips from blue to green, and blue retires. The traffic arrow visibly switches targets only at the cutover step; a "run deploy" button plays the sequence.

## §1 Seed, replay, switch { id="cutover" }

Step forward and watch the order: blue never stops serving while green catches up from snapshot to head. The traffic arrow stays on blue through boot, replay, and ready; it flips to green only once green's LSN equals the head; then blue stands down. The whole move is seed + replay + a router flip.

## §2 Why nothing waits { id="why" }

The cutover is safe because green never invents state — it reconstructs blue's exact state by replaying the same log (Dive 6.1), so at the moment of readiness the two are identical and the switch is a no-op for correctness. Blue keeps serving the whole time green catches up, so there is no window where nobody is answering. The handoff is just a router flip once green's LSN reaches the head; if green stalls, traffic simply never moves and blue carries on. This is the deploy story for the durable tier: ship a new build, let it replay, flip when ready — the same restore-plus-replay seen for a crash in Module 2, now done deliberately and live.

## §3 References & sources { id="refs" }

External:
- Blue-green deployment — the cutover pattern — https://martinfowler.com/bliki/BlueGreenDeployment.html
- State machine replication — replay to an identical state — https://en.wikipedia.org/wiki/State_machine_replication
- Designing Data-Intensive Applications, Kleppmann 2017 — rolling upgrades, replication (Ch. 4, 5) — https://dataintensive.net

Echo records:
- graft.design.md — green boot, seed + replay, cutover — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — snapshot seed and tail replay — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← One log, three replays · Dive 6.3 — Replica catch-up & the feed →_
