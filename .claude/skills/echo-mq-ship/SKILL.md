---
name: echo-mq-ship
description: >-
  Use this skill to ship ONE spec-driven rung of the EchoMQ bus program (the umbrella apps
  echo/apps/echo_mq above echo/apps/echo_wire) — any rung whose slug matches emq.* (emq.2.2, emq.2.3, emq.3
  … through emq.8, or an emq3.* stream-tier rung) — end to end through the aaw Flat-L2 lead-team,
  Director-supervised, to one ratifying LAW-4 commit. It is /x-mode with the echo_mq context pre-loaded: it
  adds nothing to the laws — it binds them to the echo_mq apps, the v2 protocol laws, the per-app gate ladder,
  and the echo_mq-SPECIALIZED build team (Venus loads the echo-mq-architect skill, Mars loads
  echo-mq-implementor; the Director verifies code + invariants; Apollo — the Mentor — loads echo-mq-evaluator
  out of the per-rung pipeline). The INPUT is the rung's
  docs/echo_mq/specs/<rung>.prompt.md runbook + its triad; the canon is docs/echo_mq/emq.design.md and the
  single roadmap docs/echo_mq/emq.roadmap.md. Triggers: "ship emq.2.2", "run/launch the emq.2.3 pipeline",
  "echo-mq-ship <rung>", "as Director fan out the emq.N lead-team", or any request to build an echo_mq rung
  that already has a .prompt.md + spec triad. Do NOT use for the static-HTML courses (the *-course-writer
  skills), the elixir rungs (the generic mars charter), or generic documents.
---

# ECHO-MQ-SHIP — ship an echo_mq-program rung via the supervised lead-team

This skill ships ONE spec-driven rung of the **EchoMQ bus program** — the parity cluster (`emq.2.1/2.2/2.3`),
the Movement-I/II family rungs (`emq.3`–`emq.8`), or a 3.x stream-tier rung (`emq3.*`) — end to end through
the aaw Flat-L2 lead-team, Director-supervised, to one ratifying **LAW-4 commit**. It is **`/x-mode` with the
echo_mq context pre-loaded**: it adds nothing to the laws — it binds them to the echo_mq apps, the v2 protocol
laws, the per-app gate ladder, and the echo_mq-specialized agents, so the run does not re-derive them.

**It is a binding layer, not a re-implementation.** Three sources of truth hold the discipline — defer to them:

1. **`.claude/commands/x.md`** + the **`/x-mode`** skill — the LAWS (CLAUDE_LAWS 1/1a/2/3/4), the pipeline
   (Venus strawman + Arms → Director rules the Arms via `AskUserQuestion` → Mars build + self-verify → Director
   verify → Mars-2 harden → Director ship; Apollo mentors after the ship, out of band), the §5
   spawn protocol, the §6 audit tools, the §10 commit rules. **The laws live there; this skill enforces them on
   an echo_mq rung.** Read the `/x-mode` skill first — everything in it applies; the deltas below are the
   echo_mq binding.
2. **The echo_mq program references** — `.claude/skills/echo-mq-program.md` (the v2 laws, the gate ladder, the
   conformance additive-minor law, the roadmap awareness, the NO-INVENT grounding, the process locks) +
   `.claude/skills/echo-mq-surface.md` (the as-built module / Lua / key map) + the canon
   `docs/echo_mq/emq.design.md` (S-1..S-7, the ADRs, the seams). **Read them in Step 0; every peer loads its
   echo-mq-* skill, which cites them.**
3. **the rung's spec** — the triad under `docs/echo_mq/specs/` (`<rung>.{md,stories.md,llms.md}` +
   `<rung>.prompt.md` + the `<scope>.progress.md` ledger). The `<rung>.md` body is authoritative; the
   `.prompt.md` is the authoritative scope for the run.

## What is different from a generic /x-mode run (the echo_mq binding)

- **The build team is echo_mq-SPECIALIZED via SKILLS, not a dedicated agent.** Spawn each peer
  `subagent_type: "general-purpose"`, adopt its `.claude/agents/<role>.md` charter, AND **load its echo-mq-*
  skill** — that is the "specialized agent" of this protocol:
  - **Venus** (architect) → `.claude/agents/venus.md` + **load `echo-mq-architect`** (the lag-1 reconcile, the
    triad-to-the-v2-laws, carving the parity surface, surface-the-fork).
  - **Mars** (implementor) → `.claude/agents/mars.md` + **load `echo-mq-implementor`** (the spec-cited build
    inside the boundary, the Lua laws, the conformance additive-minor mechanics, the gate ladder).
  - **Apollo** (the Mentor — **out of the per-rung pipeline**) → `.claude/agents/apollo.md` + `echo-mq-evaluator`
    for the craft. Apollo does NOT build, verify, or finish a rung; the **Director** verifies code + invariants
    and consolidates the rung's findings, then Apollo folds them into the agent calibrations (PROPOSE-ONLY).
  Venus + Mars self-register via `mcp__aaw__agent_register` from their own context (LAW-1; no narrated spawns).
