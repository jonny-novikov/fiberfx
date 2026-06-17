# EchoMQ — the program operating manual

> **The HOW-WE-SHIP-IT.** The *what* lives in the canon: [`../emq.design.md`](../emq.design.md) (binding
> design, S-1..S-7), [`../emq.roadmap.md`](../emq.roadmap.md) (the delivery plan + rung ladder),
> [`../emq.progress.md`](../emq.progress.md) (the as-built dashboard), [`../emq.features.md`](../emq.features.md)
> (the feature catalog incl. **Part C** forward-features), [`../emq.testing.md`](../emq.testing.md) (the
> testing view). **This file is the program's OPERATING CONTRACT** — the AAW team, the pipeline, the gate
> ladder, the boundary, the durable footguns, the live frontier — and the home of the per-agent calibrations
> ([`./emq.venus.md`](./emq.venus.md), [`./emq.mars.md`](./emq.mars.md), [`./emq.apollo.md`](./emq.apollo.md)).
> It is the on-disk **source-of-truth the slim Claude memory points to**: the memory holds the index hook + the
> live frontier; the depth lives HERE (the 2026-06-15 memory de-bloat).

## The program in one paragraph

`echo/apps/echo_mq` is **THE** EchoMQ 2.0 library — the Valkey-native bus, the single convergence target, above
`echo/apps/echo_wire` (the extracted wire: `EchoMQ.{RESP,Connector,Script}` under the `EchoWire` facade).
`apps/echomq` is the **FROZEN v1 line** (1.3.0) — the push source + feature reference, untouched, clear to
dissolve. One program, three movements: **Movement 0** (the substrate — shipped `a2d599c8`), **Movement I**
(the core — push the v1 capability surface to state-of-the-art: emq.1 scheduler/retry · the emq.2 parity
cluster CLOSED · the emq.3 flow family), **Movement II** (the extension — groups/batches/lifecycle/proof stack,
emq.4–emq.8). The named consumer is the **Exchange platform** (`echo/apps/exchange`, the `TRD.*` rungs).

## The AAW team + the pipeline (Flat-L2)

One rung per run through the aaw lead-team, Director-supervised, to one ratifying **LAW-4** commit. The pipeline
is `/x-mode` bound to echo_mq (the skill `echo-mq-ship`). The roster + the standing calibration:

- **Venus — the architect / spec-steward** ([`./emq.venus.md`](./emq.venus.md)). Reconciles the triad lag-1
  against the as-built tree, **surfaces (never rules)** the forks, authors the brief. Owns the spec
  organization + the forward-feature catalog. Edits ONLY the spec triad; never code; no git.
- **Mars — the implementor + THE PRIMARY CODE-QUALITY GATE** ([`./emq.mars.md`](./emq.mars.md)). **The rebalance
  (2026-06-15):** Mars is materially stronger in coding than Apollo, so Mars OWNS code quality — builds the
  increment AND adversarially self-verifies (the full gate ladder + the declared-keys grep + the Lua mutation
  kill-rate with `SCRIPT FLUSH` + the order theorem + the destructive probes) **BEFORE reporting**. Proactive:
  find your own defects; do not wait for a verifier. Edits code + tests; never the spec; no git.
- **Apollo — the fast finisher** ([`./emq.apollo.md`](./emq.apollo.md)). **The rebalance:** Apollo's heavy
  independent adversarial marathon (the ~1h47m "cold runs") is RETIRED to Mars. Apollo now (a) ensures the
  rung's new capability has a **story-generation test** (`echo/apps/echo_mq/test/stories/<feature>_story_test.exs`)
  so `mix echo_mq.stories` regenerates the executable acceptance catalog `docs/echo_mq/stories/`, and (b) writes
  the **closure report** (a LIGHT post-build reconcile + the spec sync + the mentoring). Fast, focused, no cold
  runs. Edits the spec triad + the story tests + the closure record; never production code; no git.
