---
title: "eg.6 — Ship AND RUN fully integrated EchoMQ + Graft (BEAM↔Rust)"
id: echo-graft-6-ship
rung: eg.6
size: L
risk: HIGH
status: Draft
deferred: "DEFERRED — drafted now to capture the reframed scope; built once the fly.io EchoMQ deploy floor exists (the live integrated run stands on a deploy that is not yet ready). See §Status."
stands-on: "eg.1–eg.5"
---

# eg.6 — Ship AND RUN fully integrated EchoMQ + Graft (BEAM↔Rust) { id="echo-graft-6-ship" }

> _Stand the whole stack up live: the BEAM orchestrator and the Rust `echo_graft_backend`, integrated over EchoMQ, running as one system on a real deploy — then measure where the transactional+replicated durability tier lands with a per-workload shootout beside the native Elixir engine, Champ, and Oban. The earlier rungs proved the binding in isolation; this rung ships it and runs it for real._

## Status — DEFERRED { id="eg6-status" }

> {style="warning"}
> **eg.6 is DEFERRED.** This spec is drafted now to capture the reframed scope, but the rung is **not** built: the "**run fully integrated**" leg stands on a live **fly.io EchoMQ deployment that is not yet ready**, and that deploy floor is the reason for deferral. The spec records the target — the live integrated run, the per-workload shootout, the cross-compile + CI ship hardening, and the fly.io deploy substrate it all stands on — so the work is fully specified the moment the deploy floor exists.
>
> The frontmatter holds `status: Draft` (the spec is drafted, not shipped). The **program ladder** (`graft.roadmap.md` / `graft.progress.md`) carries the "Deferred" lifecycle marker; the Director sets that, not this spec.
>
> **What "not ready" means concretely.** There is no fly.io Dockerfile or `fly.toml` for EchoMQ yet, and the live Rust↔Valkey binding proven in eg.5 ran against a local Valkey on `:6390` — not a deployed bus. Until EchoMQ deploys (its own deploy artifacts + a reachable bus), the integrated system cannot be *run* anywhere but a developer machine, so the integration acceptance (crit 5/7 below) cannot be discharged. **This rung does not create the fly.io artifacts** — they are the deferred deliverable, recorded here, scaffolded when eg.6 is taken up.

## Summary { id="eg6-summary" }

Bring the durability tier from *proven in isolation* to *running integrated and measured*:

1. **Run fully integrated (BEAM↔Rust, live).** The eg.5 binding stood `echo_graft_backend` on a real Valkey socket and proved the cross-runtime contract end to end; eg.6 takes that from a single developer-machine round-trip to the **whole stack running integrated** — the BEAM orchestrator, the bus, and the Rust backend up together as one supervised system on a real deploy, serving real `EchoStore.GraftBackend` traffic. This is not packaging the artifact — it is the artifact **running**, integrated.
2. **The fly.io deploy substrate (the floor the live run stands on).** A fly.io Dockerfile + `fly.toml` for EchoMQ — the deployable bus the integrated system runs against. **Recorded here, not scaffolded**: the live-integrated leg is undeliverable until this floor exists, which is exactly why the rung is deferred.
3. **Ship hardening.** Cross-compile `echo_graft_backend` for the Mac orchestrator and the Windows RTX node, gate releases through CI (lint, the cross-runtime conformance suite, the determinism loop, the shootout battery), pin `echo_graft_proto` in lockstep across the BEAM release and the binary, and close the eg.5-carried **stdin-EOF watchdog** so the supervised backend reaps cleanly on parent exit.
4. **The per-workload durability shootout (D-5).** Measure single + batch durable-enqueue across the four durable contenders — the **native Elixir `EchoStore.Graft.*` engine**, the **Rust `echo_graft` engine**, **Champ**, and **Oban** — durability annotated transactional + replicated, recording *which workload each wins* rather than a single number. Memory and BullMQ appear only as **external baselines** (no fsync / bounded-1s), never inside the durable tier.

