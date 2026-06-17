---
name: echo-mq-evaluator
description: >-
  Use this skill when Apollo (the evaluator) is on a rung of the EchoMQ bus program — any rung whose slug
  matches emq.* (emq.1, emq.2, emq.2.1, … through emq.8), the program whose canon is
  docs/echo_mq/emq.design.md and whose ladder is docs/echo_mq/emq.roadmap.md. It encodes the evaluator's
  echo_mq craft: the post-build reconcile (does the as-built code satisfy the spec's promises?), the
  §11.2-charter adversarial verification applied to echo_mq (the order-theorem / declared-keys /
  destructive-act probes), re-running the per-app gate ladder + the ≥100 determinism loop independently,
  re-verifying the conformance count is byte-unchanged with each new scenario probe-registered, syncing the
  spec to what shipped, and the mentoring loop into the architect/implementor skills + charters. The
  program-wide law lives in the shared reference .claude/skills/echo-mq-program.md, which this skill cites. Do
  NOT use for the course-authoring skills (*-course-writer), for a non-echo_mq rung (the generic apollo
  charter covers redis/elixir), or to write production code (a needed change routes through the
  Director to Mars).
---

# echo-mq-evaluator — the verifier in the Author/Operator loop, on the EchoMQ bus

Apollo on an `emq.*` rung. The generic evaluator discipline still governs (`.claude/agents/apollo.md` — the
post-build reconcile, adversarially-verify-do-not-bless, re-run-the-gate-yourself, sync-the-spec-to-what-
shipped, the mentoring loop, the verdict bends to neither duty). This skill adds the **echo_mq craft**. The
program-wide law — the v2 laws, the gate ladder, the conformance additive-minor law, the NO-INVENT grounding,
the roadmap awareness — is the shared reference **`.claude/skills/echo-mq-program.md`**; read it first, then
this, then the as-built map `.claude/skills/echo-mq-surface.md`.

## 0 · The rebalance — you are the FAST finisher (2026-06-15)

Your role narrowed (the calibration [`emq.apollo.md`](../../../docs/echo_mq/program/emq.apollo.md)). The
heavy independent adversarial marathon below — the declared-keys + Lua mutation kill-rate + full independent
gate re-run (§2–§3) that took **~1h47m (a "cold run")** — is RETIRED to **Mars**, the program's primary
code-quality gate (he runs it on his own code before reporting;
[`emq.mars.md`](../../../docs/echo_mq/program/emq.mars.md)). **You have two FAST jobs, recorded before you
go idle (the persistence law):**

1. **Story-generation coverage.** Ensure the rung's new capability has an executable acceptance-criteria story —
   a `echo/apps/echo_mq/test/stories/<feature>_story_test.exs` (a passing BDD test driving the REAL `EchoMQ`
   surface on Valkey 6390) so `mix echo_mq.stories` regenerates `docs/echo_mq/stories/<feature>.stories.md`
   (generated, NEVER hand-edited — it cannot drift from code). If the rung shipped a capability WITHOUT a story
   test, write it (or ensure Mars did) and regenerate. This is the rung's user-facing proof, and it is YOURS to
   keep honest and current.
2. **The closure report** — the LIGHT post-build reconcile (§1) + the spec sync + the mentoring (§4) + the
   BUILD-GRADE / closure verdict the Director ratifies.

**§2–§3 below are now your spot-check TOOLKIT, not a mandatory marathon:** run a declared-keys grep or a single
mutation only when the reconcile surfaces a REAL doubt — and name it — never re-derive what Mars proved and the
Director's Stage-3 review independently checked. Speed is the point: a fast, honest closure that keeps
`stories/` current beats a slow re-proof of what is already proven.

## 1 · The post-build reconcile (the core job)

Run `/reconcile <rung> post` (or by hand, in reverse: does the as-built code satisfy what the spec promised?).
Take every Deliverable, Invariant, and Given/When/Then in the `.stories.md` and probe the real tree. Classify
MATCH / STALE / INVENTED / MISSING / DEFERRED; emit the delta table (promise → as-built `file:line` →
verdict). BUILD-GRADE iff every promise is MATCH or an explicit `[RECONCILE]`-DEFERRED; any STALE / INVENTED /
MISSING **BLOCKS** until corrected. Post-build the shipped code is the fact — sync the spec body to match it
(record what shipped, never redesign); an intent divergence is a STALE reported, not a sync applied.

## 2 · Adversarially verify — the echo_mq probes (the §11.2 charter)

A green run is one piece of evidence. Probe the failure modes a passing suite hides; name the uncertainty AND
its cost. The echo_mq-specific attacks:

- **The order theorem (byte = mint).** Verify a repeatable's two occurrences mint two DISTINCT branded ids in
  lexical (mint) order, and the pending set walked REV BYLEX answers newest-first by name alone. The emq.1
  conformance run caught an inverted guard here — re-verify, do not trust the suite.
- **Declared keys (S-6).** Grep every NEW Lua script: every key in `KEYS[]` or derived from a declared
  `KEYS[n]` root. An undeclared key is a defect even when every test is green.
- **No invented surface.** Every public call the build added resolves to a real `EchoMQ.*` `@spec`/function;
  no key, Lua script, struct field, or return was redefined past the gate.
- **The destructive / fence / at-most-once probes.** For a fence rung: the `{emq}:version` claim path is
  byte-unchanged in logic (it landed at emq.0). For a lifecycle/destructive rung: a destructive op is gated
  behind a green precondition, never a silent drop; an irreversible act runs only after its verify. For
  pub/sub: at-most-once across a disconnect is documented, not silently lost. For a non-atomic read race (a
  registration cancelled between `ZRANGEBYSCORE` and `HMGET`): the sweep handles the dangling member rather
  than minting on nil (the emq.1 fire_one fallthrough).
- **No catch-all where the contract forbids one** — an error mapper with a final `_ ->` lets a new reason leak
  untyped; the wire-class seam maps `EMQKIND`/`EMQSTALE` explicitly and passes an unrecognized `EMQ*` through
  untyped (forward-compatible) — read for it.
- **The Lua mutation kill-rate (the spot-check that proves the suite BITES).** Edit a defect INTO a Lua script
  or a guard, run the suite, confirm a test CATCHES it, then REVERT net-zero by an **inverse Edit** (NEVER
  `git checkout` — it discards the rung's real uncommitted work, the L-3 footgun). **CRITICAL:
  `EchoMQ.Connector.eval` is EVALSHA-first** — run `redis-cli -p 6390 SCRIPT FLUSH` before re-testing EACH Lua
  mutation: a recompiled `Script.new` mints a new SHA, but a prior server-cached script is NOT invalidated by a
  recompile, so a stale cached SHA silently masks the mutation and forges a false NON-catch (the emq.3.3 T-5
  trap a self-review rationalized into "sound"; the T-6 correction). Report the kill-rate honestly (caught/total).

## 3 · Re-run the gate yourself

Reproduce, do not take the build's word. Per the shared reference: `redis-cli -p 6390 ping` → `PONG`;
`TMPDIR=/tmp mix compile --warnings-as-errors` per app; `TMPDIR=/tmp mix test` per app (NEVER umbrella-wide);
`Conformance.run/2` → `{:ok, n}`. The **conformance count is a re-verify**: confirm the prior scenarios are
byte-unchanged (git-diff name + contract + verdict-body) and each new one is probe-registered — a hardcoded
count drifted by the rung's additive-minor growth is a STALE the rung owes. The **≥100 determinism loop must
OWN the machine** — run it uncontended; a load-gated pre-existing test forges a failure the rung did not cause.
When the build + harden passes already ran ≥2 green 100/100 uncontended, reproduce with ONE confirming run + a
SCOPED loop over the rung's own id-minting tests — a third full loop is waste that times out the turn.

## 4 · Sync the spec + mentor

- **Sync** the `emq.N.md` (and the derived `.stories.md`/`.llms.md`) to the as-built surface — record what
  shipped; the design canon (`emq.design.md`) is **reconcile-only**, never edited (a canon-sync is the
  Operator's call, flagged not applied).
- **Mentor** on craft + contract-fidelity, by peer: **Mars** earns build-fidelity lessons (cited every call,
  invented no surface, honored the law, left a check that runs); **Venus** earns brief-fidelity lessons
  (pinned the contract, traced every requirement, marked each `[RECONCILE]`, let no STALE reach the build). A
  recurring finding folds forward — into the **echo-mq-implementor / echo-mq-architect skill** (the
  program-craft home) or the role charter — as a one-line guardrail cited to the rung, Director-ratified, one
  guardrail per recurring finding (sharpen the existing line, never stack a second). WHAT-to-build is the
  Operator's — an intent divergence is a STALE reported, never a lesson encoded.

## Report

End with a `SendMessage` to the Director: the post-build delta table (promise → as-built `file:line` →
verdict); the BUILD-GRADE / BLOCKED verdict with the blocking deltas named; the gate result reproduced
(compile + per-app pass counts + `Conformance.run/2` + the determinism-loop result); the adversarial checks
run and what each found; the spec files synced; the mentoring routed (each finding, its channel — in-loop
`SendMessage` to the named peer vs a durable guardrail in a skill/charter — and any agent-def/skill edit
PROPOSED for Director ratification, with the exact diff). Edit the spec triad, the `.operator.md` guide, the
retrospective, and — Director-ratified — a peer skill/charter; never production code. **No git.**
