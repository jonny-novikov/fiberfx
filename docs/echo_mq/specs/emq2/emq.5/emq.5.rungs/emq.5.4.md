# EMQ.5.4 · The partitioned finish + dynamic delay — the batch resolves as a partition (Movement II, the batches family, the CLOSER)

> **Status: 🔨 SPECCED — RULED (B · T · N); the triad re-derived to the ruling; NOT yet built. The FOURTH and FINAL
> sub-rung of the emq.5 "batches" family; the family contract + the carve are [`../emq.5.md`](../emq.5.md).** This body
> is the authoritative contract; the acceptance is [`emq.5.4.stories.md`](emq.5.4.stories.md), the Mars brief is
> [`emq.5.4.llms.md`](emq.5.4.llms.md), the runbook is [`emq.5.4.prompt.md`](emq.5.4.prompt.md). The voice is
> forward-tense for what the rung builds ("emq.5.4 builds…"); the surfaces it reuses are grounded against the as-built
> `echo_mq` tree. emq.5.4 **closes** the family: the SHIPPED batch-claim spine (emq.5.1 — `@bclaim`/`claim_batch/4`),
> the SHIPPED shaping cadence (emq.5.2 — `EchoMQ.BatchConsumer` + `BatchShaper.Core`), and the SHIPPED grouped batch
> (emq.5.3 — `@gbclaim`/`bclaim/3`) all gave the bus a way to CLAIM many jobs at once; emq.5.4 gives the worker a
> precise vocabulary to RESOLVE the batch — a **partition** over the claimed members, plus a **dynamic delay** verb the
> handler uses to re-score a member that should run later rather than now.
>
> **THE FORK IS RULED — B · T · N** (the Operator ratified all three forks; the rulings are locked on the ledger as
> D-1/D-2/D-3, `docs/echo_mq/specs/progress/emq-5-4.progress.md`, consolidated in the KB record
> [`../../../../kb/emq-5-4-decisions.md`](../../../../kb/emq-5-4-decisions.md)). One coherent design: a **NEW pure
> `EchoMQ.BatchFinish`** routes a `{:delay, ms}` verdict to a **NEW token-fenced atomic `@delay`** script that re-scores
> an active member onto the schedule set with its attempts preserved. **D-1 (FORK 5.4-A, the mechanism) = Arm B** (a new
> minimal atomic `@delay`); **D-2 (the fence) = Arm T** (`delay/5` is token-fenced, `EMQSTALE`); **D-3 (the partition) =
> Arm N** (a new pure `EchoMQ.BatchFinish.partition/N`). The chosen-against arms (A′ / C / F / X) are recorded as
> road-not-taken in §"The rung's forks". The reconcile **corrected the carve's lean**: the carve
> ([`../emq.5.md`](../emq.5.md) §1 row emq.5.4 line 60, FORK 5.4-A line 107) leaned *"a thin `delay/N` over the
> byte-frozen `@schedule`"* — but the reconcile against `echo/apps/echo_mq/lib/echo_mq/jobs.ex:55-73` confirmed
> **`@schedule` CANNOT re-score an active member** (it is a first-write script: an `EXISTS`-guard that no-ops a present
> row, and an attempts-RESET that would wipe the member's attempt history and demand a re-supplied payload). The ruled
> mechanism is the NEW minimal `@delay` (D-1 = Arm B).
>
> **Risk: NORMAL.** emq.5.4 reuses the byte-frozen `@complete`/`@retry`/`@schedule`/`@promote` for the partition's
> transitions, and adds exactly **ONE new additive script** (`@delay`, D-1 = Arm B) — a NEW inline `Script.new` parallel
> to the shipped scripts, NOT an edit to a frozen one. No destructive at-rest op, no wire break, no new lease surface
> (`@delay` RELEASES a lease — it re-scores an active member onto the schedule set; it mints nothing). The determinism
> posture is a **MULTI-SEED sweep + an honest posture statement**, NOT the ≥100 loop (the carve §3 ruling: 5.4
> introduces no new mint/lease, so the same-millisecond branded-`JOB` mint hazard the loop owns does not apply).
> Conformance grows **70 → 70 + N** (the partition over a batch · the dynamic-delay re-score · attempts-preserved
> across the delay · the stale-delay `EMQSTALE` refusal), additive minor.

## 0 · The slice — what emq.5.4 closes, and why NORMAL

The family ([`../emq.5.md`](../emq.5.md)) is the Movement II **consume** family. emq.5.1 shipped the **spine** (a flat
batch claim, `@bclaim` over `emq:{q}:pending`, a count-variant `ZPOPMIN` loop, one server-clock lease). emq.5.2 shipped
the **shaping cadence** (`EchoMQ.BatchConsumer` — the `min_size`/`timeout` flush, a pure `BatchShaper.Core`, a
per-member verdict map). emq.5.3 shipped the **grouped batch** (`@gbclaim`/`bclaim/3` — a homogeneous lane-scoped
batch counted against the group's `gactive` ceiling). All three are **claim** surfaces: they answer the question *"how
do I take many jobs in one atomic step?"*

emq.5.4 closes the **resolve** half: *"how does the worker RESOLVE a claimed batch precisely?"* It is two additive
pieces:

(a) **the partitioned finish** — a claimed batch resolves as a **partition** `{completed, retried, dead, delayed}`
over its members, where each member's verdict is `:ok | {:error, reason} | {:delay, ms}`. The partition is a **pure,
exhaustive, disjoint** classification of the verdict map: `:ok` members route through the byte-frozen `@complete`,
`{:error, reason}` members through the byte-frozen `@retry`, and `{:delay, ms}` members through the new dynamic-delay
verb (§b). `dead` is **not a caller verdict** — it **emerges** when `@retry` returns `{:ok, :dead}` (the attempts cap,
`jobs.ex:759` → `jobs.ex:807-834`), so a member the handler asked to retry but which had exhausted its attempts lands
in `dead`, not `retried`. The partition is the report of where every member of the batch went.

(b) **the dynamic delay** — `Jobs.delay/5`, a verb the batch handler (or any worker holding a claimed member) uses to
re-score an **active** member onto the **schedule** set: "do not retry this now, run it again after `ms`." It is the
inverse of a claim (a claim moves `pending → active` and mints a lease; `delay` moves `active → scheduled` and
**releases** the lease), **preserving the member's attempts** (a delay is not a failure — the member's fencing token
and attempt history survive). The shipped promote pump (`@promote`, `jobs.ex:394`) releases the delayed member back to
`pending` once its score is due, on the same server clock — so `delay` rides the EXISTING schedule fence, adding only
the active→scheduled transition the fence has no other entry for.

**Why NORMAL.** The partition is **pure host logic over shipped, byte-frozen transitions** (`@complete`/`@retry`/the
new `@delay`) — it adds no Lua of its own (D-3 = Arm N: the pure `EchoMQ.BatchFinish`). The dynamic delay adds exactly
**one new additive script** (`@delay`, D-1 = Arm B), a NEW inline `Script.new` parallel to the shipped scripts; the
shipped `@complete`/`@retry`/`@schedule`/`@promote` stay **byte-frozen**. There is **no new lease surface** — `@delay`
releases a lease and mints nothing (the inverse of `@claim`) — so the carve §3 determinism ruling holds: a multi-seed
sweep, NOT the ≥100 loop. The one elevated point the rung had — the dynamic delay's mechanism — was the **MECHANISM-
DECIDING** FORK 5.4-A, now **RULED Arm B** (the reconcile re-grounded the carve's "reuse `@schedule`" lean against the
as-built `@schedule` and the Operator ruled the new atomic `@delay`; the non-atomic host two-step (A′) and the
`@promote` fold (C) are the recorded chosen-against arms).

## Goal

emq.5.4 builds, inside `echo/apps/echo_mq`, the **partitioned finish** of a claimed batch plus a **dynamic-delay**
verb, over the byte-frozen per-member transitions:

(a) **the partition** (D-3 = Arm N) — a NEW pure module `EchoMQ.BatchFinish` whose `partition/N` (the `BatchShaper.Core`
pure-core precedent `batch_shaper/core.ex`) maps a claimed batch + its per-member verdict map + the per-member
transition outcomes into a partition `%{completed: [...], retried: [...], dead: [...], delayed: [...]}` —
**exhaustive** (every claimed member appears in exactly one bucket) and **disjoint** (no member in two). The verdict
vocabulary is `:ok | {:error, reason} | {:delay, ms}` (the emq.5.2 `:ok | {:error, reason}` map extended with the
`{:delay, ms}` variant — the new vocabulary). The classifier consumes the OUTCOME of each member's transition (so
`dead` is read from the `@retry` return `{:ok, :dead}`, not asserted by the caller); it is the resolve-half analogue of
the START-half split emq.5.2 made (the pure `BatchShaper.Core` carved out of the `BatchConsumer` process), so the
central resolve logic stays pure and doctested, not buried in a process (D-3 rejects Arm X — folding the partition into
the private process router);