## Rationale { id="eg6-rationale" }

A spine that only round-trips on one developer machine is proven, not shipped. Three forces shape this rung:

- **Integration is the unmet half.** eg.5 proved the *binding* (one live socket, one round-trip, byte-equal fixtures, an incompatible peer refused). What it did not do is **run the whole stack integrated on a real deploy** — the BEAM, the bus, and the backend up together, supervised, serving real durability traffic. The "transactional+replicated quadrant" claim is only credible when the tier is *running* where a consumer can reach it, not just demonstrated in a test.
- **The deploy floor gates the integration.** "Run fully integrated" presupposes a deployed bus to integrate *over*. EchoMQ has no fly.io deploy artifacts yet, so the integration acceptance cannot be discharged — hence the deferral, and hence the fly.io Dockerfile/`fly.toml` being **the** substrate this rung must first record then build.
- **The shootout must say *which workload*, not a single digit (D-5).** The COEXIST ruling (D-1 = A) keeps two page engines — native Elixir and Rust — each aimed at a different workload (in-process/low-dep vs raw-page/deployable). A single throughput number would erase exactly the distinction the coexistence rests on, so the shootout is **per-workload** by ruling: native-engine vs Rust-engine vs Champ vs Oban, named workloads, durability annotated.

## 5W + H { id="eg6-5wh" }

| | |
|---|---|
| **Who** | Platform (Fireheadz); operators run the deployed, integrated system; EchoStore durability callers reach the Rust tier over the deployed bus. |
| **What** | The whole stack **running integrated** on a real deploy (BEAM ↔ EchoMQ ↔ `echo_graft_backend`), a cross-compiled + CI-gated release, a lockstep `echo_graft_proto` pin, the stdin-EOF watchdog closed, the fly.io EchoMQ deploy substrate (Dockerfile + `fly.toml`), and the per-workload durability shootout. |
| **When** | **Deferred** — last in the ladder (stands on eg.1–eg.5), taken up once the fly.io EchoMQ deploy floor exists. |
| **Where** | `apps/echo_graft` (Rust: cross-compile + the watchdog) · the `EchoStore.GraftBackend` seam in `echo_store` (the live integrated client) · the shootout harness (reads all four engines) · the fly.io deploy config (recorded, then authored). Native `EchoStore.Graft.*` UNTOUCHED (coexist, D-1 = A). |
| **Why** | Make the durability tier **deployable, integrated, and measured** — running where consumers reach it, with no silent protocol skew, and with its position in the durability spectrum measured per-workload rather than asserted. |
| **How** | A fly.io deploy floor for EchoMQ; the BEAM + bus + backend stood up integrated against it; cargo release profiles + cross-compilation; a CI matrix (lint → conformance → determinism → shootout); a lockstep protocol-version pin with refuse-on-mismatch; a stdin-EOF watchdog in `backend_main`; the per-workload shootout battery. |

## Scope { id="eg6-scope" }

### In scope

- **Run fully integrated (live).** Stand the BEAM orchestrator, the EchoMQ bus, and `echo_graft_backend` up together as one supervised system on a real deploy, serving real `EchoStore.GraftBackend` durability traffic over the deployed bus — the eg.5 single round-trip taken to the whole-stack integrated run.
- **The fly.io EchoMQ deploy substrate** — a Dockerfile + `fly.toml` for EchoMQ, the deployable bus the integrated run stands on. **RECORDED in this spec; authored when the rung is taken up — not scaffolded now** (it is the deferred deliverable).
- **Cross-compile** `echo_graft_backend` for the Mac orchestrator and the Windows RTX node; stripped release binaries.
- **CI matrix** — clippy/lint, build, the eg.4 cross-runtime conformance suite, the ≥100-iteration determinism loop, and the per-workload shootout battery.
- **Lockstep versioning** — the same `echo_graft_proto` version (PROTO_MIN = PROTO_MAX = 2, eg.5 D-5) embedded in the BEAM release and the sidecar binary; connection refused on mismatch (the eg.4 handshake, proven live on an incompatible peer in eg.5).
- **The stdin-EOF watchdog (ship hardening, eg.5-carried).** Close the backend-orphan gap: `backend_main` currently shuts down only on SIGINT or a closed serve loop and orphans to `ppid 1` when the BEAM `Port` closes; add a stdin-EOF watchdog (the standard BEAM-port pattern) so the supervised backend self-terminates on parent exit.
- **An operational runbook** — start the integrated system, health-check it, and recover the feed cursor after a sidecar restart.
- **The per-workload durability shootout (D-5)** — single + batch durable-enqueue across the native Elixir engine, the Rust `echo_graft` engine, Champ, and Oban; durability annotated transactional + replicated; recording which workload each wins.

