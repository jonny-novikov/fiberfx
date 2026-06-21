---
name: graft-ship
description: >-
  Use this skill to ship ONE spec-driven rung of the echo_graft epic — the from-scratch Rust durability engine
  at echo/apps/echo_graft (seeded from orbitinghail/graft, NO upstream compat) and its BEAM-facing seams in
  echo/apps/echo_store — any rung whose slug matches eg.* (eg.1 … eg.6), end to end through the x-mode Flat-L2
  lead-team, Director-supervised, to the working tree (or scoped LAW-4 commits when the Operator asks). It is
  /x-mode with the echo_graft context pre-loaded: it adds nothing to the laws — it binds them to the Rust+Elixir
  CROSS-RUNTIME work (the GENERIC venus/mars/apollo charters, no echo-mq-* skills), the DUAL gate ladder (cargo
  --workspace + clippy + the ≥100 determinism loop + fault suites --test-threads=1 + TMPDIR=/tmp, AND — for a
  BEAM-facing rung — the echo_store mix ladder on Valkey 6390 with dual-side byte-equality conformance), the
  no-upstream-compatibility law, the byte-frozen echo_graft_proto wire, and the COEXIST boundary (the native
  EchoStore.Graft.* engine is UNTOUCHED). The INPUT is the rung's docs/graft/specs/graft.<N>.md spec (+ its
  .prompt.md runbook if present; else Venus authors the build brief inline); the canon is
  docs/graft/graft.roadmap.md + the standing brief echo/apps/echo_graft/README.md + the design doc
  docs/graft/graft.engine-split.design.md. Triggers: "ship eg.4", "graft-ship eg.5", "run/launch the eg.N
  pipeline", "as Director fan out the eg.N lead-team". Do NOT use for the echo_mq bus (/echo-mq-ship), the
  static-HTML courses (the *-course-writer skills), the read-only reference checkout github.local/graft, or
  generic documents.
argument-hint: <rung> (eg.1 … eg.6)  ·  empty (the next unshipped rung per the roadmap)
---

# GRAFT-SHIP — ship an echo_graft rung via the supervised lead-team

Ship ONE spec-driven rung of the **echo_graft epic** — the from-scratch Rust Volume engine at
`echo/apps/echo_graft/` (transactional commits, an LSN log, an OpenDAL→Tigris remote with a conditional-write
fence, branded-id identity, an EchoMQ change-feed) and, from `eg.4`, its BEAM-facing client seam in
`echo/apps/echo_store` — end to end through the x-mode Flat-L2 lead-team, Director-supervised, to the **working
tree** (the current git posture) or to **scoped LAW-4 commits** when the Operator asks. It is **`/x-mode` with the
echo_graft context pre-loaded**: it adds nothing to the laws — it binds them to the Rust+Elixir cross-runtime
work so the run does not re-derive them.

**It is a binding layer, not a re-implementation.** Defer to the sources of truth:

1. **`.claude/commands/x.md` + the `/x-mode` skill** — the LAWS (CLAUDE_LAWS 1/1a/2/3/4), the pipeline (Venus
   strawman/reconcile + Arms → Director rules the Arms via `AskUserQuestion` → Mars-1 build + self-verify →
   Director verify → Mars-2 harden → Director ship; Apollo the dedicated evaluator on a high-risk rung, between
   Stage 4 and 5), the §5 spawn protocol, the §6 audit tools, the §10 commit rules. **Read the `/x-mode` skill
   first** — everything in it applies; the deltas below are the echo_graft binding.
2. **The standing brief + the build guides** — `echo/apps/echo_graft/README.md` (the **binding development
   direction**: no upstream compat, the owned-divergence map, the build patches) + `echo/CLAUDE.md` §The gate
   ladder (the echo_store mix ladder + Valkey 6390, for a BEAM-facing rung). The reference checkout
   `github.local/graft` @ `b07d9312` is **READ-ONLY** — an idea source, never an edit target.
