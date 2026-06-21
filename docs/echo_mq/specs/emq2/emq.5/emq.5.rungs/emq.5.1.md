# EMQ.5.1 · The batch-claim spine — `@bclaim` + `claim_batch/4` (Movement II, the batches family, the spine)

> **Status: ✅ SHIPPED — all three forks RULED, built + Director-verified PASS, zero remediation.** The
> as-built surface is on disk (`@bclaim` `jobs.ex:200-219` + `claim_batch/4` `jobs.ex:520-539`); this body is
> synced to what shipped (Stage-5, body authoritative). The **FIRST and SPINE** sub-rung of the emq.5 "batches"
> family; the family contract + the carve are [`../emq.5.md`](../emq.5.md). emq.5.1 built the **batch CONSUME**
> spine — a worker fetches up to *N* jobs in one atomic claim instead of one at a time, amortizing the per-job
> round-trip and lease bookkeeping across the batch. Everything else in the family (shaping emq.5.2, affinity
> emq.5.3, the partitioned finish emq.5.4) rides `@bclaim`, so this rung landed first.
>
> **The rulings (the as-built facts):** FORK 5.1-A → **the LOOP** (a `ZPOPMIN` loop ×N, not the native count-pop);
> FORK 5.1-B → **THREE scenarios, conformance +3 → 64** (`batch_claim` · `batch_claim_short` · `batch_partial_failure`);
> FORK 5.1-C → **return the short batch M** (non-blocking; M=0/paused → `:empty`; oversized → depth). The rung
> label stepped to **`2.5.0`** (`mix.exs:7`, opening the batches family); the wire `@wire_version` stays FROZEN at
> `echomq:2.4.2` (the two-planes model — `@bclaim` is an additive NEW script, no wire edit).
>
> **Risk: NORMAL + the ≥100 determinism loop (held).** The increment is **additive over a proven mechanism** — the
> shipped `@gwclaim` (emq.4.4) proved the exact shape: it loops `ZPOPMIN lane` *K* times under ONE server-clock
> `TIME` read, leasing the whole batch on one deadline (`lanes.ex:87-129`). emq.5.1's `@bclaim` is the **non-grouped
> generalization** of that proven loop over the flat `emq:{q}:pending` set. The shipped `@claim` (`jobs.ex:165`) is
> **byte-frozen** (the single-pop path coexists — Director-verified: `jobs.ex` 94 ins/0 del). No destructive at-rest
> op · no frozen-line edit · no new process · no wire break. `@bclaim` is a **mint/lease surface** (it HINCRBYs
> attempts + leases on the server clock), so the **≥100 determinism loop** owned the proof (100/0; the
> same-millisecond branded-`JOB` mint hazard the loop owns).

## 0 · The slice — what emq.5.1 builds, and why the spine

The family ([`../emq.5.md`](../emq.5.md)) is the Movement II **consume** family. The **PRODUCE half already
ships** and is NOT re-built (`EchoMQ.Jobs.enqueue_many/3`, `jobs.ex:124` — bulk enqueue, the `add_bulk` producer
path). emq.5.1 builds the **batch CONSUME** spine: a single atomic claim that leases up to `size` jobs at once.

The mechanism is **reserved, not invented** — design [`../../../../emq.design.md`](../../../../emq.design.md) §6.2
(lines 457–464): *"Multi-key pops (`LMPOP`/`ZMPOP`): not adopted … a client-side pop would BYPASS the script
layer's event and bookkeeping path … Count-variant pops remain the 6.2-level surface the batch family builds on
at its rung."* A batch claim is a **count-variant `ZPOPMIN` INSIDE the claim script** — never a client-side
`LMPOP`/`ZMPOP` (those are rejected by design). The just-shipped `@gwclaim` (emq.4.4) **already proves the exact
shape**: `lanes.ex:113-121` loops `ZPOPMIN lane` *K* times under one `redis.call('TIME')`, leasing every served
job on that one deadline, `HINCRBY <row> attempts 1` per member, returning a nested array of `{id, payload,
attempts, group}` tuples. emq.5.1's `@bclaim` is the **non-grouped** generalization: the loop pops from the flat
`emq:{q}:pending` set, leases each member on one `TIME`-derived deadline, and returns a list of `{id, payload,
attempts}` tuples (no group field — the flat queue carries no lane).

