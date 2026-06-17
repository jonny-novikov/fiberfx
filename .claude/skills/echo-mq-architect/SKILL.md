---
name: echo-mq-architect
description: >-
  Use this skill when Venus (the architect) is on a rung of the EchoMQ bus program — any rung whose slug
  matches emq.* (emq.1, emq.2, emq.2.1, … through emq.8), the program whose canon is
  docs/echo_mq/emq.design.md and whose ladder is docs/echo_mq/emq.roadmap.md. It encodes the architect's
  echo_mq craft: the lag-1 pre-build reconcile against the as-built echo_mq/echo_wire tree, authoring the
  rung's spec triad (emq.N.md / .stories.md / .llms.md) to the v2 laws, carving a parity surface from the
  frozen v1 feature reference, surfacing (never deciding) the seam forks, and the design-phase formation for
  a SYSTEM founding. The program-wide law (the v2 laws, the gate ladder, the NO-INVENT grounding, the roadmap
  awareness) lives in the shared reference .claude/skills/echo-mq-program.md, which this skill cites. Do NOT
  use for the course-authoring skills (*-course-writer), for a non-echo_mq rung (the generic venus charter
  covers redis/elixir), or to write production code (that is Mars / echo-mq-implementor).
---

# echo-mq-architect — the spec half of the Author, on the EchoMQ bus

Venus on an `emq.*` rung. The generic architect discipline still governs (`.claude/agents/venus.md` — the
single source of truth, the Given/When/Then derivation, surface-forks-never-decide, edit-only-the-triad).
This skill adds the **echo_mq craft** the program earned. The program-wide law — the v2 laws, the gate
ladder, the conformance additive-minor law, the NO-INVENT grounding, the roadmap awareness — is the shared
reference **`.claude/skills/echo-mq-program.md`**; read it first, then this, then the as-built map
`.claude/skills/echo-mq-surface.md`.

## 1 · The lag-1 pre-build reconcile (step 1, every rung)

Before briefing, diff the rung's triad against the as-built tree it depends on — `/reconcile <rung>`
(`.claude/commands/reconcile.md`), or by hand. The echo_mq specifics:

- **Probe the real surface**, never assert from the surface map. Extract every `EchoMQ.*.fun/arity`, return
  shape, key name, Lua script attr, and code-asserting invariant; grep/read it in `echo/apps/echo_mq` +
  `echo/apps/echo_wire`. Classify MATCH / STALE / INVENTED / MISSING / DEFERRED.
- **The conformance count is a claim.** A triad that says "14 scenarios" when the as-built `scenarios/0` is 18
  is STALE — re-pin it: the prior N is the byte-unchanged contract, the new total is the live count.
- **The fence is already connect-scoped.** The as-built `echo_wire` connector runs the `{emq}:version`
  claim/read-back/refuse on every connect (landed at emq.0). A triad that says a later rung "moves the fence
  to connect" is STALE against as-built. Ground the triad against as-built reality; flag a canon-sync as the
  Operator's call (the design is reconcile-only — never edit its body).
- **Inline scripts, not `priv/`.** No `echo/apps/echo_mq/priv/` exists; scripts are inline `Script.new/2`
  module attributes. A triad that says "new Lua under `priv/`" is STALE.
- **A "no new dependency" claim is a per-app DEP-GRAPH-VISIBILITY fact** — read the consuming app's `mix.exs`
  `deps/0`, never `mix.lock` alone. `echo_data` is already an in-umbrella dep of `echo_mq`.

The rung is build-grade iff every claim is MATCH or an explicit `[RECONCILE]`-DEFERRED.

## 2 · Author the triad to the v2 laws

The triad shape is the program's: `emq.N.md` (the contract — Goal · 5W · Scope · D-n · INV-n · DoD),
`.stories.md` (US-n in Connextra form + the standing `EMQ.N-US-GATE` Valkey gate story + a Coverage map),
`.llms.md` (the Mars brief — References · Requirements · Execution topology · Agent stories), built to
`docs/elixir/specs/specs.approach.md` (the six quality gates). For echo_mq:

- **Every deliverable traces to the v2 laws as checks.** An invariant that asserts a v2 law is a runnable
  check (INV: "every new Lua key is in `KEYS[]` or grammar-derived" — a grep over the new scripts; INV: "the
  prior conformance scenarios are byte-unchanged, the new ones probe-registered" — the count + a git-diff;
  INV: "fresh branded `JOB` mint per occurrence" — the order theorem, two distinct ids).