3. **the rung's spec** — `docs/graft/specs/graft.<N>.md` (authoritative) + its `.prompt.md` runbook **if it
   exists** (`graft.1.prompt.md` is the precedent; later rungs may have none — then **Venus authors the build
   brief inline** in Stage 1, as it did for eg.4) + the single roadmap `docs/graft/graft.roadmap.md` + the design
   doc `docs/graft/graft.engine-split.design.md`.

## Arguments & scope

```
$ARGUMENTS
```

- **A RUNG** — `eg.1` … `eg.6` → ship that rung (the default). Internally the aaw `scope` is the **dashed** slug
  `eg-1` … `eg-6` (NO dots — `tool_x_*` / `TeamCreate` require `^[a-z0-9][a-z0-9-]*$`, and a dot split-brains the
  registry across its three namespaces).
- **Empty** → read the roadmap §4 ladder + `docs/graft/graft.progress`, and ship the next **unshipped** rung in
  program order; if that is ambiguous, ask in plain text (do not guess a large scope).

## What is different from a generic /x-mode run (the echo_graft binding)

- **The team is GENERIC, not project-specialized.** There are no `graft-*` skills. Spawn each peer
  `subagent_type: "general-purpose"` (full toolset incl. `mcp__aaw__*`) and adopt its `.claude/agents/<role>.md`
  charter (`venus` = reconcile-or-author the spec + the build brief; `mars` = build to the brief, edits
  code+tests not the spec; `apollo` = the high-risk evaluator/reconciler). The peers self-register via
  `mcp__aaw__agent_register` from their own context (LAW-1; no narrated spawns). The "## The echo_graft facts"
  block below is the pre-loaded context they would otherwise re-derive.
- **The boundary is `echo/apps/echo_graft`** (the Rust cargo workspace — crates `echo_graft`,
  `echo_graft_test`, `echo_graft_tracing`, + any new crate a rung adds, e.g. `echo_graft_proto` /
  `echo_graft_backend`). **A BEAM-facing rung (eg.4+) also touches the ONE named Elixir seam** in
  `echo/apps/echo_store` (`EchoStore.GraftBackend` — a coexisting PEER) and may reuse the `echo/apps/echo_wire`
  RESP codec (`EchoMQ.RESP`, read-only). **Three things are out of bounds by construction:** (a) the reference
  `github.local/graft` (READ-ONLY); (b) the native engine `echo/apps/echo_store/lib/echo_store/graft/*`
  (`EchoStore.Graft.*` — **UNTOUCHED** by the coexist ruling, below); (c) any third umbrella app
  (`echo_mq`/`echo_data`/`echo_bot`/`codemojex`/`exchange`).
- **COEXIST is the load-bearing architecture ruling (Operator D-1=A, 2026-06-21).** The umbrella has **two
  functional-twin engines** and they coexist: the native-BEAM `EchoStore.Graft.*` (CubDB) stays the canonical,
  no-foreign-process default; the Rust `echo_graft` engine — named **`echo_graft_backend`** as the EchoMQ
  participant — serves raw-page / replica-recovery workloads. A graft rung **adds the Rust path alongside the
  native one; it never replaces or retires it** (that would be Option B, a separate Operator-ruled rung). See
  `docs/graft/graft.engine-split.design.md`.