What emq.5.1 stands on (all SHIPPED, present-tense — cited by re-probe, the lag-1 law):

- `EchoMQ.Jobs.claim/3` + `@claim` (`jobs.ex:418` host, `jobs.ex:165` script — the single-pop spine the batch
  generalizes; **byte-frozen** by this rung): one `ZPOPMIN emq:{q}:pending`, `HINCRBY <row> attempts 1`,
  `HSET <row> state active`, the server-clock lease (`TIME` → `ZADD active now+lease id`), returns `{id, payload,
  att}`; the host returns `{:ok, {id, payload, att}}` on a hit, `:empty` on an empty pending set, and honors the
  queue-wide pause flag (`Jobs.paused?/2`, `jobs.ex:439`) host-side FIRST (a paused queue answers `:empty`).
- `@gwclaim` (`lanes.ex:87` — the count-variant multi-pop loop the spine ports): the proven `for _ = 1, k do
  ZPOPMIN … end` under one `TIME`, one batch lease, per-member `HINCRBY attempts`.
- `EchoMQ.Keyspace` (`keyspace.ex` — `queue_key/2` builds `emq:{q}:<type>` for the braced grammar; `job_key/2`
  gates `BrandedId.valid?/1` and raises before any wire).
- `@complete`/`@retry` (`jobs.ex:214`/`jobs.ex:291`, **byte-frozen**) — per-member resolution: the worker
  resolves each batch member through the shipped per-member transitions, so **partial-failure isolation is a
  TESTED property, not new Lua** (one member's failure is one `@retry`; the rest complete via `@complete`).
- `EchoMQ.Conformance` (`conformance.ex` — the additive-minor harness, **61** scenarios live).

## Goal

emq.5.1 builds, inside `echo/apps/echo_mq`, the **batch-claim spine**:

1. **`@bclaim`** — a NEW inline `Script.new(:bclaim, …)` module attribute in `jobs.ex`: a **count-variant
   `ZPOPMIN emq:{q}:pending`** that pops up to `size` heads under ONE server-clock `TIME` read, leasing each
   popped member on that one deadline (`ZADD active now+lease id`), `HINCRBY <row> attempts 1` + `HSET <row>
   state active` per member, and returns a **list of `{id, payload, attempts}` tuples** (the non-grouped
   isomorph of `@gwclaim`'s nested-array return). The loop stops early when the pending set empties (a request
   for `size` N with only M<N pending returns M; an empty pending set returns the empty list). Declared keys
   `[pending, active]` + the queue base root ARGV (the `@claim` key convention, `jobs.ex:422-423`); every
   per-row key derived in-script from the declared base root by the A-1 grammar (`base .. id`, the `@claim`
   `ARGV[1] .. id` form at `jobs.ex:168`).
2. **`Jobs.claim_batch/4`** — the host API: `claim_batch(conn, queue, size, lease_ms)` (arity 4), the faithful
   batch generalization of `claim/3` (arity 3 — the extra arg is `size`). It honors the queue-wide pause flag
   host-side FIRST (the `claim/3` precedent, `jobs.ex:419` — a paused queue answers `:empty` without touching the
   pending set), evals `@bclaim`, and answers **`{:ok, [{id, payload, att}, ...]}`** (the served members, in pop
   order — mint order, since `ZPOPMIN` pops the lowest score and the pending set is score-0 mint-ordered) or
   **`:empty`** (the pending set was empty, or the queue is paused). The manual-pull surface IS `claim_batch/4`
   (a worker calls it directly to pull a batch); the batch-aware Consumer shaping that drives it on a
   `min_size`/`timeout` cadence is emq.5.2, NOT this rung.
3. **Partial-failure isolation** — a *tested property*, not new Lua: a worker resolves each of the `size`
   returned members independently through the shipped, **byte-frozen** `@complete` (`jobs.ex:214`) and `@retry`
   (`jobs.ex:291`); one poisoned member that `@retry`s (or dead-letters) leaves the rest free to `@complete`. No
   batch-scoped resolution script exists — the batch is a *claim* unit, not a *resolution* unit (the partitioned
   finish — a batch resolving as a partition — is emq.5.4, NOT this rung).
4. The **conformance scenario(s)** — additive minor, the prior **61** byte-unchanged → the new total (the count
   delta is FORK 5.1-B; see the forks); the proof (the `:valkey` suite + the **≥100 determinism loop** — a
   mint/lease surface) + the byte-freeze grep on `@claim` (`grep redis.call` on the `@claim` diff = 0).

All under the v2 master invariant: braced `emq:{q}:` keyspace · branded `JOB` ids gated at the key builder ·
every Lua key in `KEYS[]` or derived from a declared `KEYS[n]` / ARGV-base root by the A-1 grammar · the server
clock (`TIME`) on the batch lease · inline `Script.new/2` (never `priv/`) · additive-minor conformance growth.

## Rationale (5W)

- **Why** — a high-throughput worker that pulls one job per round-trip pays the per-job wire latency + the
  per-job lease bookkeeping on every job. A **batch claim** amortizes both across up to `size` jobs in one atomic
  script: one round-trip, one `TIME` read, one lease deadline for the whole batch. The mechanism is the design's
  reserved §6.2 count-variant pop (a `ZPOPMIN` loop inside the claim script — never a client-side multi-key pop,
  which bypasses the bookkeeping path), and the shape is **already proven** by the shipped `@gwclaim` (emq.4.4).
  It is the **spine** because the rest of the family (shaping, affinity, the partitioned finish) builds on
  `@bclaim`.
- **What** — emq.5.1 builds: (1) `@bclaim` — the new inline count-variant `ZPOPMIN emq:{q}:pending` loop (up to
  `size` heads, one `TIME`, one batch lease, per-member attempts, a list-of-tuples return — the non-grouped
  `@gwclaim` isomorph); (2) `claim_batch/4` — the host API (arity 4, the `claim/3` generalization, the manual-pull
  surface, the queue-wide pause honored FIRST); (3) partial-failure isolation as a TESTED property over the
  byte-frozen `@complete`/`@retry`; (4) the conformance scenario(s) (additive minor — the prior 61 byte-unchanged →
  the new total, the count delta ruled at FORK 5.1-B); (5) the `:valkey` proof + the **≥100 determinism loop**
  (a mint/lease surface) + the byte-freeze grep on `@claim` (= 0).
- **Who** — the program (the rung that founds the batch-consume family); high-throughput **bulk-drain
  consumers** (codemojex's high-volume settle path is the named consumer the family carries to scale); the
  conformance harness, which grows by the batch-claim scenario(s). The shipped `@claim` single-pop is the
  precedent the new `@bclaim` generalizes (byte-frozen — the single-pop and batch paths coexist). **Apollo** is an
  optional fast-finisher (this rung edits no shipped script — `@bclaim` is additive); the ≥100 loop is the
  Director's verify, not an Apollo mandate.
- **When** — Movement II, the batches family's **first and spine** sub-rung, **first** (everything below builds
  on it). The forks (FORK 5.1-A the count mechanism; FORK 5.1-B the conformance decomposition; FORK 5.1-C the
  empty/under-fill semantics — see the forks) are RULED by the Operator at the pre-build reconcile (the Director
  routes via `AskUserQuestion`) BEFORE Mars builds.
- **Where** — `echo/apps/echo_mq` only: `jobs.ex` (the new `@bclaim` script + `claim_batch/4` host verb;
  `@claim`/`claim/3` and every other shipped script **byte-frozen** — the batch path is additive), `conformance.ex`
  (the three batch-claim scenarios + the count re-pin), the `:valkey` proof (a new or extended test), the two pinning
  tests (`conformance_run_test.exs` `{:ok, 64}` + `conformance_scenarios_test.exs` `@run_order` — the count
  re-pinned 61 → 64), `mix.exs` (the rung label **`2.5.0`**, RULED — opening the batches family). `echo_wire` is
  **untouched** (the batch claim rides the shipped connector `eval`;
  `@wire_version` stays `echomq:2.4.2`). `apps/echomq` is **untouched** (the capability reference). The §6
  grammar in `keyspace.ex` is **unedited** (no new key family — `@bclaim` rides the shipped
  `emq:{q}:pending`/`active` sets).

## Scope

- **In** — the batch-claim spine: (1) `@bclaim` (the count-variant `ZPOPMIN emq:{q}:pending` loop — up to `size`
  heads, one `TIME`, one batch lease, per-member `HINCRBY attempts` + `HSET state active`, a list-of-tuples
  return); (2) `claim_batch/4` (the host API — the manual-pull surface, the `claim/3` generalization, the
  queue-wide pause honored FIRST, `{:ok, [members]}` | `:empty`); (3) partial-failure isolation as a TESTED
  property over the byte-frozen `@complete`/`@retry`; (4) the conformance scenario(s) (additive minor — the prior
  61 byte-unchanged → the new total); (5) the `:valkey` suite + the **≥100 determinism loop** (a mint/lease
  surface) + the byte-freeze grep on `@claim` (= 0).
- **Out** — the **`min_size`/`timeout` shaping** (a batch-aware Consumer that waits for ≥ `min_size` OR until
  `timeout` — emq.5.2; the manual-pull `claim_batch/4` is the spine, the cadence is the next rung); **group
  affinity + batch concurrency** (`@gbclaim`, a homogeneous lane-scoped batch — emq.5.3; this rung is the flat,
  non-grouped claim only); the **partitioned finish** (a batch resolving as a partition — complete /
  retry-poison-alone / dead — emq.5.4; this rung resolves members individually through the shipped transitions,
  the partition shape is the next rung); any **edit to the shipped `@claim` or any other shipped script** (every
  shipped script byte-frozen — `@bclaim` is a NEW additive script, INV2); any **client-side `LMPOP`/`ZMPOP`** (the
  design §6.2 rejection — the pop is `ZPOPMIN` INSIDE the script, INV3); any **new key family** (the batch claim
  rides the shipped `emq:{q}:pending`/`active` sets — INV3); any **`echo_wire`/transport** change; any **edit to
  the frozen v1 line** (`apps/echomq`).

## Invariants (the runnable checks emq.5.1 carries)

- **EMQ.5.1-INV1 — the count-variant pop is INSIDE the script (the §6.2 law), never a client-side multi-key
  pop.** `@bclaim` pops with a `ZPOPMIN emq:{q}:pending` loop INSIDE the inline `Script.new/2` — never a
  client-side `LMPOP`/`ZMPOP` (the design §6.2 rejection: a client pop bypasses the script layer's bookkeeping
  path). The loop is the proven `@gwclaim` shape (`lanes.ex:113-121`): `for _ = 1, k do ZPOPMIN pending; HINCRBY
  attempts; HSET state active; ZADD active <lease> id end`. *Check:* a grep of `@bclaim` for `LMPOP`/`ZMPOP`
  returns empty; the pop is `ZPOPMIN` inside the inline script; `claim_batch/4` evals the script, never issues a
  client-side multi-key pop.
- **EMQ.5.1-INV2 — the byte-freeze discipline (`@claim` and every shipped script byte-unchanged).** `@bclaim` is
  a NEW additive script; emq.5.1 edits **no** shipped script. `@claim` (`jobs.ex:165`) — and every other shipped
  script (`@enqueue`/`@schedule`/`@complete`/`@retry`/`@promote`/`@reap`/`@update_data`/`@update_progress`/
  `@add_log`/`@remove_job`/`@reprocess`/`@extend_lock`/`@extend_locks`, and every `@g*` in `lanes.ex`) — is
  **byte-identical to HEAD**. *Check:* `grep redis.call` on the lib diff, restricted to every shipped script body,
  returns 0; the prior conformance scenarios (`claim`, `complete`, `retry`, `dead`, `reap`, …) pass
  byte-unchanged; the prior **61** byte-unchanged.
- **EMQ.5.1-INV3 — the wire law (real braced `KEYS[]` pin the slot, no new key family).** The declared keys
  `KEYS[1]=pending` / `KEYS[2]=active` are **real braced `KEYS[]`** that PIN the `{q}` slot (A-1/S-6); the per-row
  key `jk = ARGV[1] .. id` (`ARGV[1] = emq:{q}:job:`, the EXACT `@claim` ARGV-base row-key form, `jobs.ex:200-219`
  the as-built `@bclaim`, the `@claim` form at `jobs.ex:165`) is **slot-sound because the row shares the `{q}`
  hashtag `KEYS[1]`/`KEYS[2]` pin — NOT because an ARGV base is itself a declared root** (an ARGV-passed base is
  expressly NOT a declared root under the declared-keys / F-1 rule; what makes the script slot-sound is the real
  braced `KEYS[]` pinning the slot the ARGV-derived row shares — the as-built code comment, `jobs.ex:192-196`,
  states this exactly). **No new key family** — the batch claim rides the shipped `emq:{q}:pending`/`active` sets;
  the §6 grammar in `keyspace.ex` is unedited. *Check:* `pending`/`active` are passed as `KEYS[]` (not ARGV); a
  reviewer names the braced `KEYS[]` that pin every key's slot; a grep of `@bclaim` for a key outside
  `emq:{q}:pending`/`active`/`job:<id>` returns empty; the §6 grammar is unedited; `{emq}:version` reads
  `echomq:2.4.2`.
- **EMQ.5.1-INV4 — server clock where the lease is touched.** `@bclaim` reads `TIME` **server-side** inside the
  script ONCE per call (`jobs.ex:205-206`) and leases EVERY job it pops on that one deadline (`ZADD active
  now+lease id` per member, `jobs.ex:215` — the shipped `@gwclaim` one-lease-per-turn pattern, `lanes.ex:110-119`,
  and the `@claim` `TIME` pattern, `jobs.ex:172-174`); no host timestamp crosses the lease. *Check:* a grep of
  `@bclaim` for a host-supplied lease timestamp returns empty; the lease is computed from `redis.call('TIME')`
  once; the `batch_claim` scenario asserts every served member carries a `TIME`-derived `active` score (the same
  lease deadline for the whole batch).
- **EMQ.5.1-INV5 — branded `JOB` identity + the order theorem (byte = mint).** The members `@bclaim` returns are
  branded `JOB` ids popped from the score-0 mint-ordered `pending` set by `ZPOPMIN` (lowest score first), so the
  batch is served in **mint order** (byte order IS mint order — the order theorem; the pending set carries no
  second index). The id is the wire form throughout (no host re-mint in the claim path — `@bclaim` pops existing
  members, it does not mint). *Check:* a batch claimed from a pending set of distinct-mint JOB-ids returns them in
  mint order (the lexically-least first, matching a single-pop sequence of `claim/3`); the returned ids are
  branded `JOB` ids; no `BrandedId.generate!` is called inside the claim path.
- **EMQ.5.1-INV6 — attempts as the fencing token (per member).** Each member `@bclaim` returns carries its OWN
  freshly-incremented attempts token (`HINCRBY <row> attempts 1` per member, the `@gwclaim` per-member pattern,
  `lanes.ex:117`), so the batch is `size` independently-fenced leases, not one shared token. A member completed or
  retried with a stale token is refused `EMQSTALE` by the shipped, byte-frozen `@complete`/`@retry`. *Check:* a
  batch of N members returns N tuples each with its own `att` (a member claimed for the first time carries `1`; a
  member that was reaped + re-batched carries `2`); a `@complete` of one member with the wrong token answers
  `{:error, :stale}` (the shipped fencing); the other members complete with their own live tokens.
- **EMQ.5.1-INV7 — partial-failure isolation (a TESTED property over byte-frozen transitions).** One member of a
  claimed batch that fails (resolved through `@retry` — scheduled or dead) does NOT affect the other members
  (resolved through `@complete`); there is no batch-scoped resolution script (the batch is a *claim* unit, not a
  *resolution* unit). *Check:* a batch of N is claimed, member k is `@retry`'d (scheduled) and the rest are
  `@complete`'d → member k's row is `scheduled` with `last_error` kept, the rest are retired, and re-claiming
  finds only member k (after promote); the property is asserted with the shipped `@complete`/`@retry` byte-frozen
  (no new Lua).
- **EMQ.5.1-INV8 — the additive-minor conformance law.** The **three** batch-claim scenarios — `batch_claim`
  (the full claim) · `batch_claim_short` (under-fill / oversized-clamp / empty / paused) · `batch_partial_failure`
  (the isolation property) — are registered in `scenarios/0` **with their probes in the same change** (FORK 5.1-B
  RULED THREE); the prior **61** scenarios pass **byte-unchanged** (name + contract + verdict-body identical,
  git-verified); the count re-pins **61 → 64** in **both** pinning tests (`conformance_run_test.exs` `{:ok, 64}` +
  `conformance_scenarios_test.exs` `@run_order`). *Check:* the git-diff of `scenarios/0` shows only the three
  additions; both count assertions updated to `64`; `Conformance.run/2` prints 64 lines and returns `{:ok, 64}`.

## Closed error set (the typed refusals `claim_batch/4` may surface — grounded, no new codes)

`claim_batch/4` introduces **NO new `EMQ*` wire class** — it reuses the closed registry the shipped claim path
already uses. The full surface (each grounded against the as-built `@claim`/`claim/3` path):

- **`:empty`** — the pending set was empty (the `@bclaim` loop popped zero members → returns the empty list,
  mapped host-side to `:empty`), OR the queue is paused (the `Jobs.paused?/2` host-side gate answers `:empty`
  FIRST, the pending set untouched — the `claim/3` precedent, `jobs.ex:419`). This is `claim/3`'s `:empty`,
  generalized: a batch of zero is `:empty`, exactly as a single empty pop is.
- **An ill-formed queue name** — `Keyspace.queue_key/2` builds the braced key; an ill-formed queue raises at the
  key builder before any wire (the shipped keyspace gate — wellformedness only). `claim_batch/4` adds no new
  refusal here; it inherits the keyspace gate.
- **No `EMQKIND`/`EMQSTALE` from the claim itself** — the claim path does not check kind (kind is the *enqueue*
  script's first act, `@enqueue`/`@genqueue`) and does not fence a token (the token is MINTED by the claim,
  `HINCRBY attempts 1`); `EMQSTALE` surfaces only at the per-member `@complete`/`@retry` resolution (the shipped,
  byte-frozen fencing — out of this rung's claim path, in the worker's resolution path). `claim_batch/4` raises
  no `EMQSTALE`.

There is **no new typed refusal** for an over-large `size` request (a request for `size` N when only M<N are
pending returns M members, not a refusal — the under-fill is a normal result, FORK 5.1-C; an empty pending set is
`:empty`, the zero case of the same rule). `size` is validated host-side as a positive integer (the `claim/3`
`lease_ms > 0` guard precedent, `jobs.ex:418`) — a non-positive `size` is a `FunctionClauseError` at the guard
(a programming error, not a wire refusal), matching the shipped `claim/3` guard discipline.

## The rung's forks — RULED (the Operator's pre-build decisions; SHIPPED, Director-verified PASS)

> All three forks are settled — the rulings below SUPERSEDE the "lean" framing the pre-build draft carried, and
> are the as-built facts. Each is cited to the shipped code.

### FORK 5.1-A — the count mechanism — RULED: the LOOP

> **RULED: a `ZPOPMIN` loop ×N** (over the native `ZPOPMIN key count`). As built (`jobs.ex:200-219`): `@bclaim`
> reads `ZCARD KEYS[1]` and clamps `k = min(size, depth)` (`jobs.ex:201-204`, the `@gwclaim` clamp without the
> group headroom — the flat queue has no lane ceiling), reads ONE `redis.call('TIME')` (`jobs.ex:205-206`), then
> loops the `@claim` per-member transitions: `ZPOPMIN KEYS[1]` (break on empty), `HINCRBY <row> attempts 1`,
> `HSET <row> state active`, `ZADD active now+lease id` on the one shared deadline, collect `{id, payload, att}`
> (`jobs.ex:208-217`). **Why the loop:** symmetry with the shipped `@gwclaim`/`@gclaim` per-member fencing — each
> member needs its OWN `HINCRBY attempts` + `HSET state active` + `ZADD active` regardless, so the native count-pop
> would save only the pop syscall, not the per-member work. Both arms were INSIDE the script (INV1 held either
> way — neither is a client-side multi-key pop).

### FORK 5.1-B — the conformance scenario decomposition — RULED: THREE scenarios (+3 → 64)

> **RULED: THREE scenarios, conformance +3 → 64** (the Operator chose the granular decomposition over the
> two-scenario draft lean). As built (`conformance.ex`): `batch_claim` (the full claim — N members in mint order,
> each at attempts 1, on the one shared `TIME`-lease) · `batch_claim_short` (the under-fill / oversized-clamp /
> empty / paused cases — a request for N with M<N pending returns M, N>depth clamps to depth, M=0 and a paused
> queue answer `:empty`) · `batch_partial_failure` (the isolation property — one member retried, the rest
> completed, over the byte-frozen `@complete`/`@retry`). The prior **61** scenarios are byte-unchanged; both
> pinning tests pin **64** (`conformance_run_test.exs:50` `{:ok, 64}` + `conformance_scenarios_test.exs`
> `@run_order`).

### FORK 5.1-C — the empty / under-fill semantics — RULED: return the short batch M (non-blocking)

> **RULED: return the short batch M** (over BLOCK/wait-for-N). As built (`claim_batch/4`, `jobs.ex:520-539`): a
> request for `size` N with M<N pending returns `{:ok, [M members]}` (the `@bclaim` `k = min(size, depth)` clamp,
> `jobs.ex:203-204` — never over-popping); an oversized request (N > depth) clamps to depth; M=0 returns `:empty`
> (`{:ok, []}` → `:empty`, `jobs.ex:534`); a paused queue returns `:empty` with the pending set UNTOUCHED (the
> host-side `paused?/2` gate FIRST, `jobs.ex:522-523` — the `claim/3` precedent). **Why non-blocking:** the spine
> is a manual-pull (the `claim/3` precedent: `:empty` immediately, never blocks); the `min_size`/`timeout`
> blocking/shaping cadence is `EchoMQ.Consumer`'s job at emq.5.2, never folded into the spine (which would couple
> 5.1↔5.2 and put a wait loop in the claim path).