### Out of scope

- The async-NIF hot-read optimization (a deferred post-eg.6 spec; the sidecar is the integration spine, `graft.roadmap.md:99,107`).
- Further performance passes (PGO/BOLT — a Graft future-work note; defer).
- Multi-region / cross-bucket replication (single Tigris bucket; `graft.roadmap.md:106`).
- Any change to the native `EchoStore.Graft.*` engine (untouched under D-1 = A) or to `github.local/graft` (read-only idea source).

## Specification { id="eg6-spec" }

### The integrated run (the headline)

The whole stack runs as one supervised system: the BEAM orchestrator boots, the EchoMQ bus is reachable on its deployed address, and `echo_graft_backend` is stood up as a supervised participant on that bus. `EchoStore.GraftBackend` clients reach the Rust tier over the deployed bus (not a local `:6390` socket as in eg.5), commit/read/snapshot/sync over the byte-frozen v2 wire, and observe commit-LSN advances on the `egraft:feed:{vol}` lane. The integration is *live* — a deployed bus, a deployed backend, real traffic — which is exactly why it cannot be discharged until EchoMQ deploys.

### The deploy floor

EchoMQ ships with a fly.io Dockerfile + `fly.toml` (the deploy artifacts EchoMQ presently lacks) so the bus is reachable as a deployed service. The integrated run stands on this floor. **This spec records the floor as the gating dependency; the artifacts themselves are authored when the rung is taken up.**

### Cross-compile + CI

The build matrix covers both targets, with early verification that the engine's dependency tree (Fjall, the async runtime, the OpenDAL object-storage client) builds on Windows. CI stages run in order: lint → build → conformance → determinism (≥100) → shootout, and the per-workload `echo_graft` results are recorded. Release units are pinned: the BEAM release and the sidecar binary embed the same `echo_graft_proto` version (PROTO_MIN = PROTO_MAX = 2), and a version mismatch on connect is refused and logged — no silent skew (the eg.4 handshake; eg.5 proved an incompatible peer is refused on the live wire).

### The stdin-EOF watchdog

`backend_main`'s shutdown `select!` watches only `ctrl_c` and the serve loop today (`backend_main.rs`, eg-5 Y-5), so a BEAM `Port.close` shuts the pipe but does not signal the child — it reparents to `ppid 1` and leaks Valkey connections (eg-5 L-3: orphaned backends survived a green `mix` exit; the interim reap is `pkill -f target/debug/echo_graft_backend`). eg.6 adds a stdin-EOF watchdog: when the parent closes the port, stdin reaches EOF and the watchdog triggers a clean shutdown, so the supervised backend reaps itself on parent exit.

### The per-workload shootout (D-5)

The shootout battery measures single + batch durable-enqueue across the **four durable contenders** — the native Elixir `EchoStore.Graft.*` engine, the Rust `echo_graft` engine, Champ, and Oban — over the integrated, live path where applicable. The durability column reads transactional + replicated for the two Graft engines, bounded-K for Champ, strict-per-commit for Oban. **Memory and BullMQ appear only as external baselines** (no fsync to amortize / Redis-AOF bounded-1s) — they are *not* in the durable tier (they do not satisfy transactional + replicated). The result records **which workload each contender wins**, not a single throughput digit — the coexistence (D-1 = A) rests on the two page engines serving different workloads, so the measurement must surface that split.

