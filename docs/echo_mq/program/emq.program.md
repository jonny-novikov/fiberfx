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
`echo/apps/echo_wire` (the extracted wire: `EchoMQ.{RESP,Connector,Script}` under the `EchoWire` facade). The
legacy v1 line was **rewritten fresh into `echo_mq`** under the v2 laws (never migrated) and **removed** — single
source of truth, no compatibility layer. One program: a **foundation** (EchoMQ protocol v2 + the BCS substrate —
established as `emq.0`), **Movement I** (the core — the v1 capability surface pushed to state-of-the-art: emq.1
scheduler/retry · the emq.2 parity cluster · the emq.3 flow family — **CLOSED at conformance 52/52**), and
**Movement II** (the extension — groups/batches/lifecycle/cache/proof stack, emq.4–emq.8 — **OPEN; emq.4.1 control plane + emq.4.2 group recovery SHIPPED, live conformance 55/55**, additive minors, the protocol version (the wire fence + the mix.exs label together)
climbing the **2.x line** per rung `echomq:2.4.1 → 2.4.2 → …`; the `echomq:3.0.0` major is the **Stream Tier (EchoMQ 3.0)**, after Movement II). The **worked
consumer** is **codemojex** (`echo/apps/codemojex` — the Mastermind-style game on `EchoMQ.Lanes`/`Consumer`/
`Events` + the `EchoData.Bcs` stores); the **headline-planned consumer** is **echo_bot** (`echo/apps/echo_bot` —
Telegram notifications at scale; the seam is `EchoBot.Platform.Telegram.send_reply/3`).

## The AAW team + the pipeline (Flat-L2)

One rung per run through the aaw lead-team, **Director-orchestrated**, to one ratifying **LAW-4** commit. The
pipeline is `/x-mode` bound to echo_mq (the skill `echo-mq-ship`). The roster + the standing calibration:

- **Venus — the architect / spec-steward / strawman author** ([`./emq.venus.md`](./emq.venus.md)). Authors the
  strawman triad, reconciles it lag-1 against the as-built tree, and **frames the seam forks as four-part Arms**
  (Rationale / 5W / Steelman / Steward — [`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md)) for
  the Director to rule. Surfaces, never rules. Owns the spec organization + the forward-feature catalog. Edits
  ONLY the spec triad; never code; no git.
- **Director — the orchestrator + the verifier.** Rules each Arm *with the Operator* via the **mandatory
  `AskUserQuestion`** (a fork is never decided silently); then **independently verifies code + invariants** (a
  real gate re-run on Valkey 6390 + an adversarial probe incl. declared-keys + a net-zero mutation spot-check);
  runs the REMEDIATE loop; **consolidates the rung's findings + learnings for Apollo**; lands the LAW-4 pathspec
  commit + the Stage-6 fold. Calls no Edit on production code except a net-zero mutation spot-check (LAW-1a).
- **Mars — the implementor + THE PRIMARY CODE-QUALITY GATE** ([`./emq.mars.md`](./emq.mars.md)). Builds the
  increment AND adversarially self-verifies (the full gate ladder + the declared-keys grep + the Lua mutation
  kill-rate with `SCRIPT FLUSH` + the order theorem + the destructive probes) **BEFORE reporting**, AND ships
  the **story-generation test** (moved from Apollo) so `mix echo_mq.stories` keeps `docs/echo_mq/stories/`
  current. Proactive: find your own defects; do not lean on the Director's verify. Edits code + tests; never the
  spec; no git.
- **Apollo — the Mentor (exclusively), out of the pipeline** ([`./emq.apollo.md`](./emq.apollo.md)). Receives
  the Director's consolidated findings + learnings and turns them into **better agents + a better process** — one
  guardrail per finding aimed at the implicated contract, sharpen-don't-stack, **PROPOSE-ONLY** (the Director
  ratifies under an Operator grant). No build, no verify, no per-rung *build-closure* reconcile / spec-sync (→ the
  Director's verify + Venus's spec ownership), no story coverage (→ Mars). The cold runs are retired. **Stage 7 is
  Operator-grantable-extensible** beyond pure calibration: by explicit grant a run may add (a) a **process-doc
  reconcile** — sync `docs/echo_mq/program` against how the run ACTUALLY ran (Venus's lag-1 reconcile applied to
  the how-we-ship-it; corrective, distinct from additive calibration; emq.4.1-D4); and (b) on a **HIGH-risk /
  destructive rung**, a **destructive-op adversarial evaluation** — does the at-rest op's blast radius MATCH its
  contract, read from the declared key list (no SCAN/KEYS*) + the conformance survivor-asserting scenario
  (emq.4.1-D5). Both PROPOSE-ONLY, both docs-only, never production code, never git.

**The pipeline:** Venus (strawman + Arms) → **Director (rules the Arms via `AskUserQuestion`)** → **Mars (build +
self-verify + stories)** → **Director (verify code + invariants + REMEDIATE)** → Mars-2 (remediate + harden) →
**Director (ship + consolidate findings)** → **Apollo (calibrate the agents)**. **The verification floor** =
Mars's adversarial self-verification **+** the Director's independent verify. The slow independent-Apollo marathon
is gone (the cold-run fix); Apollo's value moved off the critical path — it makes the *next* rung's agents better
rather than this rung's build slower.

## Right-sizing the run (pragmatic delivery)

**Rigor is constant; only ceremony scales.** The 7-stage pipeline above is the SHAPE, not a fixed cost — the
Director triages the formation at bootstrap against the rung's actual surface, and a small rung runs a small
formation (an Operator cost ruling — a 2-line fix once cost a full-team run).

**The L2 Topology Router (the named formation tiers — `emq3.3-D9`, Operator-authorized).** The Director triages
ONE of four formations at bootstrap from the rung's `.prompt.md` **risk tier × design-space width** — the
*router* is the decision, the *tiers* are its outputs. A "peer" is an in-pipeline **self-registered** Agent
(`mcp__aaw__agent_register`) beside the always-present Director:

| Tier | Peers | Engage when | Roster |
|---|---|---|---|
| **Solo** | 1 | trivial / mechanical — a doc reconcile, a 1-line fix, a re-pin, a version digit | Director + 1 builder (Mars); Venus skipped, Apollo async |
| **Duo** | 2 | NORMAL additive capability, the triad clean/existing | Venus + Mars; Director verifies; Apollo folds async |
| **Trio** | 3 | Apollo **MANDATORY** (a new process/lease surface · a destructive at-rest op · a frozen-line touch) **OR** a docs/stories-heavy rung | Venus + Mars + Apollo |
| **Squad** | 4+ | **HIGH-risk with a WIDE design space** | a dual-architect design-ahead (2 Venus, divergent lenses) and/or a Mars-1/Mars-2 split + a specialist, + Apollo |

The router is **enforced, not advisory**: the Director records the chosen tier as a `tool_x_decision` at
bootstrap (the *formation ruling*), and `mcp__aaw__status(scope)` must then show **exactly that tier's
registered peers** — no more (over-ceremony is the ewr.4.1 footgun — ~370k tokens, zero shipped), no fewer
(under-staffing a HIGH-risk rung skips the mandatory Apollo). A tier can be **re-graded mid-build** (footgun 8:
a surfaced destructive op bumps NORMAL→HIGH, Duo→Trio) — ceremony scales, **the gate ladder never**. The
dual-architect *design-ahead* is the **Squad front**; once it has delivered (the KB + the ruled triad), the live
build runs the **Squad back-half** (Mars + Apollo) and the spent front is not re-spawned. **Cross-/compact
reconnect:** the aaw tools defer after a compaction — re-`ToolSearch` the spine and re-run `mcp__aaw__status`
as the first act, BEFORE any ledger write or spawn (an `agents:null` with a populated ledger is the FAKE-N
*inverse* — work no registered agent can attest; `emq3.3-L1`).

- **Match the formation to the rung.** A trivial / mechanical rung (a doc reconcile, a one-line fix, a re-pin)
  runs as ONE builder under the Director — not Venus + Mars-1 + Mars-2 + the full battery. A NORMAL capability
  rung runs the standard loop. A HIGH-risk rung (a new process/lease surface, a destructive at-rest op, a
  frozen-line touch) runs the full battery + may fan out a second architect. What scales is the number of peers
  and passes — the gate ladder that applies is **always run in full**; rigor never scales down.
- **Confirm-don't-rebuild a proactive scope extension** (footgun 8): when a peer builds a surface before the
  directive lands, the Director re-confirms it against the ruling — never re-spawns to redo it.
- **[PROPOSED ewr.4.1-L1 — ship the substance; Director to ratify] Commit the working in-boundary slice; do not
  let a peripheral coordination detail block the ship.** When the substance is green, pure, and in-boundary, a
  CUTOVER / VERSION / coordination detail that changes no shipped artifact must NOT gate the commit. And **default
  any decision that does not change the shipped artifact** rather than asking the Operator — reserve
  `AskUserQuestion` for forks that move the build, not for choosing a version digit. ewr.4.1 burned ~2h / ~370k+
  subagent tokens and shipped ZERO because a ~200-line LOW-risk client-contract change ran the full team and then
  spun on (and over-asked the Operator about) a version number the Operator ultimately cancelled. The rung's own
  prompt marked risk=LOW (Apollo optional); per "rigor is constant, only ceremony scales" above, a LOW-risk
  ~200-line client-contract change is a ONE-builder pass — match the formation to the stated risk.
- **A generated bundle is WRITE-ONLY.** Never `Read` / `grep -n` / `git diff` a generated artifact (a stories
  catalog, a fan-out bundle) to verify it — that burns context on output you produced. Verify the GENERATOR: the
  source test, `grep -c` for the expected count, the running-server / re-run check. The artifact reproduces from
  one documented command (the story-gen discipline below) — trust the command, not a re-read.

**LAW-1 (no role-play):** every peer is a REAL `Agent` spawn that self-registers (`mcp__aaw__agent_register`);
a registered id without a spawned agent is FAKE-N. **The persistence law:** a verifier records its verdict
(`tool_x_report` / a `SendMessage`) **before** going idle — an idle notification carries no findings, and a
verdict that lives only in an agent's context is, for the audit, indistinguishable from work never done (the
emq-3-3 Apollo halt — ~1h47m, then idle, no Y-n — is why this is a law).

## The boundary

`echo/apps/echo_mq` (+ the ONE named `echo/apps/echo_wire` seam a rung touches — the emq.1 resubscribe
precedent). **No third app** — a rung builds the bus, never its consumers. `echo/mix.lock` ships only if a real
dep moved (expect EXCLUDED). **Out-of-band — never in an emq commit:** the sibling/consumer apps
`echo/apps/{codemojex,echo_bot}`, `docs/{echo/art,echo/mesh}`, `docs/fsharp`, `html/`, `.claude/skills/mesh-writer`.
The `git commit -- <pathspec>` law (never `git add -A`) protects against sweeping any pre-staged sibling.

## The EchoWire client seam (forward — adopt the new wire's construction half)

`echo/apps/echo_wire` now ships the **construction** half it never owned: `EchoWire.Pipe` (the `ewr.1.1`
founding rung — a `%Pipe{conn, via, cmds}` accumulator threaded by `|>`, a curated six-family verb set +
`command/2`, flushing once through `Connector.pipeline/3`) — the fluent builder that replaces hand-written
nested `[[binary]]` literals (positional flags kept correct by eye). **echo_mq is the downstream consumer that
adopts it:** going forward, a rung that assembles **multi-command host logic** (a pipeline of two-plus commands
built host-side) constructs it with `EchoWire.Pipe`, not a hand-rolled `Connector.pipeline` list. The boundaries
(Operator ruling, this session):

- A **single inline `Script.new/2` eval stays on the frozen Script path** — the Pipe is for multi-command
  *construction*, not a one-shot Lua eval (emq.4.2's group-scoped reap is one eval, so it does NOT wire the Pipe).
- The adoption is a **dedicated, separately-scoped wiring rung** that converts existing call-sites + proves the
  frozen floor — **never folded into a capability rung's diff**.
- The wire stays frozen below the facade: `EchoWire.Pipe` is a NEW module above `Connector`, never a connector edit.

## The gate ladder (the operating procedure)

- `asdf current erlang` — **re-probe `.tool-versions`, never hardcode**; inside `echo/` it resolves to
  **28.5.0.1** (the old `ASDF_ERLANG_VERSION=28.1` advice is DEAD). `redis-cli -p 6390 ping` → `PONG`
  (the live engine is **Valkey on 6390**, fence key `{emq}:version` = the current `@wire_version` — climbs per rung, `DEL` + re-seed on a bump).
- `TMPDIR=/tmp mix compile --warnings-as-errors` — **per touched app**, clean.
- `TMPDIR=/tmp mix test --include valkey` — **inside the touched app's dir**; umbrella-wide `mix test` is
  **BANNED** (the full suite hangs).
- `EchoMQ.Conformance.run/2` → `{:ok, n}` — the **additive-minor law**: every prior scenario byte-unchanged
  (name + contract + verdict-body, git-verified), each new one probe-registered in the SAME change, the count
  re-pinned in BOTH pinning tests (`conformance_scenarios_test.exs` + `conformance_run_test.exs`).
- **The ≥100 determinism loop** — only for an id-minting / process / engine suite (the same-ms branded-id mint
  hazard); the loop OWNS the machine (no concurrent server, no sibling heavy I/O). One green run is not proof.
- **Match the gate's rigor to the rung's HAZARD — the loop is not the universal gate.** The ≥100 loop answers
  ONE hazard (id-mint / process / lease *determinism* — the same-ms mint collision). A **destructive at-rest op**
  has a different hazard — **blast radius**, not determinism — and the right gate is the **mutation battery**: a
  defect injected in BOTH failure directions (over-reach — touch a forbidden key; under-clean — skip a required
  delete) and each confirmed CAUGHT, plus a blast-radius scope probe. A destructive script that uses **no
  `SCAN`/`KEYS*`/wildcard** is **blast-radius-bounded by construction** — its maximum damage is provable by
  reading the declared key list, and a conformance scenario asserting the SURVIVORS (the in-flight counter, a
  sibling lane, the registry) is the proof. Running the ≥100 loop on such a rung **forges load the rung did not
  introduce** (no mint/TIME/process); skip it and state the determinism posture honestly. (emq.4.1: the
  destructive `@gdrain` was gated by the mutation battery — over-reach `HDEL gactive` + under-clean skip-ring-
  `LREM` both caught — not the loop; F4.)
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
8. **A rung's risk tier can change MID-BUILD — surface, do not decide, then re-grade.** A destructive-treatment
   choice (build the at-rest delete now vs park it) can surface only once the build is underway and the surface
   is concrete. Mars **surfaces** it as a build-time judgment — never decides it — the **Operator rules** (via
   the Director's `AskUserQuestion`), and a BUILD ruling **re-grades the rung** (NORMAL → HIGH) AND its verify
   depth (the destructive op draws the mutation battery + the blast-radius probe — footgun-adjacent to the gate
   ladder's hazard-match rule). The emq.4.1 lane-scoped drain (R3) emerged mid-build, was ruled BUILD (D-5), and
   bumped the rung NORMAL → HIGH (F5). When a builder proactively EXTENDS scope (builds the surface before the
   directive lands), the Director **confirms-don't-rebuilds** — the proactive build is re-confirmed against the
   ruling, not redone.

## The spec home + the file convention (2026-06-15)

- `specs/` holds **ONLY** the chapter triads `emq.N.{md,stories.md,llms.md}`. Each chapter's **decomposition** —
  its `prompt`/`design`/`tooling` docs **and** its sub-rung quads (`emq.N.M.{md,stories,llms,prompt}.md`) — lives
  in a same-named folder **`specs/emq.N/`** (e.g. `specs/emq.2/`, `specs/emq.3/`).
- The **run-ledgers** (`emq-N-M.{progress.md,registry.json}`) live archived in **`specs/progress/`** (they were
  burying the key artifacts; relocated `fd8876d5`).
- The **forward-feature 5-section catalog** (Goal/Rationale/5W/Scope/AC, by category) is
  [`../emq.features.md`](../emq.features.md) **Part C**.
- The **generated story catalog** is `docs/echo_mq/stories/` — produced by `mix echo_mq.stories` from
  `echo/apps/echo_mq/test/stories/*_story_test.exs`; **generated, NEVER hand-edited** (it cannot drift from
  code). **The story-gen discipline (the ewr.1.1 F-1 lesson):** a committed generated artifact **reproduces from
  ONE documented command, byte-for-byte** (`mix echo_mq.stories` run twice is `diff`-clean). The shared task
  harvests over a fixed glob and can **over-produce** into a per-feature out dir — that is a **finding to
  SURFACE** (the `--match <substring>` scoping fix is additive + default-byte-identical, in-scope for the rung),
  **never a hand-prune** into a non-idempotent artifact. The hand-authored `<rung>.stories.md` USER stories
  (Venus's, the acceptance face a person signs) are a **DISTINCT layer** from the GENERATED proof — neither
  edited to fork from the other.
- The **per-agent calibrations** are `program/emq.{venus,mars,apollo}.md` (this folder).

## The live frontier (re-true at each rung close)

- **Movement I CLOSED — closed at conformance 52/52.** Shipped: the foundation `emq.0` · `emq.1` (scheduler/retry)
  · the `emq.2` parity cluster (2.1 read · 2.2 operator · 2.3 watch · 2.4 closer) · the `emq.3` flow family (3.1
  single-queue · 3.2 child-result reads · 3.3 cross-queue · 3.4 failure-policy/bulk · 3.5 grandchildren/deep
  recursion). The flow fan-in is eventually-consistent across queues (the `flow:outbox` on the child slot + the
  `Pump` sweep + the `:processed` HSETNX idempotent deliver); grandchildren are host-orchestrated over byte-frozen
  scripts.
- **Movement II OPEN — live conformance 54/54.** emq.4 (groups deepened, 4.1–4.4) is BUILDING: **`emq.4.1` the
  fair-lanes control plane SHIPPED** (HIGH-risk) — `Lanes.reassign/4` (the multi-key atomic lane move; re-aims
  the RETIRED v1 `changePriority`) + `Lanes.drain/3` (the lane-scoped destructive drain; blast-radius bounded by
  construction), conformance 52 → 54 (additive minors; the wire fence climbs per rung — `echomq:2.4.x`). **NEXT on the
  ladder:** emq.4.2 group-aware recovery · 4.3 the park-don't-poll metronome (HIGH-risk) · 4.4 weighted/deficit
  rotation + the starvation drill · then emq.5 batches · emq.6 lifecycle controls · emq.7 cache deepened · emq.8
  the proof stack (conformance + engine matrix + telemetry + benchmark). emq.7 is least coupled to the machine and
  may be pulled forward (an Operator call). The 3.x stream tier (`emq3.*`) is PROPOSED, hard-gated on emq.0.
- **The version arc — ONE protocol version, climbing per rung.** The
  wire fence IS the protocol version, and it **climbs by a minor each rung through the 2.x line**: `echomq:2.4.1` (emq.4.1) →
  `echomq:2.4.2` (emq.4.2) → … (emq.8 closes the 2.x line); the `echomq:3.0.0` **MAJOR** lands with the **Stream Tier (EchoMQ 3.0)**, after Movement II. Two artifacts carry
  the same number and a rung bumps **both** by one — the **wire fence** `@wire_version` (the `{emq}:version`
  boot key, `echo_wire/lib/echo_mq/connector.ex:33` — the protocol marker) and the **release label**
  (`echo/apps/echo_mq/mix.exs` + `echo_wire/mix.exs` `version:`). The connector's fence **logic** (`fence/2`,
  the framing) stays FROZEN — only the `@wire_version` **constant** moves; the **single-owner wire** makes
  per-rung climbing safe (no external clients — the connector + the server deploy as a unit, so the exact-match
  fence is a self-consistency check, not a cross-version gate, and a minor bump is a versioned advance, never a
  structural wire break).
  - **The `:fence` scenario + `connector_test` are VERSION-AGNOSTIC** — they assert the live key `==
    EchoMQ.Connector.wire_version()`, so they track the marker and **never need per-rung editing**. The one
    constant `@wire_version` is the single source of truth (the trap was a *hardcoded* `echomq:2.0.0` across
    three sites; de-hardcoding kills it). Re-modeling that version-marker scenario is sanctioned and distinct
    from the additive-minor law, which governs **capability** scenarios.
  - **A fence bump re-seeds the live key.** `@wire_version` exact-matches `{emq}:version` and seeds it only when
    nil (`SET NX`), so a bump needs a one-time `DEL {emq}:version` and the next connector boot re-seeds the new
    value (a prod ops migration; the test env DELs it). The connector logic is untouched.
  - **What a rung ships:** an **additive-minor** capability (new conformance scenarios — the count grows — +
    host verbs, no new wire class) **plus the one-line `@wire_version` + `mix.exs` bump**. (SUPERSEDES the
    earlier 'two-planes / fence frozen at 2.0.0' framing — **emq.4.2-D3**, the Operator's reopened Fork-2; the
    fence was always meant to climb per the founding rule.)
  - **[PROPOSED ewr.4.1-L1 — the client-contract carve-out; Director to ratify] The fence climbs ONLY when
    the rung adds a server-side capability scenario.** The blanket "every rung bumps `@wire_version`" above is
    sound for an echo_mq additive-minor (4.1/4.2 grew the conformance count → the bump is a benign in-boundary
    self-consistency advance). It is the WRONG default for a rung whose substance changes **no wire-protocol and
    no keyspace** — a CLIENT-CONTRACT-ONLY rung (e.g. ewr.4.1's Pool-fronted enqueue). Such a rung **DEFAULTS to
    NO fence climb**: the change is invisible to the wire, so the fence has nothing to mark. The cost of getting
    this wrong is concrete (ewr.4.1): the bump edited the FROZEN base `echo_wire` for a change that needed no
    fence, then the stale `{emq}:version` refused 320/392 valkey tests and the auto-classifier (correctly) denied
    the shared-fence reset — a self-inflicted block, then a version-number adjudication the Operator cancelled
    outright. **Test:** does the rung add a `Conformance` scenario that exercises a NEW server-side behaviour? If
    no → no `@wire_version` bump, no frozen-base edit. The version number, when it DOES move, is a one-line
    in-boundary mechanic (the three reflected literals) — **never a frozen-`echo_wire` edit that gates the ship,
    never an Operator adjudication of the digit.**