- **Director — the supervisor.** The Stage-3 independent review (the one independent adversarial pass that
  stays a hard floor), the REMEDIATE loop, the LAW-4 pathspec commit, the Stage-6 fold. Calls no Edit on
  production code except a net-zero mutation spot-check (LAW-1a).

**The pipeline:** Venus → **Mars (build + STRONG self-verify)** → Director review → Mars-2 (remediate + harden)
→ **Apollo (story coverage + closure report)** → Director ship. **The verification floor** = Mars's adversarial
self-verification **+** the Director's Stage-3 review **+** Apollo's reconcile. The slow
independent-Apollo-marathon is gone — that is the cold-run fix, and it works because a strong implementor
running the mutation kill-rate on their own code finds the defects earlier than a separate agent re-deriving
them cold (the Stage-3 review keeps a genuine independent pass).

**LAW-1 (no role-play):** every peer is a REAL `Agent` spawn that self-registers (`mcp__aaw__agent_register`);
a registered id without a spawned agent is FAKE-N. **The persistence law:** a verifier records its verdict
(`tool_x_report` / a `SendMessage`) **before** going idle — an idle notification carries no findings, and a
verdict that lives only in an agent's context is, for the audit, indistinguishable from work never done (the
emq-3-3 Apollo halt — ~1h47m, then idle, no Y-n — is why this is a law).

## The boundary

`echo/apps/echo_mq` (+ the ONE named `echo/apps/echo_wire` seam a rung touches — the emq.1 resubscribe
precedent). `apps/echomq` (frozen v1) UNTOUCHED. No third app. `echo/mix.lock` ships only if a real dep moved
(expect EXCLUDED). **Out-of-band — never in an emq commit:** `echo/apps/{exchange,investex}`,
`docs/{exchange,echo/art,echo/mesh}`, `docs/fsharp`, `html/`, `.claude/skills/mesh-writer`.

## The gate ladder (the operating procedure)

- `asdf current erlang` — **re-probe `.tool-versions`, never hardcode**; inside `echo/` it resolves to
  **28.5.0.1** (the old `ASDF_ERLANG_VERSION=28.1` advice is DEAD). `redis-cli -p 6390 ping` → `PONG`
  (the live engine is **Valkey on 6390**, fence key `{emq}:version` = `echomq:2.0.0`, persists by design).
- `TMPDIR=/tmp mix compile --warnings-as-errors` — **per touched app**, clean.
- `TMPDIR=/tmp mix test --include valkey` — **inside the touched app's dir**; umbrella-wide `mix test` is
  **BANNED** (the full suite hangs).
- `EchoMQ.Conformance.run/2` → `{:ok, n}` — the **additive-minor law**: every prior scenario byte-unchanged
  (name + contract + verdict-body, git-verified), each new one probe-registered in the SAME change, the count
  re-pinned in BOTH pinning tests (`conformance_scenarios_test.exs` + `conformance_run_test.exs`).
- **The ≥100 determinism loop** — only for an id-minting / process / engine suite (the same-ms branded-id mint
  hazard); the loop OWNS the machine (no concurrent server, no sibling heavy I/O). One green run is not proof.
- **The durable harness** — a committed re-runnable `echo/rungs/bus/emq_<rung>_check.sh` (+ `.out`); a hand-run
  loop tee'd to `/tmp` evaporates on a crash (ephemeral-proof ≠ a harness).
- `TMPDIR=/tmp` on **every** mix command. `echo_mq` lib/test is **NOT** under `mix format` (the long-line
  one-scenario-per-line conformance registry is the committed convention — do not reflow).

## The durable footguns (the lessons that cost us)

1. **The mutation-revert footgun (L-3).** `git checkout -- <path>` to undo a spot-check restores **HEAD** — on a
   modified-uncommitted file it DESTROYS the in-flight fix. Revert a mutation by an **inverse Edit** (or a `cp`
   backup), **never `git checkout`**; commit a verified fix promptly to immunize it.