## Acceptance criteria { id="eg6-acceptance" }

> Forward-tense: eg.6 is deferred; these criteria specify what the built rung **will** prove, discharged once the deploy floor exists. No number below is asserted as measured.

1. **Given** the release pipeline, **when** invoked, **then** it produces `echo_graft_backend` binaries for both targets (Mac + Windows), each embedding the same pinned `echo_graft_proto` version (PROTO_MIN = PROTO_MAX = 2) as the BEAM release.
2. **Given** CI, **when** it runs, **then** lint, the cross-runtime conformance suite, the ≥100-iteration determinism loop, and the per-workload shootout battery all pass, and the `echo_graft` results are recorded.
3. **Given** a BEAM release at a mismatched protocol version, **when** it connects to a deployed backend, **then** the connection is refused and the mismatch is logged (the eg.4 handshake; the eg.5 live-wire refusal carried forward).
4. **Given** the per-workload shootout battery, **when** run, **then** `echo_graft` (Rust) and the native `EchoStore.Graft.*` engine each report single and batch durable-enqueue jobs/s with durability annotated transactional + replicated, **beside Champ and Oban**, and the result names which workload each wins; Memory and BullMQ appear only as external baselines, outside the durable tier.
5. **Given** the whole stack deployed and **running integrated** (BEAM ↔ deployed EchoMQ ↔ `echo_graft_backend`), **when** `EchoStore.GraftBackend` clients drive real durability traffic over the deployed bus, **then** commit/read/snapshot/sync succeed end to end and commit-LSN advances are observed on the `egraft:feed:{vol}` lane — the integrated system runs, not just the binding.
6. **Given** the Windows target, **when** the dependency tree is built, **then** it compiles and the conformance suite passes there as well as on the Mac target.
7. **Given** a `backend_main` running under the BEAM `Port` and a parent exit (Port close), **when** stdin reaches EOF, **then** the stdin-EOF watchdog triggers a clean shutdown and the backend self-terminates — no orphan reparented to `ppid 1`, no leaked Valkey connections.
8. **Given** a sidecar restart under production-shaped load on the deployed bus, **when** clients reconnect, **then** they resume from their feed cursor with no lost committed LSNs.

## Stories { id="eg6-stories" }

> Each Deliverable → a Connextra story + Given/When/Then acceptance + the invariant it exercises (the `eg.*` inline-brief convention; no separate `.stories.md`). The Coverage line maps every Deliverable → its story.

