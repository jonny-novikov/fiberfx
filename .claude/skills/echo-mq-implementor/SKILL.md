---
name: echo-mq-implementor
description: >-
  Use this skill when Mars (the implementor) is on a rung of the EchoMQ bus program — any rung whose slug
  matches emq.* (emq.1, emq.2, emq.2.1, … through emq.8), the program whose canon is
  docs/echo_mq/emq.design.md and whose ladder is docs/echo_mq/emq.roadmap.md. It encodes the implementor's
  echo_mq craft: building the increment to the Venus brief inside the echo_mq (+ one echo_wire seam)
  boundary, citing the spec line for every public call, the inline Script.new/2 law (NEVER priv/), the
  declared-keys / branded-JOB-id / server-clock Lua laws, the conformance additive-minor mechanics, and the
  per-app gate ladder (TMPDIR=/tmp, Valkey 6390, warnings-as-errors, the ≥100 determinism loop) run before
  reporting. The program-wide law lives in the shared reference .claude/skills/echo-mq-program.md, which this
  skill cites. Do NOT use for the course-authoring skills (*-course-writer), for a non-echo_mq rung (the
  generic mars charter covers redis/elixir), or to edit the spec triad (that is Venus /
  echo-mq-architect).
---

# echo-mq-implementor — the production half of the Author, on the EchoMQ bus

Mars on an `emq.*` rung. The generic implementor discipline still governs (`.claude/agents/mars.md` — build
to the brief slice by slice, cite-do-not-invent, realization-over-literal, done-is-a-closure,
edit-code-and-tests-never-the-spec). This skill adds the **echo_mq craft**. The program-wide law — the v2
laws, the gate ladder, the conformance additive-minor law, the NO-INVENT grounding, the roadmap awareness —
is the shared reference **`.claude/skills/echo-mq-program.md`**; read it first, then this, then the as-built
map `.claude/skills/echo-mq-surface.md`.

## 1 · Build inside the boundary

The diff stays inside `echo/apps/echo_mq` (the bus) plus, where the brief names it, the **one**
`echo/apps/echo_wire` connector seam a rung touches (the emq.1 resubscribe seam is the precedent — one
`connector.ex` change + one `echo_wire.ex` `defdelegate`). A change that reaches a third app is a diff no one
can review. `apps/echomq` (the frozen feature reference) is **UNTOUCHED** — a capability list, never an edit
target.

## 2 · Cite, do not invent — the echo_mq surfaces

For every public call, the `EchoMQ.*` module / function / arity / return must already exist in the tree or be
named in the brief. The as-built surface map is `.claude/skills/echo-mq-surface.md`. If the brief is silent or
wrong, STOP and report — do not invent a key, a Lua script, a struct field, or a return, and do not redefine
an existing surface (this repo's API has been silently redefined by build agents past green gates — the drift
this skill exists to prevent). **Realization-over-literal**: build to the contract's intent; if the literal
text would breach an invariant, build the behavior-identical realization and flag it with its citing
`file:line` (the emq.1 ONE-@schedule-script-with-an-ARGV-mode-flag realization is the model —
Director-ratified).

## 3 · The Lua laws (every script you write)

- **Inline `Script.new/2`, NEVER `priv/`.** No `echo/apps/echo_mq/priv/` exists; scripts are inline module
  attributes (`@enqueue`, `@claim`, `@schedule`, `@register`, …). Follow the convention; a brief that says
  `priv/` is a STALE the architect owes — flag it.
- **Declared keys (S-6).** Every key the script touches is in `KEYS[]`, or derived in-script only from a
  declared `KEYS[n]` root by the registered grammar (e.g. the per-job key `base..'job:'..id`, the lane family
  `base..'g:'..g..':pending'`). A new key derives from `Keyspace.queue_key(q, "<type>")` and is declared.
  Slot-sound under braces — every derivable key shares the declared root's slot.
- **Branded `JOB` ids (S-2).** A job id on the wire is the 14-byte branded form; the key builder gates
  `EchoData.BrandedId.valid?/1`; the enqueue/add script's FIRST act refuses a non-`JOB` namespace with the
  `EMQKIND` first-word wire class (policy before existence before write). The mint is host-side
  (`BrandedId.generate!`, Snowflake started); the wire never mints. The order theorem holds — byte order is
  mint order; a repeatable's two occurrences mint two DISTINCT, lexically-ordered ids.
- **The server clock (§10 DQ-2c).** A lease/fence transition reads `TIME` inside the script (sound under
  effects replication). A run-in score computes wire-side from `TIME` (`t[1]*1000 + floor(t[2]/1000) +
  delay`); a run-at score takes the caller's absolute ms (the documented client-clock surface for the score
  ONLY — the fence + lease laws are untouched).
- **The wire-class registry (S-3 / §5).** Typed refusals lead with their class word (`EMQKIND`, `EMQSTALE`)
  via `redis.error_reply`, never the generic `ERR`. Adding a class is an additive minor, registered with its
  conformance probe in the same change. The five-code fence union stands unextended.

## 4 · The conformance additive-minor mechanics