- **The v2 master invariant binds every rung** (the wire broke ONCE): braced `emq:{q}:` keyspace · branded
  `JOB` ids gated at the key builder · **every Lua key in `KEYS[]` or derived from a DECLARED `KEYS[n]` root**
  (the A-1 rule — an `ARGV`-passed base is NOT a declared root; a script that derives a key from a base must
  still declare ≥1 real `KEYS[]` entry to pin the `{q}` slot — the emq.2.1 F-1 finding, gate-invisible on
  single-node Valkey) · server clock (`TIME`) where a lease is touched · honest-row conformance · additive
  registration is a protocol minor, a wire break is a major.
- **The boundary** is `echo/apps/echo_mq` (+ the ONE named `echo/apps/echo_wire` connector seam a rung touches
  — the emq.1 resubscribe seam is the precedent).
- **The gate ladder is the echo_mq one** (`.claude/skills/echo-mq-program.md` §The gate ladder), NOT a generic
  `mix test`. Hold each stage's gate against it:
  - `asdf current erlang` (re-probe `.tool-versions`, never hardcode) + `redis-cli -p 6390 ping` → `PONG` (the
    live engine is **Valkey on 6390**, not the default 6379).
  - `TMPDIR=/tmp mix compile --warnings-as-errors` **per touched app** — never umbrella-wide.
  - `TMPDIR=/tmp mix test` **inside the touched app's dir** — umbrella-wide `mix test` is **BANNED**; add
    `--include valkey` for a wire rung.
  - `EchoMQ.Conformance.run/2` → `{:ok, n}`: the **additive-minor law** — the prior scenarios pass
    byte-unchanged (name + contract + verdict-body identical, git-verified) and each new one is
    probe-registered in the SAME change; re-pin the count in both pinning tests.
  - **The ≥100 determinism loop** ONLY for an id-minting / process / engine suite (the same-ms branded-id mint
    hazard); the loop OWNS the machine. **A pure-read / no-process rung** (emq.2.1's posture) runs a multi-seed
    sweep instead and states the determinism posture honestly — running the loop would forge load the rung did
    not introduce.
- **The risk tier decides the verify depth + the design formation** (the `.prompt.md`'s declared tier): a rung
  with a **destructive at-rest operation** (a migration DELETE), a **new process or lease surface** (emq.2.3's
  worker-side lock plane), a **frozen-line touch**, or an **auth/deploy** dimension is **high-risk** → the
  Director's verify deepens (the ≥100 determinism loop, the full mutation battery) and the design fork may fan
  out a **second architect** (two Venus, the same Arms, divergent lenses —
  [`aaw.architect-approach.md`](../../../docs/aaw/aaw.architect-approach.md)). A **pure-read / additive-verb**
  rung (emq.2.1) is normal → Venus's reconcile + the Director's verify are the floor. Apollo is **never** a
  pipeline stage — it mentors after the ship.
- **Records freeze.** NEVER edit a frozen `{scope}.progress.md` ledger's historical content (a path, a figure,
  a verdict) — it is the audit trail of what was true then. The rung's own live ledger is where T/D/V/L/Y/Z
  land.

## 0. Bootstrap (Director, before any spawn)

Read the named rung's `<rung>.prompt.md` (the authoritative scope) + its triad + `docs/echo_mq/emq.roadmap.md`,
**and `.claude/skills/echo-mq-program.md` + `echo-mq-surface.md`**, **and the `/x-mode` skill**. Declare the
mode (**Flat-L2**) and **triage the L2 Topology Router** — Solo / Duo / Trio / Squad
(`docs/echo_mq/program/emq.program.md` §Right-sizing) from the rung's **risk tier × design-space width** —
recording the chosen tier as the **formation `tool_x_decision`**; `mcp__aaw__status(scope)` must then show
EXACTLY that tier's registered peers (no more — over-ceremony is the ewr.4.1 footgun; no fewer — under-staffing
a HIGH-risk rung skips the mandatory Apollo). Deep-reason the rung (the §0 of `/x-mode`: the 5W, the solution space incl. a do-nothing
baseline, the invariants as runnable checks, the smallest change that preserves correctness) and record it as a
`tool_x_trace` (T-n). **Confirm the Stage-1 gate is reachable** — the triad exists (or Venus authors it) and
the `.prompt.md`'s settled forks carry **no open Operator decision**; if a fork is open (a seam, a
sequencing/Arm ruling, a destructive-treatment choice), **STOP and `AskUserQuestion`** before spawning. Note
the toolchain: `asdf current erlang` (re-probe), **Valkey on 6390** (`redis-cli -p 6390 ping`).