- **S-1 — Run fully integrated (live).** *As a platform operator, I want the BEAM, the EchoMQ bus, and `echo_graft_backend` running integrated on a real deploy, so that the durability tier serves real consumers, not just a test round-trip.* **Given** the deployed stack, **when** `EchoStore.GraftBackend` drives commit/read/snapshot/sync over the deployed bus, **then** it succeeds end to end and feed advances are observed. **Invariant:** the integrated path uses the byte-frozen v2 wire; the bus is the contract (`graft.roadmap.md:59`). **(crit 5)**
- **S-2 — The fly.io deploy floor.** *As a platform operator, I want EchoMQ deployable on fly.io, so that the integrated system has a reachable bus to run against.* **Given** the fly.io Dockerfile + `fly.toml` (authored when the rung is taken up), **when** EchoMQ is deployed, **then** the bus is reachable as a service and S-1 can be discharged. **Invariant:** the deploy floor gates the integration — eg.6 is deferred until it exists; the artifacts are recorded here, not scaffolded. **(scope gate; enables crit 5)**
- **S-3 — Cross-compiled, version-pinned release.** *As a release engineer, I want `echo_graft_backend` cross-compiled for Mac + Windows with a lockstep proto pin, so that I deploy beside Go workers on either target with no protocol skew.* **Given** the pipeline, **when** invoked, **then** both binaries embed PROTO_MIN = PROTO_MAX = 2 matching the BEAM release; a mismatch is refused on connect. **Invariant:** byte-frozen wire + lockstep version pin (gate 3). **(crit 1, 3)**
- **S-4 — CI gates every release.** *As a release engineer, I want CI to run lint → conformance → determinism → shootout in order, so that no release ships unmeasured or unverified.* **Given** CI, **when** it runs, **then** all stages pass and the `echo_graft` shootout results are recorded; Windows compiles and passes conformance too. **Invariant:** determinism ≥100 on any new mint/lease/commit surface (gate 4); the carved runtime keeps upstream parity (gate 1). **(crit 2, 6)**
- **S-5 — The backend reaps cleanly on parent exit.** *As a platform operator, I want the supervised backend to self-terminate when the BEAM port closes, so that a restart leaves no orphaned process holding Valkey connections.* **Given** `backend_main` under the BEAM `Port`, **when** the parent exits and stdin reaches EOF, **then** the watchdog triggers a clean shutdown — no `ppid 1` orphan, no leaked connections. **Invariant:** ship hardening of the eg.5-carried orphan gap (eg-5 L-3 / D-8); no silent process leak. **(crit 7)**
- **S-6 — The per-workload durability shootout.** *As a platform architect, I want single + batch durable-enqueue measured per-workload across the native engine, the Rust engine, Champ, and Oban, so that the transactional+replicated tier's position is measured, not asserted, and the coexistence is justified by which workload each wins.* **Given** the shootout battery, **when** run, **then** each durable contender reports single + batch throughput with durability annotated, naming the workload each wins; Memory/BullMQ are external baselines only. **Invariant:** D-5 (per-workload, not a single number); the durable tier is exactly {native Elixir, Rust, Champ, Oban}. **(crit 4)**
- **S-7 — Feed-cursor recovery after restart.** *As an EchoStore caller, I want to resume from my feed cursor after a backend restart on the deployed bus, so that no committed LSN is lost across the restart.* **Given** a sidecar restart under production-shaped load, **when** clients reconnect, **then** they resume from their cursor with no lost committed LSNs. **Invariant:** the change-feed is ordered + idempotent-per-LSN, replayable from a last-seen LSN (`feed.rs` `events_since`, eg.3; README.md:158-176). **(crit 8)**

**Coverage:** S-1 → crit 5 · S-2 → scope gate (enables crit 5) · S-3 → crit 1, 3 · S-4 → crit 2, 6 · S-5 → crit 7 · S-6 → crit 4 · S-7 → crit 8. Every Deliverable in §Scope maps to a story; every acceptance criterion is exercised by a story.

## Build brief { id="eg6-brief" }

> Folded inline (the `eg.*` convention). The runbook (`graft.6.prompt.md`) is authored when the rung is taken up; until then this brief is the build contract. **Build nothing now** — the rung is deferred.

### References (read first)

- **Standing brief + as-built map:** `echo/apps/echo_graft/README.md` (eg.1–eg.5 SHIPPED; the Build & test gate ladder incl. `--features precept` + `ECHO_GRAFT_BACKEND_TEST=1`).
- **The COEXIST ruling + D-5:** `docs/graft/graft.engine-split.design.md` (§7: D-1 = A coexist; D-5 = per-workload shootout, native vs Rust vs Champ vs Oban).
- **The eg.5 ledger (the carried debt + the live binding):** `docs/graft/eg-5.progress.md` (L-3 the backend-orphan / stdin-EOF watchdog; D-5 the v2 wire drop-v1; Z-1 the SHIPPED footprint).
- **The roadmap:** `docs/graft/graft.roadmap.md` (the rung ladder, the cross-cutting gates §6, the sidecar-not-NIF integration posture §3).
- **The proto wire (frozen at v2):** `echo/apps/echo_graft/crates/echo_graft_proto/src/lib.rs` (PROTO_MIN = PROTO_MAX = 2; `Msg::Commit { …, mode, … }`; the strict-arity decoder).
- **The backend entry (the watchdog site):** `echo/apps/echo_graft/crates/echo_graft_backend/src/backend_main.rs` (the shutdown `select!` — ctrl_c + serve, no stdin today).