2. **The concurrent-index race.** The Operator stages/commits out-of-band (proven repeatedly — a pre-staged
   `html/echomq/index.html` appeared mid-close). ALWAYS a **guarded pathspec commit**: re-verify
   `git diff --cached --name-only` is purely the rung boundary immediately before `git commit`, ABORT on any
   foreign path; `git commit -- <path>` partial-commits your file while leaving a concurrent committer's staged
   entry untouched. **Never `git add -A`, never a bare commit.**
3. **Ephemeral proof ≠ a harness** — the committed re-runnable script is the structural fix (see the gate ladder).
4. **The persistence law** (above) — record the verdict before idle.
5. **`SCRIPT FLUSH` / EVALSHA-first.** `EchoMQ.Connector.eval` is EVALSHA-first; a recompiled `Script.new` mints
   a new SHA but a prior server-cached script is NOT invalidated by a recompile — `redis-cli -p 6390 SCRIPT FLUSH`
   before re-testing EACH Lua mutation, or a stale SHA masks the change (the T-6 lesson).
6. **The wire-fixture byte-fidelity (L-2).** A hand-fabricated wire fixture counts only if BYTE-FAITHFUL to the
   producer's emit — reuse the producer's real shape, never a hand-typed sibling that can drift to a different
   slot/path than the assertion names.
7. **Records-freeze.** Never rewrite a frozen `{scope}.progress.md` ledger's historical content; the run ledgers
   live archived in `specs/progress/`.

## The spec home + the file convention (2026-06-15)

- `specs/` holds **ONLY** the chapter triads `emq.N.{md,stories.md,llms.md}`. Each chapter's **decomposition** —
  its `prompt`/`design`/`tooling` docs **and** its sub-rung quads (`emq.N.M.{md,stories,llms,prompt}.md`) — lives
  in a same-named folder **`specs/emq.N/`** (e.g. `specs/emq.2/`, `specs/emq.3/`).
- The **run-ledgers** (`emq-N-M.{progress.md,registry.json}`) live archived in **`specs/progress/`** (they were
  burying the key artifacts; relocated `fd8876d5`).
- The **forward-feature 5-section catalog** (Goal/Rationale/5W/Scope/AC, by category) is
  [`../emq.features.md`](../emq.features.md) **Part C**.
- The **generated story catalog** is `docs/echo_mq/stories/` — produced by `mix echo_mq.stories` from
  `echo/apps/echo_mq/test/stories/*_story_test.exs`; **generated, NEVER hand-edited** (it cannot drift from code).
- The **per-agent calibrations** are `program/emq.{venus,mars,apollo}.md` (this folder).

## The live frontier (re-true at each rung close)

- **Shipped:** emq.0 · emq.1 · emq.2.1/2.2/2.3/**2.4** (the parity cluster CLOSED) · emq.3.1 (single-queue flow,
  `f9849efe`) · emq.3.2 (child-result reads, `68b6baed`) · **emq.3.3 (cross-queue flow, `7de4e90a`)** — the
  completion signal hops the slot boundary via an outbox on the child slot + the Pump sweep + the `:processed`
  HSETNX idempotent deliver. Conformance **47**.
- **Specced:** **emq.3.4** (failure-policy `fail_parent_on_failure`/`ignore_dependency_on_failure` over the
  §6-reserved `:failed`/`:unsuccessful` subkeys + `add_bulk/3`; **Arm A** — grandchildren deferred to emq.3.5,
  the V-1 fork ruled D-2). **HIGH-risk** (a shipped `@retry` dead-letter edit + cross-slot failure delivery).
- **NEXT:** the **emq.3.4 BUILD** (runbook `specs/emq.3/emq.3.4.prompt.md`) → emq.3.5 grandchildren → Movement I
  CLOSES → Movement II (emq.4 groups · emq.5 batches · emq.6 lifecycle · emq.8 proof stack).
