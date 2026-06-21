---
title: "eg.4 — BEAM↔Rust backend & protocol"
id: echo-graft-4-sidecar-proto
rung: eg.4
size: L
risk: HIGH
status: BUILD-GRADE (Apollo eg.4 evaluation 2026-06-21 · D-1 A · D-2 echo_graft_backend · D-7 RESOLVED Option A — compositional proof accepted, real Rust↔Valkey binding deferred to eg.5/eg.6) — synced to as-built
stands-on: "eg.2 · eg.3"
---

# eg.4 — BEAM↔Rust backend & protocol { id="echo-graft-4-sidecar-proto" }

> _Run the **Rust page-engine** as a supervised backend that is a first-class EchoMQ participant, with a versioned protocol crate as the contract that keeps the BEAM and Rust sides in lockstep — a coexisting peer beside the native `EchoStore.Graft.*` engine, never a replacement._

> {style="note"}
> **Reconciliation banner (read first — RESOLVED).** As originally specced, eg.4 introduced its Elixir client under the name **`EchoStore.Graft`** — but that module already exists as a **complete native-BEAM page-store engine** (`apps/echo_store/lib/echo_store/graft/*`), a direct functional twin of the Rust engine. The collision (name + architecture) was analysed in **`docs/graft/graft.engine-split.design.md`** and ruled by the Operator: **D-1 = Option A (COEXIST)** — both engines kept; native `EchoStore.Graft.*` stays canonical and **untouched**. **D-2 = `echo_graft_backend`** (the Operator's name, overriding the architect's `…Sidecar` suggestion): the Rust EchoMQ-participant crate/binary is **`echo_graft_backend`**, the versioned wire crate is **`echo_graft_proto`**, and the Elixir client module is **`EchoStore.GraftBackend`** — a coexisting **peer** beside the native engine. eg.4's claim narrows to "drive the **Rust** page-engine" (D-3). **No longer blocked.** The resolved ledger is in "Open decisions" below.

## Summary