> **No new key family any fork** (every fork rode the shipped `emq:{q}:pending`/`active` sets — INV3); no fork
> edited a shipped script (the ruled `@bclaim` is the NEW additive script — INV2 held, `@claim` byte-frozen).

## Definition of Done

- [x] **FORK 5.1-A** (the count mechanism), **FORK 5.1-B** (the conformance decomposition + the count delta), and
      **FORK 5.1-C** (the empty/under-fill semantics) surfaced with all arms + the trade-off; the Operator ruled
      each — **5.1-A → the LOOP** (`jobs.ex:200-219`), **5.1-B → THREE scenarios, +3 → 64**, **5.1-C → return the
      short batch M** (`jobs.ex:520-539`); the body re-derived to the rulings (the `@bclaim` loop, the three
      scenarios + the count 64, the short-batch under-fill pinned).
- [x] **`@bclaim`** built (`jobs.ex:200-219`) — the NEW inline `Script.new(:bclaim, …)`: the count-variant
      `ZPOPMIN emq:{q}:pending` loop (`k = min(size, depth)`, one `TIME`, one batch lease, per-member `HINCRBY
      attempts` + `HSET state active`, a list-of-tuples return — the non-grouped `@gwclaim` isomorph), the braced
      `KEYS[]` pinning the slot, the server clock on the batch lease.
