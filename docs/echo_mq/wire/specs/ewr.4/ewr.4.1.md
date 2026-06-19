# EWR.4.1 · `echomq:2.5.0` — the client floor (the Pool half) { id="ewr-4-1-the-client-floor" }

> **Status: SPECCED** — `ewr.4.1` builds, not yet shipped. The founding rung of a **new** ladder: the
> **EchoMQ improvement roadmap** ([`../../ewr4.roadmap.md`](../../ewr4.roadmap.md), Rung 1 — `echomq:2.5.0` ·
> the client floor). This is **distinct from the EchoWire client-core program** (`ewr.1.1`–`ewr.1.4`), which is
> **COMPLETE** (Movement I + II closed; live `echomq:2.4.2` — [`../../ewr.progress.md`](../../ewr.progress.md)).
> That program added the *construction* half **above** the conformance boundary and re-pinned the count
> byte-stable. **This ladder is a different beast:** it climbs the bus's own **wire-version fence**, ships a
> coherent bus capability per rung, and is admitted by **new `Conformance` scenarios** — so its discipline is
> the **bus additive-minor law** (the conformance count **grows**), the opposite of `ewr.1.x`. The body is
> authoritative; the stories ([`ewr.4.1.stories.md`](ewr.4.1.stories.md)) and the brief
> ([`ewr.4.1.llms.md`](ewr.4.1.llms.md)) derive from it — when they disagree, this body wins.

## Goal

Make a `Pool` the **default front door for the producer hot path** — `EchoMQ.Jobs.enqueue/4` and the
schedule/batch enqueue family — so a high-rate producer is no longer capped by a single connector's
`GenServer` serialization, while every current single-connector caller stays **byte-unchanged**. The roadmap
measured this layer at ~2.2× of the recoverable client gap, with `enqueue_many` already **4.4×** the serial
path because it amortises the round-trip; routing the serial enqueue family through the round-robin pool
removes the single-`GenServer` cap from it too. Ship it as the atomic wire-version cutover to **`echomq:2.5.0`**
with the conformance scenarios that prove the pool path preserves idempotency and score-0 mint order.

This is a **client-contract** rung, not a keyspace rung: **no Lua changes, no new key type, no wire-protocol
change** — the v2 master invariant is untouched **by construction**.

## The 5W

- **Who.** A high-throughput producer of jobs (a `codemojex`-class enqueuer, the named live consumer) that
  hands `Jobs.enqueue` / `enqueue_at` / `enqueue_in` / `enqueue_many` a **pool** instead of a single connector,
  to lift producer throughput off the single-`GenServer` cap.
- **What.** An **optional `:via` dispatch** on the enqueue family (mirroring the shipped `EchoWire.Pipe`
  `via` idiom), so the same public function dispatches through `EchoMQ.Pool` when handed one, defaulting to
  `EchoMQ.Connector` for the existing arity — **additive, backward-compatible**.
- **When.** Rung 1 of the EchoMQ improvement roadmap — single-core-first, the lowest-risk and largest
  *recoverable* layer; the cutover bumps the fence to `echomq:2.5.0`.
- **Where.** `echo/apps/echo_mq` (`lib/echo_mq/jobs.ex`) + the **one** `echo_wire` fence seam — the
  `@wire_version` constant (`connector.ex:35`) and the two mix versions. **No third app** (the NIF is carved
  out — see below).
- **Why.** The decomposition put ~2.2× of the recoverable throughput in EchoMQ's own client layer; the
  `GenServer`-per-connector serial cap is the most recoverable part of it, and the `Pool` (already shipped,
  already round-robin) is the lever — no new mechanism, just routing the producer's front door through it.

## Scope — what `2.5.0` ships, and the explicit NIF carve-out

`2.5.0` ships the **Pool half (1a)** of the roadmap's Rung 1, and **only** that:

1. **Pool-fronted enqueue (`echo_mq`).** An optional `:via` on `Jobs.enqueue/4`, `enqueue_at/5`,
   `enqueue_in/5`, and `enqueue_many/3`, dispatching the script eval through `EchoMQ.Pool` when supplied,
   defaulting to `EchoMQ.Connector`. The **consumer plane stays on the single connector** (see the scope ruling
   below).
2. **The fence cutover.** Bump the three reflected version numbers to `2.5.0`.
3. **The conformance gate.** Two new scenarios proving (a) pool-fronted enqueue is still idempotent and (b)
   score-0 mint order holds across pool members — the conformance count grows **55 → 57**.

> **DEFERRED — the branded-id NIF (roadmap Rung 1, bullet 1b).** The roadmap's Rung 1 has a *second* move — the
> branded-id NIF (`codec=pure → native`, measured **14.3×** cheaper per id, [`../../ewr4.roadmap.md`](../../ewr4.roadmap.md)
> "The branded-id NIF"). It is **explicitly carved out of `2.5.0`** to its own follow-up rung. Three reasons
> the Operator ruled (recorded so the spec is honest about what `2.5.0` ships vs the roadmap's *full* Rung 1):
> (i) it crosses into **`echo_data`** (`BrandedId`/`Base62`), a **third app** beyond this rung's boundary;
> (ii) it needs an **unresolved Fly/CI `.so` build decision** (ship the compiled artifact in `priv/` on a host
> without the toolchain); (iii) it is **performance-only** — correctness is already guaranteed by the shipped
> `EchoData.Native` pure-Elixir fallback and `EchoData.BrandedId.self_check!/0`, so deferring it costs no
> correctness and no functionality. `2.5.0` therefore changes **nothing in `echo_data`, ships no NIF, and adds
> no new dependency.** The NIF is a future rung on this same ladder.

### The scope ruling — the ENQUEUE family only, not the consumer plane

The pool fronts the **producer hot path** only: `enqueue/4`, `enqueue_at/5`, `enqueue_in/5`, `enqueue_many/3`.
The **claim/complete/retry/extend consumer plane** (`Jobs.claim/3`, `complete/5`, `retry/7`, `extend_lock/5`,
`extend_locks/4`) stays on the **single connector**, for three reasons:

- **The roadmap names only the producer.** Rung 1 says *"making `Pool` the front door for `Jobs.enqueue`"* and
  *"removes the single-`GenServer` serialization that caps the serial client"* — the *producer* path
  ([`../../ewr4.roadmap.md`](../../ewr4.roadmap.md), Rung 1).
- **The consumer plane has lease + token semantics a round-robin pool must not blur.** `claim` mints a lease on
  the server clock and a fencing token; `complete`/`retry`/`extend_lock` are **token-fenced on the row's
  `attempts`** and must address the row coherently. The enqueue family is a stateless, idempotent admission
  (an `EXISTS`-guarded `HSET`+`ZADD`) — exactly the shape that round-robins safely, because **any** member can
  run it against the **server-global** state and the result is identical. Fronting the consumer plane is a
  separate design question (lease coherence across members), not a free throughput win, and is **out of scope**.
- **Smallest correct increment.** One coherent producer-path slice, proven by the gate, is the rung; the
  consumer plane is left for a future rung to weigh on its own merits.

## Locked decisions

### D1 — Spec home + the bus-discipline reframe (RECOMMENDED, proceeding)

Home the rung at `docs/echo_mq/wire/specs/ewr.4/ewr.4.1.{md,stories.md,llms.md,prompt.md}`, treating
`ewr4.roadmap.md` as the `ewr.4` chapter roadmap. **The reframe is load-bearing:** the EchoWire client-core
(`ewr.1.x`) is **closed** and lived **above** the conformance boundary (re-pinning `{:ok, N}` byte-stable,
writing no scenario — [`../../program/ewr.program.md`](../../program/ewr.program.md), the wire master
invariant). **This rung is a BUS-capability rung** — it touches the `echo_mq` **runtime** (`jobs.ex`), it
**grows** the conformance count, and it climbs the **wire-version fence**. So it runs the **bus** discipline
(the bus additive-minor law: prior scenarios byte-unchanged, the new ones probe-registered, the count grows
and is re-pinned in both pinning tests — [`.claude/skills/echo-mq-program.md`](../../../../../.claude/skills/echo-mq-program.md),
The conformance additive-minor law), **not** the wire above-conformance stance. `ewr.1.4` is the precedent for
*touching `jobs.ex` and bumping the version* — but `ewr.1.4` was behaviour-preserving and **re-pinned** the
count; this rung adds a capability gate and so **grows** it. The `ewr.4.*` slug records *which ladder* (the
EchoMQ improvement / wire-version ladder), not which discipline.

> **Surfaced for the Operator (a naming/home judgment, not a blocker).** The `ewr.4.*` slug homes the rung in
> the `wire/` tree because the rung climbs the **wire version**, yet the rung's substance is a **bus** change
> (the `echo_mq` runtime + a conformance gate). An alternative home is an **`emq.*`** chapter (e.g. an
> `emq.improvement` ladder under `docs/echo_mq/specs/`), which would co-locate it with the bus conformance it
> grows. The recommendation is `ewr.4.*` (the roadmap is named the *EchoMQ improvement roadmap* and physically
> lives at `docs/echo_mq/wire/ewr4.roadmap.md`, and the rung's *defining mechanism* is the wire-version
> cutover); the trade-off is that the discipline is bus-shaped while the home is wire-shaped. Reported with the
> options; the Operator rules the home if the recommendation is not accepted.

### D2 — The `via` enqueue contract (RECOMMENDED, proceeding)

The enqueue family accepts a pool via an **optional `:via` dispatch in an `opts` keyword**, mirroring the
shipped `EchoWire.Pipe` idiom **verbatim** (`pipe.ex:75-82` — `via: Keyword.get(opts, :via, Connector)`,
carried, never inspected). The exact shape:

- **`Jobs.enqueue/4` gains a 5th optional `opts` argument** — `enqueue(conn, queue, job_id, payload, opts \\ [])` —
  reading `:via` (default `EchoMQ.Connector`) and dispatching the script eval through `via.eval/5`. Because
  `EchoMQ.Pool.eval/5` (`pool.ex:51-52`) and `EchoMQ.Connector.eval/5` are **signature-compatible** (the pool
  delegates to `Connector.eval(next(name), …)`), the only change is `Connector.eval(conn, @enqueue, …)` →
  `via.eval(conn, @enqueue, …)` with `via = Keyword.get(opts, :via, Connector)`. **The reference is never
  pattern-matched** — the dispatch is carried, not detected (the `ewr.1.1-INV3` opacity contract, applied here).
- **`enqueue_at/5`, `enqueue_in/5` gain the same optional `opts`** (a 6th argument), threading `:via` into the
  private `schedule/6 → schedule/7` so the `@schedule` eval also dispatches through `via.eval/5`.
- **Backward-compatible by construction.** Every current call site — `enqueue(conn, q, id, payload)`,
  `enqueue_at(conn, q, id, payload, at)`, `enqueue_in(conn, q, id, payload, delay)` — is **byte-unchanged** and
  takes the default-`Connector` path (`opts = []`). The new arity is purely additive; the existing public
  arities are preserved (the default-argument form, not a sibling function).

> **Implementor design-make (left to Mars — D2 specifies the CONTRACT, not the field).** Whether `:via` rides
> an `opts` keyword (the recommendation, mirroring `Pipe.new/2`) or a dedicated `via` positional, and the exact
> internal threading of `schedule/6`, is the implementor's. The **observable contract** the spec fixes: the
> existing public arities are byte-unchanged and default to `Connector`; a supplied `:via` dispatches the
> script eval through `via.eval/5` with no reference inspection. (The `via` opacity craft:
> [`../../program/ewr.venus.md`](../../program/ewr.venus.md), "The conn-or-pool opacity is a CONTRACT to
> specify, a SHAPE to leave to Mars".)

### D3 — The `enqueue_many` batch dispatch (RECOMMENDED, proceeding)

`enqueue_many/3` already flushes through `EchoWire.Pipe` (`ewr.1.4`, `jobs.ex:101-131`) but on the **default
`via` (Connector)**. To pool-front the batch, **both** of its wire steps route to the pool:

- **The `SCRIPT LOAD`** (`jobs.ex:102`, `Connector.command(conn, ["SCRIPT", "LOAD", @enqueue.source])`) → the
  pool, so the script is cached on the member the load lands on. Because **Valkey's script cache is
  server-global** (one server on `:6390`; a `SCRIPT LOAD` on any connection makes the `sha` resolvable on every
  connection), **one** load on **any** member makes the subsequent round-robin `EVALSHA` correct on **all**
  members — this is *why* the round-robin batch is safe and is stated as an invariant (INV4).
- **The `Pipe` `via`** (`jobs.ex:111`, `Pipe.new(conn)`) → `Pipe.new(conn, via: pool)`, so the accumulated
  `EVALSHA` batch flushes through `EchoMQ.Pool.pipeline/3` (round-robin) rather than the single connector.

`enqueue_many` gains the same optional `:via` (its 4th argument, `opts`), defaulting to `Connector` — so the
existing `enqueue_many(conn, q, pairs)` is byte-unchanged. The per-item verdict mapping (`:enqueued` /
`:duplicate` / `{:error, :kind}` in input order, `jobs.ex:123-130`) is **byte-unchanged**; the empty-`pairs`
`{:error, :empty_pipeline}` edge (the `Pipe` empty guard, `pipe.ex:508`) is preserved.

### D4 — The cutover (LOCKED — the sanctioned mechanism)

The cutover is **exactly three version numbers**, all `2.4.2 → 2.5.0`, guarded by
`version_reflection_test.exs` (which asserts `echo_wire vsn == Connector.wire_version()`-minus-`echomq:` ==
`echo_mq vsn`):

1. `echo/apps/echo_wire/lib/echo_mq/connector.ex:35` — `@wire_version "echomq:2.4.2"` → `"echomq:2.5.0"`.
2. `echo/apps/echo_wire/mix.exs:7` — `version: "2.4.2"` → `"2.5.0"`.
3. `echo/apps/echo_mq/mix.exs:7` — `version: "2.4.2"` → `"2.5.0"`.

`connector_test.exs:49` asserts only the **shape** `^echomq:\d+\.\d+\.\d+$`, so `echomq:2.5.0` passes with **no
connector-shape edit**. The frozen `Connector`/`RESP`/`Script`/`Pool` module bodies are untouched — the
`@wire_version` constant bump **is** the sanctioned per-rung fence mechanism (*"the fence CLIMBS per rung"*,
[`../../ewr4.roadmap.md`](../../ewr4.roadmap.md)). The `:fence` conformance scenario reads
`Connector.wire_version()` (not a literal), so it tracks the bump with no edit.

### D5 — The conformance delta (LOCKED — additive-minor, the count grows 55 → 57)

Two new scenarios, **appended after `flow_grandchild_fail`** (the current list end), keep all 55 prior
scenarios **byte-unchanged**:

- **`pool_enqueue`** — *"pool-fronted enqueue is idempotent: a duplicate id through the pool answers duplicate
  and changes nothing; the row and pending entry match a single-connector enqueue."*
- **`pool_order`** — *"score-0 mint order holds across pool members: ids enqueued round-robin through the pool
  browse newest-first by name alone (REV BYLEX), identical to the single-connector order."*

Each is appended to `scenarios/0`, gains an `apply_scenario/3` clause, is appended to the `@run_order` list in
`conformance_scenarios_test.exs`, and the count is re-pinned **55 → 57** in **both** pinning tests
(`conformance_run_test.exs:48` `{:ok, 55}` → `{:ok, 57}`; `conformance_scenarios_test.exs:28`+`:87` the
55-element `@run_order` → 57). The new scenarios drive `Jobs.enqueue(..., via: pool)` against a real
`EchoMQ.Pool` started in the scenario, then assert the verdict against the **server-global** state (the same
state a single connector sees), so the proof is that **the pool path and the connector path are
observationally identical** for admission. Each new scenario is **probe-registered** in the same change (the
additive-minor *registration* law — engaged here because this is a bus capability rung).

## Invariants (each a runnable check)

- **INV1 — No Lua, byte-frozen scripts.** No `Script.new/2` body changes; `grep redis.call` on the
  `lib/echo_mq/` diff is **0**. The v2 master invariant (braced keyspace · branded `JOB` ids · declared keys ·
  server clock) is untouched **by construction** — this rung adds no key, no script, no wire command.
- **INV2 — Backward-compatible public arities.** Every existing enqueue call site is byte-unchanged: `enqueue/4`,
  `enqueue_at/5`, `enqueue_in/5`, `enqueue_many/3` keep their meaning with `opts = []` and dispatch through
  `EchoMQ.Connector`. Proven by the existing `jobs_test.exs` + the byte-stable prior-55 conformance.
- **INV3 — `via` opacity.** The enqueue dispatch carries `via` and calls `via.eval/5` / `via.pipeline/3` with
  **no** `is_struct`/`is_atom`/module-name guard — the dispatch is carried, not detected (the `ewr.1.1-INV3`
  contract). Proven by a single test driving the same enqueue through a `Connector` and a `Pool` to identical
  verdicts.
- **INV4 — Server-global script cache.** The batch path's `SCRIPT LOAD` on **one** pool member makes the
  `EVALSHA` resolvable on **every** member (Valkey's script cache is server-global on the single `:6390`
  server), so round-robin `EVALSHA` never `NOSCRIPT`-faults across members. Proven by the `pool_enqueue` /
  `pool_order` scenarios driving multi-member round-robin enqueue with no script-load fault.
- **INV5 — Idempotency preserved through the pool.** A second enqueue of the same `JOB` id through **any** pool
  member answers `:duplicate` and changes neither the row nor the pending set — because the `@enqueue` `EXISTS`
  refusal is evaluated server-side against the shared state, independent of which member runs it. Proven by
  `pool_enqueue`.
- **INV6 — Score-0 mint order preserved through the pool.** Ids minted in sequence and enqueued round-robin
  through the pool sort **newest-first by name alone** under `ZRANGE … REV BYLEX` (the order theorem: members
  are the ids, score is 0, byte order = mint order), identical to single-connector order. Proven by
  `pool_order`, with the standing **order-theorem net-zero mutation** (reverse/shuffle the enqueue order and
  the scenario must die).
- **INV7 — The three-number cutover holds.** `echo_wire` vsn == `Connector.wire_version()` (minus `echomq:`)
  == `echo_mq` vsn == `2.5.0`. Proven by `version_reflection_test.exs` (the self-enforcing guard) +
  `connector_test.exs:49` shape pass.
- **INV8 — No new dependency, no third app.** `echo/apps/echo_mq/mix.exs` `deps/0` is unchanged (already
  `{:echo_data, in_umbrella: true}` + `{:echo_wire, in_umbrella: true}`); `echo/mix.lock` is excluded; no
  `echo_data` edit (the NIF is deferred). The diff stays inside `echo/apps/echo_mq` + the one `echo_wire` fence
  seam. Proven by `git diff --name-only` ⊆ the boundary + `mix.lock` absent.

## The gate ladder (per-app, run before reporting)

From **`echo/apps/echo_mq/`** (the touched app; `echo_wire` is touched only at the version constant):

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
asdf current                                     # re-probe the toolchain from the app dir; never hardcode
valkey-cli -p 6390 ping                           # → PONG (the live engine)
TMPDIR=/tmp mix compile --warnings-as-errors      # clean
TMPDIR=/tmp mix test --include valkey             # the bus suite incl. the :valkey-tagged conformance + pool scenarios
# Conformance.run/2 → {:ok, 57}  (re-pinned in conformance_run_test.exs; the scenarios pin → 57-elem @run_order)
```

From **`echo/apps/echo_wire/`** (the version-constant seam — the dep-free base must still compile clean):

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_wire
TMPDIR=/tmp mix compile --warnings-as-errors      # clean (the @wire_version literal changed)
TMPDIR=/tmp mix test                              # the wire pure suite (the version-shape constant)
```

**Determinism posture — the ≥100 loop IS required (id-mint suite).** The new `pool_enqueue` / `pool_order`
scenarios mint multiple branded `JOB` ids in a tight loop and assert mint order — exactly the
**same-millisecond branded-id mint hazard** the program's gate ladder calls out (a collision flakes only
across runs, never within one). This is an **id-mint** suite, so ratify with the **≥100 determinism loop**,
not merely a multi-seed sweep:

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done   # must own the machine: no concurrent server, no sibling I/O
```

The loop must **own the machine** (no concurrent liveness server, no sibling heavy I/O — a load-gated
pre-existing test forges a failure the rung did not cause). `EchoData.Snowflake.start/1` must be running (the
conformance `setup_all` already starts it at width 4) so `generate!/1` mints.

## Definition of done

- [ ] `Jobs.enqueue/5`, `enqueue_at/6`, `enqueue_in/6`, `enqueue_many/4` accept an optional `:via` (default
      `Connector`); a supplied `EchoMQ.Pool` dispatches the script eval / batch flush through it, reference
      never inspected (INV3).
- [ ] The `enqueue_many` batch routes **both** the `SCRIPT LOAD` and the `Pipe` `via` to the pool (D3, INV4).
- [ ] Every existing enqueue call site is byte-unchanged and `Connector`-defaulted (INV2).
- [ ] The cutover bumps the three reflected versions to `2.5.0`; `version_reflection_test.exs` +
      `connector_test.exs:49` green (D4, INV7).
- [ ] `Conformance.scenarios/0` grows to **57** (`pool_enqueue`, `pool_order` appended after
      `flow_grandchild_fail`); the prior 55 byte-unchanged; the count re-pinned **55 → 57** in both pinning
      tests; `Conformance.run/2 → {:ok, 57}` (D5).
- [ ] `grep redis.call` on the `lib/echo_mq/` diff = **0**; no `echo_data` edit; `mix.lock` excluded;
      `deps/0` unchanged (INV1, INV8).
- [ ] The per-app gate ladder green from both app dirs; the **≥100 determinism loop** green owning the machine.
- [ ] The NIF (roadmap Rung 1, bullet 1b) is recorded as **DEFERRED** to a future rung, with the carve-out
      rationale in the body (scope honesty).

---

Stories: [`ewr.4.1.stories.md`](ewr.4.1.stories.md) · Runbook: [`ewr.4.1.prompt.md`](ewr.4.1.prompt.md) ·
Brief: [`ewr.4.1.llms.md`](ewr.4.1.llms.md) · Roadmap: [`../../ewr4.roadmap.md`](../../ewr4.roadmap.md) ·
Ledger: [`../progress/ewr-4-1.progress.md`](../progress/ewr-4-1.progress.md) · Program law:
[`../../../../../.claude/skills/echo-mq-program.md`](../../../../../.claude/skills/echo-mq-program.md)