## 1. Stand up the TRUE team (x.md §5)

`scope` = the rung slug, **lowercase-alphanumeric-and-dashes, NO dots** (`emq-2-2`, `emq-2-3`, `emq-3`, never
`emq.2.2` — `tool_x_*` and `TeamCreate` require `^[a-z0-9][a-z0-9-]*$`, and a dot split-brains the registry).
`operator` = `jonny`. `workspace` = `/Users/jonny/dev/jonnify`. `ledger_dir` = `docs/echo_mq/specs/progress` (the run-ledgers live in `specs/progress/`, NOT `specs/` — the
2026-06-15 relocation). The
sequence is `/x-mode` §1 verbatim: `mcp__aaw__init` → `aaw_spawn`+`agent_register` the `director` →
`TeamCreate(scope)` → `tool_x_trace(T-1)` opening the ledger `docs/echo_mq/specs/progress/<scope>.progress.md`,
lands the §0 derivation. **The scope slug matches the on-disk ledger filename** — `emq3-3` for the stream tier
(one unit), `emq-5-4` for a Movement-II rung; a wrong slug mints a NEW empty ledger and strands the
hand-written one (`emq3.3-L1`). Create one Task per stage. **zsh does not word-split unquoted vars** — iterate file lists with
`find … -print0 | while IFS= read -r -d '' f`, never `for f in $files`.

## 2. The pipeline (per `/x-mode` §2, echo_mq-bound)

Lift each stage's directive from the `<rung>.prompt.md`'s matching stage block; wrap it in the `/x-mode` §3
per-spawn ceremony **plus** "Read and operate by `.claude/agents/<role>.md`, then LOAD the `echo-mq-<role>`
skill (read its shared `echo-mq-program.md` + `echo-mq-surface.md`)."

**Venus** (authors the strawman triad, reconciles it lag-1 against the as-built `echo_mq`/`echo_wire` tree, and
frames the seam forks as four-part Arms — Rationale/5W/Steelman/Steward) → **Director rules the Arms** (the
**mandatory `AskUserQuestion`** — a fork is never decided silently) → **Mars-1** (design-make + build to the
brief inside the boundary, cite the spec line for every public call, the inline `Script.new/2` law (never
`priv/`), declared keys, branded `JOB`, the `EMQ*` typed refusals; register the conformance scenario + probe in
the same change; compile `--warnings-as-errors`; ship the story-generation test) → **Director verify** (a REAL
pass: fresh-gate reconcile + an independent gate re-run on Valkey 6390 + ≥1 adversarial probe incl.
declared-keys + a mutation spot-check, **Edit-in → test-catches → revert → verify `git diff --stat` clean**
net-zero, LAW-1a; the REMEDIATE list) → **Mars-2** (resume the Stage-1 Mars — one identity, two passes —
remediate + harden + the full gate ladder; REMEDIATE loop MAX 3) → **Director ship** (the solo ship-gate + one
LAW-4 commit + the Stage-6 fold + **consolidate the findings + learnings for Apollo**). The Director's verify
probes are the order theorem (byte = mint), declared-keys (grep every NEW Lua script — the F-1 class),
no-invented-`EchoMQ.*`-surface, and the destructive/at-most-once/non-atomic-read probes. **Apollo runs after the
ship, out of band** — it folds the consolidated findings into the agent calibrations (PROPOSE-ONLY,
Director-ratified under an Operator grant).

## 3. The capabilities (what an echo_mq rung builds)

- **the read plane (emq.2.1, shipped)** — pure-read introspection/metrics/rate-gate over the as-built four sets
  (the `EchoMQ.Metrics` worked example; no state transition).
- **the operator plane (emq.2.2)** — queue-wide pause/resume · drain · obliterate · update-data/progress ·
  add-log · remove-job · reprocess (dead→pending) — real transitions with `EMQ*` refusals.
- **the watch plane (emq.2.3)** — `EchoMQ.Events` (the existing connector pub/sub seam — **no `SSUBSCRIBE`**) ·
  `EchoMQ.Telemetry` (the surface; the contract is emq.8) · the lock-extension verb + an **opt-in supervised
  lock plane** + the explicit stalled-sweep · the cooperative cancel (distributed cancel is emq.6). **A process
  + lease rung → high-risk → the Director's deepened verify + the ≥100 determinism loop.**
