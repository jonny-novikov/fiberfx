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
  Slot-sound under braces — every derivable key shares the declared root's slot. **An `ARGV`-passed base is NOT
  a declared root** (the emq.5.1 L-1 precision): a script that builds a row key from `ARGV[1]..id` is slot-sound
  ONLY because it ALSO declares real braced `KEYS[n]` (e.g. `KEYS=[pending, active]`) that PIN the `{q}` slot —
  the `ARGV`-derived key then rides that pinned slot. A script whose ONLY keys come from `ARGV` declares no slot
  at all; the brief that calls an `ARGV` base "a declared root" is loose prose to flag.
- **Branded `JOB` ids (S-2).** A job id on the wire is the 14-byte branded form; the key builder gates
  `EchoData.BrandedId.valid?/1`; the enqueue/add script's FIRST act refuses a non-`JOB` namespace with the
  `EMQKIND` first-word wire class (policy before existence before write). The mint is host-side
  (`BrandedId.generate!`, Snowflake started); the wire never mints. The order theorem holds — byte order is
  mint order; a repeatable's two occurrences mint two DISTINCT, lexically-ordered ids.
- **The server clock (§10 DQ-2c).** A lease/fence transition reads `TIME` inside the script (sound under
  effects replication). A run-in score computes wire-side from `TIME` (`t[1]*1000 + floor(t[2]/1000) +
  delay`); a run-at score takes the caller's absolute ms (the documented client-clock surface for the score
  ONLY — the fence + lease laws are untouched).
- **The fence token IS `attempts`.** A bus in-flight transition carries no separate lock token — it fences on
  the monotonic `attempts` counter, minted at claim (`@claim`/`@bclaim`: `HINCRBY <row> 'attempts' 1`) and
  checked in-script: `local att = redis.call('HGET', KEYS[n], 'attempts'); if att ~= ARGV[k] then return
  redis.error_reply('EMQSTALE …')`. A NEW token-fenced verb mirrors `@complete`/`@retry`'s fence EXACTLY — the
  same HGET-compare-`EMQSTALE` shape, `attempts` as the token — never a new fence style; and the host call
  threads the SAME `att` its siblings thread (emq.5.4 `defp settle` passes one `att` to
  `Jobs.complete`/`Jobs.retry`/`Jobs.delay` identically). (emq.5.4 D-2/T-6: `@delay`'s fence is a faithful
  mirror of `@complete`, not a new fence.)
- **The wire-class registry (S-3 / §5).** Typed refusals lead with their class word (`EMQKIND`, `EMQSTALE`)
  via `redis.error_reply`, never the generic `ERR`. Adding a class is an additive minor, registered with its
  conformance probe in the same change. The five-code fence union stands unextended.
- **The two version planes — derive the rung label from its POSITION, never as next-free.** The `mix.exs`
  version is the DOCUMENTARY rung-label plane (read by nobody at runtime); the `@wire_version`
  (`connector.ex`) is the FROZEN wire plane — keep them distinct. Derive the label from the rung's place in
  the family ladder, NOT as the next free number: a rung WITHIN a family takes a PATCH bump (emq.4.3 → 2.4.3,
  emq.4.4 → 2.4.4), OPENING a family takes a MINOR bump with the patch reset to 0 (emq.4.4 `2.4.4` → emq.5.1
  `2.5.0`), and a no-substance rung HOLDS (emq.5.2 held `2.5.0`). A next-free MINOR mis-signals a family that
  does not exist (the emq.5.3 D-2 finding: `2.6.0` was derived as next-free, but emq.5.3 is a within-family
  rung → the patch `2.5.1`; a `2.6.0` would falsely open the emq.6 family). When the ladder is unambiguous
  this is the Director's discretion, not a fork — derive it, flag the number, do not invent a minor.

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
idempotency test passed for the wrong reason.) **And when a scenario must REPLICATE lib LOGIC for wire-level
determinism** (the emq.5.2 L-3 pattern: a conformance-local `settle_batch/4` mirroring `BatchConsumer.settle/3`'s
verdict-map mapping rather than spinning a process that injects timing nondeterminism) — pin the duplication with
a cross-reference comment naming the mirrored fn AND ensure a live-process test independently covers the same
invariant; never let the deterministic mirror be the SOLE witness of a settle/lifecycle contract, or a future
bug in the real fn passes the mirror green.

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
- **On an additive-ISOMORPH rung (the new script is a near-verbatim copy of a shipped one), two craft points.**
  (a) The byte-freeze proof is "the SHIPPED script's file region is 0-del; the redis.call additions are the
  NEW script" — a `grep redis.call` COUNT alone is ambiguous because the isomorph's lines look like duplicates
  of the frozen original; confirm 0-del on the shipped script's region specifically. (b) Identify the new
  script's SCRIPT-LOCAL lines FIRST (grep the new body vs the precedent) — the mutation spot-check MUST anchor
  on the new script's SEMANTIC DELTA (its unique lines), because the shared isomorph lines aren't uniquely
  Edit-targetable and mutating one tests the SHIPPED script, not the new one (the emq.5.3 L-1: `@gbclaim`'s
  only local anchors were `local depth = redis.call('ZCARD', lane)`, `local k = depth`, and the `att, g}` tail;
  a mutation on the byte-shared loop body would have hit frozen `@gwclaim` too).
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
