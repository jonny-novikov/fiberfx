# EWR.4.1 · the brief (Mars) — the client floor (the Pool half) { id="ewr-4-1-brief" }

> The build-grade brief Mars builds from. Derived from [`ewr.4.1.md`](ewr.4.1.md) (**authoritative**; this
> brief may lag the body — when they disagree, the body wins). Voice is forward-tense (`ewr.4.1` builds …).
> **Framing law (propagate into the build):** no gendered pronouns for agents; no perceptual/interior-state
> verbs for agents or software (components read, compute, refuse, return); no first-person narration.

## What this rung is, in one line

Route the **producer hot path** (`Jobs.enqueue` + the schedule/batch enqueue family) through an optional
`EchoMQ.Pool` via the shipped `EchoWire.Pipe` `via` idiom, bump the wire fence to **`echomq:2.5.0`**, and grow
the conformance gate **55 → 57** — **no Lua, no new key, no new dependency, no third app.** The branded-id NIF
(roadmap Rung 1, bullet 1b) is **explicitly deferred** to a future rung.

## References (read first, in order)

1. **The roadmap section** — [`../../ewr4.roadmap.md`](../../ewr4.roadmap.md), "Rung 1 — `echomq:2.5.0` · the
   client floor". The Pool half is bullet 2 ("`Pool`-fronted, pipelined enqueue as the default"); the NIF
   (bullet 1) is the **deferred** half.
2. **The `via` precedent** — `echo/apps/echo_wire/lib/echo_wire/pipe.ex:59` (`defstruct [:conn, :via, :timeout,
   cmds: []]`), `:75-82` (`new(conn, opts) → via: Keyword.get(opts, :via, Connector)`), `:496-497`
   (`command/2`), `:508-511` (`exec/1` → `via.pipeline(conn, Enum.reverse(cmds), timeout)`, empty guard). The
   `via` is **carried, never inspected** — mirror it.
3. **The enqueue family as-built** — `echo/apps/echo_mq/lib/echo_mq/jobs.ex`: `enqueue/4` (`:28-37`, the
   `Connector.eval(conn, @enqueue, …)` at `:31`), `enqueue_at/5`+`enqueue_in/5` (`:68-82`) → `schedule/6`
   (`:84-93`, the `Connector.eval(conn, @schedule, …)` at `:87`), `enqueue_many/3` (`:101-131`, the
   `SCRIPT LOAD` at `:102` + `Pipe.new(conn)` at `:111` + `Pipe.exec` at `:123`). The `@enqueue` script is
   `:15-25` (do **not** touch it).
4. **The pool surface** — `echo/apps/echo_mq/lib/echo_mq/pool.ex:45-52`: `command/3`, `pipeline/3`, `eval/5` —
   each `Connector.<fun>(next(name), …)`. Signature-compatible with `Connector`. `Pool.eval/5` is the enqueue
   front door; `Pool.pipeline/3` is the batch front door.
5. **The cutover anchors** — `echo/apps/echo_wire/lib/echo_mq/connector.ex:35` (`@wire_version`),
   `echo/apps/echo_wire/mix.exs:7`, `echo/apps/echo_mq/mix.exs:7`; the guard
   `echo/apps/echo_mq/test/version_reflection_test.exs`; the shape assertion
   `echo/apps/echo_mq/test/connector_test.exs:49`.
6. **The conformance anchors** — `echo/apps/echo_mq/lib/echo_mq/conformance.ex` (`scenarios/0` at `:78-136`,
   `run/2` at `:157-177`, the `apply_scenario/3` clauses); the pins
   `echo/apps/echo_mq/test/conformance_run_test.exs:48` (`{:ok, 55}`) and
   `echo/apps/echo_mq/test/conformance_scenarios_test.exs:28` (`@run_order`) + `:87`.
7. **The discipline** — [`.claude/skills/echo-mq-program.md`](../../../../../.claude/skills/echo-mq-program.md)
   (the v2 laws, the gate ladder, the conformance additive-minor law) +
   [`echo/CLAUDE.md`](../../../../../echo/CLAUDE.md) §3/§4 (the per-app gate ladder, `TMPDIR=/tmp`, the
   determinism loop, the boundary).