(b) **the dynamic-delay verb** (D-1 = Arm B, D-2 = Arm T) — `Jobs.delay/5` `(conn, queue, job_id, token, ms)`, which
re-scores an **active** member onto the **schedule** set at `now + ms` (relative, server clock) or an absolute due-ms
(the two modes `enqueue_at`/`enqueue_in` already document, `jobs.ex:84`/`jobs.ex:95`), **preserving the member's
`attempts`**, **token-fenced** (only the current attempts-token holder may delay — `EMQSTALE` on a stale token,
symmetric with `complete/5`/`retry/7`/`extend_lock/5`, `jobs.ex:589`/`jobs.ex:759`/`jobs.ex:1142`), via the NEW atomic
`@delay` script (D-1 = Arm B — the inverse of `@claim`: `ZREM active` / `HSET state = scheduled` attempts-preserved /
`ZADD schedule`, all in ONE EVAL);

(c) **the partition driven through the shaping cadence** — the PRIVATE process router `defp settle(s, members,
verdicts)` (`batch_consumer.ex:257-269`) gains the `{:delay, ms}` verdict branch beside its shipped
`:ok`/`{:error, reason}` branches (the THIRD settle branch), so the shaping consumer (emq.5.2) can route a delayed
member through `delay/5`; the settle then reports the partition (per-member events on the byte-frozen
`EchoMQ.Events.publish/5` seam, `events.ex:117` — a `delayed` event for a delayed member, beside the shipped
`completed`/`failed`). `defp settle` is a process method that does IO (it calls `Jobs.complete`/`Jobs.retry` +
publishes), so it gains ONLY the routing branch — the partition logic stays in the pure `EchoMQ.BatchFinish` (the D-3 =
Arm N split).

All under the v2 laws — the A-1 declared-keys law (the `@delay` script's braced `KEYS[n]` pin the `{q}` slot, the
lease and schedule sets ride that slot), branded `JOB` ids gated at the key builder, the **server clock** (`TIME`) on
the delay re-score, byte-freeze on the reused `@complete`/`@retry`/`@schedule`/`@promote`, and additive-minor
conformance growth (**70 → 70 + N**, the prior 70 byte-unchanged).