- [x] **`claim_batch/4`** built (`jobs.ex:520-539`) — the host API (arity 4, the `claim/3` generalization, the
      manual-pull surface, the queue-wide pause honored host-side FIRST, `{:ok, [{id, payload, att}, ...]}` |
      `:empty`); `@claim`/`claim/3` byte-unchanged (every shipped script byte-frozen too — Director-verified:
      `jobs.ex` 94 ins/0 del, `@claim` byte-frozen).
- [x] **Partial-failure isolation** proven as a TESTED property over the byte-frozen `@complete`/`@retry` (no new
      resolution Lua — the batch is a claim unit, not a resolution unit; the `batch_partial_failure` scenario).
- [x] The **three batch-claim conformance scenarios** registered (additive minor — the prior **61**
      byte-unchanged; the count re-pinned **61 → 64** in both pinning tests, FORK-5.1-B RULED THREE). A present
      precondition (a flooded pending set) runs the claim with a positive proof (asserts the served members); a
      vacuous pass is a LOUD failure.
- [x] The proof: the `:valkey` batch suite green per-app (422/0); the **≥100 determinism loop** green (100/0 — a
      mint/lease surface, FOREGROUND, owning the machine); the byte-freeze grep on `@claim` (and every shipped
      script) = 0; a net-zero `ZPOPMIN→ZPOPMAX` mutation caught 6 ways; honest-row reporting (Valkey on 6390).
