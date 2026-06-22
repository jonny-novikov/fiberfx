# Claude Agent — echo_graft eg.5 Build Prompt

> The orchestration runbook for **eg.5** (the low-latency write tier **+** the live Rust↔Valkey binding) under the `/graft-ship` lead-team. The authoritative scope is `docs/graft/specs/graft.5.md`; this prompt is the run's stage map. Mars builds to `graft.5.md` §eg5-brief; the Director verifies; Apollo (REQUIRED — HIGH risk) renders the verdict.

---

You are building **eg.5** of echo_graft — a hard-fork Rust durability engine re-seamed for the EchoMQ platform. You work to the spec already in this repo; you do not improvise architecture. eg.4 is shipped (the byte-frozen `echo_graft_proto` wire, the `echo_graft_backend` session+dispatch shell proven in-process, the `EchoStore.GraftBackend` BEAM client proven over live Valkey against an in-Elixir responder). eg.5 adds the write tier AND binds the backend to a real socket.

## Read first (authoritative)

- `docs/graft/specs/graft.5.md` — THIS rung: rationale, 5W+H, scope (in/out), specification, **8 Given/When/Then acceptance criteria**, the folded build brief (§eg5-brief: references, agent stories S-1..S-8, declared keys, fixture posture, gate ladder, build order), and the **ruled** decisions (§eg5-open-decisions D-A1/D-A2/D-A3 — build to them).
- `docs/graft/specs/graft.4.md` — the foundation: the wire, the declared keys, the version-negotiation contract, the D-7 deferral eg.5 discharges, the UF-1/UF-2 follow-ons.
- `docs/graft/eg-4.progress.md` — UF-1 (the unwired `Backpressure::admit` cap), UF-2 (the unexercised `not_found` arm), L-2 (the determinism-loop-vs-concurrent-build hazard), L-3 ("tested in isolation ≠ wired in").
- `docs/graft/graft.engine-split.design.md` — D-1 = COEXIST: the native `EchoStore.Graft.*` engine is UNTOUCHED; the Rust path is a coexisting peer.
- `echo/apps/echo_graft/README.md` — the standing development brief (NO upstream compat; the Rust gate ladder; fault suites `--test-threads=1`).

Treat the 8 Given/When/Then criteria as the definition of done. Do not exceed the rung's declared scope (no eg.6 cross-compile/CI/shootout; no NIF).

## Mission (one paragraph)

Put a bounded local-fsync group-commit buffer in front of the eg.2 remote commit, with a pure clock-injected shaping core (min_size OR timeout) and a per-call `:async`/`:sync` durability mode — and stand `echo_graft_backend` up on a **real Valkey :6390 socket** so it consumes `egraft:cmd:{vol}`, dispatches onto the real `Runtime` via the existing `Session::handle_frame`, and serves real `EchoStore.GraftBackend` clients over the byte-frozen wire (the eg.4 contract, proven compositionally, now proven literally). Wire UF-1's dormant `Backpressure::admit` cap into that live in-flight path. The native Elixir engine stays untouched; `egraft:*` lanes stay distinct from native `graft:{vol}:commits`.

## The boundary (hard — do not cross)

1. **Edit only `echo/apps/echo_graft` (the Rust crates) + the one named `echo_store` seam** (the live-leg test + any thin client touch the live binding needs). No third umbrella app.
2. **The native `EchoStore.Graft.*` engine is UNTOUCHED** (`apps/echo_store/lib/echo_store/graft/*` — empty diff). eg.5 ADDS the live Rust path beside it (D-1 = COEXIST).
3. **`github.local/graft` is read-only** — never touched.
4. **The `echo_graft_proto` wire** — the ruled D-A1 (drop v1; `COMMIT` as v2 in place) **intentionally regenerates** the `COMMIT` + handshake fixtures (`PROTO_MIN = PROTO_MAX = 2`), proven by the dual-side conformance; **every non-v2-touched fixture** (`FeedEvent`, `PUSH`, `PULL`, …) stays byte-identical to HEAD, and a silent re-encode of any of THOSE is a LOUD failure (gate G3).
5. **The engine (`crates/echo_graft`) stays byte-frozen** — eg.5 is a backend-crate + transport rung; no engine logic edits (the eg.4 observe-then-republish discipline: the `Runtime` is not modified).
6. **Declared keys** — every lane/field the live binding touches is in `graft.5.md` §eg5-declared-keys; nothing undeclared appears on the wire.
7. **Do not invent signatures.** Every surface in §eg5-brief is cited to a real file:line; confirm against source before calling. If unclear, read the source.

