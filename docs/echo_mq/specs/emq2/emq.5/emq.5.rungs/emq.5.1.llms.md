# EMQ.5.1 — the Mars brief (the batch-claim spine — `@bclaim` + `claim_batch/4`)

> The compact build brief. The body [`emq.5.1.md`](emq.5.1.md) is authoritative; the acceptance is
> [`emq.5.1.stories.md`](emq.5.1.stories.md); the run scope is [`emq.5.1.prompt.md`](emq.5.1.prompt.md). Build
> ONLY inside `echo/apps/echo_mq` (the batch claim rides the shipped `echo_wire` connector `eval` — no `echo_wire`
> edit). Cite the spec line for every public call; inline `Script.new/2` (NEVER `priv/`); declared keys A-1; the
> server clock on the batch lease; the conformance additive-minor mechanics.
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software (components read, compute, refuse, return); no first-person
> narration. Bind this same clause in any sub-brief.

## References (read first — the exact upstream, links/paths first)

1. **The body** — [`emq.5.1.md`](emq.5.1.md): Goal · Scope · INV1–8 · the closed error set · the forks (5.1-A/B/C)
   · DoD. **The forks are RULED by the Operator BEFORE you build** (the Director routes via `AskUserQuestion`);
   build to the ruled arms.
2. **The proven shape to PORT (SHIPPED)** — `echo/apps/echo_mq/lib/echo_mq/lanes.ex` `@gwclaim` (`lanes.ex:87-129`):
   the count-variant multi-pop loop. The load-bearing lines: the `ZCARD lane` depth clamp (`lanes.ex:91-99` — `k =
   min(request, depth, …)`, never over-pops), the ONE `redis.call('TIME')` (`lanes.ex:110-111`), the
   `for _ = 1, k do ZPOPMIN … HINCRBY attempts … HSET state active … ZADD active now+lease id end` (`lanes.ex:113-121`),
   the nested-array return (`lanes.ex:120,128`). `@bclaim` is the NON-GROUPED isomorph (pop from flat `pending`, no
   `g:`-segment, no `gactive`, no ring; return `{id, payload, att}` without the group field).
3. **The single-pop spine to GENERALIZE + BYTE-FREEZE (SHIPPED)** — `echo/apps/echo_mq/lib/echo_mq/jobs.ex`:
   - `@claim` (`jobs.ex:165-176`) — `ZPOPMIN KEYS[1]`; `if #popped == 0 then return {} end`; `jk = ARGV[1] .. id`
     (the A-1 ARGV-base row-key root); `HINCRBY jk attempts 1`; `HSET jk state active`; `TIME` → `ZADD KEYS[2]
     now+ARGV[2] id`; `return {id, HGET jk payload, att}`. **BYTE-FREEZE this** — `@bclaim` is additive.
   - `claim/3` (`jobs.ex:418-431`) — `claim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0`;
     `if paused?(conn, queue) -> :empty`; keys `[queue_key(q,"pending"), queue_key(q,"active")]`; argv
     `[queue_key(q,"job:"), Integer.to_string(lease_ms)]`; returns `{:ok, {id, payload, att}}` | `:empty`. **This
     is the arity + return + pause-first shape `claim_batch/4` generalizes** (arity 4, the extra arg `size`,
     returns a LIST).
   - `paused?/2` (`jobs.ex:439`) — the queue-wide pause gate `claim_batch/4` calls FIRST.
   - `@complete` (`jobs.ex:214`) + `@retry` (`jobs.ex:291`) — **BYTE-FROZEN**; the per-member resolution the
     partial-failure isolation rides (no new resolution Lua).
4. **The keyspace** — `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`: `queue_key/2` builds `emq:{q}:<type>` (the
   braced grammar); `job_key/2` gates `BrandedId.valid?/1` and raises pre-wire. **No grammar edit** — `@bclaim`
   rides the shipped `pending`/`active` sets + the `job:<id>` row.
5. **The conformance harness** — `echo/apps/echo_mq/lib/echo_mq/conformance.ex` (`scenarios/0` + `run/2`) + the two
   pins `test/conformance_run_test.exs` (`{:ok, 61}` at `:48`) + `test/conformance_scenarios_test.exs`
   (`@run_order`, 61 names). The additive-minor law: extend `scenarios/0` with the new scenario(s) + the probe in
   the SAME change, the prior 61 byte-unchanged, re-pin the count in BOTH tests.