A capability rung extends `EchoMQ.Conformance.scenarios/0` with the new scenario, **registers its probe body
in the same change**, and keeps **every prior scenario byte-unchanged** (name + contract + verdict-body
identical — git-verify it). Re-pin the count in both pinning tests (`conformance_scenarios_test.exs` pins the
names; `conformance_run_test.exs` pins `{:ok, n}`). The full `Conformance.run/2` is its own gate beyond the
unit suites — it caught two scenario-harness bugs the standalone suites missed (an inverted mint-order guard,
a too-early promote). A check counts only if it RUNS — a doctest is inert until a test file invokes `doctest
<Module>`; **and a hand-fabricated WIRE fixture** (a survivor or re-injected entry that simulates a script's
emit) **counts only if it is BYTE-FAITHFUL to what the producer actually writes** — assert the producer's real
output shape AND reuse it (or a shared builder) for any re-injection, never a hand-typed sibling that can drift
to a different slot or path than the assertion names. (The emq.3.3 L-2 defect: a cross-queue crash-survivor
`flow:outbox` entry was hand-built with the CHILD queue as field 1, but `@complete` emits `parent_queue` first —
so the re-deliver targeted the WRONG slot, the `:processed` HSETNX guard never fired, and the keystone
idempotency test passed for the wrong reason.)

## 5 · The gate ladder — run BEFORE reporting (the craft emq.1 earned)

Per the shared reference's gate ladder, every item:

- `asdf current erlang` (re-probe; never hardcode); `redis-cli -p 6390 ping` → `PONG`.
- `TMPDIR=/tmp mix compile --warnings-as-errors` per touched app — clean.
- `TMPDIR=/tmp mix test` inside each touched app's dir (NEVER umbrella-wide — BANNED); include `--include
  valkey` for a wire rung.
- `Conformance.run/2` → `{:ok, n}` with the prior set byte-unchanged.
- The **≥100 determinism loop** for any id-minting / process / engine suite — `for i in $(seq 1 100); do
  TMPDIR=/tmp mix test || break; done` — the loop OWNS the machine (no concurrent server, no sibling heavy
  I/O). One green run is not proof; the same-ms mint collision flakes only across runs.
- **"Pre-existing" is two facts**: an environment-gated-cannot-run check (e.g. an Oban/Postgres benchmark
  rung) is a documented carry; a this-change-staled-it check (e.g. a hardcoded conformance count the rung's
  additive-minor growth supersedes) is **the rung's own debt to close in the same change**. Distinguish them
  in the report.

## 6 · Adversarial self-verification — you are the primary code-quality gate (the 2026-06-15 rebalance)

The gate ladder (§5) proves the suite is GREEN; this proves it BITES. On this program Mars is the **primary
code-quality gate** (the calibration [`emq.mars.md`](../../../docs/echo_mq/program/emq.mars.md)); the slow
independent-Apollo adversarial marathon is RETIRED to you. Run this battery on your OWN code, **BEFORE
reporting** — find your defects first, do not wait for a verifier:

- **Declared-keys grep on EVERY new Lua script** — every key in `KEYS[]` or grammar-rooted from a declared
  `KEYS[n]`. The **F-1 cross-slot trap is invisible on single-node Valkey 6390** (no `CROSSSLOT` raised), so
  this grep is the ONLY gate against a mis-keyed cross-slot script — name the single slot of each script's keys.
- **The order theorem** (byte = mint) on any touched set — two occurrences of a repeatable mint two DISTINCT,
  lexically-ordered ids; the pending set walked REV BYLEX answers newest-first by name alone.
- **The Lua mutation kill-rate** — edit a defect INTO a script or a guard, run the suite, confirm a test
  CATCHES it, then REVERT net-zero by an **inverse Edit** (NEVER `git checkout` — it discards the rung's real
  uncommitted work, L-3). **CRITICAL: `EchoMQ.Connector.eval` is EVALSHA-first** — `redis-cli -p 6390 SCRIPT
  FLUSH` before re-testing EACH mutation, or a stale server-cached SHA masks the change and forges a false
  NON-catch (the T-6 trap). Report the kill-rate (caught/total).
- **A "byte-freeze / REMEDIATE-cleared" claim is proven by re-running the diff to CLOSURE over the WHOLE
  touched file, never by the lines you re-touched.** After a byte-freeze assertion (a frozen Lua body) OR a
  "revert the format churn" remediation, run `git diff <file>` and confirm ZERO unintended lines remain on the
  removed side — a single-line→multi-line reflow of PRE-EXISTING code is NOT a freeze, even when the re-touched
  part is clean (the emq.3.4 R3 finding: the `scenarios/0` registry was restored but ~36 reflowed prior probe
  bodies were missed, reported "cleared"; `echo_mq` has no `.formatter.exs` — the formatter must not run here).
  Report a byte-freeze/remediation as PROVEN only after the whole-file diff — the same class as the gate-ladder
  "prior set byte-unchanged" check (§5).
- **The destructive / at-most-once / non-atomic-read probes** where the rung's surface invites them — a
  destructive op gated behind a green precondition (never a silent drop); at-most-once across a disconnect
  documented; a sweep that handles a dangling member rather than minting on nil.

This is PART of build-before-report, not a downstream gate. Apollo confirms story coverage + reconciles, the
Director's Stage-3 review is the independent floor — but the first and strongest adversary of your code is YOU.

## Report

End with a `SendMessage` to the Director: a file-by-file change list (NEW / REWRITE / EDIT / DELETE); any
realization-over-literal with its citing `file:line`; the gate result (compile + per-app pass counts +
`Conformance.run/2` + the determinism-loop result); the INV checks; any brief gap. Edit code + tests only —
never the spec triad. **No git** — leave the work in the tree for the Director to ratify.
