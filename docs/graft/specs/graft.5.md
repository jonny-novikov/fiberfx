---
title: "eg.5 — Low-latency write tier + the live Rust↔Valkey binding"
id: echo-graft-5-low-latency
rung: eg.5
size: L
risk: HIGH
status: Draft
stands-on: "eg.4"
---

# eg.5 — Low-latency write tier + the live Rust↔Valkey binding { id="echo-graft-5-low-latency" }

> _Put a local-fsync group-commit buffer in front of the object-storage commit, let each call choose async (return on local fsync) or sync (await the durable, replicated remote commit), AND stand `echo_graft_backend` up on a real Valkey socket so the eg.4 contract — proven compositionally — runs end-to-end as one live EchoMQ participant._

> {style="warning"}
> **Risk — HIGH; Apollo REQUIRED.** eg.4 shipped the cross-runtime contract proven **compositionally** (the Rust dispatch in-process, the BEAM client over live Valkey against an in-Elixir conformant responder, the wire byte-equality by the shared fixtures) and the Operator (D-7 = Option A) **deferred the real Rust↔Valkey socket binding to eg.5/eg.6** (`graft.4.md` §eg4-open-decisions D-7). This rung **builds that binding** — a new live socket surface on `echo_graft_backend` carrying the wire — alongside the write tier. That is a new transport **and** a new wire-version surface (the ruled **D-A1**: drop v1 compatibility, `COMMIT` becomes the v2 shape carrying the durability mode, `PROTO_MIN = PROTO_MAX = 2`), so the rung climbs from the roadmap's NORMAL+ to **HIGH** and Apollo is mandatory (the §11.2 adversarial charter on the live path + the byte-freeze re-verification — the regenerated v2 `COMMIT` + handshake fixtures proven by the dual-side conformance, every non-v2-touched fixture still byte-identical to HEAD).

## Summary

Graft's remote commit is high-latency and low-cost; for hot paths, accept writes into a durable local buffer with one fsync per batch and roll the batch up into a remote commit. A per-call durability mode lets callers trade the loss window for latency explicitly. eg.4 proved the wire contract but left `echo_graft_backend` driven **in-process** over an in-memory `FeedSink` (`transport.rs:42-45`); eg.5 binds it to a **real Valkey :6390 socket** so the backend consumes `egraft:cmd:{vol}`, dispatches onto the real `Runtime`, and serves real `EchoStore.GraftBackend` clients over the byte-frozen `echo_graft_proto` wire — and wires UF-1's dormant `Backpressure::admit` cap (`backpressure.rs:66`) into that now-real in-flight path.

## Rationale

Object-storage commits are slow by design, and Graft's own future-work calls for buffering writes in a lower-latency durable layer in front of object storage. That buffer is the platform's balance point across performance, durability, and CPU: a local fsync amortized over a batch gives low-latency durability and few syscalls, while the async rollup gives replication. Exposing the choice per call — async returns at local-fsync speed with the loss window bounded by the open batch; sync awaits the remote conditional-write commit — keeps the durability guarantee a declared decision rather than a hidden default.

The live binding is the other half. eg.4's compositional proof is sound (the contract is the byte-frozen wire, asserted on both sides), but a deployable durability tier must actually run as the "supervised EchoMQ participant beside Go workers" the architecture names (`graft.roadmap.md` §3). eg.5 closes that gap: the Rust `Session` (today fed framed bytes by the in-process round-trip, `session.rs:99`) gets a real bus transport that reads request frames off `egraft:cmd:{vol}`/`egraft:cmd:_control`, calls `Session::handle_frame` (`session.rs:99`), and publishes replies on `egraft:reply:{client_id}` + feed events on `egraft:feed:{vol}`. The live leg that eg.4 ran against an in-Elixir responder (`live_round_trip_test.exs:81-100`) now runs against the **real Rust backend** — the contract proven compositionally is proven literally. The per-call durability mode rides the wire under the ruled **D-A1** (the Operator directive "drop v1 compatibility; use `COMMIT` as v2+", §eg5-decisions): v1 is **dropped** (`PROTO_MIN = PROTO_MAX = 2`, the handshake negotiates only v2), `COMMIT` is **modified in place** to carry a fixed-position `mode` field, and the regenerated `COMMIT`/handshake fixtures are proven by the dual-side Rust-encode==Elixir-encode conformance — never a silent re-encode.

## 5W + H { id="eg5-5wh" }

| | |
|---|---|
| **Who** | Platform; the durability mode is a request field used by `EchoStore.GraftBackend` callers; the live binding makes `echo_graft_backend` a deployable EchoMQ participant. |
| **What** | (1) A bounded local-fsync write buffer with group commit + a per-call `:async`/`:sync` durability mode + a pure shaping core (min_size OR timeout, injected clock). (2) A live Rust↔Valkey RESP3 transport binding `echo_graft_backend` to `:6390`. (3) Wiring `Backpressure::admit` into the live in-flight path (UF-1). |
| **When** | After eg.4; gates eg.6. |
| **Where** | Sidecar-side (`crates/echo_graft_backend`): the buffer + shaping core + the new live transport module; the durability mode rides the eg.4 `echo_graft_proto` wire; the live leg is exercised from `apps/echo_store` over Valkey :6390. |
| **Why** | Low-latency durable writes and fewer fsyncs under load without giving up replication or hiding the loss window — and a backend that actually runs on the bus, closing the eg.4 deferral (D-7). |
| **How** | Accept into the buffer; flush on min_size or timeout; one fsync per batch; roll up into one remote commit; ack per the chosen mode. Bind the existing `Session::handle_frame` to a real bus socket; cap per-Volume in-flight via `Backpressure::admit`. |