6. **The mechanism reservation** — [`../../../emq.design.md`](../../../emq.design.md) §6.2 (lines 457–464):
   client-side `LMPOP`/`ZMPOP` FORBIDDEN (bypass the script layer); the batch claim is a count-variant `ZPOPMIN`
   INSIDE the script.
7. **The program law** — `.claude/skills/echo-mq-program.md` (the v2 laws, the gate ladder, the additive-minor
   law) + the as-built map `.claude/skills/echo-mq-surface.md`. **Re-probe the as-built tree at Stage-0** (the
   lag-1 law — line numbers are hints, grep/Read to confirm).

## Requirements (numbered — each traces to a story + an invariant)

- **R1 — `@bclaim` (the count-variant pop loop).** A NEW inline `@bclaim = Script.new(:bclaim, …)` in `jobs.ex`:
  pop up to `size` heads from `ZPOPMIN KEYS[1]` (= `pending`) under ONE `redis.call('TIME')`; per member `HINCRBY
  jk attempts 1` + `HSET jk state active` + `ZADD KEYS[2] now+lease id` (= `active`); the row key `jk = ARGV[1] ..
  id` (the `@claim` A-1 ARGV-base root); stop the loop when the pop is empty (under-fill returns the short list);
  return the list of `{id, HGET jk payload, att}`. Declared keys `[pending, active]` + ARGV `[queue_base, lease_ms,
  size]`. **FORK 5.1-A RULED: the LOOP** (a `ZPOPMIN` loop ×N, over the native count-pop — `ZCARD` clamp `k =
  min(size, depth)` then the per-member loop; as built `jobs.ex:200-219`). The braced `KEYS[1]`/`KEYS[2]` PIN the
  `{q}` slot; the ARGV-rooted row key shares that pinned slot (it is NOT a declared root — INV3). → US1; INV1,
  INV3, INV4, INV5, INV6.
- **R2 — `claim_batch/4` (the host API).** `claim_batch(conn, queue, size, lease_ms) when is_integer(size) and
  size > 0 and is_integer(lease_ms) and lease_ms > 0`: `if paused?(conn, queue) -> :empty` (FIRST — the `claim/3`
  precedent); else `eval(conn, @bclaim, [queue_key(q,"pending"), queue_key(q,"active")], [queue_key(q,"job:"),
  Integer.to_string(lease_ms), Integer.to_string(size)])`; map `{:ok, []}` → `:empty`, `{:ok, members}` → `{:ok,
  Enum.map(members, &List.to_tuple/1)}` (the `wclaim/3` mapping precedent, `lanes.ex:290`). → US1, US2; INV3,
  INV4, INV5.
- **R3 — the under-fill semantics (FORK 5.1-C RULED: the short batch M, non-blocking).** A request for `size` N
  with M<N pending returns `{:ok, [M members]}` (the `@bclaim` `k = min(size, depth)` clamp, `jobs.ex:203-204` —
  the loop stops when `pending` empties); an oversized request (N>depth) clamps to depth; M=0 returns `:empty`; a
  paused queue returns `:empty` pending-untouched. The spine is non-blocking; the `min_size`/`timeout` cadence is
  emq.5.2's. → US2; INV3, INV5.
- **R4 — partial-failure isolation (a TESTED property, NO new Lua).** Prove a claimed batch resolves member-by-
  member through the byte-frozen `@complete`/`@retry`: claim N, `Jobs.retry/7` member k (scheduled), `Jobs.complete/4`
  the rest → k is `scheduled` (last_error kept), the rest retired, a fresh claim (post-promote) finds only k at
  attempts 2; a stale-token resolution is `EMQSTALE`. → US3; INV7, INV6, INV2.
- **R5 — the byte-freeze + wire law.** `@bclaim` is the ONLY new `redis.call`-bearing script; `@claim` + every
  shipped script (`jobs.ex` + every `@g*` in `lanes.ex`) byte-identical to HEAD (`grep redis.call` on each = 0);
  the §6 grammar unedited; `{emq}:version` = `echomq:2.4.2`. → US4; INV2, INV3.
