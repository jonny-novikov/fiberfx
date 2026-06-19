# EWR.4.1 · user stories — the client floor (the Pool half) { id="ewr-4-1-user-stories" }

> Who wants the Pool-fronted enqueue, what they need, and how acceptance is known. Derived from
> [`ewr.4.1.md`](ewr.4.1.md) (**SPECCED** — the body is authoritative; this file and the brief may lag it, and
> when they disagree the body wins). Acceptance is **forward-tense** (`ewr.4.1` builds these; the gate runs at
> the build run against the as-shipped surface). Connextra form, INVEST, concrete Given/When/Then — never
> "works correctly"; every story names the observable and the invariant(s) it exercises.

## EWR.4.1-US1 — front the producer hot path with a pool

As a **high-throughput job producer** (the live `codemojex`-class enqueuer), I want to hand `Jobs.enqueue` a
**pool** instead of a single connector, so that my enqueue rate is no longer capped by one connector's
`GenServer` serialization — without rewriting any call I already have.

Acceptance criteria:
- **Given** a started `EchoMQ.Pool` `pool` (size ≥ 2) and a fresh `JOB` id, **when** I call
  `Jobs.enqueue(conn, queue, id, payload, via: pool)`, **then** the result is `{:ok, :enqueued}`, the row is
  the three-field hash (`state` pending, `attempts` 0, `payload`), and the id is in the pending set at score 0
  — **byte-identical to a single-connector `enqueue/4`**.
- **Given** the same enqueue **without** `:via` (the existing arity `Jobs.enqueue(conn, queue, id, payload)`),
  **when** it runs, **then** it dispatches through `EchoMQ.Connector` (the default) and is **byte-unchanged**
  from today.
- **Given** the enqueue dispatch, **when** it routes through `via`, **then** the `via` reference is **never
  pattern-matched** — `via.eval/5` is called whether `via` is `EchoMQ.Connector` or `EchoMQ.Pool` (carried,
  not detected).

Exercises **INV2** (backward-compatible arities), **INV3** (`via` opacity). INVEST — independent (rides the
shipped `Pool` + the shipped `via` idiom); valuable (lifts the producer cap); testable (one enqueue, two
dispatchers, one verdict).

## EWR.4.1-US2 — idempotency survives the pool

As a **producer that retries an enqueue** (at-least-once submission), I want a duplicate id to be refused **no
matter which pool member runs it**, so that round-robin dispatch never lets a duplicate job slip through.

Acceptance criteria:
- **Given** a `JOB` id already enqueued through the pool, **when** I enqueue the **same** id again through the
  pool (a different member, by round-robin), **then** the result is `{:ok, :duplicate}`, the row's `payload` is
  the **first** value (unchanged), and the pending set has exactly **one** entry for the id.
- **Given** the duplicate refusal, **when** it is evaluated, **then** it is the server-side `@enqueue` `EXISTS`
  guard against the **server-global** state — so the verdict is independent of which member ran it.

Exercises **INV5** (idempotency preserved through the pool), **INV4** (server-global script cache — the
member-independent `EVALSHA`). INVEST — testable offline of any member affinity (the state is shared); the
**conformance scenario `pool_enqueue`** is its machine proof.

## EWR.4.1-US3 — score-0 mint order survives the pool

As an **operator browsing a queue**, I want jobs enqueued round-robin through the pool to browse
**newest-first by id alone**, so that the no-second-index order theorem holds whether the producer used one
connector or a pool.

Acceptance criteria:
- **Given** N `JOB` ids minted in sequence and enqueued **round-robin** through the pool, **when** I browse the
  pending set with `ZRANGE … "+" "-" BYLEX REV`, **then** the walk is the ids in **reverse mint order**
  (newest-first) — **identical** to enqueueing all N through a single connector.
- **Given** the order proof, **when** the enqueue order is reversed or shuffled (the net-zero mutation), **then**
  the browse no longer matches reverse-mint order and the scenario **fails** (the mutation is killed).

Exercises **INV6** (score-0 mint order preserved), **INV5** (each admission idempotent). INVEST — the
**conformance scenario `pool_order`** is its machine proof; the order-theorem mutation is the standing net-zero
guard.

## EWR.4.1-US4 — the batch path round-robins safely

As a **bulk enqueuer** (`enqueue_many`), I want the batch to flush round-robin through the pool **and** load
its script correctly, so that the already-4.4×-faster batch path also sheds the single-`GenServer` cap with no
`NOSCRIPT` fault.

Acceptance criteria:
- **Given** a pool and a list of `{id, payload}` pairs, **when** I call
  `Jobs.enqueue_many(conn, queue, pairs, via: pool)`, **then** the per-item verdicts return in **input order**
  (`:enqueued` / `:duplicate` / `{:error, :kind}`) — byte-identical to the single-connector `enqueue_many/3`.
