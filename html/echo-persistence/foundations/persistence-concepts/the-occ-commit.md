---
title: "The OCC commit"
id: ep-m3-d2
status: established
route: "/echo-persistence/foundations/persistence-concepts/the-occ-commit"
kind: "module 3 · dive 3.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive two-writer compare-and-swap race; no machine numbers."
renders-to: "foundations/persistence-concepts/the-occ-commit.html"
---

# The OCC commit { id="ep-m3-d2" }

> _Reads were free because the log never changes. Writes are the hard part: two writers can both want the next LSN. The local engine resolves it optimistically — each stages a commit against the head it read, and the append is a compare-and-swap on the head. One wins; the other is told `{:conflict, head}` and retries._

**Interactive figure.** A shared head pointer and a log of committed LSNs, with two writer panels. Step through: both read head = 5 and stage LSN 6; W1's compare-and-swap 5→6 succeeds and LSN 6 is W1's; W2's CAS fails (head already 6) and it gets `{:error, {:conflict, 6}}`; W2 re-reads head 6, stages LSN 7, and wins on retry. Prev/next or run.

## §1 Two writers, one head { id="race" }

The append is a compare-and-swap on the head: it succeeds only if the head is still what you read. Both staged LSN 6 expecting head 5; only one swap from 5→6 can land.

## §2 Why optimistic, not locked { id="why" }

A lock would make every writer wait even when there is no contention, which is most of the time. Optimistic concurrency assumes success and only pays on collision: stage freely, and let the single atomic swap on the head decide. The loser hasn't corrupted anything — it re-reads the new head and tries again, which is cheap because reads are free. This is the **local** serialization, inside one process. The next dive is the same "one writer wins" idea one layer out, where the writers are different nodes and the referee is the object store.

## §3 References & sources { id="refs" }

Echo records:
- graft.design.md — OCC commit, {:conflict, head} on the Volume — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — strict commit serialization — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

External:
- Optimistic concurrency control — stage, then compare-and-swap — https://en.wikipedia.org/wiki/Optimistic_concurrency_control
- Compare-and-swap — the atomic head update — https://en.wikipedia.org/wiki/Compare-and-swap
- Designing Data-Intensive Applications, Kleppmann 2017 — write conflicts, OCC (Ch. 7) — https://dataintensive.net

---

_Pager: ← Volume, LSN, snapshot · Dive 3.3 — The conditional-write fence →_