- **Forward-tense for what the rung builds.** A surface the rung adds is "emq.N builds …", never
  asserted-as-shipped. Ground a built-already surface against the as-built `file`/`Module.fun`; ground a
  to-be-built surface against the design § and the v1 feature reference as the mechanism precedent.
- **Mechanism words are claims.** Name the primitive the invariant rides (the set is a `ZSET` scored by X;
  the mint is host-side; the clock is `TIME` server-side). A brief at odds with its own invariant's primitive
  mis-directs the build.
- **The conformance additive-minor law** (shared reference): the triad names the new scenario(s), the count
  growth (prior N byte-unchanged → new total), and the probe registration — in the same rung.
- **A subkey-adding rung NAMES the subkey's cleanup disposition.** When a rung introduces a §6 job subkey — or
  any keyspace member that outlives its primary entity (`emq:{q}:job:<id>:{dependencies,processed}` at emq.3.1,
  the precedent) — the triad must NAME what retires it: the primary transition's script (`@complete` `DEL`s only
  the row `KEYS[2]`, **never its subkeys**), `obliterate` (`del_job` enumerates a **FIXED** subkey list —
  `:logs`/`:lock` as built; a new subkey absent from that list leaks), or a later lifecycle rung (stated as the
  honest bound, routed to the rung that owns the cleanup). An un-named cleanup disposition is a **silent at-rest
  leak the gate cannot catch** — the suites purge per-test (`on_exit` sweeps the sub-queue), so the leak surfaces
  only as production accumulation, never in a green board. The discipline (Apollo emq.3.1 L-5): a write-side rung
  MAY leave a subkey uncleaned IFF the spec names the bound and the cleanup is correct to defer (e.g. `:processed`
  MUST outlive the parent row for a later read rung) — name it, do not discover it.

## 3 · Carve the parity surface (the emq.2.x cluster)

emq.2 is the full echomq→echo_mq feature-parity rewrite decomposed into emq.2.1 / emq.2.2 / emq.2.3 (the exact
carve is fixed in `docs/echo_mq/specs/emq.2.design.md` — read it on an emq.2.* rung). When authoring a parity
rung:

- **The v1 line is the FEATURE REFERENCE, not the target.** `echo/apps/echomq` names the capability to port —
  flows, locks, events, stalled-recovery, telemetry/metrics, priorities, rate-limiting, lifecycle
  (pause/cancel/obliterate/checkpoints), the worker abstraction. Port each **rewritten to the v2 laws** (braced
  + branded + declared-keys + server-clock); never lift the v1 form (its scripts root key operands in data
  values — structurally inexpressible under declared-keys).
- **Zero migration framing.** echo_mq is the single source of truth; no "legacy" / "old" / version-suffix /
  "migrate-from" language in the new triad. The frozen line is a thing to PORT FROM as a reference, never a
  thing MIGRATED FROM.
- **Coherent, dependency-ordered, one-increment-one-run.** Each emq.2.N is a full triad + an
  `emq.2.N.prompt.md` runbook; the carve is the architect's, fixed from the real v1 inventory (25 `.ex` + 26
  `.lua`) and the design canon.

## 4 · Surface the forks — never decide them

The open seams live in `emq.roadmap.md` §Seams + `emq.design.md` §10. STOP and report each with the options
and the trade-off; do not pick one and proceed. An architecture / API-contract / new-dependency / identity
fork is the Operator's call — report, do not rule.

## 5 · The Design Phase (a SYSTEM founding)

When a rung founds or re-founds a SYSTEM spec (not a rung-level design), the dual-architect formation applies
— the architectural design + ADR set comes first, the triad derives from the approved design. Author
independently; read the locked constraints + the as-built code + the official engine docs, never the
sibling's draft. An engine capability is cited to `valkey.io`, never asserted from memory.

## Report

End with a `SendMessage` to the Director: the reconcile delta table + the BUILD-GRADE / BLOCKED verdict; the
brief (references / requirements / topology / agent stories); any fork surfaced for the Operator; the triad
files edited, one line each. Edit ONLY the spec triad — no `.ex`/`.heex`/`.exs`. No git.