The integration seam **for the Rust page-engine** (not for all durability — the native Elixir engine `EchoStore.Graft.*` needs no backend hop). Because the Rust engine does blocking object-storage and LSM I/O, it runs as a supervised backend process addressed over EchoMQ rather than an in-VM NIF — an engine crash becomes a restart, not a downed orchestrator. `echo_graft_proto` is the byte-frozen, version-negotiated wire; **`EchoStore.GraftBackend`** (the Operator's name, D-2) is the Elixir client, a peer beside the native engine.

## Rationale

A NIF couples crash domains, and alpha code that segfaults would take the orchestrator with it; the Rust engine's blocking I/O would also force dirty schedulers. A backend process isolates the engine, and the local-socket/bus hop is noise next to an object-storage commit, which is the latency regime the engine already lives in. The hard part is the cross-runtime contract, so the protocol is explicit, versioned, and verified by a conformance suite **both** sides run against one fixture set — that contract is exactly the "synchronize BEAM and Rust support" requirement, and the byte-frozen dual-side conformance is the HIGH-risk mitigation.

## 5W + H { id="eg4-5wh" }

| | |
|---|---|
| **Who** | Platform; the Elixir client (`EchoStore.GraftBackend`) is consumed by EchoStore callers that want the **Rust** page-engine (raw-page performance / a deployable backend). |
| **What** | `echo_graft_proto` (wire for open/commit/read/snapshot/push/pull/fetch + the feed event, with version negotiation), `echo_graft_backend` (the EchoMQ-participant binary), and **`EchoStore.GraftBackend`** (the Elixir client — NOT `EchoStore.Graft`, which is the native engine). |
| **When** | After eg.2 and eg.3; gates eg.5 and eg.6. |
| **Where** | `echo_graft_backend` deploys beside Go workers on the EchoMQ bus; the client lives in the Elixir app, **beside** (never replacing) the native `EchoStore.Graft.*` engine. |
| **Why** | Drive the **Rust** engine from the BEAM with an isolated crash domain and a contract that cannot silently skew. |
| **How** | RESP3 messages over EchoMQ (`EchoMQ.RESP` codec); a version handshake on connect; correlation ids; supervised reconnect keyed on the feed cursor; a shared conformance suite over one fixture set. |

## Scope { id="eg4-scope" }

### In scope

- `echo_graft_proto`: request/response messages for open, commit, snapshot read, and push/pull/fetch, plus the feed event; a protocol version negotiated on connect; a frozen encoding per message.
- `echo_graft_backend`: consumes the command lane, drives the **Rust** `Runtime`, publishes the change-feed (eg.3) on its own `egraft:feed:{vol}` lane (`feed.rs:42`), supervised.
- **`EchoStore.GraftBackend`** (the Elixir client): connect + version-check, commit/read/snapshot/sync, subscribe to the `egraft:feed:{vol}` lane, reconnect + resubscribe from the last-seen LSN.
- An error taxonomy (conflict/abort, not-found, version-mismatch, unavailable) and backpressure handling.
- A conformance suite both the Rust and Elixir sides run against the frozen fixtures.

### Out of scope

- The low-latency write tier (eg.5); cross-compile and CI (eg.6).
- An in-VM NIF (a later, separately-specified optimization).
- **The native Elixir engine `EchoStore.Graft.*` is untouched** — eg.4 adds a *new* client beside it; it does not modify, replace, or wrap the native engine.
- **The `egraft:feed:{vol}` lane stays distinct from the native engine's `graft:{vol}:commits` channel** (`sync.ex:41`) — the two engines' feeds never share a lane.

## Specification { id="eg4-spec" }

Transport is RESP3 over EchoMQ: a command lane for requests, the eg.3 feed lane (`egraft:feed:{vol}`) for advances. On connect the client (`EchoStore.GraftBackend`) sends its supported protocol-version range and `echo_graft_backend` selects one; a mismatch is refused with a clear error and **no Volume is touched**. Requests carry a correlation id; responses echo it. The commit path is client → command lane → backend → **Rust** runtime commit (eg.2 conditional write, `runtime.rs:239-243`) → feed event (eg.3, `runtime.rs:250-279`) → the client observes the ack and then the event. Reads run against a snapshot; lazy page faults happen backend-side (`runtime.rs:91-120`) and never cross the bus as raw pages unless requested. Supervision: the backend crash is a restart; the client reconnects and resubscribes from its last-seen LSN, so the feed cursor is the recovery key. Backpressure: per-Volume command concurrency (or multiple lanes) prevents head-of-line blocking when the runtime is slower than the bus.

> {style="note"}
> **As-built reconciliations (the build's three cited realizations + two field semantics).**
> - **`Commit.base` is advisory / diagnostic** [F-2]. The wire carries a `base` LSN, but the dispatch builds the writer from the Volume's **own current snapshot** (the engine's authoritative base, `volume_writer`); a stale wire `base` does **not** silently widen the write — it surfaces as the real OCC `VolumeConcurrentWrite` conflict at `commit` (the same fence S-4 exercises). `base` is threaded only into the error detail. (It is not a security boundary; the engine's snapshot is.)
> - **`replay_since` is the in-process / test model of resubscribe** [F-3]. The Rust `Session::replay_since(branded, last_seen)` is the in-Rust expression of "resume from the cursor". The **shipped live resubscribe is BEAM-side**: the connector re-issues every recorded subscription on reconnect (`connector.ex` `resubscribe/1`) and the client replays from its own last-seen-LSN cursor (`graft_backend.ex`). There is **no production double-delivery** — the in-process `replay_since` returning frames *and* re-publishing is an inspectable test convenience, moot on the shipped (BEAM-driven) path.
> - **Page-size realization** [#2]. The proto `Commit.pages` carries arbitrary-length `bytes`, but a `Page` is a fixed `PAGESIZE` (4 KiB, `page.rs:11`; `Page::from_buf` rejects any other length). The dispatch (`to_page`) right-pads a short page with zeros and refuses an over-`PAGESIZE` page with `unavailable` — **never a panic** (pinned at two altitudes: the `to_page` unit tests + the `oversize_page_commit_is_unavailable_not_a_panic` / `short_page_commits_and_reads_back_zero_filled` session round-trips).
> - **The live cross-runtime proof is compositional** [#3] — see §eg4-acceptance's reconciliation note (the Rust `Session` is not bus-bound in eg.4: no Rust valkey client, no NIF, both out of scope; cross-runtime equality rides the shared byte-frozen wire + dual-side conformance, with the BEAM client's live-bus mechanics proven over real Valkey against an in-Elixir conformant responder).

## Acceptance criteria { id="eg4-acceptance" }

1. **Given** a client and backend at compatible protocol versions, **when** the client commits a write, **then** it receives an ack carrying the LSN and subsequently a matching feed event.
2. **Given** a client at an unsupported protocol version, **when** it connects, **then** the backend refuses with a version-mismatch error and **no Volume is mutated**.
3. **Given** the backend crashes mid-session, **when** its supervisor restarts it, **then** the client reconnects, resubscribes from its last-seen LSN, and observes no lost or duplicated committed LSNs beyond at-least-once on the feed.
4. **Given** two clients committing conflicting writes to one Volume, **when** both reach the backend, **then** one acks success and the other a conflict/abort — the eg.2 fence surfaced end-to-end.
5. **Given** any defined protocol message, **when** it is re-encoded after a code change, **then** it matches the byte-frozen fixture, **or** the protocol version has been bumped.
6. **Given** the conformance suite, **when** run on both the Rust and Elixir sides, **then** both agree on every message encoding.
7. **Given** a producer outrunning the runtime, **when** the command lane fills, **then** backpressure is applied without blocking other Volumes' commands.

> {style="note"}
> **[RECONCILE: as-built — the cross-runtime proof is compositional (realization #3)].** The Rust `echo_graft_backend::Session` is **not bus-bound** in eg.4 — there is no Rust valkey client and no NIF (both explicitly out of scope, §eg4-scope). So criteria **1 / 3 / 4** are discharged **compositionally**, not by one connected BEAM↔real-Rust-over-Valkey socket: **(a)** the Rust dispatch correctness (commit→push→ack→feed, conflict, handshake refusal, replay, page-size) is proven **in-Rust** over a real `echo_graft` Runtime + an in-memory `FeedSink` (`round_trip` / `reconnect` / `backpressure` suites); **(b)** the BEAM client's bus mechanics (publish on `egraft:cmd`/`_control`, correlate on `egraft:reply:{client}`, subscribe `egraft:feed:{vol}`, advance the LSN cursor, the S-2 refusal) are proven over a **real Valkey :6390** against an in-Elixir conformant responder that speaks the **same byte-frozen `Proto`** (`live_round_trip_test`, `@moduletag :valkey`); **(c)** the cross-runtime byte-equality is the **shared single fixture set** both sides' conformance suites assert (criteria 5+6, `sha256` identical). The contract — the byte-frozen wire — is what holds the two runtimes in lockstep (the HIGH-risk mitigation the spec names). A single real **Rust↔Valkey** binding is a **deployment concern deferred to eg.5/eg.6** (the build order env-gates the live leg; §eg4-gates frames the backend as a participant "beside Go workers"). *Operator ruling on this reading: D-7 (see §eg4-open-decisions).*

---

# Build brief (the `.llms.md` brief, folded in) { id="eg4-brief" }

> The builder works from here. Every cited surface is real (confirmed against source); no signature is invented. Forward-tense marks anything unshipped.

## References — read these first { id="eg4-references" }

- **The engine-split decision** — `docs/graft/graft.engine-split.design.md` (the coexistence boundary, the as-built capability map, why `EchoStore.Graft.*` is untouched).
- **The Rust `Runtime` surface** — `apps/echo_graft/crates/echo_graft/src/rt/runtime.rs` (the 1:1 method map below).
- **The Rust feed** — `apps/echo_graft/crates/echo_graft/src/feed.rs` (`FeedEvent`, `lane_for`, byte-frozen fixture at `feed.rs:166`).
- **The Rust fence** — `apps/echo_graft/crates/echo_graft/src/remote.rs:195-211, 66-72` (`put_commit` `if_not_exists` ⇒ `precondition_failed`).
- **The Elixir RESP3 codec (REUSE, do not reimplement)** — `apps/echo_wire/lib/echo_mq/resp.ex`: `EchoMQ.RESP.encode/1` (`resp.ex:21`, → iodata) and `EchoMQ.RESP.parse/1` (`resp.ex:45`, → `{:ok, reply, rest} | :incomplete | {:error, :bad_resp}`).
- **The Elixir connector** — `apps/echo_wire/lib/echo_mq/connector.ex`: `command/3` (`:49`), `pipeline/3` (`:58`), `subscribe/2` (`:111`), `unsubscribe/2` (`:121`); facade `EchoWire` adds `eval/5`, `push_command/3`, `noreply_pipeline/3`. Out-of-band push frames reach a subscriber as `{:emq_push, ["message", channel, payload]}` (the connector's envelope; see `apps/echo_store/lib/echo_store/graft/sync.ex:10-12`).
- **The native engine's bus pattern to mirror (NOT to touch)** — `apps/echo_store/lib/echo_store/graft/sync.ex` (`publish_notice`/`subscribe_commits` over `EchoMQ.Connector`), as the precedent for the client's subscribe + decode shape.
- **The umbrella build guide** — `echo/CLAUDE.md` §3 (the `echo_store` gate ladder, `TMPDIR=/tmp`, asdf re-probe, Valkey `:6390`).

## The Rust `Runtime` 1:1 method map (the wire wraps these) { id="eg4-runtime-map" }

`echo_graft_backend` exposes the engine over the wire as a thin 1:1 dispatch onto the real `Runtime` (all in `runtime.rs`). **No new engine logic** — the backend is a session + dispatch + publish shell:

| Proto message | Rust `Runtime` call (cited) | Returns |
|---|---|---|
| `OpenVolume{branded, local?, remote?}` | `volume_open_branded(&BrandedId, Option<LogId>, Option<LogId>)` (`runtime.rs:185`) | `Volume` (→ vid) |
| `ResolveBranded{branded}` | `resolve_branded(&BrandedId)` (`runtime.rs:198`) | `Option<VolumeId>` |
| `Commit{vid, base, pages}` | `volume_writer(vid)` (`runtime.rs:298`) → `write_page`/`commit` (writer surface) | `lsn` or `VolumeConcurrentWrite` |
| `Push{vid}` | `volume_push(vid)` (`runtime.rs:239`) — fence + feed publish | `()` ; advance → feed event |
| `Pull{vid}` | `volume_pull(vid)` (`runtime.rs:223`) | `()` |
| `Read{vid, pageidx}` | `volume_reader(vid)` (`runtime.rs:293`) → `read_page` (`runtime.rs:91`) | `Page` (lazy-fault backend-side) |
| `Snapshot{vid}` | `volume_snapshot(vid)` (`runtime.rs:289`) | `Snapshot` |
| `GetCommit{log, lsn}` | `get_commit(&LogId, LSN)` (`runtime.rs:310`) | `Option<Commit>` |
| `FeedEvent` (publish only) | `feed()` (`runtime.rs:83`) → published by `volume_push` (`runtime.rs:250-279`) | — |

> The change-feed swap the engine already anticipates: `RuntimeInner.feed` is `Arc<InMemoryFeed>` and the moduledoc says *"eg.4 swaps this for an EchoMQ-backed sink behind `ChangeFeed`"* (`runtime.rs:48-49`). The backend implements `ChangeFeed` (`BusFeed`, `feed_sink.rs`) to `PUBLISH` onto `egraft:feed:{vol}` (`lane_for`, `feed.rs:42`) instead of buffering in memory.
>
> [RECONCILE: as-built — realization #1, observe-then-republish] The byte-frozen eg.3 `RuntimeInner.feed` is a **concrete** `Arc<InMemoryFeed>` (`runtime.rs:50`), **not** an `Arc<dyn ChangeFeed>` — so the sink **cannot be injected** into the Runtime without editing the frozen engine. The build satisfies the moduledoc's intent without that edit: after each `Push` the `Session` **observes** the engine's in-memory feed (`events_since(branded, bus_cursor)`, `feed.rs:69-80`) and **republishes** the new events through `BusFeed`/`FeedSink`, keeping a per-Volume bus cursor (so a no-op push publishes nothing — the S-1 negative). The `BusFeed` `ChangeFeed` impl is the sink the brief names; it is exercised by the in-process round-trip. The engine stays byte-frozen (zero edits to `runtime.rs` / `feed.rs`).

## Agent stories — each criterion as Directive + Acceptance gate { id="eg4-stories" }

Each story: **As** a role, **I want** a capability, **so that** a benefit; a Given/When/Then; the **invariant(s)** it exercises; the **real surface** it drives. Coverage maps every criterion (1–7) to a story.

### S-1 — Commit acks the LSN, then the feed event lands (criterion 1)
- **As** an EchoStore caller, **I want** a commit over the bus to ack the new LSN and then deliver a matching feed event, **so that** I can confirm durability and react to the advance without polling.
- **Given** a connected `EchoStore.GraftBackend` client + `echo_graft_backend` at compatible versions and an open branded Volume; **When** the client sends `Commit{vid, base, pages}` then `Push{vid}`; **Then** it receives an ack carrying the committed `lsn`, and subsequently a `FeedEvent` on `egraft:feed:{vol}` whose `lsn` matches.
- **Drives:** `volume_writer`+`commit` (`runtime.rs:298`), `volume_push`→`publish_feed_advance` (`runtime.rs:239-279`); client subscribe via `Connector.subscribe/2` (`connector.ex:111`).
- **Invariant:** a feed event is published **only** on a durable remote-LSN advance (`runtime.rs:250-261`) — a lost fence publishes nothing (this is the liveness the gate must positively assert: assert the event ARRIVES on a real advance, and assert NONE arrives on a no-op push).

### S-2 — An incompatible version is refused, no Volume touched (criterion 2)
- **As** an operator, **I want** an incompatible client refused at the handshake with no side effect, **so that** a version skew can never silently corrupt a Volume.
- **Given** a client advertising a version range disjoint from the backend's; **When** it connects; **Then** the backend replies a `version-mismatch` error AND no Volume is opened/mutated (assert the volume set is byte-identical before and after the refused connect — a no-op must not satisfy the letter).
- **Drives:** the handshake (proto §version-negotiation below); the negative assertion is the load-bearing proof.
- **Invariant:** refusal is total — no `volume_open_branded` runs on a rejected handshake.

### S-3 — Crash → reconnect → resubscribe from last-seen LSN, no loss (criterion 3)
- **As** an EchoStore caller, **I want** the client to resume from its last-seen LSN after a backend restart, **so that** a crash is a hiccup, not a gap.
- **Given** a live session past LSN `n`; **When** `echo_graft_backend` crashes and its supervisor restarts it; **Then** the client reconnects, resubscribes from `n`, and observes every committed LSN `> n` with no loss and no duplication beyond at-least-once.
- **Drives:** `events_since(branded, last_seen)` replay (`feed.rs:69-80`); supervised restart; `Connector.subscribe/2` re-issue.
- **Invariant:** the feed cursor (last-seen LSN) is the recovery key; replay is monotone + gap-free (`feed.rs:107-111`).

### S-4 — Two conflicting commits: one acks, one conflicts (criterion 4)
- **As** an EchoStore caller, **I want** the eg.2 fence to surface end-to-end as a clean conflict, **so that** a concurrent writer cannot double-commit.
- **Given** two clients committing conflicting writes to one Volume from the same base; **When** both reach the backend; **Then** one acks success and the other gets `conflict/abort`.
- **Drives:** local OCC `VolumeConcurrentWrite` (`README.md:107-109`) and/or the remote fence `precondition_failed` (`remote.rs:66-72`), mapped to the proto `conflict` error.
- **Invariant:** the fence is sync-then-race (`README.md:140-144`) — the conflict is real, not simulated.

### S-5 — Every proto message is byte-frozen (criterion 5)
- **As** a maintainer, **I want** each message's on-wire bytes pinned to a fixture, **so that** the wire cannot drift silently.
- **Given** any defined `echo_graft_proto` message; **When** it is re-encoded after a code change; **Then** the bytes equal the frozen fixture, OR the protocol version was bumped (a test asserts the fixture, the version, and round-trip).
- **Drives:** the fixture set (§fixtures); the eg.3 `FeedEvent` rides as an opaque bilrost blob, already byte-frozen at `feed.rs:166`.
- **Invariant:** byte-frozen wire (gate G3, `graft.roadmap.md:92`) — a fixture mismatch is a LOUD failure.

### S-6 — Rust and Elixir agree on every encoding (criterion 6)
- **As** a maintainer, **I want** both runtimes to encode/decode the SAME fixtures identically, **so that** the cross-runtime contract is proven, not assumed (the HIGH-risk mitigation).
- **Given** the one canonical fixture set; **When** the Rust conformance test and the Elixir conformance test both run; **Then** each asserts byte-equality on encode and value-equality on decode against those fixtures.
- **Drives:** `EchoMQ.RESP.encode/1`+`parse/1` (`resp.ex:21,45`) on the Elixir side; the Rust proto encoder on the other; one shared fixture file both load.
- **Invariant:** a fixture is authoritative for BOTH sides — neither side owns its own truth.

### S-7 — Backpressure isolates a slow Volume (criterion 7)
- **As** an operator, **I want** a producer outrunning the runtime to be back-pressured without stalling other Volumes, **so that** one hot Volume cannot head-of-line-block the rest.
- **Given** a producer flooding Volume A's command lane while Volume B is idle; **When** A's lane fills; **Then** backpressure applies to A and B's commands still flow (assert B's latency is unaffected within a bound).
- **Drives:** per-Volume command concurrency (multiple lanes or per-vid in-flight cap); the overflow policy stated below.
- **Invariant:** isolation is per-Volume; a full lane never blocks a different `{vol}`.

**Coverage:** criterion 1→S-1 · 2→S-2 · 3→S-3 · 4→S-4 · 5→S-5 · 6→S-6 · 7→S-7. Every criterion has exactly one story; every story names its invariant and its real surface.

## Declared keys — nothing undeclared on the wire { id="eg4-declared-keys" }

**`echo_graft_proto` message types** (the full set; each gets a byte-frozen fixture):

| Direction | Message | Fields (declared) |
|---|---|---|
| handshake | `Hello` (client→backend) | `proto_min: u32`, `proto_max: u32`, `client: str` |
| handshake | `Welcome` (backend→client) | `proto: u32` (selected) |
| handshake | `Incompatible` (backend→client) | `proto_min: u32`, `proto_max: u32` (backend's range), `reason: str` |
| request | `OpenVolume` | `corr: u64`, `branded: str(14)`, `local: opt str`, `remote: opt str` |
| request | `ResolveBranded` | `corr: u64`, `branded: str(14)` |
| request | `Commit` | `corr: u64`, `vid: str`, `base: u64`, `pages: [(u32, bytes)]` |
| request | `Push` | `corr: u64`, `vid: str` |
| request | `Pull` | `corr: u64`, `vid: str` |
| request | `Read` | `corr: u64`, `vid: str`, `pageidx: u32` |
| request | `Snapshot` | `corr: u64`, `vid: str` |
| request | `GetCommit` | `corr: u64`, `log: str`, `lsn: u64` |
| response | `Ack` | `corr: u64`, `lsn: u64` |
| response | `Pages` | `corr: u64`, `data: bytes` (one page; raw page only when `Read`-requested) |
| response | `SnapshotResp` | `corr: u64`, `lsn: u64`, `pages: u32` |
| response | `Err` | `corr: u64`, `kind: enum{conflict, not_found, version_mismatch, unavailable}`, `detail: str` |
| feed | `FeedEvent` (publish only) | the eg.3 bilrost `FeedEvent` blob, **opaque** (`volume_branded_id`·`log_id`·`lsn`·`ts`, `feed.rs:25-38`) |

**EchoMQ fields / lanes / ids the backend adds** (and nothing else):

- **Command lane(s):** `egraft:cmd:{vol}` — per-Volume command channel(s); the per-Volume keying is the backpressure isolation boundary (S-7). (A single `egraft:cmd` lane is the do-nothing alternative the design forecloses for HOL-blocking.)
- **Control lane:** `egraft:cmd:_control` — [RECONCILE: as-built] the single, vid-less lane the client (`EchoStore.GraftBackend.control_lane/0`, `graft_backend.ex`) publishes the handshake (`Hello`) and the two open-time verbs (`OpenVolume` / `ResolveBranded`, which carry a branded id but no native vid yet) on. **It is deliberately EXEMPT from the S-7 per-Volume backpressure isolation** (it has no `{vol}` to key a cap on, and its traffic is infrequent + bounded-by-construction — one handshake per session, one open per Volume lifecycle — not a sustained write path a producer can flood). The exemption is documented at both ends (`echo_graft_backend` `backpressure` moduledoc + the client `control_lane/0` comment) and pinned by the keying-isolation test `the_control_lane_is_outside_the_per_volume_cap`.
- **Reply lane:** `egraft:reply:{client_id}` — [RECONCILE: as-built] the per-client lane each `EchoStore.GraftBackend` instance subscribes at init and on which it correlates its responses (one lane per client keeps a client's replies off every other client's wire; the `corr` field pairs the in-flight request inside it). `client_id` defaults to a generated unique suffix.
- **Feed lane:** `egraft:feed:{vol}` (`lane_for`, `feed.rs:42`) — publish-only, distinct from the native `graft:{vol}:commits` (`sync.ex:41`).
- **Correlation id:** `corr: u64` on every request/response — the request↔response pairing; not a bus key, a proto field.
- **No remote-object keys are added** — the Tigris object layout (`logs/{log}/commits/{LSN}`, `segments/{sid}`) is eg.2's and unchanged (`remote.rs:33-43`).

> {style="warning"}
> **The error enum is closed:** exactly `{conflict, not_found, version_mismatch, unavailable}` (criterion's taxonomy). A new error kind is a proto-version bump, never a silent addition.

## The byte-frozen wire contract — the fixture set { id="eg4-fixtures" }

The HIGH-risk mitigation is **one canonical fixture set both runtimes assert against** (criteria 5+6):

- **Encoding = RESP3 framing** via the real Elixir codec `EchoMQ.RESP` (`resp.ex`): a message is an array of bulk strings (`encode/1`, `resp.ex:21`) — message-tag string + each declared field as a bulk string (integers/atoms bulk-encode, `resp.ex:25-28`). The Rust side encodes the identical RESP3 bytes. **Confirm the codec surface against `resp.ex` before pinning** — `parse/1` returns `{:ok, reply, rest} | :incomplete | {:error, :bad_resp}` and push frames decode as `{:push, [...]}` at the codec layer (the connector re-wraps subscriber pushes as `{:emq_push, [...]}`).
- **The `FeedEvent` rides as an OPAQUE bilrost blob** wherever the feed event appears — it is already byte-frozen at `feed.rs:166` (the eg.3 fixture). The eg.4 wire wraps that blob as one bulk string; eg.4 does **not** re-encode the feed event's fields, so the two freeze-points compose without duplication.
- **One fixture file, two readers:** a committed fixture set (e.g. `crates/echo_graft_backend/tests/fixtures/*` mirrored to `apps/echo_store/test/fixtures/graft_backend/*`, byte-identical). Each fixture is `{message_name, hex_bytes}`. The Rust conformance test encodes the message and asserts `== hex`; the Elixir conformance test does the same with `EchoMQ.RESP.encode/1` and asserts `== hex`. Both also decode the hex and assert the round-trip value.
- **A fixture mismatch is a LOUD failure on both sides**, and the only sanctioned way to change a fixture is a `proto` version bump (criterion 5).

## Version-negotiation contract { id="eg4-version-negotiation" }

- **`PROTO_MIN`/`PROTO_MAX`** are `u32` constants in `echo_graft_proto`, shared by both sides (the Elixir client reads the same range — a single source, declared in the proto crate's spec and mirrored as an Elixir module attribute).
- **Handshake:** client sends `Hello{proto_min, proto_max, client}`; backend selects `proto = min(client.proto_max, backend.PROTO_MAX)` if the ranges overlap and replies `Welcome{proto}`; else replies `Incompatible{proto_min, proto_max, reason}` and **performs no Volume operation** (S-2's negative assertion).
- **The selected `proto` is echoed on the session** and pins which fixture generation is in force; a future wire change bumps `PROTO_MAX` and ships the new fixtures alongside the old (the old stay byte-frozen).
- **The refusal error** is `Err{kind: version_mismatch}` at the session level (no `corr` needed pre-handshake — `Incompatible` carries the range directly).

## Gate ladder — run before reporting { id="eg4-gates" }

**Rust (`apps/echo_graft`, from the crate dir):**
```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_graft
TMPDIR=/tmp cargo test --workspace            # parity baseline + eg.2/eg.3 + new backend/proto tests
TMPDIR=/tmp cargo clippy --workspace          # warnings-as-errors clean (eg.3 posture: new code adds 0)
# the Rust conformance test over the shared fixtures (criterion 6, Rust side):
TMPDIR=/tmp cargo test -p echo_graft_backend conformance
# ≥100 determinism loop on the commit/version surface (mint/commit hazard):
for i in $(seq 1 120); do TMPDIR=/tmp cargo test -p echo_graft_backend -- --test-threads=1 || break; done
```
- **Fault suites run `--test-threads=1`** (eg.3 finding: `verify_snapshot.rs` shares process-global precept state and races under default parallelism, `README.md:177-181`).

**Elixir (`apps/echo_store`, from the app dir):**
```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_store
asdf current                                   # re-probe from the app dir; never hardcode the toolchain
valkey-cli -p 6390 ping                         # → PONG  (for the live-bus leg)
TMPDIR=/tmp mix compile --warnings-as-errors    # the clean-compile gate
TMPDIR=/tmp mix test                            # the Elixir conformance test asserts byte-equality vs the SAME fixtures
TMPDIR=/tmp mix test --include valkey           # the live EchoMQ/bus leg (env-gated, per eg.2's live-Tigris precedent)
```
- The **Elixir conformance test** (criterion 6, Elixir side) loads the same fixture file and asserts `EchoMQ.RESP.encode/1` byte-equality + decode round-trip.
- **The live-bus leg is env-gated** (a real Valkey `:6390` + a running `echo_graft_backend`), mirroring eg.2's `ECHO_GRAFT_TEST_*` posture — the offline conformance + unit legs always run; the end-to-end bus leg runs under the gate.

## Smallest-change build order — each a stop-and-verify step { id="eg4-build-order" }

1. **`echo_graft_proto` crate + fixtures FIRST.** Define every message (declared-keys table), pick the RESP3 framing, generate the fixture set, write the Rust byte-freeze test. *Verify:* `cargo test -p echo_graft_proto` green; fixtures committed. → unblocks both sides.
2. **`echo_graft_backend` session + dispatch.** The EchoMQ participant: consume `egraft:cmd:{vol}`, dispatch 1:1 onto the real `Runtime` (the method map), reply on the command lane; implement `ChangeFeed` to `PUBLISH` on `egraft:feed:{vol}`. *Verify:* a single-process in-Rust round-trip (open→commit→push→feed) green. (criteria 1, 4)
3. **Version handshake.** `Hello`/`Welcome`/`Incompatible`; the refusal performs no Volume op. *Verify:* S-2 (compatible connects; incompatible refused + volume set unchanged). (criterion 2)
4. **`EchoStore.GraftBackend` client + the Elixir conformance test.** Connect + version-check over `EchoMQ.Connector`, the request/response verbs, subscribe to `egraft:feed:{vol}`; the conformance test asserts byte-equality vs the shared fixtures. *Verify:* Elixir conformance green; client round-trip against a live backend (env-gated). (criteria 1, 5, 6)
5. **Reconnect + resubscribe-from-last-seen.** Supervised restart; replay via `events_since`. *Verify:* S-3 (crash → no loss/dup beyond at-least-once). (criterion 3)
6. **Backpressure.** Per-Volume concurrency / multiple lanes + the overflow policy. *Verify:* S-7 (flood A, B unaffected). (criterion 7)
7. **The live-bus env-gated leg + the determinism loop.** End-to-end over real Valkey `:6390`; the ≥100 loop on commit/version. *Verify:* the full gate ladder green, both runtimes.

> Stop at each step's acceptance boundary and report before the next — the eg.1/eg.2/eg.3 working loop.

## Dependencies & risks { id="eg4-risks" }

- **Depends on:** eg.2 (the fence), eg.3 (`FeedEvent` + `lane_for` + the in-process `ChangeFeed` seam).
- **Risk — HIGH, the cross-runtime contract:** mitigated by ONE byte-frozen fixture set both sides assert against (S-5/S-6), the version handshake (S-2), and RESP3 framing via the real `EchoMQ.RESP` codec (tractable dual-side conformance).
- **Risk — head-of-line blocking:** per-Volume command lanes / concurrency (S-7).
- **Risk — backpressure:** the bus-vs-runtime overflow policy is stated explicitly (the builder picks bounded-in-flight-per-vid vs. multiple lanes; both satisfy S-7's isolation).
- **Risk — feed-lane collision:** avoided by construction — `egraft:feed:{vol}` is distinct from native `graft:{vol}:commits`.

## Open decisions (Operator) — RESOLVED { id="eg4-open-decisions" }

The decisions are ruled; recorded here as the build-grade ledger. Full analysis: `docs/graft/graft.engine-split.design.md` §5–§7.

| # | Decision | Ruling |
|---|---|---|
| **D-1** | The `EchoStore.Graft` collision resolution | **RESOLVED — A (COEXIST).** Both engines kept; native `EchoStore.Graft.*` canonical + untouched; the Rust engine is a coexisting peer. |
| **D-2** | The Rust backend / client naming | **RESOLVED — `echo_graft_backend`** (crate/binary), `echo_graft_proto` (wire), **`EchoStore.GraftBackend`** (Elixir client). Overrides the architect's `…Sidecar` suggestion. |
| **D-3** | eg.4's claim | **RESOLVED — "drive the Rust page-engine"** (a peer integration, not the all-durability spine). |
| **D-4** | Long-term convergence of the two page-engines | **DEFERRED — post-eg.6** (decide after the per-workload shootout; do not fuse into a rung). |
| **D-5** | The eg.6 shootout shape | **RESOLVED — per-workload** (Elixir-engine vs. Rust-engine vs. Champ vs. Oban, named workloads). |
| **D-6** | If B were chosen (retirement rung) | **N/A under A.** |
| **D-7** | The live-bus leg architecture (the cross-runtime proof: compositional vs. one real Rust↔Valkey socket) | **RESOLVED — Option A (Operator, 2026-06-21; recorded as D-6 on the eg-4 aaw ledger).** The compositional cross-runtime proof is **ACCEPTED** for eg.4: criteria 1/3/4 are satisfied by the three legs meeting at the byte-frozen wire — (a) Rust dispatch proven in-Rust over a real `Runtime` + in-memory `FeedSink`, (b) BEAM bus proven over live Valkey :6390 against an in-Elixir `Proto`-conformant responder, (c) wire byte-equality proven by the shared fixtures both conformance suites assert. A single literally-connected Rust↔real-Valkey socket is **NOT required in eg.4**; the real Rust↔Valkey binding (and/or a NIF) is **deferred to eg.5/eg.6** (the deployment rungs, currently spec-out-of-scope). The settled question was purely scope — "is the socket plumbing eg.4's or eg.5/6's"; the CONTRACT is already proven, the live socket is a deployment concern. Honors §eg4-scope's bar on a Rust valkey client + a NIF without bending it. See the §eg4-acceptance reconciliation note + the forward-looking scope note below. |

> {style="note"}
> **Builder placement note (architect option, D-2 default holds):** the client is `EchoStore.GraftBackend` (a standalone peer module). If, during the build, the cleanest home turns out to be a durability-adapter placement, `EchoStore.Durability.GraftBackend` (implementing `EchoStore.Durability.Adapter`) is a noted alternative — but the **default is `EchoStore.GraftBackend`**, and either way the native `EchoStore.Graft.*` engine and the existing `EchoStore.Durability.Graft` adapter are untouched.

> {style="note"}
> **Forward-looking scope boundary — the real Rust↔Valkey socket binding is eg.5/eg.6 (D-7 = Option A).** eg.4 ships the **contract** (the byte-frozen `echo_graft_proto` wire), the **Rust dispatch shell** (`echo_graft_backend`, proven in-process), and the **BEAM client** (`EchoStore.GraftBackend`, proven over live Valkey against an in-Elixir conformant responder) — the cross-runtime equality carried by the shared fixtures. What eg.4 does **not** ship, **by ruling**, is a process that connects `echo_graft_backend` to a real Valkey socket: there is no Rust valkey client and no NIF (both §eg4-scope out-of-scope). A later rung **will** bind the Rust `Session` to the live bus — eg.5 (the low-latency write tier) or eg.6 (cross-compile + CI/deploy) **will** add the Rust-side bus transport (a real valkey client behind the `FeedSink`/command-lane seam, and/or the deferred NIF) so the backend runs as the deployed EchoMQ participant "beside Go workers" the §eg4-spec describes. Two as-built seams already anticipate that binding and **should be wired then**: the publish-only `transport::FeedSink` trait (a live binding maps `publish` to a bus `PUBLISH`) and the per-Volume `backpressure::Backpressure` cap (its `admit` is unwired in eg.4 — the live dispatch is its natural consumer; see the known-coverage note's sibling in the eg-4 ledger, UF-1). This is **forward-looking**: the binding is unbuilt and is **not** asserted as shipped.

> {style="note"}
> **Known coverage gap (Apollo un-prompted finding, eg.4 evaluation) — NON-BLOCKING.** The `dispatch::err_kind_of` mapping has **three arms**; only two are positively exercised. The `VolumeConcurrentWrite → conflict` arm is proven end-to-end (`conflicting_commits_one_acks_one_conflicts`), but the **`VolumeNotFound → not_found` arm is unexercised** — a mutation flipping it to `unavailable` **survives the whole suite** (mutation kill-rate 3/4). The wire still refuses cleanly (a missing Volume becomes *some* typed error, never a panic), so the closed-taxonomy + no-panic guarantees hold; only the *specific* `not_found` kind for a missing-Volume engine error is unpinned. A one-line follow-up test — drive a `Commit`/`Read`/`Snapshot` against an unknown vid through the dispatch and assert `Msg::Err{kind: not_found}` — would close it. Recommended for the eg.5 follow-on; not a ship blocker for eg.4.
