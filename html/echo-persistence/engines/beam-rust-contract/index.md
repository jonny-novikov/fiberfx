---
title: "Module 10 — The BEAM↔Rust contract"
id: ep-m10-hub
status: established
route: "/echo-persistence/engines/beam-rust-contract"
kind: "module 10 hub — Chapter III, 3 dives (closes Chapter III)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive two-runtime / three-lane wire SVG; no machine numbers."
grounded-in: "docs/graft/specs/graft.4.md (eg.4, SHIPPED) · docs/graft/graft.roadmap.md · docs/graft/graft.engine-split.design.md"
renders-to: "engines/beam-rust-contract/index.html"
---

# The BEAM↔Rust contract { id="ep-m10-hub" }

> _The native engine lives in the BEAM; the Rust engine does not. So the platform reaches it the way it reaches everything else — over EchoMQ. `EchoStore.GraftBackend` on the BEAM drives the `echo_graft_backend` Rust sidecar through one byte-frozen wire, `echo_graft_proto`: a version handshake on connect, a command/reply lane for requests, and the eg.3 feed lane for advances. The contract is the only coupling — an engine crash is a restart, not a downed orchestrator — and a shared fixture set both runtimes assert against is what keeps them in lockstep. This is rung eg.4._

**Interactive figure (hub).** A BEAM client box on the left and a Rust sidecar box on the right, joined by three lanes — a command lane (`egraft:cmd:{vol}`, left→right), a reply lane (`egraft:reply:{client}`, right→left), and a publish-only feed lane (`egraft:feed:{vol}`, right→left). `connect` runs the `Hello`/`Welcome` handshake. `commit + push` sends a `Commit`, the Rust side takes the eg.2 fence, an `Ack` carrying the new LSN returns, and a `FeedEvent` with the matching LSN is published. A no-op push publishes nothing (the S-1 negative); a crash resumes the client from its last-seen LSN.

## §1 The wire is the contract { id="wire" }

Transport is RESP3 over EchoMQ. On connect the client sends `Hello{proto_min, proto_max}`; the backend selects a version and replies `Welcome{proto}`, or refuses with `Incompatible` — and a refusal **touches no Volume** (the S-2 negative: assert the Volume set is byte-identical before and after a rejected connect). Each request carries a `corr` id the response echoes, on a per-client reply lane `egraft:reply:{client}`; commands ride per-Volume lanes `egraft:cmd:{vol}` so one hot Volume can never head-of-line-block another. The message set is small and closed — `OpenVolume`, `Commit`, `Push`, `Pull`, `Read`, `Snapshot`, `GetCommit`, the `Ack`/`Pages`/`Err` responses, and the opaque eg.3 `FeedEvent` — and the error enum is exactly `{conflict, not_found, version_mismatch, unavailable}`; a new kind is a version bump, never a silent addition. The backend is a thin **1:1 dispatch** onto the real Rust `Runtime` (`Commit`→`volume_writer`, `Push`→`volume_push`, `Read`→`volume_reader`→lazy fault): no new engine logic, just session, dispatch, and publish.

## §2 Why a sidecar, and how the proof holds { id="why" }

The Rust engine does blocking object-storage and LSM I/O, so it runs as a **supervised backend process**, not an in-VM NIF: a NIF would couple crash domains (a segfault takes the orchestrator with it) and force dirty schedulers, while a backend turns an engine crash into a restart. The local-socket/bus hop is noise next to an object-storage commit, the latency regime the engine already lives in. On a crash the client reconnects and **resubscribes from its last-seen LSN** — the feed cursor is the recovery key, and replay is monotone and gap-free, so a restart is a hiccup, not a gap. The hard part is the cross-runtime contract, and the HIGH-risk mitigation is a single byte-frozen fixture set both runtimes assert against. The eg.4 proof is **compositional** (Operator ruling D-7 = A): the Rust dispatch is proven in-process over a real `Runtime` and an in-memory feed sink; the BEAM client's bus mechanics are proven over a live Valkey on `:6390` against an in-Elixir responder that speaks the same `Proto`; and the two meet at the shared fixtures (identical `sha256`). The one literally-connected Rust-to-Valkey socket is a deployment concern, deferred by ruling to eg.5/eg.6 — the contract is already proven.

## §3 The three dives { id="dives" }

- **Dive 10.1 — The byte-frozen wire & the handshake** _(soon)_ — `echo_graft_proto` message by message, RESP3 framing, the `Hello`/`Welcome`/`Incompatible` negotiation, the closed error enum, and one fixture set both runtimes assert byte-for-byte. → `/echo-persistence/engines/beam-rust-contract/the-byte-frozen-wire`
- **Dive 10.2 — Commit, ack, and the feed advance** _(soon)_ — the command path end to end: `Commit` → the Rust fence → `Ack(lsn)` → `Push` → `FeedEvent(lsn)` — and the S-1 liveness invariant: a no-op push publishes nothing. → `/echo-persistence/engines/beam-rust-contract/commit-ack-and-feed`
- **Dive 10.3 — Crash, reconnect & the compositional proof** _(soon)_ — supervised restart, resubscribe-from-last-seen-LSN as the recovery key, and why three legs meeting at one byte-frozen wire prove the cross-runtime contract without a single live socket. → `/echo-persistence/engines/beam-rust-contract/crash-reconnect-and-the-proof`

## §4 Build & check { id="build" }

**What you build.** Trace one commit across the boundary: name the lane it leaves on, the Rust call it dispatches to, where the fence runs, the lane the `Ack` returns on, and the single condition under which a `FeedEvent` is published. If you can also say what a no-op push publishes, you have the contract.

**Check.** What is the one thing that keeps the BEAM and Rust sides in lockstep, and why is a crash a restart rather than an outage? "One byte-frozen fixture set both assert against; the engine is a supervised backend, not a NIF" means you have the module.

## §5 References & sources { id="refs" }

Echo records:
- graft specs / graft.4.md — eg.4: the backend, the proto, the handshake, the declared keys, the seven stories — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.4.md
- graft.roadmap.md — eg.4 in the eg.1–eg.6 ladder; byte-frozen wire as a gate — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.engine-split.design.md — the COEXIST ruling: GraftBackend a peer, the native engine untouched — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- ewr.design.md — EchoWire / the RESP3 connector the client rides — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/wire/design/ewr.design.md

External:
- RESP3 protocol — the framing echo_graft_proto encodes to — https://redis.io/docs/latest/develop/reference/protocol-spec/
- Erlang NIFs — the crash-domain coupling a sidecar avoids — https://www.erlang.org/doc/system/nif.html
- orbitinghail/graft — the upstream engine echo_graft is seeded from — https://github.com/orbitinghail/graft

---

_Pager: ← Module 9 — Tigris & the fence · Module 11 — EchoMQ Bus →_
