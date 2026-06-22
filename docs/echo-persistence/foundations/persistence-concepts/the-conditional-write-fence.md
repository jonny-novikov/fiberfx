---
title: "The conditional-write fence"
id: ep-m3-d3
status: established
route: "/echo-persistence/foundations/persistence-concepts/the-conditional-write-fence"
kind: "module 3 · dive 3.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive create-if-not-exists race; no machine numbers."
renders-to: "foundations/persistence-concepts/the-conditional-write-fence.html"
---

# The conditional-write fence { id="ep-m3-d3" }

> _The OCC commit kept one process honest. Off the box, the writers are different nodes — after a partition, two may both think they're primary and both try to write commit LSN 7. The referee is the object store: create-if-not-exists lets the first PUT through and rejects the second._

**Interactive figure.** Two nodes, A and B, each PUT the same commit object key to a central object store, with a fence toggle. With the fence on, A's PUT returns 200 and B's returns 412 Precondition Failed; the object keeps A's commit — safe. With the fence off, both return 200 and B's write overwrites A's — split-brain, A's commit lost. A run button animates A then B; reset clears it.

## §1 One key, one winner { id="fence" }

With the fence on, the store creates the key once (200) and rejects any later PUT (412). With it off, every PUT succeeds and the last writer wins — two primaries, one key, a lost commit.

## §2 Why this is the durability floor { id="why" }

The whole replicated design rests on one atomic guarantee from the object store and nothing more: a write that succeeds **only if the key does not already exist**. Both engines lean on it identically — the native one via Tigris's conditional headers, the Rust one via OpenDAL's if-not-exists, which surfaces the rejection as a precondition failure. That single primitive turns "append the next LSN" into a safe operation across nodes, with no lock service, no consensus cluster, no coordinator. Take it away and two primaries quietly diverge. With it, the page engines in Chapter III are built on solid ground.

## §3 References & sources { id="refs" }

External:
- Tigris object conditionals — If-None-Match, create-if-not-exists — https://www.tigrisdata.com/docs/objects/conditionals/
- Apache OpenDAL — if-not-exists → precondition failed (Rust engine) — https://opendal.apache.org/
- Split-brain — what the fence prevents — https://en.wikipedia.org/wiki/Split-brain_(computing)

Echo records:
- graft.engine-split.design.md — RemoteCommit fence in both engines — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- graft.design.md — conditional commit, the replicated floor — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← The OCC commit · Chapter II — The local store →_