- [x] INV1–INV8 verified as runnable checks; the family contract ([`../emq.5.md`](../emq.5.md)) remains the carve
      authority; this body is authoritative (synced to the as-built post-build, Stage-5). **Apollo** was an
      optional fast-finisher (this rung edits no shipped script — `@bclaim` is additive).

Family: [`../emq.5.md`](../emq.5.md) (the contract, the carve, the forks — the carve authority) · Rung stories +
brief: [`emq.5.1.stories.md`](emq.5.1.stories.md) · [`emq.5.1.llms.md`](emq.5.1.llms.md) · Runbook:
[`emq.5.1.prompt.md`](emq.5.1.prompt.md) · The proven shape it generalizes (SHIPPED, the form to PORT):
`echo/apps/echo_mq/lib/echo_mq/lanes.ex` — `@gwclaim` (`lanes.ex:87` — the count-variant multi-pop loop: one
`TIME`, K heads served on one lease, per-member `HINCRBY attempts`, a nested-array return) · The single-pop spine
it generalizes (SHIPPED, **byte-frozen** by this rung): `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — `@claim`
(`jobs.ex:165`) + `claim/3` (`jobs.ex:418` → `{:ok, {id, payload, att}}` | `:empty`, the queue-wide pause honored
FIRST) + the byte-frozen `@complete` (`jobs.ex:214`) / `@retry` (`jobs.ex:291`) the partial-failure isolation
rides · The mechanism reservation: [`../../../../emq.design.md`](../../../../emq.design.md) §6.2 (lines 457–464 —
count-variant pops are the batch family's 6.2-level surface; client-side `LMPOP`/`ZMPOP` FORBIDDEN) · The v2 laws:
§6 (the braced keyspace) · S-6 (the declared-keys A-1 law) · §4 (the server-clock law — the lease) · S-3/§5 (the
additive-minor conformance law) · Roadmap: [`../../../../emq.roadmap.md`](../../../../emq.roadmap.md) (the emq.5 row ·
Movement II) · Approach: [`../../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