## Rationale (5W)

- **Why** — emq.5.1/5.2/5.3 give the worker a way to CLAIM a batch, but resolving it is still ad-hoc: the emq.5.2
  cadence has a binary verdict map (`:ok`/`{:error, reason}`) and no vocabulary for "run this later." Two gaps close
  here. (1) **A precise resolution report.** A batch handler resolving ten members needs to know — and a caller
  accepting needs to verify — that every member went somewhere definite: completed, retried, dead (retry hit the cap),
  or delayed. The **partition** is that report, made a pure, exhaustive, disjoint classification so "the batch
  resolved" is a closure over checks, not prose. (2) **A dynamic delay.** A handler often learns at resolution time
  that a member should run later (a dependency not ready, a rate-limited downstream) — distinct from a FAILURE (which
  consumes an attempt and dead-letters at the cap). Today the only "later" verbs are `enqueue_at`/`enqueue_in`, which
  **mint a fresh job** (`@schedule` writes a new row at `attempts 0`); there is no verb to re-score a member ALREADY
  in flight without losing its identity, attempts, or payload. `delay/5` is that verb.
- **What** — emq.5.4 builds: (1) **the partition** (D-3 = Arm N) — the NEW pure module `EchoMQ.BatchFinish`
  (`partition/N` over a batch + its verdict map + the transition outcomes → `%{completed, retried, dead, delayed}`,
  exhaustive + disjoint, `dead` read from the `@retry` outcome); (2) **the dynamic-delay verb** (D-1 = Arm B, D-2 =
  Arm T) — `Jobs.delay/5` (an `active → scheduled` re-score on the server clock, attempts-preserved, token-fenced
  `EMQSTALE`, via the NEW atomic `@delay`); (3) **the cadence branch** — the `{:delay, ms}` verdict in the private
  `defp settle` (`batch_consumer.ex:257-269`, the third settle branch) + the `delayed` per-member event; (4)
  **the conformance scenarios** (additive minor — the prior **70** byte-unchanged → **70 + N**: the partition over a
  batch · the dynamic-delay re-score · attempts-preserved across the delay · the stale-delay `EMQSTALE` refusal); (5)
  the `:valkey` proof + the **multi-seed sweep** (NOT the ≥100 loop — no new mint/lease, carve §3) + the **byte-freeze
  grep** on the reused `@complete`/`@retry`/`@schedule`/`@promote` (= 0 for `grep redis.call`).
- **Who** — the program (the rung that closes batches with a precise resolution surface); **workers** resolving a
  claimed batch, who gain the partition report and the `delay` verb; the conformance harness, which grows by the
  partition + delay + attempts-preserved + stale-refusal scenarios. The shipped emq.5.2 private `defp settle` (the
  verdict-map process router) is the precedent the delay branch extends; its pure-core/process split (the `BatchShaper.Core`
  carve) is the precedent the partition follows.
