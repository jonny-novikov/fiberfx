---
title: "The create-if-not-exists fence"
id: ep-m9-d2
status: established
route: "/echo-persistence/engines/tigris+fence/the-create-if-not-exists-fence"
kind: "module 9 · dive 9.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive cross-engine arbiter SVG; no machine numbers."
renders-to: "engines/tigris+fence/the-create-if-not-exists-fence.html"
---

# The create-if-not-exists fence { id="ep-m9-d2" }

> _Module 3 introduced the fence as a primitive. Here it does real work: the durable commit is a create-if-not-exists on the next commit object, and because the bucket is shared, the bucket itself is the arbiter. Three different writers — the native engine, the Rust engine, a replica promoting itself — can all reach for the same slot; exactly one wins, the rest get `ConditionNotMatch` and step down. The commit chain stays strictly linear._

**Interactive figure.** Three writer boxes on the left — native engine, Rust engine, promoting replica — each showing the head LSN it currently knows. A commit chain runs along the top right with one open dashed slot at the tip. When a writer attempts, an arrow goes to the open slot: a writer at the true head creates it (green; the chain grows and that writer is recorded), while a writer on a stale head is rejected (red, `ConditionNotMatch`) and re-reads the head before it can retry.

## §1 One slot, one winner { id="arbiter" }

All three know head 3. Have one attempt: it creates `commit/4` and wins, advancing the head. Have another attempt while still on head 3 — `commit/4` exists, so it gets `ConditionNotMatch`, re-reads head 4, and can then try `commit/5`. In any order of attempts, the chain only ever grows by one link with a single recorded owner; it never forks.

## §2 Why the log can't fork { id="why" }

A commit is durable only when its commit object exists in the bucket, and the object is written with create-if-not-exists keyed by LSN. That single rule makes forking impossible: two writers can both believe they are at the head and both try to create `commit/N+1`, but the object store admits exactly one create — the other comes back a conditional-write conflict — `ConditionNotMatch` from the Rust engine's OpenDAL `put_commit if_not_exists`, the matching `If-None-Match` 412 from the native engine's create-only PUT, the same rule two ways. The loser is not wedged; it re-reads the head it now knows exists, sees the winner's commit, and retries at `N+2`. Crucially, none of this depends on which engine is asking: the native engine writing directly to Tigris and the Rust engine writing through OpenDAL (Dive 8.2) express the same conditional create, so the bucket arbitrates across engines and even admits a replica promoting itself to writer. The result is a strictly linear commit chain with a single owner per link — the same OCC guarantee the VolumeServer gave locally (Module 7), now enforced by the shared remote for everyone at once. With the head safe, the last question is reading it back cold.

## §3 References & sources { id="refs" }

External:
- Tigris conditional writes — create-if-not-exists semantics — https://www.tigrisdata.com/docs/objects/conditionals/
- If-None-Match — the conditional header — https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match
- Linearizability — one winner, a single order — https://en.wikipedia.org/wiki/Linearizability

Echo records:
- graft specs / graft.2.md — eg.2 — the conditional-write commit as the fence — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.2.md
- graft.roadmap.md — eg.2 — the conditional-write commit as the fence — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.engine-split.design.md — RemoteCommit fence across both engines — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- graft.design.md — commit object, create-if-not-exists, linear log — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← Push rollup · Dive 9.3 — Log-head recovery →_