## Ground truth (verified — do not re-derive)

- **The transport seams the live binding wraps** are eg.4's, unchanged: `Session::handle_frame(&[u8]) -> Vec<u8>` (`crates/echo_graft_backend/src/session.rs:99`, the request entry) and the publish-only `FeedSink` trait (`crates/echo_graft_backend/src/transport.rs:24`). The live transport adds **I/O only** — it does not change the handshake, dispatch, error taxonomy, page-size realization, or feed-republish.
- **The cap to wire (UF-1)** is `Backpressure::admit(vol) -> Option<Permit>` (`crates/echo_graft_backend/src/backpressure.rs:66`, default cap 64 `:32`); the `Permit` releases on drop (`:103`). It is called **nowhere** in `session.rs`/`dispatch.rs` today (grep-confirm) — eg.5's live transport is its consumer. The control lane is exempt by construction (`:12-23`).
- **The wire is hand-rolled positional RESP3, NOT bilrost** (`crates/echo_graft_proto/src/lib.rs`): `Msg::to_parts`/`from_parts` (`:359,404`), `encode_parts`/`decode_parts` (`:73,91`), `PROTO_MIN=PROTO_MAX=1` **today** (`:32-34` — D-A1 sets both to `2`). The `Commit` decode is **strict-arity** (`:444-461`: `if tail.len() != npages*2 { Err(BadField) }`). Under the ruled D-A1 (drop v1; `COMMIT` as v2+) the strict arity is simply UPDATED for the new in-place `mode` field — v1 is dropped (no deployed consumer), so there is no v1 decode path to keep compatible and `COMMIT` is modified in place, not forked to a `COMMIT2`.
- **No redis/valkey client is vendored** — `Cargo.lock` carries `tokio`, `bytes`, `opendal`, `reqwest`, `bilrost`, `parking_lot`, none redis/valkey/fred/rustis (grep-confirmed). `encode_parts`/`decode_parts` are byte-identical to `EchoMQ.RESP.encode/1` (`lib.rs:70-71`). So the ruled transport (D-A2) is a raw RESP3 socket reusing the proto codec over the already-vendored `tokio` — no new client dep.
- **The buffer rolls up into** `volume_push` (`crates/echo_graft/src/rt/runtime.rs:239`) which fences (the eg.2 conditional write) + publishes the feed advance (`:250-279`); `volume_writer` (`:298`) stages pages.
- **The eg.4 live leg** (`apps/echo_store/test/echo_store/graft_backend/live_round_trip_test.exs`) runs the client over real Valkey :6390 against an **in-Elixir conformant responder** (`:81-100`); eg.5 re-points that leg's responder at the **real Rust backend** for criterion 7.

## The three forks are RULED — build to the rulings (no open gate)

The Operator ruled all three forks (2026-06-22, via `AskUserQuestion`; each Director-verified against source), and **D-A1 was subsequently superseded by an Operator directive** ("drop v1 compatibility; use `COMMIT` as v2+"). The authoritative record is `docs/graft/eg-5.progress.md` §eg5-decisions (**D-5** = the wire directive, D-3 transport, D-4 buffer), folded into `graft.5.md` §eg5-open-decisions (D-A1/D-A2/D-A3). Build to them — there is no open gate:

- **D-A1 (build step 2) — DROP v1; `COMMIT` as v2+.** `Msg::Commit` gains a fixed-position `mode` field (`async`|`sync`), modified **in place** (NOT a `COMMIT2`); `PROTO_MIN = PROTO_MAX = 2` (the handshake negotiates only v2; a v1 peer fails by design). **Single** conformance generation — the `COMMIT` + handshake fixtures are REGENERATED for v2 (not byte-frozen to HEAD) and proven by the dual-side Rust-encode==Elixir-encode conformance; every non-v2-touched fixture stays byte-frozen to HEAD. The `:sync` default lives in the **client API** (`push` defaults the mode to `:sync`, always encodes it) — not a wire default.
- **D-A2 (build step 4)** — the Rust→Valkey transport is a **raw RESP3 socket reusing the proto codec**: a thin `tokio` loop reusing `encode_parts`/`decode_parts` for payloads + the flat-array pub/sub envelope; only `HELLO 3` + the read loop are new wire code; no new client dep. The live leg stays env-gated (`ECHO_GRAFT_BACKEND_TEST`). (A-2b mature client ruled against.)
- **D-A3 (build steps 1 + 3)** — the buffer reuses the engine's **Fjall** local store; criterion 4 proven by a fault test (fsync the open batch → crash before `volume_push` → restart → unaccounted ⊆ the open batch).