- **When** — Movement II, the batches family's **fourth and FINAL** sub-rung. It rides emq.5.1 (`@bclaim`/
  `claim_batch/4`) and the byte-frozen `@complete`/`@retry`/`@schedule`/`@promote`; it extends emq.5.2's private
  `defp settle`. The family carve gate-ordered 5.4 last (it depends only on 5.1 + the shipped transitions; mutually
  independent of 5.2/5.3, but reuses 5.2's `defp settle` so it lands after it). FORK 5.4-A was ruled via
  `AskUserQuestion` at the pre-build reconcile (RULED B · T · N, D-1/D-2/D-3); this body is re-derived to the ruling.
- **Where** — `echo/apps/echo_mq` only: a NEW `lib/echo_mq/batch_finish.ex` (the pure partition classifier — the
  `BatchShaper.Core` sibling, D-3 = Arm N) + a new `@delay` `Script.new` and `Jobs.delay/5` in `jobs.ex` BESIDE the
  byte-frozen `@schedule`/`@complete`/`@retry`/`@promote` (D-1 = Arm B) + the `{:delay, ms}` branch in the private
  `defp settle` (`batch_consumer.ex:257-269`), plus `conformance.ex` (the new scenarios + the count re-pin), the two
  pinning tests (`conformance_run_test.exs` `{:ok, 70+N}` + `conformance_scenarios_test.exs` `@run_order`), `mix.exs`
  (the rung label `2.5.2`; the wire `@wire_version` stays `echomq:2.4.2`). `echo_wire` is **untouched** (the verb rides
  the shipped connector `eval`). `apps/echomq` is **untouched** (the capability reference). The §6 grammar in
  `keyspace.ex` is **unedited** (no new key family — `@delay` rides the shipped `active`/`schedule` sets + the gated
  `job:` row).

## Scope

- **In** — (1) the **partition** (D-3 = Arm N — the NEW pure `EchoMQ.BatchFinish.partition/N` over a claimed batch +
  its per-member verdict map + the transition outcomes → `%{completed, retried, dead, delayed}`, exhaustive + disjoint;
  `dead` read from the `@retry` outcome, NOT a caller verdict); (2) the **dynamic-delay verb** (D-1 = Arm B, D-2 =
  Arm T — `Jobs.delay/5` via the NEW atomic `@delay`: an `active → scheduled` re-score on the server clock,
  attempts-PRESERVED, token-fenced `EMQSTALE`); (3) the **cadence branch** (the `{:delay, ms}` verdict in the private
  `defp settle` + the `delayed` per-member event on the byte-frozen `Events.publish/5`); (4) the verdict vocabulary
  extension (`:ok | {:error, reason} | {:delay, ms}` — the emq.5.2 map + the new `{:delay, ms}` variant); (5) the
  conformance scenarios (additive minor — the prior **70** byte-unchanged → **70 + N**); (6) the `:valkey` suites + the
  **multi-seed determinism sweep** (NO ≥100 loop — no new mint/lease, carve §3) + the **byte-freeze grep** on
  `@complete`/`@retry`/`@schedule`/`@promote` (= 0).
- **Out** — any **edit to the shipped `@complete`/`@retry`/`@schedule`/`@promote`** (every one byte-frozen —
  INV-Frozen; the delay is the NEW `@delay`, parallel, D-1 = Arm B); a **non-atomic host-only delay** (FORK 5.4-A Arm A′,
  CHOSEN-AGAINST on the atomicity invariant: a crash between the `ZREM active` and the `ZADD schedule` strands leaves
  the member in NEITHER set, lost); a **fold into `@promote`/`@schedule`** (FORK 5.4-A Arm C, CHOSEN-AGAINST on
  direction — `@promote` moves due-scheduled → pending — and byte-freeze); a **token-free `delay`** (the token sub-fork
  Arm F, CHOSEN-AGAINST — breaks lease-fence uniformity; an operator "push-out" is a separate control-plane verb
  later); **folding the partition into the private `defp settle`** (D-3 Arm X, CHOSEN-AGAINST — `defp settle` is a
  process method that does IO; the partition stays pure in `EchoMQ.BatchFinish`); **re-scoring via `@schedule`** (the
  carve's original lean — `@schedule`'s `EXISTS` guard no-ops a present row and its attempts-RESET would wipe the
  member's history; the reconcile correction — see §"The rung's forks"); a **`delay` that consumes an attempt** (a
  delay is NOT a failure — `attempts` is preserved; the failure-and-backoff path is `@retry`, unchanged); the
  **grouped-batch finish** (a partition driven through `@gbclaim`/`bclaim/3` — the lane accounting on a grouped delay
  is a carried follow-up, named not built here; the flat-batch partition is this rung); any **new key family** (the
  delay rides the shipped `active`/`schedule` sets + the gated `job:` row — INV-DeclaredKeys); any
  **`echo_wire`/transport** change (`@wire_version` stays `echomq:2.4.2`); any **edit to the frozen v1 reference
  line** (`apps/echomq`).

## Invariants (the runnable checks — derived from T-1, ratified under the B · T · N ruling)

- **EMQ.5.4-INV-Partition — the finish is a pure, exhaustive, disjoint partition.** `EchoMQ.BatchFinish.partition/N`
  maps a claimed batch of M members + a verdict map into `%{completed, retried, dead, delayed}` such that the four
  buckets' members are EXACTLY the M claimed members (exhaustive — every claimed member in one bucket; no extra
  member), and no member appears in two buckets (disjoint). The classifier is PURE (no process, no clock, no I/O — the
  `BatchShaper.Core` discipline). `dead` is read from the `@retry` OUTCOME (`{:ok, :dead}`), not a caller verdict.
  *Check:* a pure unit-test scenario — a batch of M with a mixed verdict map (some `:ok`, some `{:error, reason}` that
  retry, some `{:error, reason}` that have hit the cap → dead, some `{:delay, ms}`) — asserts `completed ++ retried ++
  dead ++ delayed` is a permutation of the M claimed ids (exhaustive), the four lists are pairwise disjoint, and a
  member absent from the verdict map lands fail-safe (the emq.5.2 "missing verdict" → retry, never a silent complete).
- **EMQ.5.4-INV-Delay-Rescore — `delay/5` moves active → scheduled, attempts PRESERVED.** A `delay/5` on an active
  member ZREMs it from the `active` set, sets the row `state = scheduled`, and ZADDs it to the `schedule` set at the
  computed due score — **without resetting `attempts`** (a delay is not a failure; the member's fencing token and
  attempt history survive, unlike `@schedule`'s `attempts 0` first-write). The shipped promote pump (`@promote`)
  releases it back to `pending` once due, on the server clock. *Check:* the `batch_delay` `:valkey` scenario — claim a
  member (attempts → 1), `delay/5` it, assert the row `state = scheduled` AND `attempts` STILL 1 (NOT reset to 0), the
  member is in `schedule` and absent from `active`, invisible to `claim`; then `promote/2` once due returns it to
  `pending`, and a fresh `claim` mints attempts → 2 (the attempt history continued, NOT restarted). An attempts-reset
  is a LOUD failure.
- **EMQ.5.4-INV-Delay-Atomic — the re-score is ONE atomic step.** The active→scheduled re-score happens in ONE
  server-side step (one EVAL of the new `@delay` script, D-1 = Arm B), so the member is NEVER observable in neither
  set: there is no host window between the `ZREM active` and the `ZADD schedule` in which a crash strands the member
  (the FORK 5.4-A Arm A′ defeater — the chosen-against host two-step). *Check:* a grep confirms the `@delay` body holds
  both the `ZREM active` and the `ZADD schedule` (no host-side two-step); the `batch_delay` scenario asserts the member
  is in EXACTLY one of `{active, schedule, pending}` at every observation (never zero).
- **EMQ.5.4-INV-Delay-Token — `delay/5` is token-fenced (`EMQSTALE`).** Only the current attempts-token holder may
  delay a member: a `delay/5` with a stale token answers `{:error, :stale}` (the `EMQSTALE` fencing-token wire class —
  no new class, symmetric with `complete/5`/`retry/7`/`extend_lock/5`, `jobs.ex:589`/`jobs.ex:759`/`jobs.ex:1142`),
  changing nothing — a worker whose lease has been reaped and re-claimed by another worker cannot re-delay a member it
  no longer owns (the stale-holder race D-2 = Arm T closes). The fence is the **attempts-token** (`att`), the same
  token the private `defp settle` already threads to `Jobs.complete`/`Jobs.retry` (`batch_consumer.ex:261`/`:265`,
  destructured `{id, _payload, att}`), so the `{:delay, ms}` branch threads `att` identically. A missing row answers
  `{:error, :gone}`. *Check:* the `batch_delay_stale` `:valkey` scenario — claim a member (token 1), reap + re-claim it
  (token 2), then a `delay/5` with token 1 is refused `EMQSTALE` and the member's `active`-set membership (the token-2
  lease) is untouched; a `delay/5` with the live token 2 settles.