- **The gate ladder is DUAL (Rust + Elixir), NOT a single `cargo test`.** Hold each stage against it.
  - **Rust** (from `echo/apps/echo_graft`): `TMPDIR=/tmp cargo test --workspace` (parity + the rung's tests) ·
    `TMPDIR=/tmp cargo clippy --workspace` **exit 0** (the eg.2 posture — *plain* clippy, **not** `-D warnings`;
    the carried `redundant_clone`/test-idiom warnings are deferred, a new rung adds **zero** new warnings) ·
    `cargo build --workspace` shows zero refs to a removed surface (eg.1 parity). `TMPDIR=/tmp` is **load-bearing**
    — the harness tmp overlay hits ENOSPC and surfaces as spurious mid-suite I/O failures.
  - **Fault-injection suites run `--test-threads=1`** — `precept` fault state is **process-global**, so the
    carried `verify_snapshot.rs` fault tests race under cargo's default parallelism (the eg.3 finding). The
    authoritative gate run is **serial** for any suite that arms a fault.
  - **The ≥100 determinism loop** for any **mint / lease / commit / version-negotiation** surface (the same-ms
    branded-id mint hazard + the conditional-write race): `for i in $(seq 1 100); do TMPDIR=/tmp cargo test -p
    echo_graft_test --test <suite> -- --test-threads=1 || break; done`. A pure-subtractive or docs-only rung
    runs a multi-seed sweep instead and states the determinism posture honestly.
  - **Elixir** (a BEAM-facing rung only, from `echo/apps/echo_store`): re-probe `asdf current` / `.tool-versions`
    **from the app dir** (never hardcode the toolchain) · `valkey-cli -p 6390 ping` → `PONG` (for a live-bus leg)
    · `TMPDIR=/tmp mix compile --warnings-as-errors` · `TMPDIR=/tmp mix test` incl. the **dual-side conformance
    test** (the Elixir side asserts byte-equality against the SAME frozen fixtures the Rust side verifies — the
    cross-runtime-skew mitigation). The **live Valkey/EchoMQ and live-Tigris legs are env-gated** (the eg.2
    live-Tigris precedent — proved in-process by default, the live leg behind `ECHO_GRAFT_TEST_*` env).
- **The no-upstream-compatibility law.** `echo_graft` keeps **no** compatibility with upstream Graft — not API,
  not wire, not cherry-pick. Every divergence is **owned**, recorded in `README.md`, never re-merged. A rung may
  modify any carried file for EchoMQ's correctness/DX; it never tries to stay mergeable with `github.local/graft`.
- **The byte-frozen wire (`echo_graft_proto`).** Once a `echo_graft_proto` message defines its encoding, the
  encoding is **frozen** — a change goes through a **protocol-version bump**, never a silent re-encode. The eg.3
  `FeedEvent` bilrost fixture (51 bytes) and every eg.4 proto fixture are byte-pinned; on a re-drive rung the
  shipped encodings stay **byte-identical to HEAD**. The **dual-side conformance** (Rust + Elixir, shared
  fixtures) is the proof.
- **The cross-cutting acceptance gates bind every rung** (roadmap §6), in addition to the rung's own criteria:
  **upstream parity** (the carved baseline never regresses) · **declared keys** (every remote object key + every
  EchoMQ field/lane/correlation-id a rung adds is enumerated in its spec — nothing undeclared on the wire or in
  the bucket) · **byte-frozen wire** · **determinism loop** · **shootout battery** (eg.6, **per-workload** under
  the coexist ruling) · **no scheduler block** (any post-eg.6 NIF runs on a dirty scheduler) · **license
  retained** (the repo-level MIT/Apache-2.0 `LICENSE-*` + the workspace `license` field — **no per-file
  headers**; upstream licenses at the repo level).
- **The risk tier decides the verify depth + the formation** (the rung's declared tier): `eg.1`/`eg.2` are
  **NORMAL** → the Director's solo verify is the floor, no Apollo. `eg.3` is **NORMAL+** → Apollo RECOMMENDED.
  **`eg.4` is HIGH** (the cross-runtime contract + a wire/version surface) → **Apollo is REQUIRED** (between
  Stage 4 and 5), and the verify deepens (the dual-side conformance, the determinism loop on the commit/version
  surface, the full fence mutation battery). `eg.5` is NORMAL+; `eg.6` (cross-compile + CI + the shootout) is
  NORMAL.
- **Right-size the formation.** If the rung's increment is already built and green (eg.1/eg.2/eg.3 were built
  directly, solo), Stages 1–2 are **already done**: the run collapses to the Director's **independent verify +
  the reconcile + (on request) the scoped commit**. Do not re-spawn a build team for built-and-green code —
  rigor is constant; only ceremony scales.
- **The git posture is UNTRACKED-by-default.** The whole `echo/apps/echo_graft` + `docs/graft` tree is currently
  **untracked** on the jonnify `echo_mq` branch (eg.1–eg.3 shipped to the working tree, **not committed**). The
  default ship is **to the working tree — no commit unless the Operator asks** (§2).

## The echo_graft facts (the pre-loaded context for the peers)

- **The mission** (roadmap §1) — own the transactional+replicated durability quadrant beside Champ (bounded-loss,
  in-memory + periodic snapshot) and Oban (strict but single-node). `echo_graft` = a from-scratch system seeded
  from Graft's core, SQLite layer removed, three seams rewritten (Tigris remote, branded-Snowflake identity, the
  EchoMQ change-feed), run as a supervised Rust sidecar the BEAM drives over EchoMQ (RESP3). Build targets: a Mac
  orchestrator + a Windows RTX compute node.
