---
name: echo-mq-three-movements
description: "EchoMQ program — echo/apps/echo_mq is THE v3 library. DEPTH lives on-disk at docs/echo_mq/program/emq.program.md (the operating manual + agent calibrations). Shipped emq.0. emq.1 emq.2 emq.3 — **MOVEMENT I CLOSED**. Epics layer + AAW Epic/corpus framework instrument live. Rebalance 2026-06-15: Mars=primary code-quality gate, Apollo=fast finisher (stories+closure). This memory = slim pointer + frontier (de-bloated to disk 2026-06-15)."
metadata:
  node_type: memory
  type: project
  originSessionId: 0be564f9-9bb6-42f9-8196-f11e99620607
---

**The program.** `echo/apps/echo_mq` is THE EchoMQ 2.0 library (Valkey-native, above `echo/apps/echo_wire`);
`apps/echomq` is the FROZEN v1 line (1.3.0), the feature reference, untouched, clear to dissolve. One program,
three movements; shipped one rung per run through the aaw lead-team (Director-supervised → one LAW-4 commit).
The named consumer is the Exchange platform.

## The depth lives ON DISK — read these (the 2026-06-15 de-bloat)

This memory is a **slim pointer, not the source of truth**. The operating manual, the agent calibrations, the
footguns, and the gate ladder are a committed on-disk doc:
- **`docs/echo_mq/program/emq.program.md`** — THE operating manual: the AAW pipeline, the roster + the
  per-agent calibrations (`emq.{venus,mars,apollo}.md`, same folder), the boundary, the gate ladder, the durable
  footguns, the live frontier.
- `docs/echo_mq/emq.design.md` (canon, S-1..S-7) · `emq.roadmap.md` (plan + ladder) · `emq.progress.md`
  (as-built dashboard) · `emq.features.md` (catalog + **Part C** forward-features) · `emq.testing.md`.
- Run-ledgers (per-rung audit trails): `docs/echo_mq/specs/progress/emq-N-M.progress.md`.

## The live frontier (re-true at each rung close)

Shipped: emq.0 · emq.1 · emq.2.1/2.2/2.3/2.4 (parity cluster CLOSED) · emq.3.1 `f9849efe` · emq.3.2 `68b6baed`
· **emq.3.3 cross-queue flow `7de4e90a`** (outbox-on-{C} + Pump sweep + `:processed` HSETNX idempotent deliver;
conf 47). **emq.3.4 failure-policy + bulk SHIPPED `4c401479`** (the additive `@retry` dead-letter branch + `@flow_fail_deliver`
over the §6-reserved `:failed`/`:unsuccessful`; both enqueue scripts + `@complete`/`@flow_deliver` byte-frozen;
`add_bulk/3` sequential/fail-closed-per-flow + `ignored_failures/3`; conf 50; Apollo BUILD-GRADE; the `emq-3-4-build`
lead-team). **emq.3.5 (grandchildren / deep recursion) SHIPPED `cd3c383a` 2026-06-15 — MOVEMENT I CLOSED** (the `/echo-mq-ship`
Flat-L2 run; Apollo BUILD-GRADE, NORMAL-risk, Arm A). Forks RULED (ledger D-1): **S2 · Arm A** = host/sweep re-emit
over byte-frozen Lua → **S1 · NORMAL-risk**; S3 · Arm A (unified `add/3` nested-tree clause); S-Bound · 8. D3
completion composes recursively FREE over the byte-frozen `@complete`; the recursive FAILURE hook (D4, the SOLE new
mechanism) is host/sweep re-emit (`Pump.maybe_reemit_parent_death` deliver-loop + `on_same_queue_child_death` from
`retry/7`, reusing emq.3.4's outbox+sweep+`@flow_fail_deliver` one more hop; `parent_fail_link/3` host-reads
ancestry). All 19 `Script.new` bodies byte-frozen; conf 50→52; the **depth-4 multi-tick same-queue** test the
load-bearing proof. **GOTCHA worth keeping**: the same-queue failure half had a REAL production gap — the re-emit was
UNWIRED from `retry/7`, so a same-queue child's death HUNG its parent — hidden behind a FALSE-GREEN (4 test
hand-calls simulating the re-emit production never ran); caught + closed in-cycle (depth-3 tests can't reach the
recursive deliver-loop hop, so the depth-4 multi-tick test is what bites; a Director mutation probe confirmed
depth-4 RED / depth-3 GREEN). The flow family (3.1–3.5) is parity-complete → **Movement II (emq.4–8) opens**. **NEW — the Epics layer** (`docs/echo_mq/epics/`:
emq.epic.0 the meta-epic + emq.epic.1 the v3.x command DSL; the AAW framework Epic/corpus instrument + the
repo-controlled-memory model PENDING Operator grant). Build vs design scope: `emq-3-4` design closed Z-1; the BUILD
ran as the fresh `emq-3-4-build` scope (ledger_dir immutable after init).

## Critical operational quick-ref (DEPTH in emq.program.md)

Per-app `mix` only (umbrella `mix test` BANNED) · **erlang 28.5.0.1** (re-probe; the 28.1 advice is DEAD) ·
`TMPDIR=/tmp` on every mix · **Valkey 6390** · the **concurrent-index race** (the Operator commits out-of-band →
guarded pathspec commit, re-verify `git diff --cached`, `git commit -- <path>` partial, NEVER `git add -A`) ·
the **mutation-revert** (inverse Edit, never `git checkout` — L-3) · **`SCRIPT FLUSH`** before re-testing a Lua
mutation (EVALSHA-first) · committed harness ≠ ephemeral `/tmp` proof · the **persistence law** (record the
verdict + SendMessage before idle) · `echo_mq` not under `mix format` · **spec home convention:** `specs/` =
chapter triads only, decomposition → `specs/emq.N/`, ledgers → `specs/progress/`.

## The rebalance (2026-06-15, Operator-directed — agents were too passive)

**Mars = the PRIMARY code-quality gate** — owns the gate ladder + the adversarial battery (declared-keys,
mutation kill-rate w/ `SCRIPT FLUSH`, order theorem), proactively, BEFORE reporting. **Apollo = the FAST
finisher** — story-gen coverage (`test/stories/*_story_test.exs` → `mix echo_mq.stories` →
`docs/echo_mq/stories/`) + the closure report; the ~1h47m cold-run adversarial marathon retired to Mars.
Details: `emq.program.md` + `emq.{mars,apollo,venus}.md`.

Related: [[echomq-umbrella-app]], [[bcs-course]],
[[x-mode-cclin-leadteam]], [[local-valkey-replaces-redis]], [[exchange-platform]].