### Requirements (numbered; each traced to a story + a gate)

1. Author the fly.io EchoMQ deploy artifacts (Dockerfile + `fly.toml`) → S-2 (the deploy floor; the gating dependency).
2. Stand the integrated stack up against the deployed bus; point `EchoStore.GraftBackend` at the deployed address (not local `:6390`) → S-1, gate 5.
3. Cross-compile `echo_graft_backend` for Mac + Windows; lockstep the proto pin → S-3, gates 1/3.
4. Add the CI matrix (lint → build → conformance → determinism → shootout) → S-4, gates 2/6, cross-cutting gates §6.
5. Add the stdin-EOF watchdog to `backend_main` → S-5, gate 7.
6. Build the per-workload shootout battery (native Elixir, Rust, Champ, Oban; Memory/BullMQ baselines) → S-6, gate 4, cross-cutting gate §6.5.
7. Prove feed-cursor recovery across a restart on the deployed bus → S-7, gate 8.

### Execution topology

- **Runtime shape:** BEAM orchestrator (Elixir) ↔ deployed EchoMQ (RESP3) ↔ `echo_graft_backend` (Rust, supervised) ↔ Tigris (OpenDAL). The integrated, deployed form of the eg.4/eg.5 topology (`graft.roadmap.md:35-57`).
- **Build order (task DAG):** deploy floor (1) → integrated run (2) ∥ stdin-EOF watchdog (5) → cross-compile + pin (3) → CI (4) → shootout (6) → recovery proof (7). The deploy floor (1) gates 2/7; the watchdog (5) and cross-compile (3) are independent of the deploy and can land first.
- **Files touched:** `apps/echo_graft/crates/echo_graft_backend/src/backend_main.rs` (watchdog); the cross-compile release config (cargo profiles); CI config; the shootout harness (reads all four engines); the `EchoStore.GraftBackend` deployed-address wiring in `echo_store`; the fly.io Dockerfile + `fly.toml` for EchoMQ. **NOT touched:** native `EchoStore.Graft.*`; `echo_graft_proto` engine bytes (frozen at v2); `github.local/graft`.

### Agent stories (Directive + Acceptance gate)

- **Directive:** Add the stdin-EOF watchdog to `backend_main`. **Acceptance gate (contract):** *precondition* — a `backend_main` running under a BEAM `Port`; *postcondition* — on Port close (stdin EOF) the process exits cleanly with no `ppid 1` orphan and zero leaked Valkey connections; *invariant* — the shutdown path remains the only termination route (ctrl_c, closed serve, or stdin-EOF), no new wire or behaviour. **A no-op must not satisfy this:** the gate must spawn the backend under a real Port, close it, and assert the process is gone + connection count returns to baseline (the eg.5 reap reproduced positively, then closed) — a test that never spawns-and-closes proves nothing.
- **Directive:** Build the per-workload shootout battery. **Acceptance gate (contract):** *precondition* — the four durable engines reachable (native in-process; Rust over the integrated bus; Champ; Oban on Postgres); *postcondition* — single + batch durable-enqueue measured for each, durability annotated, the winning workload named per contender; *invariant* — Memory/BullMQ are baselines only, never counted in the durable tier; the two Graft engines both read transactional + replicated. **A no-op must not satisfy this:** an absent engine (e.g. Oban without Postgres) is a LOUD failure under explicit opt-in, never a silent skip-or-pass — the battery names what it could not run.
- **Directive:** Stand the integrated stack up and prove crit 5 on the deployed bus. **Acceptance gate (contract):** *precondition* — EchoMQ deployed (S-2) + the backend deployed beside it; *postcondition* — `EchoStore.GraftBackend` commit/read/snapshot/sync succeed over the deployed bus + feed advances observed; *invariant* — the byte-frozen v2 wire; lane disjointness (`egraft:*` ⊥ native `graft:*`). **A no-op must not satisfy this:** the proof runs against the *deployed* bus, not a local `:6390` socket — an env that silently falls back to local fails the integration's letter.