## Scope { id="eg5-scope" }

### In scope

**A. The low-latency write tier (the roadmap's eg.5).**

- A bounded, durable local buffer: accept → batch → one fsync per batch → one remote commit/rollup (the eg.2 `volume_push` fence, `runtime.rs:239`).
- A pure shaping core: accumulate and flush when a batch reaches `min_size` or ages past `timeout`, with an injected clock (no real time in tests).
- A per-call durability mode: `:async` acks on local fsync (loss window = the open batch); `:sync` acks only after the remote conditional-write commit (durable + replicated before ack).
- Telemetry: batch size, flush latency, fsync count per Volume.
- Within-Volume order preserved: commit order equals accept order.

**B. The live Rust↔Valkey binding (the D-7 deferral, now built).**

- A new live transport module in `echo_graft_backend` that opens a real RESP3 connection to **Valkey :6390**, `SUBSCRIBE`s the command lanes (`egraft:cmd:{vol}` + the control lane `egraft:cmd:_control`), and for each request frame calls the existing `Session::handle_frame` (`session.rs:99`) and `PUBLISH`es the reply on the client's reply lane (`egraft:reply:{client_id}`).
- The feed direction is the existing publish-only seam: a live `FeedSink` (`transport.rs:24`) whose `publish(lane, frame)` maps to a bus `PUBLISH` on `egraft:feed:{vol}` (the `InMemorySink` of eg.4 swapped for a real one; the `Session`/`BusFeed` code is unchanged).
- The eg.4 live-leg test that ran against an in-Elixir responder (`live_round_trip_test.exs`) is re-pointed at the **real Rust `echo_graft_backend`** for the end-to-end criterion, env-gated (the eg.2 live-Tigris / eg.4 `ECHO_GRAFT_BACKEND_TEST` precedent) so the default suite needs no running backend.

**C. The UF-1 cap wiring (the eg.4 follow-on).**

- `Backpressure::admit(vol)` (`backpressure.rs:66`) is consulted in the live request path before dispatching a `{vol}`-bearing command; over the per-Volume cap the request is refused with `Msg::Err{kind: Unavailable}` (`dispatch.rs:270` taxonomy) — never unbounded buffering, never a blocked dispatch thread. The control lane stays exempt by construction (`backpressure.rs:12-23`).
- The eg.4 UF-2 follow-up rides along: a one-line test driving a `Commit`/`Read`/`Snapshot` against an unknown vid through the dispatch asserts `Msg::Err{kind: not_found}` (closes the unexercised `VolumeNotFound → not_found` arm, `graft.4.md` §eg4-open-decisions known-coverage-gap note).

### Out of scope

- Cross-compile, CI, packaging (eg.6).
- The durability shootout battery (eg.6).
- Tuning policy automation (a controller is a later, separate concern).
- An in-VM NIF (a later, separately-specified hot-read optimization — the binding here is a socket, not a NIF; `graft.roadmap.md` §7 non-goal).
- **The native Elixir engine `EchoStore.Graft.*` is untouched** (D-1 = COEXIST) — eg.5 adds the live Rust path; it does not modify, replace, or wrap the native engine, and `egraft:*` lanes stay distinct from native `graft:{vol}:commits` (`sync.ex:41`).
- **`github.local/graft`** (the read-only upstream reference) is never touched.

## Specification { id="eg5-spec" }

**The write tier.** Two layers: a local durable buffer (disk fsync) feeding the eg.2 remote commit. The shaping core is pure and clock-injected so flush triggers are deterministic under test. `:async` returns once the batch is fsync'd locally; its loss window is exactly the records in the open (not-yet-remotely-committed) batch, and that bound is surfaced per Volume. `:sync` returns only after the remote conditional-write commit acks, so on return the write is durable and replicated. The buffer lives sidecar-side; the durability mode is a **per-call** field carried on the commit request. It rides the wire under the ruled **D-A1** (drop v1; `COMMIT` as v2+): `Msg::Commit` gains a fixed-position `mode` field (`async`\|`sync`), the proto constant becomes `PROTO_MIN = PROTO_MAX = 2`, and the existing `COMMIT` encoding is **modified in place** (the v1 generation is dropped — there is no deployed v1 consumer, so the regenerated `COMMIT` fixture is the new single generation, not a v1-byte-frozen one). The `:sync` **default lives in the client API** — `EchoStore.GraftBackend.commit/push` defaults the mode to `:sync` and **always** encodes it — so the wire never carries a mode-absent `COMMIT`; the default is an ergonomics choice, not a wire/version default. Order within a Volume is preserved across the batch (the buffer flushes in accept order).

**The live binding.** The Rust `Session` (eg.4) already takes framed request bytes and returns framed reply bytes via `handle_frame(&[u8]) -> Vec<u8>` (`session.rs:99`) and emits feed frames through the abstract `FeedSink` (`transport.rs:24`) — the two seams a live transport wraps. eg.5 adds a live transport that connects to Valkey :6390 as the ruled **raw RESP3 socket reusing the `echo_graft_proto::{encode_parts,decode_parts}` codec** (**D-A2**: `lib.rs:73,91`, byte-identical to `EchoMQ.RESP`, over the already-vendored `tokio` — no new client dep); subscribes the command lanes; for each inbound request frame calls `Session::handle_frame`; publishes the reply on the requesting client's `egraft:reply:{client_id}` lane; and binds a live `FeedSink` so feed events `PUBLISH` on `egraft:feed:{vol}`. The handshake, dispatch, error taxonomy, page-size realization, and feed-republish are all **unchanged** — the binding is transport only, not engine or wire logic. A version mismatch on connect is still refused by the existing `negotiate` (`session.rs:199`) with no Volume touched.

**The cap.** The live transport consults `Backpressure::admit(vol)` (`backpressure.rs:66`) for each `{vol}`-bearing command before handing the frame to `Session::handle_frame`; `None` (at the cap) → the transport returns `Msg::Err{kind: Unavailable}` to the client without dispatching, and the `Permit` (`backpressure.rs:103`, release-on-drop) is held for the dispatch's duration. The control lane is not capped (no `{vol}`; `backpressure.rs:12-23`).

> {style="note"}
> **The live tier must prove its own liveness (a gate is not a no-op).** Criterion 7 (the live binding) is satisfied ONLY by a leg that exercises a **PRESENT, running** `echo_graft_backend` over a real Valkey socket and asserts a real round-trip (open → commit → push → ack → feed). When the env gate is unset the leg is **reported excluded, never trivially passed** (the eg.4 `:valkey`-tag posture, `live_round_trip_test.exs:17-21`); when it is set, the binding MUST connect and prove the round-trip, or the criterion FAILS loud. A skip-or-pass shape does not satisfy the letter.

## Acceptance criteria { id="eg5-acceptance" }

1. **Given** a stream of `:async` writes arriving faster than the remote commit, **when** they are accepted, **then** they ack at local-fsync latency and one remote commit rolls up the batch — the async throughput exceeds the per-call `:sync` rate, and both numbers are recorded.
2. **Given** a `:sync` write, **when** it acks, **then** the remote conditional-write commit has already succeeded (durable and replicated before ack).
3. **Given** the shaping core with an injected clock, **when** either `min_size` or `timeout` is reached first, **then** it flushes deterministically at that trigger, with no dependence on real time.
4. **Given** a crash after a local fsync but before the remote commit in `:async` mode, **when** the sidecar restarts, **then** at most the open batch is unaccounted, and all previously remotely-committed LSNs are intact and replicated.
5. **Given** writes to one Volume, **when** a batch flushes, **then** the committed order equals the accept order.
6. **Given** a Volume configured for `:async`, **when** queried, **then** its loss-window bound (the max open-batch size or age) is reported, not implicit.
7. **Given** a **running** `echo_graft_backend` bound to a real Valkey :6390 and a real `EchoStore.GraftBackend` client, **when** the client performs the handshake then `open → commit → push`, **then** it receives a `Welcome`, an LSN-bearing `Ack`, and a matching feed event on `egraft:feed:{vol}` — the bytes on every lane equal the byte-frozen conformance fixtures, and an incompatible client is refused with no Volume touched. (The env-gated end-to-end leg; excluded-not-passed when the gate is unset — §eg5-spec liveness note.)
8. **Given** the live binding under a producer flooding one Volume's command lane past its in-flight cap, **when** the cap is reached, **then** `Backpressure::admit` returns `None` and the transport refuses further `{vol}` commands with `Msg::Err{kind: Unavailable}` while a second Volume's commands still flow — the cap is consulted at the **production** call site, not only in a unit test (UF-1 closed).

> {style="note"}
> **Coverage:** criterion 1→S-1 · 2→S-2 · 3→S-3 · 4→S-4 · 5→S-5 · 6→S-6 · 7→S-7 (live binding) · 8→S-8 (cap wiring). Criteria 1–6 are the roadmap's write tier; 7–8 are the D-7/UF-1 additions this rung's HIGH risk attaches to.

## Dependencies & risks { id="eg5-risks" }

- **Depends on:** eg.4 (the byte-frozen wire, the `Session`/dispatch shell, the `FeedSink` + `Backpressure` seams, the `EchoStore.GraftBackend` client).
- **Risk — HIGH, a new live transport surface:** mitigated by reusing the eg.4 `Session::handle_frame` entry unchanged (the transport adds I/O, not protocol logic), the byte-frozen fixtures re-asserted on the live path, and the env-gated leg that proves its own liveness (no skip-or-pass).
- **Risk — wire change for the durability mode:** the ruled **D-A1** drops v1 and modifies `COMMIT` in place to carry the `mode` field (`PROTO_MIN = PROTO_MAX = 2`). The `COMMIT` + handshake fixtures are **intentionally regenerated** for v2 — proven by the dual-side Rust-encode==Elixir-encode conformance (NOT a HEAD-diff) — while **every non-v2-touched fixture** (`FeedEvent`, `PUSH`, `PULL`, …) stays byte-identical to HEAD. A silent re-encode of an untouched message is still a LOUD failure (gate G3, `graft.roadmap.md:92`).
- **Risk — hidden loss window:** the async bound must be a declared, queryable per-Volume policy (criterion 6).
- **Risk — buffer medium:** the local buffer is bounded-loss until rollup; document that it is disk-fsync durability, not replicated, until the remote commit.
- **Risk — transport dependency cost:** ruled **D-A2 = a raw RESP3 socket reusing the proto codec** over the already-vendored `tokio` — the workspace vendors **no** redis/valkey client (`Cargo.lock` carries `tokio`/`bytes`/`opendal`/`reqwest`/`bilrost`, none redis), so the ruled path adds only `HELLO 3` + the read loop, not a heavyweight client.

---

# Build brief (the `.llms.md` brief, folded in) { id="eg5-brief" }

> The builder (Mars) works from here. Every cited surface is real (confirmed against source at the cited line); no signature is invented. Forward-tense marks anything unshipped. The full runbook is `docs/graft/specs/graft.5.prompt.md`.

## References — read these first { id="eg5-references" }

- **The eg.4 spec + brief** — `docs/graft/specs/graft.4.md` (the wire, the declared keys, the fixtures, the version-negotiation contract, the D-7 deferral this rung discharges, the UF-1/UF-2 follow-ons).
- **The eg.4 ledger** — `docs/graft/eg-4.progress.md` (UF-1 = the unwired cap; UF-2 = the unexercised `not_found` arm; L-3 = "tested in isolation ≠ wired in").
- **The COEXIST design** — `docs/graft/graft.engine-split.design.md` (the native `EchoStore.Graft.*` engine is UNTOUCHED; the Rust path is a coexisting peer).
- **The Rust backend session (the live transport wraps these two seams)** — `crates/echo_graft_backend/src/session.rs`: `Session::handle_frame(&[u8]) -> Vec<u8>` (`:99`, the request entry), `Session::hello` (`:67`), `negotiate` (`:199`), `replay_since` (`:159`).
- **The abstract transport (swap `InMemorySink` for a live one)** — `crates/echo_graft_backend/src/transport.rs`: the `FeedSink` trait (`:24`, publish-only), `InMemorySink` (`:42`).
- **The per-Volume cap (UF-1 — wire `admit`)** — `crates/echo_graft_backend/src/backpressure.rs`: `Backpressure::admit(vol) -> Option<Permit>` (`:66`), `with_default` (`:52`, cap 64 `:32`), the control-lane exemption (`:12-23`).
- **The 1:1 dispatch + error taxonomy** — `crates/echo_graft_backend/src/dispatch.rs`: `dispatch` (`:32`), `err_kind_of` (`:270`, the closed `{conflict, not_found, version_mismatch, unavailable}`), `to_page` (`:244`, the page-size realization).
- **The byte-frozen wire codec (the ruled D-A2 raw socket reuses this)** — `crates/echo_graft_proto/src/lib.rs`: `Msg::{encode,decode}` (`:521,526`), `encode_parts`/`decode_parts` (`:73,91`, byte-identical to `EchoMQ.RESP.encode/1`), `PROTO_MIN`/`PROTO_MAX` (`:32-34`, both become `2` under D-A1), the `Commit` encode/decode (`:374-381` `to_parts`, `:444-461` `from_parts` — `Msg::Commit` gains the `mode` field in place; the v1 generation is dropped).
- **The runtime commit/push seam (the buffer rolls up into this)** — `crates/echo_graft/src/rt/runtime.rs`: `volume_push` (`:239`), `volume_writer` (`:298`), `publish_feed_advance` (`:250-279`).
- **The Elixir client** — `apps/echo_store/lib/echo_store/graft_backend.ex` (the request/reply over `EchoMQ.Connector`, the lanes, the feed cursor); the eg.4 live leg `apps/echo_store/test/echo_store/graft_backend/live_round_trip_test.exs` (re-point its responder at the real backend for criterion 7).
- **The umbrella build guide** — `echo/CLAUDE.md` §3 (the `echo_store` gate ladder, `TMPDIR=/tmp`, asdf re-probe, Valkey :6390); the Rust gate ladder `echo/apps/echo_graft/README.md` (`cargo test --workspace`, fault suites `--test-threads=1`).

## Agent stories — each criterion as Directive + Acceptance gate { id="eg5-stories" }

Each story: **As** a role, **I want** a capability, **so that** a benefit; a Given/When/Then; the **invariant(s)** it exercises; the **real surface** it drives.

### S-1 — Async writes ack at fsync latency; one push rolls up the batch (criterion 1)
- **As** an EchoStore caller on a hot path, **I want** `:async` writes to ack at local-fsync latency and roll up into one remote commit, **so that** I get durable low-latency writes with replication amortized.
- **Given** a stream of `:async` writes faster than the remote commit; **When** accepted; **Then** each acks on local fsync and one `volume_push` (`runtime.rs:239`) rolls up the batch — measured async throughput > per-call `:sync` rate, both numbers recorded.
- **Drives:** the buffer's accept path + the shaping-core flush → `volume_writer`/`commit` → `volume_push`.
- **Invariant:** one fsync per batch; the async ack precedes the remote commit (the loss-window definition).

### S-2 — Sync acks only after the durable replicated commit (criterion 2)
- **As** a caller needing a hard durability guarantee, **I want** `:sync` to return only after the remote conditional-write commit acks, **so that** on return the write is durable and replicated.
- **Given** a `:sync` write; **When** it acks; **Then** the remote `put_commit` fence (`remote.rs` `if_not_exists`) has already succeeded.
- **Drives:** the buffer's sync path that awaits `volume_push`.
- **Invariant:** sync acks are downstream of the remote LSN advance — no ack before the fence.

### S-3 — The shaping core flushes deterministically on min_size OR timeout (criterion 3)
- **As** a maintainer, **I want** the flush decision in a pure clock-injected core, **so that** flush triggers are deterministic under test.
- **Given** the shaping core with an injected clock; **When** `min_size` OR `timeout` is reached first; **Then** it flushes at exactly that trigger, no real-time dependence.
- **Drives:** a pure `BatchShaper`-style core (the eg.5.2 `BatchShaper.Core` precedent in the echo_mq program is the shape to mirror, but here in Rust); the clock is a parameter.
- **Invariant:** no `SystemTime::now()` in the decision path; the trigger is `min(size_reached, age_reached)`.

### S-4 — Crash after fsync, before remote commit: at most the open batch is unaccounted (criterion 4)
- **As** an operator, **I want** a crash between local fsync and remote commit to lose at most the open batch, **so that** the durability bound is exactly the declared loss window.
- **Given** a crash after a local fsync but before the remote commit in `:async`; **When** the sidecar restarts; **Then** at most the open batch is unaccounted and every previously remotely-committed LSN is intact + replicated.
- **Drives:** the **Fjall** buffer medium (the ruled D-A3) + restart recovery; the engine's durable Fjall commits survive, the un-pushed buffer tail is the bound.
- **Invariant:** previously-pushed LSNs are never lost; the unaccounted set ⊆ the open batch.

### S-5 — Within-Volume order = accept order (criterion 5)
- **As** a caller, **I want** committed order to equal accept order within a Volume, **so that** a batch never reorders my writes.
- **Given** writes to one Volume; **When** a batch flushes; **Then** the committed order equals accept order.
- **Drives:** the buffer's per-Volume FIFO accumulation.
- **Invariant:** the flush preserves accept order (a stable batch).

### S-6 — The async loss-window bound is queryable, not implicit (criterion 6)
- **As** an operator, **I want** the async loss-window bound reported per Volume, **so that** the loss window is a declared policy, not a hidden default.
- **Given** a Volume configured `:async`; **When** queried; **Then** its max open-batch size/age is reported.
- **Drives:** a per-Volume policy query on the buffer.
- **Invariant:** the bound is surfaced (criterion's "not implicit").

### S-7 — The live binding serves a real client over a real Valkey socket (criterion 7) — the D-7 discharge
- **As** the platform, **I want** `echo_graft_backend` to run as a real EchoMQ participant on Valkey :6390 serving real `EchoStore.GraftBackend` clients, **so that** the eg.4 contract proven compositionally runs literally end-to-end.
- **Given** a **running** backend bound to :6390 + a real client; **When** the client does handshake → `open → commit → push`; **Then** it gets `Welcome` + an LSN `Ack` + a matching `egraft:feed:{vol}` event, every lane's bytes equal the frozen fixtures, and an incompatible client is refused with no Volume touched.
- **Drives:** the new live transport → `Session::handle_frame` (`session.rs:99`) → `dispatch` → the live `FeedSink`; the re-pointed `live_round_trip_test.exs` against the real backend.
- **Invariant (LIVENESS — load-bearing):** the env-gated leg exercises a PRESENT backend and asserts the real round-trip; gate unset → reported excluded, NEVER trivially passed (§eg5-spec liveness note). The wire is the ruled v2 (`PROTO_MIN = PROTO_MAX = 2`, `COMMIT` carrying `mode`); the regenerated `COMMIT`/handshake fixtures are proven by the dual-side conformance, every non-v2-touched fixture unchanged from HEAD.

### S-8 — The per-Volume cap is wired into the live dispatch (criterion 8) — UF-1 closed
- **As** an operator, **I want** the per-Volume in-flight cap consulted at the live production call site, **so that** a runaway producer is bounded in memory, not just bounded by a unit test.
- **Given** the live binding under a flood of one Volume past its cap; **When** the cap is reached; **Then** `Backpressure::admit` (`backpressure.rs:66`) returns `None` and the transport refuses further `{vol}` commands with `Msg::Err{kind: Unavailable}` while a second Volume still flows.
- **Drives:** the live transport's pre-dispatch `admit(vol)` consult; the `Permit` held across dispatch (`backpressure.rs:103`).
- **Invariant (the L-3 precept):** grep proves `admit()` is called from the live transport path — a green unit test that constructs `Backpressure` directly does NOT satisfy this; the production call site must consult it. The control lane stays exempt (`backpressure.rs:12-23`).

## Declared keys — nothing undeclared on the wire { id="eg5-declared-keys" }

**No NEW EchoMQ lane is introduced by eg.5** — the live binding consumes the eg.4 lanes from the Rust side (eg.4 declared them client-side; eg.5 makes the backend the real subscriber/publisher). The full set the live binding touches:

| Lane / field | Direction (eg.5 adds the Rust side) | Source |
|---|---|---|
| `egraft:cmd:{vol}` | the backend now **SUBSCRIBE**s (was: client PUBLISH only) | `graft_backend.ex:59` (`cmd_lane`), `backpressure.rs:6` |
| `egraft:cmd:_control` | the backend now **SUBSCRIBE**s the handshake/open/resolve lane | `graft_backend.ex:382` (`control_lane`), `backpressure.rs:18` |
| `egraft:reply:{client_id}` | the backend now **PUBLISH**es the correlated reply (was: client SUBSCRIBE only) | `graft_backend.ex:53` (`@reply_lane_prefix`) |
| `egraft:feed:{vol}` | the backend's live `FeedSink` now **PUBLISH**es here (was: in-memory sink) | `feed.rs:42` (`lane_for`), `transport.rs:24` |
| `corr: u64` | unchanged — the request↔response pairing inside a reply lane | `echo_graft_proto/src/lib.rs` (every request/response) |
| **`COMMIT.mode` (ruled D-A1)** | a fixed-position `mode` field (`async`\|`sync`) added to `COMMIT` in place; `PROTO_MIN = PROTO_MAX = 2` (v1 dropped); the client always encodes the mode (defaults to `sync`) | `echo_graft_proto/src/lib.rs:264-273` (the `Commit` struct gains `mode`) + `:374-381` (`to_parts`) + `:444-461` (`from_parts`); the exact field position + token bytes Mars pins against the regenerated fixture (build-realization detail, §eg5-build-order step 2) |

> {style="warning"}
> **No NEW remote-object key.** The Tigris layout (`logs/{log}/commits/{LSN}`, `segments/{sid}`) is eg.2's, unchanged (`remote.rs`). The buffer is a **local** durable medium (Arm 3); it adds no remote key.
> **The error enum stays closed:** `{conflict, not_found, version_mismatch, unavailable}` (`echo_graft_proto/src/lib.rs:142-151`). A cap rejection reuses `unavailable`; no new kind.

## The byte-freeze posture — what is regenerated, what stays frozen { id="eg5-fixtures" }

The ruled D-A1 (drop v1; `COMMIT` as v2+) **changes the byte-freeze rule for two messages and only two** — `COMMIT` and the handshake. There is no deployed v1 consumer (the whole `echo_graft` + `echo_store` GraftBackend tree is untracked / undeployed), so the v1-byte-frozen scaffolding protected nothing; the byte-freeze law binds where a peer in the field could break, and there is none.

- **`COMMIT` + the handshake fixtures are INTENTIONALLY regenerated for v2.** `Msg::Commit` gains the `mode` field; `PROTO_MIN = PROTO_MAX = 2`. These fixtures are NOT byte-frozen to HEAD — they are the new **single** generation. The cross-runtime proof is the **dual-side conformance**: Rust-`encode` == Elixir-`encode` on the regenerated fixtures, plus the decode round-trip on each side. (There is no second/old generation to assert; the v1 decoder path is removed.)
- **Every NON-v2-touched fixture stays byte-identical to HEAD** — `FeedEvent` (the 51-byte opaque blob, `feed.rs:166`), `PUSH`, `PULL`, `READ`, `SNAP`, `ACK`, `PAGES`, `ERR`, etc. A silent re-encode of any of these is a LOUD failure (gate G3, `graft.roadmap.md:92`). The live `FeedSink` publishes the SAME `Msg::Feed{blob}` framing the eg.4 `BusFeed` produces (`feed_sink.rs:34-40`) — no re-encode.
- **`PROTO_MIN = PROTO_MAX = 2` confirmed, no v1 decoder path remains** — a v1 peer fails the `Hello`/`Welcome` negotiation by design (v1 is dropped, the correct outcome).

## Gate ladder — run before reporting { id="eg5-gates" }

**Rust (`apps/echo_graft`, from the crate dir):**
```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_graft
TMPDIR=/tmp cargo test --workspace            # parity baseline + eg.2/3/4 + the new buffer/transport/cap tests
TMPDIR=/tmp cargo clippy --workspace          # the new code adds 0 warnings (eg.3/eg.4 posture)
# the Rust conformance test over the SHARED fixtures (byte-freeze re-verified; criterion 7):
TMPDIR=/tmp cargo test -p echo_graft_backend conformance
# fault suites run --test-threads=1 (the eg.3 process-global precept-state race):
TMPDIR=/tmp cargo test -p echo_graft_test -- --test-threads=1
# ≥100 determinism loop on the commit + the live-binding surface (run ISOLATED — no concurrent cargo,
# the eg.4 L-2 precept: a relinking build mid-loop is a harness artifact, not a determinism defect):
for i in $(seq 1 120); do TMPDIR=/tmp cargo test -p echo_graft_backend --test <buffer_or_binding_suite> || break; done
```

**Elixir (`apps/echo_store`, from the app dir):**
```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_store
asdf current                                   # re-probe from the app dir; never hardcode the toolchain
valkey-cli -p 6390 ping                         # → PONG  (the live-bus leg)
TMPDIR=/tmp mix compile --warnings-as-errors    # zero-NEW-warnings (2 pre-existing echo_store warnings are not a regression — eg.4 Y-1)
TMPDIR=/tmp mix test                            # the conformance test asserts byte-equality vs the SAME fixtures
ECHO_GRAFT_BACKEND_TEST=1 TMPDIR=/tmp mix test --include valkey   # the end-to-end leg vs the REAL backend (criterion 7)
```
- **Criterion 7's live leg runs against the REAL `echo_graft_backend`** (the eg.4 in-Elixir responder is replaced for this leg) — env-gated; **unset → reported excluded, never trivially passed** (the eg.4 `:valkey`-tag posture). A PRESENT backend MUST be exercised, or the criterion fails loud (§eg5-spec liveness note).
- **The byte-freeze re-verification is mandatory** (HIGH-risk): the shared `wire.fixtures` diff byte-identical Rust↔Elixir; the eg.3 `FeedEvent` blob 3-way match holds; `grep`-confirm no silent re-encode of any v1 message.

## Smallest-change build order — each a stop-and-verify step { id="eg5-build-order" }

> Order chosen so each step is independently verifiable. The wire-touching decision (D-A1) and the transport decision (D-A2) are **ruled** (§eg5-decisions) — the steps below build to the rulings, no open gate.

1. **The pure shaping core + the buffer (write tier, no wire change).** A clock-injected `BatchShaper`-style core (min_size OR timeout) + the bounded per-Volume buffer that accepts → batches → fsyncs → rolls up via `volume_push` (`runtime.rs:239`). *Verify:* unit tests for the core (deterministic flush, S-3), the buffer (order S-5, one fsync/batch S-1, the loss-window query S-6). (criteria 1, 3, 5, 6)
2. **The `:async`/`:sync` durability mode (the ruled D-A1 — drop v1, `COMMIT` as v2 in place).** Add a fixed-position `mode` field (`async`\|`sync`) to `Msg::Commit` **in place** (`lib.rs:264-273` struct, `:374-381` `to_parts`, `:444-461` `from_parts`), set `PROTO_MIN = PROTO_MAX = 2` (`lib.rs:32-34`), **regenerate** the `COMMIT` + handshake fixtures (the v1 generation is dropped — no second generation, no v1 decoder path), and update **both** conformance suites (Rust + Elixir) to assert byte-equality on the regenerated fixtures + the decode round-trip. The exact `mode` field position + token bytes is the one build-realization detail Mars pins against the regenerated fixture. Default the mode to `:sync` **in the client API** (`EchoStore.GraftBackend.commit/push` always encodes it) — not a wire default. *Verify:* `:sync` acks downstream of `volume_push` (S-2); `:async` acks on fsync; the single conformance generation green (Rust-encode == Elixir-encode on the regenerated fixtures); `PROTO_MIN = PROTO_MAX = 2`, no v1 decoder path remains; every non-v2-touched fixture byte-identical to HEAD. (criterion 2; the mode for 1)
3. **Crash recovery for the open batch.** Restart leaves at most the open batch unaccounted; pushed LSNs intact. *Verify:* S-4 (crash after fsync / before push → bound holds; the fault suite runs `--test-threads=1`). (criterion 4)
4. **The live Valkey transport (the ruled D-A2 raw RESP3 socket).** A new transport module — a thin `tokio` socket loop reusing `encode_parts`/`decode_parts` (`lib.rs:73,91`) for both the message payloads and the flat-array pub/sub envelope (no new client dep; `HELLO 3` + the read loop are the only new wire code): connect to :6390 over RESP3, `SUBSCRIBE` the command + control lanes, call `Session::handle_frame` (`session.rs:99`) per request frame, `PUBLISH` the reply on `egraft:reply:{client_id}`, bind a live `FeedSink` (`transport.rs:24`) → `PUBLISH` on `egraft:feed:{vol}`. *Verify:* the env-gated end-to-end leg over real :6390 against the real backend (S-7); byte-freeze re-verified. (criterion 7)
5. **Wire the cap (UF-1) + close UF-2.** Consult `Backpressure::admit(vol)` (`backpressure.rs:66`) in the live transport before dispatch; over-cap → `Msg::Err{Unavailable}`; the control lane stays exempt. Add the UF-2 `not_found`-arm test (unknown vid → `Msg::Err{not_found}`). *Verify:* S-8 (flood A → A refused, B flows; **grep** proves `admit` is called from the live path — the L-3 precept); the `not_found` arm now killed by a mutation. (criterion 8 + UF-2)
6. **The full dual gate + the determinism loop.** Both ladders green end-to-end; the ≥100 loop on the commit/binding surface run ISOLATED. *Verify:* the gate ladder above, both runtimes; byte-freeze final check.

> Stop at each step's acceptance boundary and report before the next — the eg.1–eg.4 working loop.

## Dependencies & risks (brief) { id="eg5-brief-risks" }

- **Depends on:** eg.4 (wire, `Session`, `FeedSink` + `Backpressure` seams, the `EchoStore.GraftBackend` client).
- **Risk — HIGH, the live transport + the ruled wire change:** mitigated by reusing `Session::handle_frame` unchanged, the dual-side conformance re-asserted live on the regenerated `COMMIT`/handshake fixtures + the byte-frozen non-v2-touched fixtures, the liveness-proving env-gated leg, and the D-A1 discipline (drop v1, `COMMIT` as v2 in place, `PROTO_MIN = PROTO_MAX = 2`, the client always encodes the mode).
- **Risk — the L-3 trap (a green mechanism test masks an unwired mechanism):** criterion 8 explicitly requires the **production** call site to consult `admit` (grep-verified), not just a unit test that instantiates the cap.

## Decisions (Operator) — RULED { id="eg5-open-decisions" }

The three forks Venus surfaced are **ruled** (Operator, 2026-06-22, via `AskUserQuestion`; each Director-verified against source), and D-A1 was subsequently **superseded by an Operator directive** ("drop v1 compatibility; use `COMMIT` as v2+"). The authoritative decision record is the run ledger `docs/graft/eg-5.progress.md` §eg5-decisions (**D-5** supersedes the v1-preserving parts of D-2 for the wire; D-3 transport; D-4 buffer); recorded here as the build-grade ledger so Mars builds from a resolved brief.

| # | Decision | Ruling |
|---|---|---|
| **D-A1** | The durability-mode wire encoding (was fork A-1; the keep-v1 form D-2 was **superseded by D-5**). The proto is **hand-rolled positional RESP3 with a strict `Commit` arity check** (`lib.rs:444-461`), and v1 has **zero deployed consumers** (the tree is untracked / undeployed). | **RESOLVED — D-5: drop v1 compatibility; `COMMIT` becomes the v2+ shape.** `Msg::Commit` gains a fixed-position `mode` field (`async`\|`sync`), modified **in place** (not a `COMMIT2`); `PROTO_MIN = PROTO_MAX = 2` (the handshake negotiates only v2; a v1 peer fails negotiation by design). **Single** conformance generation — the `COMMIT` + handshake fixtures are intentionally regenerated and proven by the dual-side Rust-encode==Elixir-encode conformance (NOT a HEAD-diff); every non-v2-touched fixture stays byte-identical to HEAD. The `:sync` default lives in the **client API** (`push` defaults the mode to `:sync` and always encodes it) — not a wire/version default. (D-5 supersedes the earlier keep-v1 / dual-generation / `COMMIT2` form: v1 protected a non-existent consumer, so dropping it removes net complexity for zero lost value.) |
| **D-A2** | The Rust→Valkey transport (was fork A-2). The workspace vendors **no** redis/valkey/fred/rustis client (`Cargo.lock`: `tokio`/`bytes`/`opendal`/`reqwest`/`bilrost`); `encode_parts`/`decode_parts` are **byte-identical to `EchoMQ.RESP.encode/1`** (`lib.rs:70-71`). | **RESOLVED — a raw RESP3 socket reusing the proto codec.** A thin `tokio` socket loop reuses the codec for both message payloads and the flat-array pub/sub envelope; only `HELLO 3` + the read loop are new wire code. Zero heavyweight deps; Rust and BEAM share the encoder shape (no second-encoder drift surface). The live leg stays **env-gated** (`ECHO_GRAFT_BACKEND_TEST`, the eg.2/eg.4 precedent). The alternative A-2b (a mature client for pool/cluster ergonomics) was ruled against — the engine's first heavyweight dep + a drift-capable second encoder, for ergonomics a single-socket backend does not yet need. |
| **D-A3** | The buffer medium + how criterion 4 is proven (was fork A-3). | **RESOLVED — reuse the engine's Fjall local store.** The group-commit buffer rides the existing durable Fjall store (the engine already fsyncs there on commit). Criterion 4 (crash after local fsync, before remote `volume_push` `runtime.rs:239`) is proven by a fault test (`--test-threads=1`): fsync the open batch, simulate a crash before push, restart, assert the unaccounted set ⊆ the open batch. Reversible if a separate WAL is later wanted. |
