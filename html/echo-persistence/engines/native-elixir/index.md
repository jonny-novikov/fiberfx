---
title: "Module 7 — The native Elixir engine"
id: ep-m7-hub
status: established
route: "/echo-persistence/engines/native-elixir"
kind: "module 7 hub — Chapter III, 3 dives (opens Chapter III)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive OTP-topology SVG; no machine numbers."
renders-to: "engines/native-elixir/index.html"
---

# The native Elixir engine { id="ep-m7-hub" }

> _Everything so far has been mechanism. Here it becomes a running engine: `EchoStore.Graft`, pure Elixir on CubDB, the platform's default. A handful of OTP processes implement the ideas you already know — a VolumeServer serializes commits, a lazy Reader faults through the tiers, a Committer drains the commit-log-as-outbox to object storage._

**Interactive figure (hub).** A topology of the engine: solid boxes are processes (VolumeServer, Reader, Committer), dashed boxes are stores (clients, commit log/outbox, CubDB, ETS, Tigris). Tapping a process — or its control button — dims everything else and lights its data path: VolumeServer shows the write path (client → append to CubDB → record in the commit log); Reader shows the read fault (client → ETS → CubDB → Tigris); Committer shows the drain (commit log → conditional PUT → Tigris). Each process is a dive.

## §1 Ideas, now processes { id="topo" }

The native engine is deliberately small because Chapters I–II did the hard thinking. The VolumeServer is a GenServer whose single mailbox gives the strict commit order Module 3 needed, doing the OCC head-check and appending pages to CubDB. The Reader is the lazy read path: the head cache in ETS, then CubDB's pages, then a segment fetched from Tigris on a miss. The Committer treats the commit log as an outbox, draining it to object storage behind the conditional-write fence — the same log that is durability locally is the replication source remotely. Branded ids tie it together: `VOL` for volumes, `SEG` for segments, `CMT` for commits.

## §2 The three dives { id="dives" }

- **Dive 7.1 — The VolumeServer** — one GenServer mailbox serializes commits; the OCC check needs no lock because the mailbox already is one. → `/echo-persistence/engines/native-elixir/the-volume-server`
- **Dive 7.2 — The lazy Reader** — a page request faults through ETS, then CubDB, then a remote segment, and is cached on the way back. → `/echo-persistence/engines/native-elixir/the-lazy-reader`
- **Dive 7.3 — The commit-log outbox** — one log, two jobs: durable locally, pending upload; the Committer drains it to Tigris behind the fence. → `/echo-persistence/engines/native-elixir/the-commit-log-outbox`

## §3 Build & check { id="build" }

**What you build.** Name each process and the one chapter idea it implements: VolumeServer → Module 3's serialized OCC commit; Reader → the storage ladder's tiered fault; Committer → Module 6's replication source. If the blanks fill, the engine is the foundations wired together.

**Check.** Why does the VolumeServer need no explicit lock, and what are the two roles of the commit log? "The mailbox serializes" and "durability + outbox" mean you have the module.

## §4 References & sources { id="refs" }

External:
- GenServer — one message at a time — https://hexdocs.pm/elixir/GenServer.html
- ETS — the in-memory head cache — https://www.erlang.org/doc/man/ets.html

Echo records:
- graft.engine-split.design.md — EchoStore.Graft processes, the split — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- store.design.md — VolumeServer, Reader, Committer — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — the native engine on CubDB — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← Replay & recovery · Dive 7.1 — The VolumeServer →_