- **the family rungs (emq.3–emq.8)** — parent/flow · groups deepened · batches · lifecycle controls · the cache
  deepened · the conformance/telemetry/benchmark proof stack.
- **the 3.x stream tier (emq3.*)** — the stream verbs, `EchoMQ.Stream`, consumer groups, retention, the archive
  — on the certified wire, hard-gated on emq.0.

Every capability is grounded in a real `echo_mq`/`echo_wire` module (`echo-mq-surface.md`), the v1→v2 parity
catalog (`docs/echo_mq/emq.features.md` — the legacy line was rewritten fresh, never lifted, then removed), or a
design §; NO-INVENT, forward-tense ("emq.N builds …") for an unshipped surface.

## 4. LAW-4 — the single ratifying commit (Director-only, per x.md §10)

At `tool_x_complete` (Z-n), exactly once: the Director's verify clean + the echo_mq gate green; **≥1
`tool_x_decision` (D-n)** + the **Z-n** written this turn; `git status
--short` AND `git diff --cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then a
**pathspec** commit — `git commit -F <msg> -- <exact paths>` (or `git add <explicit paths>` for new files then
`git commit -F <msg>`); **NEVER `git add -A`, NEVER a bare commit** (the Operator pre-stages out-of-band). The
rung commit is the rung's **measured surface ONLY** — the code (`echo/apps/echo_mq/**`) + the rung triad + the
`<scope>.progress.md`/`.registry.json`; **when the tree is entangled** with other concerns (a roadmap
consolidation, a cross-program rename, a sibling design phase), commit those as **separate scoped commits** so
the LAW-4 commit stays a faithful record of exactly the rung — do not let one status-line edit sweep an
unrelated reconcile into the rung commit. **Stage-6 fold:** flip the rung's status in the SINGLE
`docs/echo_mq/emq.roadmap.md` (+ `emq.progress.md`), surface the next frontier, and — under an **explicit
Operator grant only** — fold a recurring finding into the `echo-mq-implementor`/`echo-mq-architect` skill or a
role charter (one guardrail per finding). The message cites the slug, the Z-n, the D-n, and the Y-n report.

## 5. Quality gate (before Z-n, mirrors /x-mode §5)

- [ ] The `<rung>.prompt.md` + triad + roadmap + `echo-mq-program.md`/`echo-mq-surface.md` + the `/x-mode` skill
      read; mode declared Flat-L2.
- [ ] T-n derivation, D-n per locked contract, L-n per surprise written to `<scope>.progress.md`.
- [ ] Every peer is a REAL self-registered `Agent` spawn (`general-purpose` + charter + the loaded echo-mq-*
      skill; no FAKE-N); the Director called no Edit/Write on production code EXCEPT a mutation spot-check
      reverted **net-zero** (LAW-1a).
- [ ] The Director's verify was a real pass (echo_mq-gate re-run on Valkey 6390 + an adversarial probe incl.
      **declared-keys** + a mutation spot-check), not a glance; **every design Arm was ruled via
      `AskUserQuestion` before the build**; a high-risk rung deepened the verify (≥100 loop, full mutation battery).
- [ ] The echo_mq gate ladder is green: per-app compile `--warnings-as-errors` + per-app suites (NEVER
      umbrella-wide) + `Conformance.run/2` with the prior scenarios byte-unchanged + the new ones
      probe-registered + (process/mint rung) the ≥100 determinism loop. The boundary grep is empty
      (the consumer/sibling apps `echo/apps/{codemojex,echo_bot}` + `mix.lock`).
- [ ] LAW-4: Z-n written → exactly one Director pathspec commit per concern; nothing foreign in `--cached`; the
      frozen ledgers untouched.
- [ ] `mcp__aaw__status(scope)` shows the registered peers (no FAKE-N).

## 6. Map

- The laws + pipeline: `.claude/commands/x.md` + the `/x-mode` skill.
- The echo_mq program references: `.claude/skills/echo-mq-program.md` (the law) + `echo-mq-surface.md` (the
  as-built map).
- The role skills the peers load: `.claude/skills/echo-mq-{architect,implementor,evaluator}/SKILL.md`.
- The role charters they wrap: `.claude/agents/{venus,mars,apollo}.md` (each carries an `## echo_mq program`
  block pointing at its skill).
- The canon + the single roadmap: `docs/echo_mq/emq.design.md` · `docs/echo_mq/emq.roadmap.md`.
- The specs (source of truth): `docs/echo_mq/specs/<rung>.{md,stories.md,llms.md,prompt.md}`.
- The run's audit trail: the rung's `<scope>.progress.md` + `mcp__aaw__status`.