### The prompt (a short comprehensive directive for the build)

Ship AND run the fully integrated EchoMQ + Graft stack (BEAM ↔ Rust over EchoMQ), then measure it per-workload — only once the fly.io EchoMQ deploy floor exists. Author the fly.io Dockerfile + `fly.toml` for EchoMQ; stand the BEAM, the deployed bus, and `echo_graft_backend` up together as one supervised, integrated system; point `EchoStore.GraftBackend` at the deployed bus; cross-compile the backend for Mac + Windows with a lockstep `echo_graft_proto` v2 pin (refuse-on-mismatch); gate releases through a CI matrix (lint → conformance → determinism ≥100 → shootout); close the stdin-EOF watchdog so the supervised backend reaps cleanly on parent exit; and run the per-workload durability shootout across the native Elixir engine, the Rust engine, Champ, and Oban (Memory/BullMQ baselines only), recording which workload each wins. The proto is frozen at v2 — no new wire; the shootout reads engines; fly.io adds deploy config, not wire. Native `EchoStore.Graft.*` and `github.local/graft` are untouched. Dual gate ladder per `echo/apps/echo_graft/README.md` (Rust: `cargo test --workspace` + `--features precept` `--test-threads=1` + clippy + the ≥100 loop; Elixir: the `echo_store` mix ladder on the deployed bus with dual-side byte-equal conformance). Per-app testing only; agents run no git; the Director commits by pathspec when asked.

## Dependencies & risks { id="eg6-risks" }

- **Depends on:** eg.1–eg.5, **and the fly.io EchoMQ deploy floor** (the deferral root — the integrated run is undeliverable without a deployed bus).
- **Risk — the deploy floor is the gate.** "Run fully integrated" cannot be discharged until EchoMQ deploys; eg.6 is deferred precisely on this. The fly.io Dockerfile/`fly.toml` is the first build step when the rung is taken up.
- **Risk — Windows cross-compile.** The engine's native deps (Fjall, the async runtime, the OpenDAL client) must build on the target; verify early rather than at ship time (crit 6).
- **Risk — protocol skew across release units.** The lockstep v2 pin plus refuse-on-mismatch (crits 1/3) is the guard; eg.5 proved the live-wire refusal on an incompatible peer.
- **Risk — backend orphan (eg.5-carried).** Closed by the stdin-EOF watchdog (crit 7); until built, the interim is the documented `pkill` reap (`backend.md`, eg-5 L-3).
- **Risk — the shootout could collapse to one number.** D-5 forbids it: the measurement is per-workload, naming which contender wins which workload, or the coexistence rationale is unmeasured.

## Cross-cutting gates (from `graft.roadmap.md` §6) { id="eg6-xgates" }

Every rung is done only when these hold, in addition to its own acceptance: upstream parity (the carved runtime keeps Graft's Volume/transaction tests green) · declared keys (every remote object key + EchoMQ field enumerated — eg.6 adds none; the proto is frozen at v2, fly.io adds deploy config) · byte-frozen wire (`echo_graft_proto` v2 frozen; no silent edit) · determinism loop (≥100 on any new mint/lease/commit surface) · shootout battery (the durable-enqueue path measured, recorded beside Champ/Oban — here, per-workload) · no scheduler block (no NIF in the spine) · license retained (upstream MIT/Apache-2.0 headers preserved).
