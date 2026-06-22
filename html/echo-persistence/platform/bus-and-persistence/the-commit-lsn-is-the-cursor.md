---
title: "Dive 12.1 — The commit LSN is the cursor"
id: ep-m12-d1
status: established
route: "/echo-persistence/platform/bus-and-persistence/the-commit-lsn-is-the-cursor"
kind: "module 12 · dive 12.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive accept→commit→publish→bind SVG; no machine numbers."
grounded-in: "docs/graft/graft.design.md (two-tier join at the batch, :async/:sync, LSN published over EchoMQ)"
renders-to: "platform/bus-and-persistence/the-commit-lsn-is-the-cursor.html"
---

# The commit LSN is the cursor { id="ep-m12-d1" }

> _The accept tier is fast because it amortizes one fsync over a whole batch; the commit tier is durable because each batch becomes one replicated transaction. They meet at the batch, and the number that transaction produces — the LSN — is published over EchoMQ. So a replica catching up, a consumer reading the feed, and the store proving durability all name their position with the same integer._

**Interactive figure.** Enqueues accumulate in the Champ accept tier (fsync per K). Committing folds the batch into a single Graft transaction — `:sync` waits for the Tigris-replicated commit — which mints an LSN and publishes it over EchoMQ, advancing every replica's cursor to the same point.

## §1 The two tiers meet at the batch { id="join" }

Champ is the accept tier: state lives in memory and a single fsync is amortized over *K* records, so enqueues are cheap and the only exposure is the open batch — `K` is the dial, and it is exactly the loss window in records. `echo_graft` is the commit tier: each batch rolls up into one Graft transaction, replicated to Tigris as a single LSN behind the conditional-write fence of Module 9. The two tiers join precisely at the batch boundary, and that join is where the durability choice lives, per call. `:async` returns once the batch is fsync'd locally — the fast path, exposure bounded by the open batch. `:sync` returns only after the Tigris-replicated commit acknowledges — slower, but durable against the loss of the whole node. Crucially, aligning the commit batch to the consumer's claim batch makes "enqueue through record" one durable, replicated unit: the same boundary that bounds Champ's fsync is the boundary that becomes a Graft LSN, so there is no seam between accepting work and durably committing it — only a choice of how long to wait.

## §2 One integer, three meanings { id="cursor" }

The LSN that the commit mints is not kept inside the store; it is **published over EchoMQ**, and that publication is the whole reason the bus and the floor are one system. Consider what the same integer means in three places. On the **store** side it is a durability boundary: everything at or below it is committed and replicated to Tigris. On a **replica** it is a position: a catching-up node fetches the head, learns the LSN, and faults pages up to it (Module 9's log-head recovery). On the **bus** it is an offset: a consumer of the change feed subscribes "from this LSN" and receives every advance after it. Because all three are the identical number, a replica's lag, a consumer's backlog, and a commit's durability are measured on one axis, and binding them is free — the commit already did it by publishing. This is also why the cross-runtime contract of Module 10 used the feed cursor as its recovery key: the LSN is the one coordinate every participant, in any runtime, already agrees on. Choose one cursor for both worlds and the rest of the platform's coherence follows.

## §3 References & sources { id="refs" }

Echo records:
- graft.design.md — the two-tier join at the batch; :async / :sync; the LSN published over EchoMQ binds replicas — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.roadmap.md — the commit tier; the conditional-write fence; log-head recovery — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- store.design.md — commit, the remote LSN as the shared cursor — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

External:
- Write-ahead logging — the log sequence number — https://en.wikipedia.org/wiki/Write-ahead_logging
- Group commit — one fsync over a batch — https://en.wikipedia.org/wiki/Group_commit

---

_Pager: ← Module 12 — EchoBus + Echo Persistence · Dive 12.2 — The outbox beside the bus →_