- **R6 — the three conformance scenarios (additive minor — FORK 5.1-B RULED THREE).** Register `batch_claim`
  (full) + `batch_claim_short` (under-fill/oversized/empty/paused) + `batch_partial_failure` (isolation) in
  `scenarios/0` with probes in the SAME change; the prior **61** byte-unchanged; re-pin **61 → 64** in BOTH pins.
  Write/extend the `:valkey` proof to US1 (a POSITIVE proof — `size` members served from a flooded set) + US2 (the
  under-fill/clamp/empty/paused) + US3 (the isolation). → US5, US1, US2, US3; INV8.
- **R7 — the proof + determinism posture.** Per-app gate ladder inside `echo/apps/echo_mq` (TMPDIR=/tmp, `--include
  valkey`); `Conformance.run/2 → {:ok, 64}`; the **≥100 determinism loop** (a mint/lease surface — FOREGROUND,
  owning the machine); honest-row (Valkey 6390). → US6; S-4, INV4, INV5.

## Execution topology

**Runtime shape.** `claim_batch/4` is a host fn over the shipped connector `eval` — no new process, no new
supervised child, no `echo_wire` edit. The batch is a CLAIM unit (one atomic `@bclaim` eval leases up to `size`
members on one deadline); the worker resolves each member individually through the shipped per-member transitions
(the batch is NOT a resolution unit — the partitioned finish is emq.5.4). The pending set is the shipped
score-0 mint-ordered `emq:{q}:pending` ZSET; `@bclaim` pops the lowest scores (mint order), so the batch is served
oldest-first (the order theorem). One server-clock `TIME` per call → one shared lease deadline for the batch.

**The build-order task DAG.**
```
R1 @bclaim (the new script)  ──►  R2 claim_batch/4 (the host API)
   │                                  ├─► R3 under-fill semantics (the short batch / pause-first)
   │                                  └─► R4 partial-failure isolation (over byte-frozen @complete/@retry)
   ├─► R5 byte-freeze + wire-law grep (every shipped script = 0; §6 unedited)
   └─► R6 THREE conformance scenarios + the 61→64 re-pin  ──►  R7 proof (:valkey + the ≥100 loop)
```

**The EXACT files touched** (the Stage-6 commit pathspec — Director-only; adjust to the ruled touch-set):
```
echo/apps/echo_mq/lib/echo_mq/jobs.ex            (the NEW @bclaim script + claim_batch/4; @claim + every shipped script BYTE-FROZEN)
echo/apps/echo_mq/lib/echo_mq/conformance.ex     (the three batch-claim scenarios + the count prose)
echo/apps/echo_mq/test/<batch_or_jobs>_test.exs  (the :valkey batch proof — NEW or EDIT; US1 + US2 + US3)
echo/apps/echo_mq/test/conformance_run_test.exs       (re-pin {:ok, 64})
echo/apps/echo_mq/test/conformance_scenarios_test.exs (re-pin @run_order → 64 names)
echo/apps/echo_mq/mix.exs                        (the rung label — 2.5.0, RULED)
docs/echo_mq/specs/emq2/emq.5/emq.5.rungs/emq.5.1.{md,stories.md,llms.md,prompt.md}  (Stage-5 sync)
docs/echo_mq/specs/progress/emq-5-1.progress.md  (+ the registry)
```
**EXCLUDED:** `keyspace.ex` (no grammar edit), `lanes.ex` (every `@g*` byte-frozen — `@bclaim` is in `jobs.ex`,
NOT a lane script), `stalled.ex`/`admin.ex` (byte-unchanged), `echo_wire/*` (untouched — `@wire_version` frozen),
`apps/echomq` (the capability reference), `mix.lock` (no real dep moved), any `AM`-status out-of-band file.

## Agent stories (Directive + Acceptance gate — each a contract at the boundary)

- **AS1 — build `@bclaim`.** *Directive:* author the NEW inline `@bclaim` count-variant pop loop (FORK 5.1-A
  RULED: the LOOP) in `jobs.ex`, the non-grouped `@gwclaim` isomorph over flat `pending`.
  *Acceptance gate (contract):* **precondition** — a flooded `emq:{q}:pending` of K mint-ordered JOB-ids;
  **postcondition** — one eval pops up to `size` lowest-score members, each `state=active` + scored in `active` on
  ONE `TIME`-derived deadline, each with `attempts` incremented by 1; **invariant** — the pop is `ZPOPMIN`
  INSIDE the script (no `LMPOP`/`ZMPOP`), every key on the one `{q}` slot, no host timestamp in the lease (INV1,
  INV3, INV4, INV6).