## Requirements (numbered; each traced to a story + an invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R1 | `Jobs.enqueue/5` gains optional `opts` (`enqueue(conn, queue, job_id, payload, opts \\ [])`); reads `:via` (default `EchoMQ.Connector`); dispatches the `@enqueue` eval through `via.eval/5`. Existing `enqueue/4` arity byte-unchanged. | US1 | INV2, INV3 |
| R2 | `enqueue_at/6` + `enqueue_in/6` gain the same optional `opts`; thread `:via` into `schedule/7` so the `@schedule` eval dispatches through `via.eval/5`. Existing `/5` arities byte-unchanged. | US1 | INV2, INV3 |
| R3 | `enqueue_many/4` gains optional `opts`; routes **both** the `SCRIPT LOAD` (`via.command/3`) **and** the `Pipe` `via` (`Pipe.new(conn, via: pool)`) to the pool. Existing `/3` arity byte-unchanged; per-item verdict order + empty-`pairs` `{:error, :empty_pipeline}` preserved. | US4 | INV4, INV2 |
| R4 | The `via` reference is **never** pattern-matched / `is_struct`/`is_atom`/module-guarded — carried, not detected. | US1 | INV3 |
| R5 | Cutover: `@wire_version` (`connector.ex:35`) + `echo_wire/mix.exs:7` + `echo_mq/mix.exs:7` all `2.4.2 → 2.5.0`. No connector-shape edit. | US5 | INV7, INV1 |
| R6 | Conformance grows **55 → 57**: append `pool_enqueue` + `pool_order` to `scenarios/0` (after `flow_grandchild_fail`), add their `apply_scenario/3` clauses, append to `@run_order`, re-pin `{:ok, 57}` + the 57-element `@run_order` in both pinning tests. Prior 55 byte-unchanged. | US2, US3, US6 | INV5, INV6 |
| R7 | No `Script.new/2` body change (`grep redis.call` on the `lib/echo_mq/` diff = 0); no `echo_data` edit; `echo/mix.lock` excluded; `deps/0` unchanged. | (all) | INV1, INV8 |

## Execution topology