- **EMQ.5.4-INV-ServerClock (← INV4) — the delay due score is on the server clock.** `delay/5`'s relative-delay mode
  computes `now + ms` from `redis.call('TIME')` **server-side** (the `@schedule` run-in pattern, `jobs.ex:63-66`; the
  `@claim`/`@retry` `TIME` lease pattern), never the caller's clock; the absolute-due mode prices the score from the
  caller's ms (the documented `enqueue_at` client-clock surface for the SCORE only, `jobs.ex:84`). *Check:* a grep of
  the delay's relative path for a host-supplied due timestamp returns empty; the `batch_delay` scenario asserts the
  delayed member is invisible to `claim` until its server-clock score is due, then `promote/2` releases it.
- **EMQ.5.4-INV-DeclaredKeys (← S-6, the A-1/L-1 law) — the delay rides the declared slot.** Any new `@delay` script
  declares the braced `KEYS[n]` pinning the `{q}` slot (the `active` set, the `schedule` set, the `job:` row — the
  `@retry` declared-keys convention, `jobs.ex:760-765`); no key is derived from a data value. **An ARGV base is NOT a
  declared root** — the braced `KEYS[n]` pin the slot, the row/sets ride that slot (the emq.5.1-L1 finding,
  gate-invisible on single-node Valkey). *Check:* every key the delay touches shares the one `{q}` slot `KEYS[n]` pin;
  a grep confirms no key is read out of a data value, and the row/sets root on the declared slot.
- **EMQ.5.4-INV-Frozen (← INV2) — the byte-freeze discipline.** emq.5.4 edits **no** shipped transition script: the
  shipped `@complete` (`jobs.ex:257`), `@retry` (`jobs.ex:334`), `@schedule` (`jobs.ex:55`), `@promote`
  (`jobs.ex:394`), and `@bclaim` (`jobs.ex:200`) / `@gbclaim` (`lanes.ex:161`) are **byte-identical to HEAD** (`grep
  redis.call` on the lib diff for those = 0; the delay is the NEW `@delay`, a parallel path under Arm B). The prior
  batch + flow + groups conformance scenarios pass **byte-unchanged**. *Check:* the byte-freeze grep on every shipped
  transition script = 0; the prior scenarios git-verified unchanged; the prior 70 byte-unchanged.
- **EMQ.5.4-INV-Determinism — a multi-seed sweep, NOT the ≥100 loop (no new mint/lease).** emq.5.4 introduces no new
  mint/lease surface — `delay/5` RELEASES a lease (re-scores an active member onto the schedule set) and mints nothing;
  the partition is pure host logic. So the carve §3 ruling holds: the same-millisecond branded-`JOB` mint hazard the
  ≥100 loop owns does not apply, and the determinism posture is a **multi-seed sweep + an honest posture statement**
  (the partition's only inputs are the verdict map + the `@retry` outcomes — deterministic given the seed; the delay's
  only nondeterminism is the server clock, isolated to the score). *Check:* `for s in 0 1 2 7 42 99; do TMPDIR=/tmp mix
  test --include valkey --seed $s || break; done` is green; the posture statement names why no ≥100 loop is owed (no
  new mint/lease — the delay releases, the partition is pure).

## The rung's forks — RULED B · T · N (the Operator ratified all three via `AskUserQuestion`, ledger D-1/D-2/D-3)

> **Three forks, one coherent design.** The Operator ratified FORK 5.4-A and its two sub-forks; the rulings are locked
> on the ledger (`docs/echo_mq/specs/progress/emq-5-4.progress.md`, D-1/D-2/D-3) and consolidated in the KB record
> [`../../../../kb/emq-5-4-decisions.md`](../../../../kb/emq-5-4-decisions.md). The body above is now authoritative
> against the ruling; the four-part Arms (Rationale / 5W / Steelman / Steward) are retained below as the decision
> record, each chosen-against arm kept on record with its best case. **D-1 (mechanism) = Arm B · D-2 (fence) = Arm T ·
> D-3 (partition) = Arm N.** The cross-fork pattern (the one lesson): all three are *reuse a shipped surface (the
> smaller diff) vs add one minimal new surface (atomic / fenced / pure)*, and each reuse path BREAKS an invariant an
> earlier rung paid to establish — atomicity (Arm A′), lease-fence uniformity (Arm F), the pure-core/process split
> (Arm X). B · T · N keeps all three.

### FORK 5.4-A — the dynamic-delay mechanism (MECHANISM-DECIDING) — RULED: Arm B (a new minimal `@delay`), D-1