- **AS2 — build `claim_batch/4`.** *Directive:* the host API (arity 4, the `claim/3` generalization, pause-first,
  `{:ok, [members]}` | `:empty`). *Acceptance gate:* **precondition** — `size > 0`, `lease_ms > 0` (the guard);
  **postcondition** — `{:ok, members}` (mint-ordered tuples) on a hit, `:empty` on an empty/paused queue;
  **invariant** — `paused?/2` is consulted FIRST and a paused queue leaves `pending` untouched (the `claim/3`
  precedent — US2's pause leg).
- **AS3 — prove partial-failure isolation.** *Directive:* a `:valkey` proof that a claimed batch resolves
  member-by-member over the byte-frozen `@complete`/`@retry`. *Acceptance gate:* **precondition** — a batch of N
  with one designated poison member; **postcondition** — member k `scheduled` (last_error kept), the rest retired,
  a fresh post-promote claim finds only k at attempts 2; **invariant** — no batch-scoped resolution script exists
  (`@complete`/`@retry` byte-frozen — INV7, INV2). The proof MUST actually fail a member (no vacuous pass).
- **AS4 — the byte-freeze + conformance.** *Directive:* register the THREE batch-claim scenarios (FORK 5.1-B
  RULED THREE — `batch_claim` + `batch_claim_short` + `batch_partial_failure`) additive-minor; re-pin 61 → 64 in
  both pins; run the byte-freeze grep. *Acceptance gate:* **postcondition** — `Conformance.run/2 → {:ok, 64}`, both
  pins pass, `grep redis.call` on every shipped script = 0; **invariant** — the prior 61 scenarios byte-unchanged
  (git-verified), each new scenario's probe registered in the same change (INV8, INV2). A scenario that claims a
  batch and asserts nothing about the served members fails its own letter.
- **AS5 — the proof + the ≥100 loop.** *Directive:* run the full per-app gate ladder + the ≥100 determinism loop
  (a mint/lease surface) inside `echo/apps/echo_mq`. *Acceptance gate:* **postcondition** — `compile
  --warnings-as-errors` clean, `mix test --include valkey` green, the ≥100 loop green (FOREGROUND, owning the
  machine), honest-row (Valkey 6390); **invariant** — the determinism posture is the ≥100 loop (NOT a multi-seed
  sweep — `@bclaim` leases on the server clock and the proof mints branded JOB-ids: a mint/lease surface).

## A short comprehensive prompt (no decision the spec has not fixed — except the ruled forks)

Build the batch-claim spine inside `echo/apps/echo_mq` to the ruled FORK 5.1-A/B/C arms. Add ONE new inline
`@bclaim` script in `jobs.ex` — a count-variant `ZPOPMIN emq:{q}:pending` loop (the non-grouped generalization of
the shipped `@gwclaim`, `lanes.ex:87`): pop up to `size` heads under ONE `redis.call('TIME')`, lease each on that
one deadline (`ZADD active now+lease id`), `HINCRBY <row> attempts 1` + `HSET <row> state active` per member, the
row key rooted `ARGV[1] .. id` (the `@claim` A-1 form, `jobs.ex:168`), stop the loop when `pending` empties,
return the list of `{id, payload, att}`. Add `claim_batch/4` — the host API (arity 4, the `claim/3` generalization
at `jobs.ex:418`, pause-first via `paused?/2`, `{:ok, [members]}` | `:empty`). Keep `@claim` and EVERY shipped
script (`jobs.ex` + every `@g*` in `lanes.ex`) byte-identical to HEAD. Prove partial-failure isolation over the
byte-frozen `@complete`/`@retry` (no new resolution Lua — the batch is a claim unit). Register the THREE
batch-claim scenarios additive-minor (`batch_claim` + `batch_claim_short` + `batch_partial_failure`; the prior 61
byte-unchanged; re-pin 61 → 64 in both pins). Run the
per-app gate ladder + the ≥100 determinism loop (a mint/lease surface) on Valkey 6390. No `echo_wire` edit
(`@wire_version` frozen at `echomq:2.4.2`); no §6 grammar edit; no client-side `LMPOP`/`ZMPOP`; no new key family;
no git. Report the gate results before going idle.