- **The rungs** (roadmap §4) — `eg.1` carve + workspace (SQLite removed, Fjall retained) · `eg.2` Tigris remote +
  conditional-write fence · `eg.3` branded-id + EchoMQ change-feed · `eg.4` `echo_graft_backend` sidecar +
  `echo_graft_proto` versioned wire + `EchoStore.GraftBackend` Elixir client · `eg.5` low-latency write tier
  (group-commit buffer) · `eg.6` ship (cross-compile + CI + the durability shootout vs Champ/Oban, per-workload).
- **As-built (eg.1–eg.3 SHIPPED, 98 tests, determinism 100/100, live-Tigris verified)** — the `Runtime` surface
  (`crates/echo_graft/src/rt/runtime.rs`: `volume_open_branded`, `volume_writer`/`volume_reader`, `volume_push`
  →`RemoteCommit` conditional-write fence, `volume_pull`, `read_page`→lazy `FetchSegment`, `volume_snapshot`,
  `get_commit`, `feed()`), the OpenDAL remote + fence (`remote.rs`), branded identity (`identity.rs`,
  `BrandedId`), the in-process change-feed (`feed.rs`: `FeedEvent` byte-frozen, `ChangeFeed`, `InMemoryFeed`,
  `lane_for`→`egraft:feed:{vol}`), the error taxonomy (`err.rs`: `LogicalErr::VolumeConcurrentWrite`=conflict,
  `VolumeNotFound`=not-found).
- **Ground truths that diverge from the seed (NO-INVENT — confirm against source, do not re-derive):** remote is
  Apache **OpenDAL** (`RemoteConfig::{Memory,Fs,S3Compatible}`), **not** `object_store`; the native id is base58
  **`Gid`** while the branded `{NS}{base62}` id is **caller-supplied** (the engine validates/stores/round-trips,
  **never mints** — no Snowflake minter in Rust); local commit OCC is **snapshot-version level, not page-level**;
  the macOS `tcp_user_timeout` cfg-gate is the one owned build divergence; there is **no `echo_graft_remote`
  crate** (remote is a module). Every claim grounds in a real `echo_graft` file, the real `echo_store`/`echo_wire`
  surface, the README, or a roadmap/design §; forward-tense ("eg.N builds …") for an unshipped surface.

## 0. Bootstrap (Director, before any spawn)

Read the rung's `graft.<N>.md` spec (+ its `.prompt.md` if present) + the roadmap + the design doc, **and**
`echo/apps/echo_graft/README.md` (the development direction) **and** `echo/CLAUDE.md` (for a BEAM-facing rung)
**and the `/x-mode` skill**. Declare the mode (**Flat-L2**, or **Director-solo** for an already-built rung).
Deep-reason the rung (the `/x-mode` §0: the 5W, the solution space incl. a do-nothing baseline, the invariants as
runnable gates, the smallest change that preserves correctness) → `tool_x_trace` (T-n). **Confirm the Stage-1
gate is reachable** — the spec exists (or Venus authors it + the build brief inline) and carries **no open
Operator decision** (an architecture fork like the coexist split, a wire-encoding choice, a destructive at-rest
op); if a fork is open, **STOP and `AskUserQuestion`** before spawning. Note the toolchain: homebrew `cargo`
(workspace `rust-version` re-probed, never hardcoded), `TMPDIR=/tmp`, and — for a BEAM rung — `asdf current` +
Valkey 6390.

