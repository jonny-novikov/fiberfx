# EMQ.5.1 — stories (the batch-claim spine — `@bclaim` + `claim_batch/4`)

> The acceptance face of [`emq.5.1.md`](emq.5.1.md) (the body is authoritative — if a story disagrees with the
> body, the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then acceptance
> (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every Deliverable
> traces to a story. **SHIPPED — Director-verified PASS; the three forks are RULED (the facts below).**
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule).** US1 is a POSITIVE proof: a present
> precondition (a flooded pending set) MUST run the batch claim and assert the served members — a vacuous pass (a
> batch that serves zero from a NON-empty pending set, or a `size`-1 claim that proves nothing about the batch)
> is a LOUD failure, never a silent green. US3's partial-failure isolation MUST actually retry one member and
> complete the rest — a property asserted with no failing member proves nothing and fails its own letter.
>
> **The forks are RULED (the shipped facts).** US1's claim is the OBSERVABLE outcome — `size` members in mint
> order, each fenced, on one shared lease — which held for both arms of FORK 5.1-A; the ruled mechanism is **the
> LOOP** (`@bclaim` = a `ZPOPMIN` loop ×N, `jobs.ex:200-219`). The conformance count is **64** (FORK 5.1-B RULED
> THREE — `batch_claim` · `batch_claim_short` · `batch_partial_failure`). The under-fill semantics is **return the
> short batch M** (FORK 5.1-C RULED, non-blocking; `claim_batch/4` `jobs.ex:520-539`).

---

## US1 — The batch claim (up to `size` members in one atomic, server-clocked pull)

**As a** high-throughput bulk-drain consumer, **I want** to claim up to `size` jobs in one atomic call instead
of one at a time, **so that** I amortize the per-job round-trip and the per-job lease bookkeeping across the
whole batch — one wire round-trip, one server-clock read, one lease deadline.

- **Exercises:** EMQ.5.1-INV1 (the count-variant pop is inside the script, no client-side multi-key pop),
  EMQ.5.1-INV3 (declared keys A-1, braced slot, no new key family), EMQ.5.1-INV4 (server clock on the batch
  lease), EMQ.5.1-INV5 (branded JOB ids in mint order — the order theorem), EMQ.5.1-INV6 (attempts as the
  fencing token, per member).

```gherkin
Given a queue with a pending set flooded with K distinct mint-ordered JOB-ids (K >= size, e.g. K=10, size=4)
When claim_batch(conn, queue, size, lease_ms) is called once
Then it answers {:ok, members} with exactly `size` tuples {id, payload, attempts}
  And the members are the `size` LOWEST-score (oldest-mint) ids, in mint order (identical to `size` sequential claim/3 pops)
  And each member carries attempts = 1 (a first claim mints token 1, per member — HINCRBY attempts 1 each)
  And every served member's row is now state = active, and is scored in the active set on ONE shared lease deadline
       (the deadline = a single server-clock TIME read + lease_ms; no host timestamp crosses the lease)
  And the pop is a ZPOPMIN emq:{q}:pending loop INSIDE the inline script (no client-side LMPOP/ZMPOP — design §6.2)
  And every key the script touches is emq:{q}:pending / active / job:<id>, all on the one {q} slot (no new key family)
```

- **Liveness (no vacuous pass):** the window MUST serve exactly `size` members from a pending set of K>=size; an
  outcome where fewer than `size` are served from a sufficiently-flooded set is a LOUD failure (the claim
  under-served), and a `size`-1 claim that exercises only the single-pop path proves nothing about the batch (the
  scenario MUST use `size >= 2` against K > size). The shared-lease assertion is load-bearing: the served members
  MUST all carry the SAME active-set deadline (one `TIME` read for the batch) — distinct deadlines would mean the
  loop re-read `TIME` per member (a regression the proof catches).
- **Determinism note (a mint/lease surface):** `@bclaim` HINCRBYs attempts + leases on the server clock and the
  proof mints branded JOB-ids; the **≥100 determinism loop** owns this proof (the same-millisecond branded-`JOB`
  mint hazard — FOREGROUND, owning the machine, timeout-bounded chunks driven to an accumulated count).

---

## US2 — The under-fill is a short batch, not a refusal (the spine is non-blocking)

**As a** bulk-drain consumer, **I want** a claim for `size` N when only M < N are pending to return the M
available members (not block, not error), **so that** I drain whatever is ready without waiting — the blocking
`min_size`/`timeout` cadence is a separate, opt-in shaping rung (emq.5.2), never forced into the spine.

- **Exercises:** EMQ.5.1-INV5 (mint-ordered members), EMQ.5.1-INV3 (the shipped sets, no new key family); the
  closed error set (`:empty` is the zero case of the under-fill rule).

```gherkin
Given a queue with M pending JOB-ids and a claim requesting size N where M < N (e.g. M=2, N=5)
When claim_batch(conn, queue, N, lease_ms) is called
Then [FORK 5.1-C RULED: RETURN THE SHORT BATCH] it answers {:ok, members} with exactly M tuples
       (the M available members, mint-ordered, each fenced and leased on the shared deadline — the @bclaim
        k = min(size, depth) clamp, jobs.ex:203-204, never over-popping)
  And an oversized request (N > depth) clamps to depth (the same min(size, depth) clamp)
  And a subsequent claim_batch on the now-empty pending set answers :empty (the zero case of the same rule)
  And a claim_batch against a queue paused queue-wide answers :empty with the pending set UNTOUCHED
       (the queue-wide pause honored host-side FIRST — the claim/3 precedent, jobs.ex:522-523)
```

- **Liveness:** the under-fill scenario MUST start with M > 0 pending and request N > M, and assert exactly M
  served (a short batch that serves zero from M>0 pending, or that serves N from M<N, is a LOUD failure). The
  `:empty` leg MUST be the genuinely-empty case (zero pending) AND the paused case (the pending set non-empty but
  the queue paused → `:empty`, pending untouched). This is the `batch_claim_short` conformance scenario.
- **As shipped:** FORK 5.1-C ruled RETURN THE SHORT BATCH (non-blocking — `claim_batch/4`, `jobs.ex:520-539`);
  the blocking `min_size`/`timeout` cadence is emq.5.2's job, never in the spine.

---

## US3 — Partial-failure isolation (one poisoned member never sinks the batch)

**As a** bulk-drain consumer, **I want** to resolve each member of a claimed batch independently — completing the
good ones and retrying the poisoned one — **so that** one bad job in a batch of `size` is isolated to its own
retry, the rest settle, and the batch is a CLAIM unit, never an all-or-nothing RESOLUTION unit.

- **Exercises:** EMQ.5.1-INV7 (partial-failure isolation — a tested property over byte-frozen transitions),
  EMQ.5.1-INV6 (per-member fencing token), EMQ.5.1-INV2 (the resolution rides the byte-frozen `@complete`/`@retry`,
  no new Lua).

```gherkin
Given a batch of N members claimed in one claim_batch call (each with its own attempts token, e.g. N=3, member k is "poison")
When member k is resolved via Jobs.retry/7 (scheduled, last_error kept) and the other N-1 via Jobs.complete/4|5
Then member k's row is state = scheduled with its last_error kept; the other N-1 rows are retired (complete deleted them)
  And the other members' completion is UNAFFECTED by member k's failure (no batch-scoped rollback — each transition is independent)
  And after promote, a fresh claim finds ONLY member k (the poison), now carrying attempts = 2 (its own token advanced)
  And a stale-token resolution of any member is refused EMQSTALE by the shipped, byte-frozen @complete/@retry (per-member fencing)
  And no batch-scoped resolution script exists (grep: @bclaim is the only new script; @complete/@retry are byte-frozen)
```

- **Liveness (no vacuous pass):** the scenario MUST actually fail member k (drive a real `@retry`) and complete
  the rest — a "partial-failure" proof with no failing member, or one that completes all N, proves nothing about
  isolation and is a LOUD failure. The EMQSTALE leg MUST exercise a genuinely stale token (a wrong attempts value)
  and observe the shipped refusal.

---

## US4 — The byte-freeze discipline (`@bclaim` is additive; every shipped script stands unbroken)

**As a** maintainer of the frozen wire, **I want** `@bclaim` to be a NEW additive script with `@claim` and every
other shipped script byte-identical to HEAD, **so that** the batch-claim spine cannot silently re-shape the
single-pop claim path or any shipped transition the whole bus rests on.

- **Exercises:** EMQ.5.1-INV2 (byte-freeze every shipped script), EMQ.5.1-INV8 (the prior conformance scenarios
  byte-unchanged).

```gherkin
Given the shipped script corpus in jobs.ex (@enqueue, @schedule, @claim, @complete, @retry, @promote, @reap,
       @update_data, @update_progress, @add_log, @remove_job, @reprocess, @extend_lock, @extend_locks) and every @g* in lanes.ex
When emq.5.1 builds @bclaim (a NEW inline Script.new(:bclaim, …)) and claim_batch/4
Then @bclaim is the ONLY new redis.call-bearing script in the lib diff
  And every shipped script is byte-identical to HEAD (grep redis.call on each shipped script body in the lib diff = 0)
  And the prior conformance scenarios pass byte-unchanged (claim, complete, retry, dead, reap, … — name + contract + verdict body git-verified)
  And the §6 grammar in keyspace.ex is unedited (no new emq:{q}:<type> family — @bclaim rides pending/active)
  And {emq}:version reads echomq:2.4.2 (the wire @wire_version is unchanged — @bclaim is an additive NEW script, not a wire edit)
```

- **Liveness:** the byte-freeze grep is run over the ACTUAL lib diff against HEAD and asserted = 0 for every
  shipped script; a non-zero result on a shipped script is a LOUD failure (an unintended edit), not a warning.

---

## US5 — Additive-minor conformance growth (the count re-pin)

**As a** keeper of the conformance harness, **I want** the batch-claim scenario(s) registered with their probes
in the same change and the prior set kept byte-unchanged, **so that** the bus contract grows only by additive
minor and a port still conforms by translation.

- **Exercises:** EMQ.5.1-INV8 (the additive-minor conformance law).

```gherkin
Given the live conformance set is 61 scenarios (conformance_run_test.exs asserts {:ok, 61};
       conformance_scenarios_test.exs @run_order = 61 names — the prior set, byte-unchanged contract)
When emq.5.1 registers the THREE batch-claim scenarios in scenarios/0 (FORK 5.1-B RULED THREE —
       batch_claim (full) + batch_claim_short (under-fill/oversized/empty/paused) + batch_partial_failure (isolation))
Then the git-diff of scenarios/0 shows ONLY additions (the prior 61 names + contracts + verdict bodies byte-unchanged, git-verified)
  And each new scenario's probe is registered in the SAME change (a present precondition — a flooded pending set — runs it with a positive proof)
  And the count re-pins 61 -> 64 (the three ruled scenarios) in BOTH pinning tests
       (conformance_run_test.exs {:ok, 64} + conformance_scenarios_test.exs @run_order)
  And Conformance.run/2 prints 64 lines and returns {:ok, 64} against the truth row (Valkey on 6390)
```

- **Liveness:** the new scenarios are not vacuous — `batch_claim` asserts the served members (US1),
  `batch_claim_short` asserts the under-fill/clamp/empty/paused outcomes (US2), and `batch_partial_failure`
  asserts isolation (US3); a scenario that claims a batch and asserts nothing about the served share fails its own
  letter (the gate-must-exercise-its-outcome rule).

---

## US6 — Honest-row proof + the determinism posture (the ≥100 loop)

**As an** evaluator (Apollo, an optional fast-finisher — this rung edits no shipped script), **I want** the proof
run against the truth row with the determinism posture honest to a mint/lease surface, **so that** a green board
reflects the real engine and the real same-millisecond mint hazard, never a host that lacks Valkey or a single
lucky run.

- **Exercises:** the honest-row law (S-4), the determinism posture (the ≥100 loop — a mint/lease surface); closes
  the rung's proof.

```gherkin
Given the live engine is Valkey on port 6390 (valkey-cli -p 6390 ping -> PONG)
When the per-app gate ladder runs inside echo/apps/echo_mq (TMPDIR=/tmp, --include valkey)
Then compile --warnings-as-errors is clean (exit 0), the :valkey batch suite is green (422/0), Conformance.run/2 -> {:ok, 64}
  And the >=100 determinism loop owns the proof (a mint/lease surface — FOREGROUND, owning the machine,
       timeout-bounded chunks driven to an accumulated count; no concurrent liveness server or sibling heavy I/O) — 100/0
  And the byte-freeze grep on @claim (and every shipped script) = 0 (INV2 — jobs.ex 94 ins/0 del, @claim byte-frozen)
  And the claims are phrased against Valkey, current stable line (a host without Valkey runs the probes elsewhere and reports them as that row, never the truth row)
```

- **Determinism rationale:** unlike emq.4.4 (which minted no id in the claim and started no process → a
  multi-seed sweep sufficed), emq.5.1's proof mints branded JOB-ids to flood the pending set and `@bclaim` leases
  on the server clock — a mint/lease surface, so the ≥100 loop is REQUIRED (the same-millisecond branded-id mint
  collision flakes only across runs).

---

## US-GATE — the standing conformance gate (every emq.* rung)

**As the** program, **I want** the full conformance harness green against the truth row at the rung's close, **so
that** the bus contract is provably whole after the spine lands.

```gherkin
Given Valkey on 6390 is up (PONG) and the fence reads the live @wire_version (echomq:2.4.2)
When EchoMQ.Conformance.run/2 runs over a live connection at the rung's close
Then it prints one line per scenario and returns {:ok, 64} (the re-pinned total — 61 + the FORK-5.1-B THREE scenarios)
  And both pinning tests pass (the pure registry test + the wire run test, count re-pinned to 64)
```

---

## Coverage map (every Deliverable → its story)

| Deliverable (from [`emq.5.1.md`](emq.5.1.md) Goal/Scope/DoD) | Story | Invariant(s) |
|---|---|---|
| `@bclaim` — the count-variant `ZPOPMIN emq:{q}:pending` loop (FORK-5.1-A RULED: the LOOP, `jobs.ex:200-219`) | US1 | INV1, INV3, INV4, INV5, INV6 |
| `claim_batch/4` — the host API (the manual-pull surface, the `claim/3` generalization, pause-first) | US1, US2 | INV3, INV4, INV5 |
| The empty / under-fill semantics (FORK-5.1-C RULED: the short batch M, non-blocking) | US2 | INV3, INV5 |
| Partial-failure isolation (a tested property over the byte-frozen `@complete`/`@retry`) | US3 | INV7, INV6, INV2 |
| The byte-freeze of `@claim` + every shipped script (`@bclaim` additive) | US4 | INV2 |
| The prior conformance scenarios byte-unchanged + the count re-pin 61 → 64 | US4, US5, US-GATE | INV2, INV8 |
| The `batch_claim` + `batch_claim_short` conformance scenarios (additive minor — FORK-5.1-B RULED THREE) | US1, US2, US5 | INV1, INV8 |
| The `batch_partial_failure` conformance scenario (additive minor) | US3, US5 | INV7, INV8 |
| The `:valkey` batch suite + the ≥100 determinism loop + honest-row | US6 | S-4, INV4, INV5 |
| The conformance harness green (`{:ok, 64}`) at the rung's close | US-GATE | INV8 |

**Traceability note (correct by definition):** every Deliverable in the body maps to at least one story above,
and every story names the invariant(s) it exercises; completion is provable from this text — a Deliverable with
no green story is not done. The `@bclaim` count-pop is covered by US1 authored to the OBSERVABLE outcome (`size`
members, mint-ordered, fenced, one shared lease) — which held for both FORK 5.1-A arms; the ruling pinned **the
LOOP** without changing what US1 asserts. The count is **64** (FORK 5.1-B RULED THREE) and the under-fill
semantics is **the short batch** (FORK 5.1-C RULED); US5/US-GATE/US2 are pinned to those ruled values.