- **Given** the batch through the pool, **when** it runs, **then** **both** the `SCRIPT LOAD` **and** the
  `Pipe` flush route to the pool, and **no** `EVALSHA` faults `NOSCRIPT` on any member — because one
  server-global `SCRIPT LOAD` makes the `sha` resolvable on every member.
- **Given** an **empty** `pairs`, **when** `enqueue_many(..., via: pool)` runs, **then** it answers
  `{:error, :empty_pipeline}` (the `Pipe` empty guard) — unchanged from `ewr.1.4`.

Exercises **INV4** (server-global script cache), **INV2** (backward-compatible arity). INVEST — rides the
shipped `EchoWire.Pipe` `via`; the verdict order is the same positional-reply contract `ewr.1.1-INV6` proves.

## EWR.4.1-US5 — the atomic wire-version cutover to `2.5.0`

As a **bus operator rolling out the rung**, I want `2.5.0` to be an atomic fence cutover, so that a
mid-rollout `2.4.2` client is rejected, not silently tolerated, and the three reflected versions can never
drift.

Acceptance criteria:
- **Given** the cutover, **when** the build lands, **then** `Connector.wire_version()` is `"echomq:2.5.0"`,
  `Application.spec(:echo_wire, :vsn)` is `"2.5.0"`, and `Application.spec(:echo_mq, :vsn)` is `"2.5.0"` — all
  three equal (the version-reflection guard green).
- **Given** a connector connecting against a keyspace fenced at a different version, **when** `fence/2` runs,
  **then** it returns `{:error, {:version_fence, got}}` (fatal) — the existing climbing-fence behaviour,
  unchanged.
- **Given** the connector shape assertion, **when** it runs, **then** `Connector.wire_version() =~
  ~r/^echomq:\d+\.\d+\.\d+$/` passes with **no connector-shape edit**.

Exercises **INV7** (the three-number cutover holds), **INV1** (no wire-protocol change beyond the version
constant). INVEST — independent of the enqueue change; the `version_reflection_test.exs` guard is self-enforcing.

## EWR.4.1-US6 — the gate grows by exactly two scenarios (additive-minor)

As an **author of the next rung on this ladder**, I want the conformance count to grow from **55 to 57** with
the prior 55 byte-unchanged, so that the gate proves the new capability without disturbing the standing
contract.

Acceptance criteria:
- **Given** `Conformance.scenarios/0`, **when** the rung lands, **then** it answers **57** entries — the prior
  **55 byte-unchanged** (name + contract + verdict-body git-identical) and `pool_enqueue` + `pool_order`
  **appended after `flow_grandchild_fail`**.
- **Given** `Conformance.run/2`, **when** it runs against Valkey on `6390`, **then** it returns `{:ok, 57}`.
- **Given** the two pinning tests, **when** they run, **then** `conformance_run_test.exs` pins `{:ok, 57}` and
  `conformance_scenarios_test.exs` pins a **57-element** `@run_order` with `Keyword.keys == @run_order`.
- **Given** each new scenario, **when** the change lands, **then** it is **probe-registered** in the same change
  (the additive-minor registration law).

Exercises **INV5/INV6** (the new scenarios' substance) + the bus additive-minor law. INVEST — the count growth
is the gate's own acceptance.

## Coverage — every Deliverable → its story → its invariant

| Deliverable (body) | Story | Invariant(s) |
|---|---|---|
| `:via` dispatch on `enqueue/5` (default `Connector`, `Pool` carried) | US1 | INV2, INV3 |
| `:via` on `enqueue_at/6` + `enqueue_in/6` (the schedule eval) | US1 | INV2, INV3 |
| Idempotency preserved through any pool member | US2 | INV5, INV4 |
| Score-0 mint order preserved round-robin | US3 | INV6, INV5 |
| `enqueue_many/4` batch: SCRIPT LOAD + Pipe `via` → pool | US4 | INV4, INV2 |
| Server-global script cache → safe round-robin `EVALSHA` | US4 | INV4 |
| The three-number cutover to `2.5.0` | US5 | INV7, INV1 |
| Conformance grows 55 → 57 (`pool_enqueue`, `pool_order`), prior byte-unchanged | US6 | INV5, INV6 |
| No Lua / no new dep / no third app (NIF deferred) | (all) | INV1, INV8 |

**The two story layers, kept distinct.** THIS file is the **hand-authored USER stories** (the acceptance a
person signs). A bus capability rung that adds conformance scenarios proves them through the `:valkey`
conformance harness (`conformance_run_test.exs`) — not a separate generated `docs/echo_mq/wire/stories/`
catalogue (that catalogue is the `EchoWire.Pipe` construction-pattern proof, untouched by this rung). The
`pool_enqueue` / `pool_order` scenarios are the machine proof of US2/US3/US6.

---

Body: [`ewr.4.1.md`](ewr.4.1.md) · Brief: [`ewr.4.1.llms.md`](ewr.4.1.llms.md) · Runbook:
[`ewr.4.1.prompt.md`](ewr.4.1.prompt.md)