## 1. Stand up the TRUE team & run the pipeline (x.md §5)

`scope` = the dashed rung slug (`eg-4`); `operator` = `jonny`; `workspace` = `/Users/jonny/dev/jonnify`;
`ledger_dir` = `docs/graft` (the run ledger `<scope>.progress.md` lands there — the `eg-engine-split.progress.md`
precedent). Sequence per `/x-mode` §1: `mcp__aaw__init` → `aaw_spawn`+`agent_register` the `director` →
`TeamCreate(scope)` → `tool_x_trace(T-1)`. Create one Task per stage. **zsh does not word-split unquoted vars** —
iterate file lists with `find … -print0 | while IFS= read -r -d '' f`.

Lift each stage's directive from the `.prompt.md` (or the Stage-1 Venus brief); wrap it in the `/x-mode` §3
per-spawn ceremony + "Read and operate by `.claude/agents/<role>.md`."

**Venus** (reconcile the spec lag-1 against the as-built `echo_graft` / `echo_store` tree, or author it; author
the build brief — agent stories, declared keys, the byte-frozen fixture set, the gate ladder, the
smallest-change build order; frame seam forks as four-part Arms — Rationale/5W/Steelman/Steward) → **Director
rules the Arms** (mandatory `AskUserQuestion`) → **Mars-1** (build to the brief inside the boundary, cite the
spec for every public call, the real `Runtime`/`echo_store`/`echo_wire` surface only — **no invented
signatures**, run the dual gate) → **Director verify** (a REAL pass: a fresh-gate reconcile + an **independent
gate re-run** — `cargo test --workspace` + fault suites `--test-threads=1` + the determinism loop, and for a
BEAM rung the `mix` ladder on Valkey 6390 + the dual-side conformance — + an adversarial probe incl.
**declared-keys** + a **byte-freeze** check on the shipped fixtures + a mutation spot-check: Edit-in →
test-catches → revert → `git diff --stat` clean **net-zero**, LAW-1a) → **Mars-2** (resume the Stage-1 Mars —
one identity, two passes — remediate + harden + the full dual gate; REMEDIATE loop MAX 3) → **Director ship**
(the working-tree hand-off, or the scoped commits on request, + the Stage-6 fold). **Apollo** spawns **on a
high-risk rung** (eg.4) with the §11.2 charter, runs the post-build reconcile + the adversarial verify, resolves
every ambiguity with the Operator via `AskUserQuestion`, and renders BUILD-GRADE / BLOCKED before the ship.

## 2. The ship — working tree by default, scoped LAW-4 commits on request (Director-only, x.md §10)

The default ship is **to the working tree**: leave the rung's changes staged-in-the-tree (not committed), report
the green dual gate + the verified acceptance, and **stop at the acceptance boundary** — eg.1–eg.3 shipped this
way (untracked). **Commit only when the Operator asks.** When asked, at `tool_x_complete` (Z-n), exactly once:
the Director's verify clean + the dual gate green (+ on eg.4, Apollo BUILD-GRADE); **≥1 `tool_x_decision` (D-n)** +
the **Z-n** written this turn; `git status --short` AND `git diff --cached --name-only` reviewed;
`.git/rebase-merge`/`rebase-apply` checked. The working tree is **entangled** with the Operator's parallel work
— **NEVER `git add -A`, NEVER a bare commit**; stage each concern with an explicit pathspec and commit it with
`-- <paths>`, split into **separate scoped commits per concern**:

- `git add echo/apps/echo_graft && git commit -F <msg> -- echo/apps/echo_graft` → `[echo_graft] <rung> — <title>`
  (the Rust engine + its tests).