**Runtime shape (unchanged).** One Valkey server on `:6390`. A producer holds either a single `EchoMQ.Connector`
(today's default) or an `EchoMQ.Pool` (N round-robin connector members, one supervisor — `pool.ex`). The
enqueue family's `@enqueue`/`@schedule` scripts run **server-side** against the **server-global** state
(`emq:{q}:job:<id>` row + `emq:{q}:pending` ZSET), so **which** member runs an admission is observationally
irrelevant — the rung's whole safety argument. No process is added; no key is added; no Lua changes.

**Build-order task DAG.**

```
T1 (enqueue :via)  ─┐
T2 (schedule :via) ─┼─→ T4 (conformance scenarios pool_enqueue/pool_order) ─→ T5 (re-pin both pin tests 55→57)
T3 (batch :via)    ─┘                                                              │
T6 (cutover 3 numbers) ───────────────────────────────────────────────────────────┴─→ GATE (per-app ladder + ≥100 loop)
```

T1/T2/T3 are independent runtime edits (all in `jobs.ex`). T4 depends on T1/T3 (the scenarios drive
`enqueue(..., via: pool)` + `enqueue_many(..., via: pool)`). T5 re-pins after T4. T6 (the cutover) is
independent and can land any time before the gate. The gate runs last.

**EXACT files touched (the whole boundary):**

| File | Edit |
|---|---|
| `echo/apps/echo_mq/lib/echo_mq/jobs.ex` | R1/R2/R3 — `:via` on `enqueue`, `enqueue_at`, `enqueue_in`, `schedule`, `enqueue_many`. **Do NOT touch any `@...` `Script.new` body.** |
| `echo/apps/echo_mq/lib/echo_mq/conformance.ex` | R6 — append `pool_enqueue` + `pool_order` to `scenarios/0`; add two `apply_scenario/3` clauses. (Optionally refresh the moduledoc tally prose — cosmetic, not gated.) |
| `echo/apps/echo_mq/test/conformance_run_test.exs` | R6 — re-pin `{:ok, 55}` → `{:ok, 57}` (`:48`). |
| `echo/apps/echo_mq/test/conformance_scenarios_test.exs` | R6 — append the two names to `@run_order` (`:28-84`); the `Keyword.keys == @run_order` assertion (`:87`) then re-pins automatically. |
| `echo/apps/echo_wire/lib/echo_mq/connector.ex` | R5 — `@wire_version "echomq:2.4.2"` → `"echomq:2.5.0"` (`:35`) ONLY. No other connector edit. |
| `echo/apps/echo_wire/mix.exs` | R5 — `version: "2.4.2"` → `"2.5.0"` (`:7`). |
| `echo/apps/echo_mq/mix.exs` | R5 — `version: "2.4.2"` → `"2.5.0"` (`:7`). |
| `echo/apps/echo_mq/test/jobs_test.exs` (if present) | OPTIONAL — a `via`-opacity unit test driving one enqueue through a `Connector` and a `Pool` to identical verdicts (INV3). The conformance scenarios are the primary proof; this is a fast offline guard. |

**OUT OF BOUNDS:** any `Script.new` body (byte-frozen Lua); `echo_data` (the NIF is deferred — touch nothing
there); `echo/mix.lock`; the `EchoWire` facade; the `Connector`/`RESP`/`Script`/`Pool` module bodies beyond the
`@wire_version` constant; any third app. `git diff --name-only` MUST be ⊆ the table above (minus `mix.lock`).

## Agent stories (each a Directive + an Acceptance gate)

### AS1 — `:via` on the serial enqueue
**Directive.** In `jobs.ex`, add an optional `opts \\ []` to `enqueue/4` (→ `enqueue/5`), `enqueue_at/5`
(→ `/6`), `enqueue_in/5` (→ `/6`), and the private `schedule/6` (→ `schedule/7`). Read
`via = Keyword.get(opts, :via, EchoMQ.Connector)` and replace the two `Connector.eval(conn, @enqueue|@schedule,
…)` calls (`:31`, `:87`) with `via.eval(conn, @enqueue|@schedule, …)`. **Do not** pattern-match `via`.
**Acceptance gate.** `enqueue(conn, q, id, p, via: pool)` and `enqueue(conn, q, id, p)` produce the identical
row + pending entry; the existing `enqueue/4` call sites compile and pass byte-unchanged. *(precondition: a
started `EchoMQ.Pool`; postcondition: `{:ok, :enqueued}` + the three-field row + score-0 pending entry;
invariant: the `via` reference is never inspected.)*

### AS2 — `:via` on the batch
**Directive.** In `enqueue_many/3` (→ `/4` with `opts \\ []`), set `via = Keyword.get(opts, :via,
EchoMQ.Connector)`; change the `SCRIPT LOAD` (`:102`) to `via.command(conn, ["SCRIPT", "LOAD",
@enqueue.source])` and the accumulator seed (`:111`) to `Pipe.new(conn, via: via)`. Leave the per-pair
`command/2` `EVALSHA` and the verdict mapping (`:123-130`) byte-unchanged.
**Acceptance gate.** `enqueue_many(conn, q, pairs, via: pool)` answers the per-item verdicts in input order,
identical to `enqueue_many/3`; **no** `EVALSHA` faults `NOSCRIPT` on any member (the one server-global
`SCRIPT LOAD` suffices); empty `pairs` answers `{:error, :empty_pipeline}`. *(precondition: a pool + pairs;
postcondition: ordered verdicts; invariant: one SCRIPT LOAD resolves the sha on every member.)*

### AS3 — the cutover to `2.5.0`
**Directive.** Bump exactly three constants to `2.5.0`: `@wire_version` (`connector.ex:35`),
`echo_wire/mix.exs:7`, `echo_mq/mix.exs:7`. Change nothing else in the connector.
**Acceptance gate.** `version_reflection_test.exs` green (all three numbers equal `2.5.0`);
`connector_test.exs:49` shape assertion green (no edit there). *(precondition: the three literals at `2.4.2`;
postcondition: all three at `2.5.0`; invariant: the connector module body unchanged beyond the constant.)*

### AS4 — the two conformance scenarios + the re-pin
**Directive.** Append `pool_enqueue` and `pool_order` to `scenarios/0` **after `flow_grandchild_fail`** with
the one-line contracts from the body D5; add an `apply_scenario(:pool_enqueue, conn, q)` and
`apply_scenario(:pool_order, conn, q)` clause that **start a real `EchoMQ.Pool`** (size ≥ 2) in the scenario,
drive `Jobs.enqueue(conn, q, id, p, via: pool)` (and the duplicate / round-robin sequence), and assert the
verdict against the server-global state; **stop the pool** in the scenario (a `Supervisor.stop` analogous to
the `events`/`resubscribe` connector teardown). Append the two names to `@run_order`
(`conformance_scenarios_test.exs`) and re-pin `{:ok, 55}` → `{:ok, 57}` (`conformance_run_test.exs:48`). Keep
the prior 55 scenarios + their clauses **byte-unchanged**.
**Acceptance gate.** `Conformance.run/2 → {:ok, 57}`; `Conformance.scenarios/0` has 57 entries; both pin tests
green; `git diff` shows the prior 55 scenario bodies unchanged. *(precondition: 55 scenarios; postcondition: 57,
prior byte-unchanged, both pins re-pinned; invariant: each new scenario probe-registered in this change.)*

> **The pool scenario shape — make it ACTUALLY exercise the pool (a gate must specify its own liveness).** A
> `pool_enqueue`/`pool_order` clause that started no pool, or passed `via: Connector`, would PASS while proving
> nothing about the pool. The clause MUST: (a) start an `EchoMQ.Pool` with **size ≥ 2** so round-robin spans
> distinct members; (b) pass `via: pool` (not `via: Connector`); (c) for `pool_order`, enqueue **≥ 3** ids in
> sequence so the round-robin actually distributes across members and the REV-BYLEX walk is a real order proof.
> The order-theorem **net-zero mutation** (reverse/shuffle the enqueue order) MUST kill `pool_order` — verify
> it does (the standing positional-order proof, `ewr.1.1-L4`).

### AS5 — the boundary + frozen-floor proof
**Directive.** Before reporting, prove the byte-frozen floor: `grep redis.call` on the `lib/echo_mq/` diff =
**0**; no `Script.new` body changed; no `echo_data` edit; `echo/mix.lock` unchanged; `deps/0` unchanged; the
`EchoWire` facade + the `Connector`/`RESP`/`Script`/`Pool` bodies (beyond `@wire_version`) untouched.
**Acceptance gate.** `git diff --name-only` ⊆ the files table (minus `mix.lock`); `git grep -c redis.call` on
the diff = 0. *(invariant: the diff is purely the boundary; the v2 master invariant is untouched by
construction.)*

## The gate ladder (run before reporting)

From **`echo/apps/echo_mq/`** (the touched app):

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
asdf current                                     # re-probe; never hardcode the toolchain
valkey-cli -p 6390 ping                           # → PONG
TMPDIR=/tmp mix compile --warnings-as-errors      # clean
TMPDIR=/tmp mix test --include valkey             # the bus suite incl. conformance + the two pool scenarios
# Conformance.run/2 → {:ok, 57}
```

From **`echo/apps/echo_wire/`** (the version-constant seam):

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_wire
TMPDIR=/tmp mix compile --warnings-as-errors      # clean
TMPDIR=/tmp mix test                              # the wire pure suite (the version-shape constant)
```

**The ≥100 determinism loop IS required** — `pool_enqueue`/`pool_order` mint multiple branded `JOB` ids in a
loop and assert mint order (the same-millisecond mint hazard flakes only across runs):

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done   # OWN the machine: no concurrent server, no sibling I/O
```

**`TMPDIR=/tmp` on EVERY `mix`** (the harness tmp overlay hits ENOSPC → spurious mid-suite I/O failures).
`EchoData.Snowflake.start/1` must be running (the conformance `setup_all` starts it at width 4).

## What this rung does NOT do (scope honesty)

- **No branded-id NIF** — roadmap Rung 1 bullet 1b is **deferred** (crosses into `echo_data`, needs an
  unresolved Fly/CI `.so` decision, perf-only; correctness held by `EchoData.Native` + `BrandedId.self_check!/0`).
  Touch nothing in `echo_data`.
- **No consumer-plane pooling** — `claim`/`complete`/`retry`/`extend_lock`/`extend_locks` stay on the single
  connector (lease + token coherence is a separate design question; out of scope).
- **No Lua, no new key, no wire-protocol change** — the v2 master invariant is untouched by construction.

---

Body: [`ewr.4.1.md`](ewr.4.1.md) · Stories: [`ewr.4.1.stories.md`](ewr.4.1.stories.md) · Runbook:
[`ewr.4.1.prompt.md`](ewr.4.1.prompt.md) · Roadmap: [`../../ewr4.roadmap.md`](../../ewr4.roadmap.md)
