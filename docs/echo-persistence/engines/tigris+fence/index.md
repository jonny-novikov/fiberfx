---
title: "Module 9 — Tigris & the fence"
id: ep-m9-hub
status: established
route: "/echo-persistence/engines/tigris+fence"
kind: "module 9 hub — Chapter III, 3 dives (closes Chapter III)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive shared-remote bucket SVG; no machine numbers."
grounded-in: "docs/graft/graft.roadmap.md (eg.2) · docs/graft/specs/graft.2.md · docs/graft/graft.design.md"
renders-to: "engines/tigris+fence/index.html"
---

# Tigris & the fence { id="ep-m9-hub" }

> _Both engines, however different inside, write the same remote: a Tigris bucket holding two kinds of object — page `segments` and the `commit` chain that is the durable log head. Three operations run against it: push rollup coalesces changed pages into a segment, the create-if-not-exists fence picks one winner per commit, and log-head recovery reads the head back. In the roadmap this is rung eg.2 — the Tigris remote backend plus the conditional-write commit verified as the multi-writer fence._

**Interactive figure (hub).** The native Elixir engine and the Rust engine on the left both write into a Tigris bucket on the right, which holds a row of commit objects (the log head, with a head pointer at the tip) and a row of page segments; a cold node sits below it. Tapping push rollup highlights the segments and the write path; the fence highlights the commit chain and head; recovery highlights the head, chain, and the read path to the cold node.

## §1 One remote, two engines, three jobs { id="floor" }

The remote is where the two engines stop being different. Whatever a Volume is locally — a CubDB keyspace or a Fjall partition — its durable, shareable form is the same: Zstd-framed page segments and a chain of commit objects whose tip is the log head, all in one Tigris bucket reached over OpenDAL (S3-compatible, SigV4). Three operations act on it. Push rollup turns the pages changed since the last upload into one segment. The fence — a conditional **create-if-not-exists** on the next commit object — lets the bucket itself decide which writer owns each commit, so even two engines or a promoting replica can never fork the log; in the Rust engine this is `put_commit` with `if_not_exists` returning `ConditionNotMatch` on a loss, and in the native engine the matching create-only `If-None-Match` PUT — the same protocol, two implementations, which is exactly what eg.2 verifies. And log-head recovery lets any cold node read the head back from the bucket and start serving, faulting pages on demand. Each is a dive.

## §2 The three dives { id="dives" }

- **Dive 9.1 — Push rollup** — many page writes, some repeated, become one segment: latest version per page, Zstd-framed, a single object. → `/echo-persistence/engines/tigris+fence/push-rollup`
- **Dive 9.2 — The create-if-not-exists fence** — three different writers race for one commit slot; the bucket grants exactly one, losers step down, the chain stays linear. → `/echo-persistence/engines/tigris+fence/the-create-if-not-exists-fence`
- **Dive 9.3 — Log-head recovery** — a cold node reads the head and chain from the bucket, then faults pages from segments on demand; no full download. → `/echo-persistence/engines/tigris+fence/log-head-recovery`

## §3 Build & check { id="build" }

**What you build.** Name the two object kinds in the bucket and what each is for, then map the three operations onto them: which writes segments, which writes a commit object, which reads them back. The bucket layout is the deliverable.

**Check.** What single object-store primitive lets the remote arbitrate commits across both engines, and why can't the log fork? "Create-if-not-exists on the commit object (`if_not_exists` / `If-None-Match`)" means you have the module.

## §4 References & sources { id="refs" }

External:
- Tigris conditional writes — create-if-not-exists, the fence — https://www.tigrisdata.com/docs/objects/conditionals/
- Apache OpenDAL — the S3-compatible remote layer (SigV4) — https://opendal.apache.org/
- orbitinghail/graft — segments + commit chain on object storage (upstream idea source) — https://github.com/orbitinghail/graft

Echo records:
- graft.roadmap.md — eg.2: Tigris remote backend + commit/fence; the conditional-write fence verified — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft specs / graft.2.md — the eg.2 rung spec (the remote, segments, the fence) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.2.md
- graft.design.md — segments, commit objects, the remote — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — both engines, one shared bucket — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md

---

_Pager: ← The Rust engine · Dive 9.1 — Push rollup →_