## Build order (each a stop-and-verify step — `graft.5.md` §eg5-build-order)

1. **The pure shaping core + the bounded buffer** (no wire change). Clock-injected `BatchShaper`-style core (min_size OR timeout) + the per-Volume buffer (accept → batch → fsync → roll up via `volume_push`). *Verify:* deterministic flush (S-3), order (S-5), one fsync/batch (S-1), the loss-window query (S-6).
2. **The `:async`/`:sync` durability mode** (ruled D-A1 = drop v1, `COMMIT` as v2 in place). Add a fixed-position `mode` field (`async`|`sync`) to `Msg::Commit` **in place** (`lib.rs:264-273` struct, `:374-381` `to_parts`, `:444-461` `from_parts` — update the strict arity for the new field), set `PROTO_MIN = PROTO_MAX = 2` (`lib.rs:32-34`), **regenerate** the `COMMIT` + handshake fixtures (the v1 generation is dropped — no second generation, no v1 decoder path), update **both** conformance suites to assert byte-equality on the regenerated fixtures + the decode round-trip. The exact `mode` field position + token bytes is the one build-realization detail you pin against the regenerated fixture. Default the mode to `:sync` **in the client API** (`EchoStore.GraftBackend.commit/push` always encodes it) — not a wire default. *Verify:* `:sync` acks downstream of `volume_push` (S-2); the single conformance generation green (Rust-encode == Elixir-encode on the regenerated fixtures); `PROTO_MIN = PROTO_MAX = 2`, no v1 decoder path remains; every non-v2-touched fixture byte-identical to HEAD.
3. **Crash recovery for the open batch.** *Verify:* S-4 (crash after fsync / before push → unaccounted ⊆ open batch; fault suite `--test-threads=1`).
4. **The live Valkey transport** (ruled D-A2 = raw RESP3 socket). New transport module — a thin `tokio` socket loop reusing `encode_parts`/`decode_parts` (`lib.rs:73,91`) for both payloads and the flat-array pub/sub envelope (`HELLO 3` + the read loop are the only new wire code; no new client dep): connect :6390 RESP3, `SUBSCRIBE` command + control lanes, call `Session::handle_frame` per request, `PUBLISH` reply on `egraft:reply:{client_id}`, bind a live `FeedSink` → `PUBLISH` on `egraft:feed:{vol}`. *Verify:* the env-gated end-to-end leg over real :6390 against the REAL backend (S-7); byte-freeze re-verified.
5. **Wire the cap (UF-1) + close UF-2.** Consult `admit(vol)` in the live transport before dispatch; over-cap → `Msg::Err{Unavailable}`; control lane exempt. Add the UF-2 unknown-vid → `not_found` test. *Verify:* S-8 (flood A → A refused, B flows; **grep** proves `admit` called from the live path — the L-3 precept); the `not_found` arm now mutation-killed.
6. **Full dual gate + the determinism loop** (ISOLATED — the L-2 precept). *Verify:* the gate ladder, both runtimes; final byte-freeze check.

Stop at each step's acceptance boundary and report before the next.

## Verification — the dual gate ladder (run before reporting; `graft.5.md` §eg5-gates)

**Rust (`cd echo/apps/echo_graft`):**
- `TMPDIR=/tmp cargo test --workspace` — parity baseline + eg.2/3/4 + the new buffer/transport/cap tests, all green.
- `TMPDIR=/tmp cargo clippy --workspace` — the new code adds 0 warnings (the pre-existing eg.1–3 warnings are not a regression).
- `TMPDIR=/tmp cargo test -p echo_graft_backend conformance` — the shared fixtures byte-frozen (re-verified; criterion 7).
- `TMPDIR=/tmp cargo test -p echo_graft_test -- --test-threads=1` — fault suites (the eg.3 precept-global-state race).
- The **≥100 determinism loop** on the commit/binding surface, run **ISOLATED** (no concurrent cargo — a relinking build mid-loop is the eg.4 L-2 harness artifact, not a defect).