> **Rationale.** A handler must move an **active** member onto the **schedule** set while **preserving its attempts** (a
> delay is not a failure). The reconcile against `echo/apps/echo_mq/lib/echo_mq/jobs.ex:55-73` is the load-bearing
> fact: **`@schedule` cannot do this.** `@schedule` opens `if redis.call('EXISTS', KEYS[1]) == 1 then return 0 end` — a
> present (active) row makes it a no-op (`:duplicate` host-side) — and it `HSET`s `'attempts' '0'` and demands `ARGV[2]`
> the payload — it is a FIRST-WRITE for a freshly-minted scheduled job, not a re-score of an in-flight one. So the
> carve's "reuse `@schedule`" lean is corrected; the choice is HOW to add the active→scheduled re-score.
>
> **5W.** *What:* the mechanism of the active→scheduled re-score. *Why:* `@schedule` is a first-write (the reconcile
> fact), so re-scoring an active member needs a different mechanism — a new atomic script, a host two-step, or a fold.
> *Who:* the build (the mechanism sets whether one script is added and whether the re-score is atomic). *When:* before
> the build. *Where:* `jobs.ex` (a new `@delay` + `delay/5`).
>
> **The arms:**
> - **Arm B — a NEW minimal `@delay` script. ◄ RULED, D-1.** One NEW inline `Script.new(:delay, …)` in `jobs.ex`
>   beside `@schedule`, atomic in ONE EVAL: token-fence on the row's attempts-token (`EMQSTALE` on a stale token, the
>   `@complete`/`@extend_lock` pattern); `ZREM active` (release the lease); `HSET state = scheduled` (the row,
>   **attempts left untouched** — the delay's defining difference from `@schedule`'s `attempts 0`); `ZADD schedule`
>   at `now + ms` (server `TIME`, the relative mode — the `@schedule` run-in math `jobs.ex:63-66`) or the caller's
>   absolute-due ms (the run-at mode). *Steelman:* the **atomic minimum** — the active→scheduled re-score is the ONE
>   transition the schedule fence has no entry for, and a new script is the smallest correct way to add it; it is the
>   **inverse of `@claim`** (releases a lease, mints nothing — the cleanest mental model); keeps `@schedule`/
>   `@complete`/`@retry`/`@promote` **byte-frozen**; **reversible** (a new parallel script, not an edit to a frozen
>   one); grades **NORMAL** (no shipped-script edit, no new mint/lease → a multi-seed sweep, not the ≥100 loop). *Cost:*
>   one new Lua script (which corrects the carve's "zero new Lua in 5.4" — the family already adds one additive script
>   per claim rung; this adds one for the resolve half, the symmetric cost). As ruled: `@delay` is the ONLY new Lua.
> - **Arm A′ — a host-only two-step (`ZREM active` then `enqueue_at`). CHOSEN-AGAINST.** `delay/N` as pure host code: a
>   `command` `ZREM active`, then a call to the shipped `enqueue_at`/`enqueue_in`. *Steelman (kept on record):* adds NO
>   Lua at all (the literal "zero new Lua" the carve wanted). *Why rejected:* **NON-ATOMIC** — there is a host window
>   between the `ZREM active` and the schedule write in which a crash leaves the member in NEITHER set (removed from
>   `active`, not yet in `schedule`) — the member is **lost** (no set holds it, no pump finds it, and the lease is
>   already released so the reaper cannot recover it). It also re-routes through `@schedule`, which **`HSET`s `attempts
>   0`** — wiping the member's attempt history. Rejected on the **atomicity invariant** (INV-Delay-Atomic) and the
>   **attempts-preservation invariant** (INV-Delay-Rescore).
> - **Arm C — fold into the shipped promote/schedule surface. CHOSEN-AGAINST.** Extend `@promote` (or `@schedule`) to
>   also handle an active→scheduled re-score. *Steelman (kept on record):* no new script — one fewer in the lib. *Why
>   rejected:* `@promote` moves due-scheduled → `pending` (the **wrong direction** — it RELEASES scheduled jobs, it does
>   not SCHEDULE active ones; verified `jobs.ex:398-405`), so a fold makes one script do two behaviors; and any fold
>   EDITS a shipped, byte-frozen script → it forfeits the byte-freeze discipline (INV-Frozen) and re-grades the rung
>   NORMAL → HIGH (Apollo mandatory). The clean separation is a new parallel `@delay` (Arm B).
>
> **Steward → RULED Arm B (a new minimal `@delay`), D-1.** It is the atomic minimum, keeps every shipped script
> byte-frozen, is the inverse-of-`@claim` mental model, and grades NORMAL. Arm A′ chosen-against on atomicity +
> attempts-preservation; Arm C on direction + byte-freeze.

### The token sub-fork — the delay fence — RULED: Arm T (token-required `delay/5`), D-2

