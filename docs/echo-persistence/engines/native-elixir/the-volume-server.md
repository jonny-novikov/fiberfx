---
title: "The VolumeServer"
id: ep-m7-d1
status: established
route: "/echo-persistence/engines/native-elixir/the-volume-server"
kind: "module 7 · dive 7.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive single-mailbox serialization SVG; no machine numbers."
renders-to: "engines/native-elixir/the-volume-server.html"
---

# The VolumeServer { id="ep-m7-d1" }

> _The write path is one GenServer. Many clients commit at once, but a GenServer has a single mailbox and runs one message at a time — so concurrent commits become a strict order for free. Each is checked with OCC: if the base it read still matches the head, it appends; otherwise it's a conflict and the client retries. No lock, because the mailbox already is one._

**Interactive figure.** Two client boxes enqueue commit messages into a single vertical mailbox tube, each message tagged with the base LSN it read at enqueue time. The VolumeServer below the tube consumes the front message one at a time: if its base equals the current head, it appends and advances the head shown on the right; if the head has since moved, it replies `{:error,{:conflict, head}}`. Having both clients commit on the same base, then processing, shows one win and one conflict — order decided by the mailbox, no lock taken.

## §1 Concurrent in, ordered out { id="mailbox" }

Have A and B both commit while the head is LSN 4 — each captures base 4 — then process. Whoever the mailbox put first appends and takes LSN 5; the second finds base 4 ≠ head 5 and gets a conflict to retry. Concurrency goes in; a strict, conflict-checked order comes out.

## §2 The mailbox is the lock { id="why" }

People reach for a mutex to protect a shared counter; on the BEAM you reach for a process. Because a GenServer dequeues and runs one message to completion before the next, there is never a moment where two commits inspect the head at once — the serialization is structural, not enforced. So the OCC check inside `handle_call` is a plain comparison: does this commit's base still equal the head? If yes, append the page to CubDB and bump the head; if no, reply `{:error,{:conflict, head}}` and let the caller re-read and retry. Two clients that both based on LSN 4 cannot both win: whoever the mailbox put first takes LSN 5, the other conflicts. One writer process per volume, no locks, and the strict order Module 3 assumed — that is the whole write path.

## §3 References & sources { id="refs" }

External:
- GenServer — one message at a time — https://hexdocs.pm/elixir/GenServer.html
- Optimistic concurrency control — base-version check on commit — https://en.wikipedia.org/wiki/Optimistic_concurrency_control
- OTP design principles — processes as serialization — https://www.erlang.org/doc/design_principles/des_princ.html

Echo records:
- store.design.md — VolumeServer, write-lock via mailbox, OCC — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — single-writer serialization per volume — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← The native Elixir engine · Dive 7.2 — The lazy Reader →_