**Elixir (`cd echo/apps/echo_store`):**
- `asdf current` (re-probe; never hardcode) · `valkey-cli -p 6390 ping` → PONG.
- `TMPDIR=/tmp mix compile --warnings-as-errors` — **zero-NEW-warnings** (2 pre-existing echo_store warnings are not a regression — eg.4 Y-1).
- `TMPDIR=/tmp mix test` — the conformance test asserts byte-equality vs the SAME fixtures.
- `ECHO_GRAFT_BACKEND_TEST=1 TMPDIR=/tmp mix test --include valkey` — the end-to-end leg vs the **REAL** `echo_graft_backend` (criterion 7).

**The liveness rule (HIGH-risk, load-bearing):** criterion 7's live leg MUST exercise a PRESENT, running backend over a real socket and assert the round-trip. Env gate unset → the leg is **reported excluded, never trivially passed** (the eg.4 `:valkey`-tag posture). A skip-or-pass shape does not satisfy the criterion.

**The byte-freeze rule (HIGH-risk), under D-A1:** (a) the `COMMIT` + handshake fixtures are INTENTIONALLY regenerated for v2 → verify **Rust-encode == Elixir-encode** on the NEW fixtures (the dual-side conformance is the cross-runtime proof, NOT a HEAD-diff); (b) **every non-v2-touched fixture** (`FeedEvent` 51-byte, `PUSH`, `PULL`, …) stays byte-identical to HEAD, and a silent re-encode of any of THOSE is a LOUD failure; (c) `PROTO_MIN = PROTO_MAX = 2` confirmed, no v1 decoder path remains.

## The pipeline (the `/graft-ship` Flat-L2 lead-team — Apollo REQUIRED)

1. **Venus** (this rung's first agent) — reconciled `graft.5.md` + authored `graft.5.prompt.md`; surfaced A-1/A-2/A-3, the Operator **ruled** them (D-A1/D-A2/D-A3), and Venus folded the rulings into both specs. (DONE on entry — the brief is RESOLVED, no open gate.)
2. **Mars-1** — build steps 1–6 to the brief; the dual gate green; report per-step.
3. **Director** — independent dual-gate re-run + an adversarial probe (declared-keys, byte-freeze, a net-zero mutation spot-check incl. the `admit`-call-site grep and the `not_found` arm); findings → Mars-2.
4. **Mars-2** — remediate + harden (REMEDIATE MAX 3).
5. **Apollo (REQUIRED)** — the §11.2 adversarial charter on the live path: re-run both gates independently, re-verify the byte-freeze, attack the live transport (hostile frames, an at-the-cap flood, an incompatible handshake over the real socket), confirm the `admit` call site is wired (the L-3 precept) and the `not_found` arm is killed, render the BUILD-GRADE verdict + the spec-sync.
6. **Director** — ship to the working tree (no commit unless the Operator asks; the whole `echo_graft` + `docs/graft` tree is untracked on the `echo_mq` branch, as eg.1–eg.4 shipped).

## Report format (end of each rung)

- **Shipped:** what now exists, by crate/module.
- **Acceptance:** each of the 8 Given/When/Then, pass/fail with the test that proves it (criterion 7's live leg ran against the REAL backend; criterion 8's `admit` call site grep-confirmed).
- **Gates:** dual ladder (Rust workspace + conformance + fault + determinism; Elixir conformance + the live leg), byte-freeze, declared keys — pass/fail.
- **Forks:** how A-1/A-2/A-3 were ruled and what was built to the ruling (one line each).
- **Deviations:** anything realized differently from the spec and why (one line each — the eg.4 realization discipline).
- **Next:** the eg.6 entry conditions (cross-compile + CI + the shootout over this now-proven-live path) and any decision the Operator owes.

## Do not

- Exceed the rung's scope (no eg.6 cross-compile/CI/shootout; no NIF; no tuning-controller).
- Touch the native `EchoStore.Graft.*` engine, `github.local/graft`, or a third umbrella app.
- Silently re-encode any **non-v2-touched** wire message (`FeedEvent`, `PUSH`, `PULL`, …) — those stay byte-identical to HEAD. (`COMMIT` + the handshake ARE intentionally regenerated for v2 under D-A1 — proven by the dual-side conformance, not a HEAD-diff.)
- Ship criterion 7 with a skip-or-pass live leg, or criterion 8 with a unit-test-only cap (the L-3 trap — the production call site must consult `admit`).
- Reopen A-1/A-2/A-3 — they are RULED (D-A1/D-A2/D-A3, §eg5-open-decisions); build to the rulings. Surface any NEW fork the build uncovers, but do not relitigate a settled one.
- Commit unless the Operator asks; pathspec only, never `git add -A`.
