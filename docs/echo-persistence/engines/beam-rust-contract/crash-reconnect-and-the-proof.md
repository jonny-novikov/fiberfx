---
title: "Dive 10.3 — Crash, reconnect & the compositional proof"
id: ep-m10-d3
status: established
route: "/echo-persistence/engines/beam-rust-contract/crash-reconnect-and-the-proof"
kind: "module 10 · dive 10.3 (closes Module 10)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive three-legs-meet-at-the-wire proof SVG; no machine numbers."
grounded-in: "docs/graft/specs/graft.4.md (D-7 compositional proof, S-3, the forward-looking scope)"
renders-to: "engines/beam-rust-contract/crash-reconnect-and-the-proof.html"
---

# Crash, reconnect & the compositional proof { id="ep-m10-d3" }

> _A HIGH-risk cross-runtime rung raises a fair question: if there is no single process wiring the Rust engine to a live Valkey socket, is the contract really proven? The Operator's answer (ruling D-7) is yes, and it is the more interesting answer — the guarantee is composed from three independent legs that meet at one byte-frozen wire, and the literal socket is a deployment detail deferred to a later rung._

**Interactive figure.** Three leg boxes on the left — Rust in-process over a real Runtime and in-memory feed sink, BEAM over live Valkey against an in-Elixir conformant responder, and a shared fixture set with identical `sha256` — each converging on a central `byte-frozen echo_graft_proto` node. From it an arrow points to a badge reading "cross-runtime contract"; when all three legs are established the badge reads "proven" and turns green. A dashed box marks the deferred live Rust↔Valkey socket for eg.5/eg.6.

## §1 Why the proof composes { id="proof" }

eg.4 deliberately does not ship a Rust process bound to a live Valkey socket — there is no Rust client and no NIF, both out of scope. So the three at-least-once / commit / conflict criteria are discharged compositionally, and the Operator ruled (D-7 = A) that this is sufficient for the rung. Leg **A** proves the Rust side in isolation: the dispatch correctness — commit→push→ack→feed, the conflict path, handshake refusal, replay, page-size handling — runs in-process over a real `echo_graft` `Runtime` and an in-memory feed sink. Leg **B** proves the BEAM side: the client's bus mechanics — publishing on the command lane, correlating on its reply lane, subscribing the feed lane, advancing the LSN cursor, refusing an incompatible handshake — run over a real Valkey on `:6390` against an in-Elixir responder that speaks the same `Proto`. Leg **C** is the join: cross-runtime byte-equality is the one shared fixture set both conformance suites assert, with identical `sha256`. The contract — the byte-frozen wire — is the only thing holding the two runtimes in lockstep, and it is exactly the HIGH-risk mitigation the rung names. The single literally-connected socket is a deployment concern, ruled into eg.5/eg.6; two as-built seams (the publish-only feed sink trait and the per-Volume backpressure cap) already anticipate it and get wired then. The contract is proven now; the plumbing is scheduled.

## §2 The cursor is the recovery key { id="recover" }

Because the engine is a supervised backend rather than a NIF, a crash is bounded: the engine goes down, its supervisor restarts it, and the orchestrator never falls with it. The client's job on the other side of that crash is small and exact — reconnect, and **resubscribe from its last-seen LSN**. That cursor is the whole recovery protocol: replay from it is monotone and gap-free, so every committed LSN above the cursor is redelivered and none below it is repeated beyond the at-least-once the feed already promises. There is no separate "catch-up" state to corrupt and no position to lose, because the position is just the largest LSN the client has already seen. On the shipped path the resubscribe is BEAM-side: the connector re-issues every recorded subscription on reconnect and the client replays from its own cursor — the in-Rust `replay_since` is the in-process expression of the same idea, an inspectable test convenience, never a production double-delivery. So a backend restart is a hiccup, not a gap, and it is the same shape as the proof above: a small, explicit contract (here, "resume from the cursor") doing the work that an implicit, stateful mechanism would do less safely.

## §3 References & sources { id="refs" }

Echo records:
- graft specs / graft.4.md — the compositional-proof reconciliation (D-7), S-3, the forward-looking scope — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.4.md
- graft.engine-split.design.md — the COEXIST ruling; the sidecar, not a NIF — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- graft.roadmap.md — eg.5/eg.6, where the live socket binds — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md

External:
- OTP supervision — a crash is a restart — https://www.erlang.org/doc/system/sup_princ.html
- At-least-once delivery — the feed's posture — https://en.wikipedia.org/wiki/At-least-once_delivery

---

_Pager: ← Dive 10.2 — Commit, ack, and the feed advance · Module 11 — EchoMQ Bus →_
