---
title: "eg.4 — BEAM↔Rust sidecar & protocol"
id: echo-graft-4-sidecar-proto
rung: eg.4
size: L
risk: HIGH
status: Draft — BLOCKED on D-1 (see graft.engine-split.design.md)
stands-on: "eg.2 · eg.3"
---

# eg.4 — BEAM↔Rust sidecar & protocol { id="echo-graft-4-sidecar-proto" }

> _Run the **Rust page-engine** as a supervised sidecar that is a first-class EchoMQ participant, with a versioned protocol crate as the contract that keeps the BEAM and Rust sides in lockstep._

> {style="warning"}
> **Reconciliation banner (read first — this rung is BLOCKED).** As specced, eg.4 introduced its Elixir client under the name **`EchoStore.Graft`** — but that module already exists as a **complete native-BEAM page-store engine** (`apps/echo_store/lib/echo_store/graft/*`), a direct functional twin of the Rust engine. The collision (name + architecture) is analysed in **`docs/graft/graft.engine-split.design.md`**, which surfaces three resolutions (A coexist / B Rust supersedes / C native-canonical) for the Operator. **This spec is written assuming the recommended Option A**: the native `EchoStore.Graft` engine stays; the Rust client is renamed **`EchoStore.GraftSidecar`** (D-2), and eg.4's claim narrows from "the integration spine for all durability" to "the sidecar integration for the **Rust** page-engine" (D-3). If the Operator chooses B or C, the alternate scopes in the design doc apply (B adds a separate, high-blast-radius retirement rung as a precondition; C reduces eg.4 to a benchmark harness). **Do not build until D-1 is decided.** See "Open decisions" below.

## Summary

The integration seam **for the Rust page-engine** (not for all durability — the native Elixir engine `EchoStore.Graft.*` needs no sidecar). Because the Rust engine does blocking object-storage and LSM I/O, it runs as a supervised sidecar addressed over EchoMQ rather than an in-VM NIF — an engine crash becomes a restart, not a downed orchestrator. `echo_graft_proto` is the byte-frozen, version-negotiated wire; **`EchoStore.GraftSidecar`** (renamed from the colliding `EchoStore.Graft`, D-2) is the Elixir client.

## Rationale

A NIF couples crash domains, and alpha code that segfaults would take the orchestrator with it; Graft's blocking I/O would also force dirty schedulers. A sidecar isolates the engine, and the local-socket/bus hop is noise next to an object-storage commit, which is the latency regime the engine already lives in. The hard part is the cross-runtime contract, so the protocol is explicit, versioned, and verified by a conformance suite both sides run — that contract is exactly the "synchronize BEAM and Rust support" requirement.

## 5W + H { id="eg4-5wh" }

| | |
|---|---|
| **Who** | Platform; the Elixir client (`EchoStore.GraftSidecar`) is consumed by EchoStore callers that want the **Rust** page-engine (raw-page performance / a deployable sidecar). |
| **What** | `echo_graft_proto` (wire for open/commit/read/snapshot/push/pull/fetch + the feed event, with version negotiation), `echo_graft_sidecar` (the EchoMQ-participant binary), and **`EchoStore.GraftSidecar`** (the Elixir client — NOT `EchoStore.Graft`, which is the native engine). |
| **When** | After eg.2 and eg.3; gates eg.5 and eg.6. Blocked on D-1. |
| **Where** | The sidecar deploys beside Go workers on the EchoMQ bus; the client lives in the Elixir app, beside (not replacing) the native `EchoStore.Graft.*` engine. |
| **Why** | Drive the **Rust** engine from the BEAM with an isolated crash domain and a contract that cannot silently skew. |
| **How** | RESP3 messages over EchoMQ; a version handshake on connect; correlation ids; supervised reconnect keyed on the feed cursor; a shared conformance suite. |

## Scope { id="eg4-scope" }

### In scope

- `echo_graft_proto`: request/response messages for open, commit, snapshot read, and push/pull/fetch, plus the feed event; a protocol version negotiated on connect; a frozen encoding per message.
- `echo_graft_sidecar`: consumes the command lane, drives the runtime, publishes the change-feed (eg.3), supervised.
- `EchoStore.Graft`: connect + version-check, commit/read/snapshot/sync, subscribe to the feed, reconnect + resubscribe from the last-seen LSN.
- An error taxonomy (conflict/abort, not-found, version-mismatch, unavailable) and backpressure handling.
- A conformance suite both the Rust and Elixir sides run against the frozen fixtures.

### Out of scope

- The low-latency write tier (eg.5); cross-compile and CI (eg.6).
- An in-VM NIF (a later, separately-specified optimization).

## Specification { id="eg4-spec" }

Transport is RESP3 over EchoMQ: a command lane for requests, the eg.3 feed lane for advances. On connect the client sends its supported protocol-version range and the sidecar selects one; a mismatch is refused with a clear error and no Volume is touched. Requests carry a correlation id; responses echo it. The commit path is client → command lane → sidecar → runtime commit (eg.2 conditional write) → feed event (eg.3) → the client observes the ack and then the event. Reads run against a snapshot; lazy page faults happen sidecar-side and never cross the bus as raw pages unless requested. Supervision: the sidecar crash is a restart; the client reconnects and resubscribes from its last-seen LSN, so the feed cursor is the recovery key. Backpressure: per-Volume command concurrency (or multiple lanes) prevents head-of-line blocking when the runtime is slower than the bus.

## Acceptance criteria { id="eg4-acceptance" }

1. **Given** a client and sidecar at compatible protocol versions, **when** the client commits a write, **then** it receives an ack carrying the LSN and subsequently a matching feed event.
2. **Given** a client at an unsupported protocol version, **when** it connects, **then** the sidecar refuses with a version-mismatch error and no Volume is mutated.
3. **Given** the sidecar crashes mid-session, **when** its supervisor restarts it, **then** the client reconnects, resubscribes from its last-seen LSN, and observes no lost or duplicated committed LSNs beyond at-least-once on the feed.
4. **Given** two clients committing conflicting writes to one Volume, **when** both reach the sidecar, **then** one acks success and the other a conflict/abort — the eg.2 fence surfaced end-to-end.
5. **Given** any defined protocol message, **when** it is re-encoded after a code change, **then** it matches the byte-frozen fixture, **or** the protocol version has been bumped.
6. **Given** the conformance suite, **when** run on both the Rust and Elixir sides, **then** both agree on every message encoding.
7. **Given** a producer outrunning the runtime, **when** the command lane fills, **then** backpressure is applied without blocking other Volumes' commands.

## Dependencies & risks { id="eg4-risks" }

- **Depends on:** eg.2, eg.3.
- **Risk — HIGH, the cross-runtime contract:** mitigate with byte-frozen fixtures, the shared conformance suite, and the version handshake (criteria 5/6/2).
- **Risk — head-of-line blocking:** per-Volume concurrency or multiple lanes (criterion 7).
- **Risk — backpressure:** define the bus-vs-runtime overflow policy explicitly.