- *(BEAM-facing rung)* `git add echo/apps/echo_store/lib/echo_store/graft_backend* … && git commit -F <msg> --
  <the EchoStore.GraftBackend paths>` → `[echo_graft] <rung> — EchoStore.GraftBackend client + conformance` —
  **the native `EchoStore.Graft.*` paths are NEVER in `--cached`** (the coexist boundary).
- `git add docs/graft && git commit -F <msg> -- docs/graft` → `[echo_graft] <rung> specs + reconcile`.

The reference `github.local/graft` is **never** staged. Each message cites the slug, the Z-n, the D-n, and the
Y-n report. **Stage-6 fold:** flip the rung's status in `docs/graft/graft.roadmap.md` + bump
`docs/graft/graft.progress` (the ANSI tracker), backward-reconcile the rung `.md` to the green as-built surface,
and surface the next rung. Do not push unless asked.

## 3. Quality gate (before Z-n, mirrors /x-mode §5)

- [ ] The `graft.<N>.md` spec (+ `.prompt.md` if present) + roadmap + design doc + `README.md` (+ `echo/CLAUDE.md`
      for a BEAM rung) + the `/x-mode` skill read; mode declared.
- [ ] T-n derivation, D-n per locked contract, L-n per surprise written to `docs/graft/<scope>.progress.md`.
- [ ] Every peer is a REAL self-registered `Agent` spawn (`general-purpose` + the venus/mars/apollo charter; no
      FAKE-N); the Director called no Edit/Write on production code EXCEPT a mutation spot-check reverted
      net-zero (LAW-1a).
- [ ] Every design Arm was ruled via `AskUserQuestion` before the build (notably any architecture/coexist or
      wire-encoding fork).
- [ ] The DUAL gate is green: Rust `cargo test --workspace` + plain `clippy` exit 0 (zero NEW warnings) +
      fault suites `--test-threads=1` + (mint/lease/commit/version surface) the ≥100 determinism loop, all under
      `TMPDIR=/tmp`; **for a BEAM rung** the `echo_store` mix ladder on Valkey 6390 + the dual-side byte-equality
      conformance. The **byte-freeze** holds (shipped `echo_graft_proto`/`FeedEvent` fixtures byte-identical to
      HEAD) and **declared keys** are complete.
- [ ] The boundary grep is empty: only `echo/apps/echo_graft` (+ the named `echo_store`/`echo_wire` seam for a
      BEAM rung) + `docs/graft` changed; the native `echo_store/lib/echo_store/graft/*`, the reference
      `github.local/graft`, and every third umbrella app are **untouched**; `Cargo.lock`/`mix.lock` excluded
      unless a real dep moved.
- [ ] License retained (repo-level `LICENSE-*` + the workspace `license` field; no per-file headers).
- [ ] LAW-4 (only if the Operator asked to commit): Z-n written → one Director pathspec commit **per concern**;
      nothing foreign in `--cached`; otherwise the ship is the working-tree hand-off.
- [ ] `mcp__aaw__status(scope)` shows the registered peers.

## 4. Map

- The laws + pipeline: `.claude/commands/x.md` + the `/x-mode` skill. The charters the peers wrap:
  `.claude/agents/{venus,mars,apollo}.md`.
- The development direction (the binding brief) + the owned-divergence map: `echo/apps/echo_graft/README.md`.
- The Elixir gate ladder (Valkey 6390, `TMPDIR=/tmp mix`, asdf re-probe): `echo/CLAUDE.md`.
- The canon + the single roadmap + the design doc + the ANSI tracker: `docs/graft/graft.roadmap.md` ·
  `docs/graft/graft.engine-split.design.md` · `docs/graft/graft.progress`.
- The specs (source of truth): `docs/graft/specs/graft.<N>.md` (+ `graft.<N>.prompt.md` if present).
- The code (the boundary): `echo/apps/echo_graft/` (Rust) + the `echo_store`/`echo_wire` seam (a BEAM rung) +
  the read-only reference `github.local/graft/`.
- The run's audit trail: `docs/graft/<scope>.progress.md` + `mcp__aaw__status`.
