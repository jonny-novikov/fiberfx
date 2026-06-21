# emq.5.4 — the partitioned finish + dynamic delay, the final decisions: B · T · N (the batches-family closer) { id="emq-5-4-decisions" }

> _The Director's synthesis of Venus-1's reconcile, consolidated and ground-verified, for the Operator to ratify.
> **emq.5.4 resolves into three decisions, one coherent design:** a NEW pure module `EchoMQ.BatchFinish` routes a
> `{:delay, ms}` verdict to a NEW token-fenced atomic `@delay` script that re-scores an active member onto the
> schedule set with its attempts preserved. The three forks were argued four-part (Rationale · 5W · Steelman ·
> Steward) and each converges the same way — **the reuse path is the smaller diff, the new-surface path is the
> correct one** — because each reuse path BREAKS an invariant an earlier rung paid to establish: atomicity (Arm
> A′), lease-fence uniformity (Arm F), the pure-core/process split (Arm X). The decisions are **B · T · N**.
> This doc records them; the build re-derives the triad to the ruling at the ship's Stage-0/1. Every surface below
> was re-verified at source for this record (NO-INVENT); the one grounding correction is named in §1._

Companions: the rung triad [`../specs/emq2/emq.5/emq.5.rungs/emq.5.4.md`](../specs/emq2/emq.5/emq.5.rungs/emq.5.4.md)
(the authoritative body, FORK 5.4-A) · the family carve [`../specs/emq2/emq.5/emq.5.md`](../specs/emq2/emq.5/emq.5.md)
(the carve authority; the corrected emq.5.4 row) · the scope ledger
[`../specs/progress/emq-5-4.progress.md`](../specs/progress/emq-5-4.progress.md) (T-1 Director derivation · T-2/T-3
Venus-1 reconcile + author) · the architect's method
[`../../aaw/aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md) (the four-part lens) · the sibling
precedent (SHIPPED — the verdict-map cadence + the pure/process split):
[`../specs/emq2/emq.5/emq.5.rungs/emq.5.2.md`](../specs/emq2/emq.5/emq.5.rungs/emq.5.2.md).

## The board in one paragraph

emq.5.1/5.2/5.3 gave the bus three ways to **CLAIM** a batch (the flat `@bclaim`/`claim_batch/4`, the shaping
`EchoMQ.BatchConsumer` + the pure `BatchShaper.Core`, the grouped `@gbclaim`/`bclaim/3`). emq.5.4 closes the
**RESOLVE** half: how a worker resolves a claimed batch precisely. Two pieces are missing — (a) a first-class
**partition** over the outcome classes a member can reach (completed, retried, dead, delayed), and (b) a handler
**delay** verb that re-scores a member to run later WITHOUT burning an attempt (distinct from a failure-retry).
The load-bearing finding the reconcile surfaced re-frames the whole rung: the carve leaned _"a thin `delay/N` over
the byte-frozen `@schedule`"_, but `@schedule` **cannot** re-score an active member — it is a first-write script.
Three forks follow from that finding: the delay re-score mechanism (FORK 1), the delay fence + arity (FORK 2), and
the partition surface (FORK 3). Each is a **reuse-a-shipped-surface vs add-one-minimal-new-surface** choice, and
each reuse path breaks an earlier rung's invariant. The decision is **B · T · N**.

## 1 · The as-built grounding (re-verified at source for this record)

The reconcile (T-2) grounded every cited surface; this record re-probed them. All MATCH except one naming
correction, named below. Line numbers are HEAD (`ecb48cd9`-era) and drift; the modules / arities / shapes are the
contract.

- **The load-bearing finding — `@schedule` cannot re-score an active member.** `@schedule`
  ([`jobs.ex:55`](../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex)) opens
  `if redis.call('EXISTS', KEYS[1]) == 1 then return 0 end` (`:59-61` — the idempotency guard: a present row makes
  it a no-op, `:duplicate` host-side) and writes
  `redis.call('HSET', KEYS[1], 'state', 'scheduled', 'attempts', '0', 'payload', ARGV[2])` (`:70` — it RESETS
  attempts to `0` and DEMANDS the payload `ARGV[2]`). An already-active batch member's row EXISTS with
  `state = active`, `attempts = N` — so `@schedule` on it returns `0` and never re-scores it; bypassing the guard
  would wipe the attempt history and demand a re-supplied payload. `@schedule` is a FIRST-WRITE for a freshly-minted
  scheduled job, not a re-score of an in-flight one. The carve's "reuse `@schedule`" lean is mechanically wrong
  for an active→scheduled re-score. **Verified at source — confirmed, not taken on faith.**
- **The byte-frozen transition targets (the partition's per-member routes).** `@complete`
  ([`jobs.ex:257`](../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex)) + `complete/5` (`:589`, the head carries the
  default `result`; the token fence answers `{:error, :stale}` on `EMQSTALE`, `:616`); `@retry` (`:334`) + `retry/7`
  (`:759`); `@promote` (`:394` — `ZRANGEBYSCORE` due → `ZREM` → re-enqueue, i.e. moves **due-scheduled → pending**,
  the WRONG direction for a re-score, confirmed at `:398-405`). `dead` **emerges** from `@retry` at the attempts
  cap: the `{:ok, "dead"}` arm (`:807`) returns `{:ok, :dead}` (`:834`) — it is the script's OUTCOME, not a caller
  verdict. The schedule modes the delay mirrors: `enqueue_at/6` (`:84`, absolute caller-ms) / `enqueue_in/6` (`:95`,
  relative server-clock). The token-fence precedent: `extend_lock/5` (`:1142`) over `@extend_lock` (`:1065`,
  `EMQSTALE` at `:1069`).
- **The cadence it extends, with the one naming CORRECTION.** The brief and ledger cite "`BatchConsumer.settle/3`"
  as the emq.5.2 verdict-map router. **At source it is `defp settle(s, members, verdicts)`
  ([`batch_consumer.ex:257-269`](../../../echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex)) — a PRIVATE process
  method, not a public `settle/3`.** It routes `:ok → Jobs.complete` (`:261`, invoked at `/4`, the default `result`)
  and `{:error, reason} → Jobs.retry` (`:265`), with a missing-verdict fail-safe at `:259`
  (`Map.get(verdicts, id, {:error, "missing verdict"})`), and fires the per-member event via the private `publish/3`
  (`:274`) over the byte-frozen `EchoMQ.Events.publish/5` (`events.ex:117`). The correction STRENGTHENS Fork 3: a
  PRIVATE method that does IO (it calls `Jobs.complete`/`Jobs.retry` + publishes) is unmistakably a process method,
  which is exactly why the pure partition must NOT be folded into it (§ Fork 3). The pure-core precedent is
  `EchoMQ.BatchShaper.Core.decide/4` ([`batch_shaper/core.ex:76`](../../../echo/apps/echo_mq/lib/echo_mq/batch_shaper/core.ex),
  `@spec` at `:74`, doctested `:63-72`) — a pure, clock-free, doctested classifier; the partition follows it.
- **The conformance floor + the two pins.** `scenarios/0` (`conformance.ex:87`) + `run/2` (`:179`); the count is
  **70**, pinned at `test/conformance_run_test.exs:56` (`Conformance.run(conn, q) == {:ok, 70}`) and
  `test/conformance_scenarios_test.exs:33` (`@run_order`, the 70 names) asserted at `:107`
  (`Keyword.keys(Conformance.scenarios()) == @run_order`). The moduledoc OPENING prose lags ("fifty-five",
  `conformance.ex:3`) — narration, NOT a count-law breach: the count-law lives in the two pins, both of which read
  70. (The brief also noted a "sixty-four" at `:55`; this record confirms `:55` is the `@schedule` `Script.new`, so
  the "sixty-four" the ledger cited is elsewhere in the narrative prose — narration either way.)
- **The two version planes.** The rung label `echo/apps/echo_mq/mix.exs:7` = `2.5.1` → emq.5.4 climbs to `2.5.2`
  (a within-family patch). The wire `@wire_version` `echo/apps/echo_wire/lib/echo_mq/connector.ex:35` =
  `echomq:2.4.2` — **FROZEN** (an additive new script is a protocol minor at most; no new wire class). MATCH.

**Verdict:** every arm below rests on a MATCH-grounded surface; the lone naming correction (`settle` is `defp`)
does not move any decision — it confirms Fork 3's ruling.

## 2 · The three decisions

Each fork is the same shape: a **reuse path** (the smaller diff) versus a **new-minimal-surface path** (atomic /
fenced / pure). The decision goes to the new surface every time, for the one reason that dominates: the reuse path
breaks an invariant an earlier rung paid to establish.

### Decision 1 — the delay re-score mechanism: **Arm B, a new minimal `@delay` script** (FORK 5.4-A)

The handler must move an ACTIVE member → scheduled, PRESERVING attempts. The arms:

- **Arm B — a new minimal `@delay` script. ◄ ESTABLISHED.** One new inline `Script.new(:delay, …)` beside
  `@schedule`, atomic in ONE EVAL: token-fence on the row's attempts-token (`EMQSTALE` on a stale token) →
  `ZREM active` (release the lease) → `HSET state = scheduled` (the row, **attempts left untouched** — the delay's
  defining difference from `@schedule`'s `attempts '0'`) → `ZADD schedule` at `now + ms` (server `TIME`, the
  relative mode, the `@schedule` run-in math `jobs.ex:63-66`) or the caller's absolute-due ms (the run-at mode).
  +1 script, +1 verb; every shipped script byte-frozen; the shipped `@promote` pump releases the delayed member
  back to `pending` once due, on the same server clock. **Carrying reason:** it is the ONLY arm that is both
  **atomic** AND **attempts-preserving** — it is the inverse of `@claim` (`@claim` moves `pending → active` and
  mints a lease; `@delay` moves `active → scheduled` and releases it, mints nothing), the cleanest mental model on
  the board, reversible (a new parallel script, not an edit to a frozen one), and graded NORMAL.
- **Arm A′ — a host-only two-step (`ZREM active` then `enqueue_at`). CHOSEN-AGAINST.** _Best case kept on record:_
  it adds NO Lua at all — the literal "zero new Lua" the carve wanted. _Why rejected:_ **NON-ATOMIC** — there is a
  host window between the `ZREM active` and the schedule write in which a crash leaves the member in NEITHER set
  (removed from `active`, not yet in `schedule`); the member is **lost** — no set holds it, no pump finds it, and
  the lease is already released so the reaper cannot recover it. It also routes through `@schedule`, whose
  `HSET … 'attempts' '0'` (`:70`) wipes the member's attempt history. Rejected on the atomicity invariant
  (INV-Delay-Atomic) and attempts-preservation (INV-Delay-Rescore) — the two invariants the lease discipline rests
  on.
- **Arm C — fold into the shipped `@promote`/`@schedule`. CHOSEN-AGAINST.** _Best case kept on record:_ one fewer
  script in the lib. _Why rejected:_ `@promote` moves **due-scheduled → pending** (the WRONG direction — it
  RELEASES scheduled jobs, it does not SCHEDULE active ones; verified `jobs.ex:398-405`), so folding a re-score into
  it makes one script do two behaviors; and any fold EDITS a shipped, byte-frozen script — forfeiting the
  byte-freeze discipline (INV-Frozen) and re-grading the rung NORMAL → HIGH with Apollo mandatory. The clean
  separation is a new parallel `@delay`, not a fold.

### Decision 2 — the delay fence + arity: **Arm T, token-required `delay/5`** (the token sub-fork)

Does `delay/N` require the lease token?

- **Arm T — token-required `delay/5`** (`delay(conn, queue, id, token, delay_ms)`, in-script
  `if token ~= row.token then EMQSTALE`). **◄ ESTABLISHED.** It closes the stale-holder race: worker A stalls, the
  reaper recovers the member, worker B re-claims it (token 2); a stale A must NOT be able to re-delay B's member.
  **Carrying reason:** it is the SAME shape as every other lease-holder transition — `complete/5` (`:589`),
  `retry/7` (`:759`), `extend_lock/5` (`:1142`) — and the cost is one ARGV token, an argument the caller already
  holds. The fence is what the whole bus rests on; the delay re-scores an in-flight member, so it must carry the
  same fence.
- **Arm F — token-free `delay/4`. CHOSEN-AGAINST.** _Best case kept on record:_ a slimmer signature; a
  control-plane "push this member out" operator action genuinely wants no token (an operator is not a lease
  holder). _Why rejected:_ for the HANDLER's verb it breaks lease-fence uniformity — any caller could re-delay any
  active member by id, yanking it out from under its current owner. A token-free operator "push out" is a SEPARATE
  control-plane verb to add later (the emq.4.1 `reassign`/`drain` precedent — operator verbs are their own
  surface); it is not a reason to drop the handler's fence here.

### Decision 3 — the partition surface: **Arm N, a new pure `EchoMQ.BatchFinish`** (the resolve-half split)

Where does the partitioned finish live?

- **Arm N — a new pure module `EchoMQ.BatchFinish.partition/N`** → `%{completed, retried, dead, delayed}`
  (exhaustive + disjoint over the claimed members; `dead` EMERGES from the `@retry` `{:ok, :dead}` outcome, not a
  caller verdict). **◄ ESTABLISHED.** It mirrors emq.5.2's DELIBERATE pure-core/process split: `BatchShaper.Core.decide/4`
  was split OUT of the `BatchConsumer` process precisely so the central decision is pure and doctested. **Carrying
  reason:** it applies the proven split to the RESOLVE half that 5.2 applied to the START — a pure module is the
  cheapest surface to own and test, and it keeps the rung's central logic (the partition) pure and directly
  doctested rather than buried in a process. The verdict vocabulary `:ok | {:error, reason} | {:delay, ms}` is the
  emq.5.2 map extended with the one new `{:delay, ms}` variant.
- **Arm X — extend the private `settle/3` + `BatchShaper.Core` in place. CHOSEN-AGAINST.** _Best case kept on
  record:_ no new module; the partition lands where the routing already is. _Why rejected:_ `settle` is a PRIVATE
  PROCESS method that does IO (it calls `Jobs.complete`/`Jobs.retry` + publishes — confirmed `batch_consumer.ex:257-269`,
  the §1 correction); folding the pure partition into it RE-BURIES the central logic the way 5.2 deliberately split
  apart, and grows a shipped 5.2 surface rather than leaving it byte-stable. The pure classifier stands alone
  (Arm N); the process (`settle`) gains only the `{:delay, ms}` ROUTING branch (Decision 4 below), staying a thin
  router.

### The fourth move (not a fork — it follows from the three) — the cadence branch

`settle/3` (the private process router) gains the `{:delay, ms}` verdict branch beside its shipped
`:ok`/`{:error, reason}` branches (the THIRD branch), routing a delayed member through the new `delay/5`, and
publishes a `delayed` per-member event over the byte-frozen `Events.publish/5` (`events.ex:117`). This is not a
fork — it is the minimal wiring the established design implies once Decisions 1–3 are set: the process stays a thin
router, the partition stays pure, the delay stays a token-fenced atomic script.

## 3 · The consolidated coherent design

The three decisions reinforce into ONE design, not three independent picks:

> A NEW pure `EchoMQ.BatchFinish.partition/N` classifies a claimed batch + its verdict map into the exhaustive,
> disjoint partition `%{completed, retried, dead, delayed}`. A `{:delay, ms}` verdict routes to a NEW
> **token-fenced atomic `@delay`** script that re-scores an active member onto the schedule set with its attempts
> preserved — the inverse of `@claim`. The shipped `@complete`/`@retry`/`@schedule`/`@promote` stay byte-frozen; the
> private `settle/3` gains only the `{:delay, ms}` routing branch + the `delayed` event; the shipped `@promote`
> pump releases the delayed member once its server-clock score is due.

The pieces compose because each respects the boundary the others depend on: the partition is pure (so it is
doctestable and the process stays thin), the delay is atomic + fenced (so a delayed member is never lost and never
yanked from its owner), and the schedule fence is reused (so the delay adds only the one `active → scheduled`
transition the fence had no entry for).

## 4 · The cross-fork pattern (the one lesson)

All three forks are the same shape — **reuse a shipped surface (the smaller diff) vs add one minimal new surface
(atomic / fenced / pure)** — and in all three the reuse path BREAKS an invariant an earlier rung paid to
establish:

- Arm A′ (host two-step) breaks **atomicity** — the invariant that a member is always in exactly one of
  `{active, schedule, pending}`, never zero.
- Arm F (token-free) breaks **lease-fence uniformity** — the invariant that every in-flight transition is guarded
  by the holder's token (`complete`/`retry`/`extend_lock`).
- Arm X (fold into `settle`) breaks the **pure-core/process split** — the invariant emq.5.2 paid to establish, that
  the central decision is pure and doctested, not buried in a process.

The smaller diff is the false economy: it saves a module or a script today and spends an invariant the whole bus
rests on. **B · T · N** is the design that keeps all three invariants — and it is more coherent than any reuse mix,
because the new pure module, the token-fenced atomic script, and the reused schedule fence are exactly the three
surfaces that let each other stay simple.

## 5 · The posture (additive-minor, NORMAL)

- **Conformance:** `70 → 70 + N`, additive minor — the prior 70 byte-unchanged + git-verified, each new scenario
  probe-registered, and the count re-pinned in BOTH pins (`conformance_run_test.exs:56` `{:ok, 70 + N}` +
  `conformance_scenarios_test.exs:33` `@run_order`). The new scenarios: the partition over a batch · the
  dynamic-delay re-score · attempts-preserved across the delay · the stale-delay `EMQSTALE` refusal.
- **Risk: NORMAL.** The rung reuses the byte-frozen `@complete`/`@retry`/`@schedule`/`@promote` and adds at most ONE
  new additive script (`@delay`, the inverse of `@claim` — it releases a lease and mints nothing). No destructive
  at-rest op, no wire break, no new lease surface. Apollo OPTIONAL (closure + stories, not mandatory — no new
  process/lease/destructive surface).
- **Determinism:** a **MULTI-SEED sweep + an honest posture statement**, NOT the ≥100 loop. The carve §3 ruling
  holds: emq.5.4 introduces no new mint/lease — the delay RELEASES a lease, the partition is pure host logic — so
  the same-millisecond branded-`JOB` mint hazard the ≥100 loop owns does not apply.
- **The version planes:** rung label `2.5.1 → 2.5.2` (a within-family patch); the wire `@wire_version` stays
  **FROZEN** `echomq:2.4.2` (an additive script is a protocol minor at most; the label plane climbs, the wire plane
  does not — the established pattern for `@bclaim`/`@gbclaim`).
- **The carve correction to land at Stage-5:** the family carve's emq.5.4 row + its FORK 5.4-A line currently lean
  _"reuse `@schedule` / zero new Lua"_; the build trues them up to the ruled mechanism (a new minimal `@delay`,
  one additive script — the symmetric resolve-half cost to the family's one-additive-script-per-claim-rung
  pattern).

## 6 · The decisions, restated for ratification

1. **FORK 5.4-A — Arm B:** the delay is a NEW minimal atomic `@delay` script (`ZREM active` → `HSET state = scheduled`
   attempts-preserved → `ZADD schedule`, server-clock relative / caller-ms absolute). Arm A′ rejected on atomicity
   + attempts-preservation; Arm C rejected on direction + byte-freeze.
2. **The token sub-fork — Arm T:** `delay/5` is token-required (`EMQSTALE` on a stale token), symmetric with
   `complete/5`/`retry/7`/`extend_lock/5`. Arm F (token-free) rejected for the handler's verb — an operator "push
   out" is a separate control-plane verb later.
3. **The partition surface — Arm N:** a NEW pure `EchoMQ.BatchFinish.partition/N` → `%{completed, retried, dead,
   delayed}` (exhaustive + disjoint; `dead` emerges from the `@retry` outcome), mirroring emq.5.2's pure-core/process
   split. Arm X (fold into the private `settle/3`) rejected — `settle` is a process method that does IO; the
   partition stays pure, `settle` gains only the `{:delay, ms}` routing branch.

**Consolidated: B · T · N** — a new pure `EchoMQ.BatchFinish` routes a `{:delay, ms}` verdict to a token-fenced
atomic `@delay`. The Operator ratifies; the build re-derives the triad to the ruling at Stage-0/1.