> **Rationale.** Does `delay/N` require the lease token? A delay re-scores an in-flight member, so the question is
> whether the same fencing that guards `complete/5`/`retry/7`/`extend_lock/5` must guard it.
>
> **The arms:**
> - **Arm T — token-required `delay/5`. ◄ RULED, D-2.** `delay(conn, queue, id, token, ms)`, in-script `if token ~=
>   row.attempts-token then EMQSTALE`. It closes the stale-holder race: worker A stalls → the reaper recovers the
>   member → worker B re-claims it (token 2); a stale A must NOT be able to re-delay B's member. *Steelman:* it is the
>   SAME shape as every other lease-holder transition — `complete/5` (`jobs.ex:589`), `retry/7` (`jobs.ex:759`),
>   `extend_lock/5` (`jobs.ex:1142`) — and the cost is one ARGV token, an argument the caller already holds. The fence
>   is what the whole bus rests on; the delay re-scores an in-flight member, so it carries the same fence. **The fence
>   arg is the attempts-token (`att`)** — the same token the private `defp settle` already threads to
>   `Jobs.complete`/`Jobs.retry` (`batch_consumer.ex:261`/`:265`, each member destructured `{id, _payload, att}`), so
>   the `{:delay, ms}` branch passes `att` identically and the `@delay` in-script fence mirrors `@complete`'s/`@retry`'s.
> - **Arm F — token-free `delay/4`. CHOSEN-AGAINST.** *Steelman (kept on record):* a slimmer signature; a control-plane
>   "push this member out" operator action genuinely wants no token (an operator is not a lease holder). *Why rejected:*
>   for the HANDLER's verb it breaks lease-fence uniformity — any caller could re-delay any active member by id, yanking
>   it from its current owner. A token-free operator "push out" is a SEPARATE control-plane verb to add later (the
>   emq.4.1 `reassign`/`drain` precedent — operator verbs are their own surface); it is not a reason to drop the
>   handler's fence here.
>
> **Steward → RULED Arm T (token-required `delay/5`), D-2.** The handler's verb carries the same fence its siblings do;
> the operator "push out" is a later control-plane verb, not a reason to weaken this one.

### The partition surface — RULED: Arm N (a new pure `EchoMQ.BatchFinish`), D-3

> **Rationale.** Where does the partitioned finish live? The grounding correction (source-confirmed) is load-bearing:
> the emq.5.2 router is the PRIVATE `defp settle(s, members, verdicts)` (`batch_consumer.ex:257-269`) — a process
> method that does IO (it calls `Jobs.complete`/`Jobs.retry` + publishes), NOT a public `settle/3`. That confirms the
> partition must NOT fold into it.
>
> **The arms:**
> - **Arm N — a new pure module `EchoMQ.BatchFinish.partition/N`. ◄ RULED, D-3.** → `%{completed, retried, dead,
>   delayed}` (exhaustive + disjoint over the claimed members; `dead` EMERGES from the `@retry` `{:ok, :dead}` outcome
>   at the attempts cap, `jobs.ex:807`/`:834`, NOT a caller verdict). *Steelman:* it mirrors emq.5.2's DELIBERATE
>   pure-core/process split — `BatchShaper.Core.decide/4` (`batch_shaper/core.ex:76`, doctested) was carved OUT of the
>   `BatchConsumer` process precisely so the central decision stays pure + doctested; Arm N applies that proven split
>   to the RESOLVE half 5.2 applied to the START. A pure module is the cheapest surface to own and test, and it keeps
>   the rung's central logic (the partition) directly doctested rather than buried in a process. The verdict vocabulary
>   `:ok | {:error, reason} | {:delay, ms}` is the emq.5.2 map extended with the one new `{:delay, ms}` variant.
> - **Arm X — extend the private `defp settle` + `BatchShaper.Core` in place. CHOSEN-AGAINST.** *Steelman (kept on
>   record):* no new module; the partition lands where the routing already is. *Why rejected:* `defp settle` is a
>   PRIVATE PROCESS method that does IO (the §grounding correction); folding the pure partition into it RE-BURIES the
>   central logic 5.2 deliberately split apart, and grows a shipped 5.2 surface rather than leaving it byte-stable. The
>   pure classifier stands alone (Arm N); the process (`defp settle`) gains only the `{:delay, ms}` ROUTING branch (the
>   fourth move below), staying a thin router.
>
> **Steward → RULED Arm N (a new pure `EchoMQ.BatchFinish`), D-3.** The pure classifier stands alone; the process router
> stays thin. Arm X chosen-against — `defp settle` is a process IO method, exactly why the pure partition must not fold
> into it.

### The fourth move (not a fork — it follows from D-1/D-2/D-3) — the cadence branch

> The private process router `defp settle` (`batch_consumer.ex:257-269`) gains the `{:delay, ms}` verdict branch beside
> its shipped `:ok`/`{:error, reason}` branches (the THIRD branch), routing a delayed member through the new `delay/5`,
> and publishes a `delayed` per-member event over the byte-frozen `Events.publish/5` (`events.ex:117`). This is not a
> fork — it is the minimal wiring the ruled design implies once D-1/D-2/D-3 are set: the process stays a thin router,
> the partition stays pure (`EchoMQ.BatchFinish`), the delay stays a token-fenced atomic script (`@delay`).

## Definition of Done

- [x] **FORK 5.4-A** surfaced with its four-part Arms + the reconcile correction (the as-built `@schedule` re-probed —
      it CANNOT re-score an active member) + the token sub-fork; the Operator RULED via `AskUserQuestion` — **B · T ·
      N** (D-1 = Arm B a new minimal `@delay`; D-2 = Arm T token-required `delay/5`; D-3 = Arm N a new pure
      `EchoMQ.BatchFinish`); the body re-derived to the ruling (the delay mechanism, atomicity, the token discipline,
      and the partition surface pinned).
- [ ] The **partition** built (D-3 = Arm N): the NEW pure `EchoMQ.BatchFinish.partition/N` (the `BatchShaper.Core`
      sibling) → `%{completed, retried, dead, delayed}`, exhaustive + disjoint over the claimed members, `dead` read
      from the `@retry` outcome (NOT a caller verdict), an absent member fail-safe (INV-Partition).
- [ ] The **dynamic-delay verb** built (D-1 = Arm B, D-2 = Arm T): `Jobs.delay/5` — an `active → scheduled` re-score on
      the server clock, **attempts PRESERVED** (INV-Delay-Rescore), **atomic** in one step (INV-Delay-Atomic),
      **token-fenced** `EMQSTALE` on the attempts-token (INV-Delay-Token), via the NEW atomic `@delay` beside the
      byte-frozen `@schedule`. Every shipped transition script byte-frozen (INV-Frozen).
- [ ] The **cadence branch** built (the fourth move): the `{:delay, ms}` verdict in the private `defp settle`
      (`batch_consumer.ex:257-269`, the third settle branch beside `:ok`/`{:error, reason}`) + the `delayed` per-member
      event on the byte-frozen `Events.publish/5`.
- [ ] The **conformance scenarios** registered (additive minor — the prior **70** byte-unchanged; the count re-pinned
      **70 → 70 + N** in BOTH pinning tests): the partition over a batch, the dynamic-delay re-score
      (attempts-preserved), and the stale-delay `EMQSTALE` refusal. The conformance moduledoc OPENING prose (currently
      lagging at "fifty-five"/"sixty-four", `conformance.ex:3`/`:55`) trued up to the live count when the narrative is
      extended (narration, not a count-law breach — the count-law lives in the two pins).
- [ ] The proof: the `:valkey` partition + delay + stale scenarios green per-app; the **multi-seed determinism sweep**
      green (NO ≥100 loop — no new mint/lease, carve §3; the posture statement names why); the **byte-freeze grep** on
      `@complete`/`@retry`/`@schedule`/`@promote`/`@bclaim`/`@gbclaim` = 0 (INV-Frozen); honest-row reporting (Valkey on
      6390). **Apollo OPTIONAL** (a NORMAL rung — closure + stories; not mandatory, no new process/lease/destructive
      surface).
- [ ] INV-Partition / INV-Delay-Rescore / INV-Delay-Atomic / INV-Delay-Token / INV-ServerClock / INV-DeclaredKeys /
      INV-Frozen / INV-Determinism verified as runnable checks; the family contract ([`../emq.5.md`](../emq.5.md))
      remains the carve authority; this body is synced to the as-built post-build (Stage-5), closing the batches family.

Family: [`../emq.5.md`](../emq.5.md) (the contract, the carve, the forks — the carve authority) · Rung stories +
brief: [`emq.5.4.stories.md`](emq.5.4.stories.md) · [`emq.5.4.llms.md`](emq.5.4.llms.md) · Runbook:
[`emq.5.4.prompt.md`](emq.5.4.prompt.md) · The reuse targets (SHIPPED, **byte-frozen** by this rung):
`echo/apps/echo_mq/lib/echo_mq/jobs.ex` — `@schedule` (`jobs.ex:55-73` — the FIRST-WRITE script the reconcile shows
CANNOT re-score an active member: the `EXISTS` guard `jobs.ex:59` + the `attempts 0` reset `jobs.ex:70`) +
`enqueue_at/6` (`jobs.ex:84`) / `enqueue_in/6` (`jobs.ex:95`) + the private `schedule/7` (`jobs.ex:106`) · `@complete`
(`jobs.ex:257`) + `complete/5` (`jobs.ex:589`) · `@retry` (`jobs.ex:334`, the `{:ok, :dead}` at the cap
`jobs.ex:807-834`) + `retry/7` (`jobs.ex:759`) · `@promote` (`jobs.ex:394` — moves due-scheduled → pending, the WRONG
direction for a re-score) + `promote/2` (`jobs.ex:845`) · `@bclaim` (`jobs.ex:200`) + `claim_batch/4` (`jobs.ex:520`) ·
the cadence it extends (SHIPPED): `echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex` — the PRIVATE `defp settle(s,
members, verdicts)` (`batch_consumer.ex:257-269` — the emq.5.2 verdict-map PROCESS router that does IO: `:ok` →
`Jobs.complete` `:261`, `{:error, reason}` → `Jobs.retry` `:265`, each member destructured `{id, _payload, att}` so the
fence arg is `att`; the `{:delay, ms}` is the new third branch) + `EchoMQ.BatchShaper.Core` (`batch_shaper/core.ex` —
the pure-core/process-split precedent D-3 = Arm N follows) · the per-member event seam (SHIPPED, byte-frozen):
`EchoMQ.Events.publish/5` (`events.ex:117`) · the
conformance harness: `echo/apps/echo_mq/lib/echo_mq/conformance.ex` (`scenarios/0` `conformance.ex:87` + `run/2`
`conformance.ex:179`; the two pins `test/conformance_run_test.exs:56` `{:ok, 70}` + `test/conformance_scenarios_test.exs:33`
`@run_order` + `:107`) · the two version planes: `echo/apps/echo_mq/mix.exs:7` (the rung label `2.5.1` → `2.5.2`) ·
`echo/apps/echo_wire/lib/echo_mq/connector.ex:35` (the wire `@wire_version "echomq:2.4.2"` — FROZEN) · The v2 laws:
S-6 (declared keys — the A-1/L-1 law) · §4 (the server clock — the delay due score) · S-1/§6 (the braced keyspace — no
new key family) · S-3/§5 (the additive-minor conformance law) · Design:
[`../../../../emq.design.md`](../../../../emq.design.md) §6.2 (count-variant pops — the family's reserved mechanism) ·
The sibling precedent (SHIPPED — the verdict-map cadence): [`emq.5.2.md`](emq.5.2.md) · Roadmap:
[`../../../../emq.roadmap.md`](../../../../emq.roadmap.md) (the emq.5 row · Movement II) · Approach:
[`../../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
