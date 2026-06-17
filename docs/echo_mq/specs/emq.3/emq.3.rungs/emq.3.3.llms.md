# EMQ.3.3 · agent brief — the cross-queue flow (Mars's build brief)

> The brief Mars (the implementor) builds from. The spec body [`./emq.3.3.md`](emq.3.3.md) is **authoritative**;
> this brief derives from it and may lag a resolved body — when they disagree, the body wins. **Framing (the
> propagation clause):** third person for any agent reference; no gendered pronouns; no perceptual or
> interior-state verbs for agents or software (components **read**, **compute**, **refuse**, **return**,
> **emit**, **deliver**); no first-person narration; **forward tense** for the unbuilt surface ("emq.3.3
> builds …"). emq.3.3 is **HIGH-risk** — it (a) founds a new cross-slot completion signal (the outbox + the
> sweep-deliver) and (b) **edits a shipped Lua script** (`@complete` gains an additive cross-queue branch; the
> single-queue fan-in branch is **byte-frozen**) → **Apollo MANDATORY** + the **≥100 determinism loop**. **Load
> the `echo-mq-implementor` skill** before building.

## The forks are RULED — build to these arms (D-1..D-5, this rung's ledger)

The four cross-queue forks are decided ([`./emq-3-3.progress.md`](../../progress/emq-3-3.progress.md) — V-1..V-4 surfaced,
D-1..D-5 locked under the 2026-06-15 delegated-authority directive). Build to **exactly** these arms:
- **D-1 — the signal-key:** an **OUTBOX on the CHILD's slot** — `emq:{C}:flow:outbox` (a per-queue key composed
  by the existing `Keyspace.queue_key(queue, "flow:outbox")`). The child's `@complete` emits to it **atomically
  with the active-ZREM**. NOT a parent-side waiting-roster.
- **D-2 — the cadence:** **piggyback `EchoMQ.Pump.sweep/1`** — a third pass `deliver_flow_completions` after
  promote + fire_repeats. NOT a dedicated FlowSweeper.
- **D-3 — the crash recovery:** the **`:processed` HSETNX guard** on the parent's slot — `@flow_deliver` DECRs
  only on the first record of a child. NOT a re-derivation reconcile.
- **D-4 — the shipped-script touch:** an **additive cross-queue BRANCH in `@complete`**; the single-queue fan-in
  branch (`jobs.ex:181-188`) is **BYTE-FROZEN**. NOT a separate `@complete_xq`.
- **D-5 — scope + add-side:** FLAT cross-queue (failure-policy + `add_bulk` + grandchildren are **emq.3.4**,
  OUT); the cross-queue **add is host-orchestrated, NON-atomic across slots, parent-first, fail-closed**; the new
  outbox subkey's cleanup is **NAMED, deferred** (the lifecycle rung enumerates it).

## References (read first — links/paths first)

- **The spec body (authoritative):** [`./emq.3.3.md`](emq.3.3.md) — Goal · 5W · Scope (In/Out + the honest
  bounds B1–B6) · D1–D6 · INV1–INV10 · DoD.
- **The stories (the acceptance face):** [`./emq.3.3.stories.md`](emq.3.3.stories.md) — US1–US7 + US-GATE + the
  Coverage map.
- **The ruled forks (the ADR — D-1..D-5):** [`./emq-3-3.progress.md`](../../progress/emq-3-3.progress.md) — V-1..V-4 (the four
  forks, both arms steelmanned) + D-1..D-5 (the locked decisions; read the DECISIVE ARGUMENT of D-4: atomic
  emission requires the emit INSIDE the `@complete` EVAL).
- **The family contract + the carve + INV7:** [`./emq.3.md`](../../emq.3.md) — emq.3.3 is the **cross-queue** row of
  the carve; **Fork A's cross-queue arm** (`emq.3.md:277-291`) + **INV7** (the cross-queue honesty,
  `emq.3.md:243-249`).
- **The shipped slices (the floor emq.3.3 extends):** [`./emq.3.1.md`](emq.3.1.md) (the same-queue atomic add,
  the `:processed`/`:dependencies` subkeys, the `@complete` fan-in branch, the L-5 lifecycle carry) +
  [`./emq.3.2.md`](emq.3.2.md) (`children_values/3` / `dependencies/3`, the real-result `complete/5`, the N1
  carry emq.3.3 extends with the outbox).
- **The as-built build target + the seams (re-probe at Stage-0 — line numbers DRIFT, grep/Read to confirm):**
  - `echo/apps/echo_mq/lib/echo_mq/flows.ex` — **`EchoMQ.Flows.add/3`** (`:83`, the module emq.3.3 **extends**
    with the cross-queue admit path); **`reject_cross_queue/2`** (`:191`, the host-refusal `{:error,
    :cross_queue}` emq.3.3 **REPLACES** with the admit path); `@enqueue_flow` (`:39`, the same-queue parent shape
    — `HSET child ... 'parent', ARGV[1]` `:53`, `SET KEYS[2] n` the `:dependencies` counter `:57`; KEYS[1]=parent
    row, KEYS[2]=`:dependencies`, KEYS[3]=pending, KEYS[4..]=child rows; **UNTOUCHED** as a script — the
    cross-queue add is host-orchestrated, not one new spanning script). The cross-queue child carries the
    emq.3.1 `parent` field **plus** a NEW `parent_queue` field on its row.
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **`@complete`** (`:152`); the **single-queue fan-in branch**
    `if KEYS[3] and was_active == 1 then ... DECR KEYS[3]; HSET KEYS[4] ARGV[1] ARGV[5]; if left<=0 ... end`
    (`:181-188`, **BYTE-FROZEN** — only ADD a new branch beside it); the existing branch-by-key-presence /
    `group`-field idiom (`:159`/`:181`, the additive pattern to mirror); `complete/5` (`:365`, `result \\ nil`,
    the host wrapper — extend to detect `parent_queue` and supply the outbox key + cross-queue ARGV);
    `parent_of/3` (`:397`, the `HGET ... 'parent'` host read — **extend** to read `parent_queue` too, e.g.
    `HMGET ... 'parent' 'parent_queue'`); **`@extend_locks`** (`:664`, the A-1 slot-rooted-ARGV precedent
    `local jk = base .. 'job:' .. id`, `:675` — the form `@flow_deliver`'s host-built parent keys follow, gated).
  - `echo/apps/echo_mq/lib/echo_mq/pump.ex` — **`EchoMQ.Pump.sweep/1`** (`:91`, `{:ok, %{promoted, fired}}` →
    grows to `%{promoted, fired, delivered}`); `handle_info(:tick, ...)` (`:81`, calls `sweep`); `:transient`
    child_spec (`:31-38`); `:tick_ms` (`:73`, default 1000 `:44`) + `:batch` (`:74`, default 100). Add
    `deliver_flow_completions(conn, queue, batch)` + the `@flow_deliver` `Script.new/2` attribute here (the
    cadence's home).
  - `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — **`queue_key/2`** (`:14`, the pure composer `"emq:{" <> q <>
    "}:" <> type` — `queue_key(queue, "flow:outbox")` composes the outbox key slot-soundly; **NO registry
    allowlist edit needed**, `keyspace.ex` is **UNEDITED**); `job_key/2` (`:17`, gates `BrandedId.valid?/1`,
    **raises** — INV4; the deliver rebuilds the parent key via `job_key(parent_queue, parent_id)`).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — `scenarios/0` (`:51`, a **keyword list**, **46** entries
    as-built; the last is `flow_children_values:` `:98`; the additive edit **appends** `flow_cross_queue:` + a
    `defp apply_scenario(:flow_cross_queue, conn, q)` probe; the moduledoc/`run/2` doc "forty-six"/`n == 46` →
    "forty-seven"/`n == 47`).
  - `echo/apps/echo_mq/lib/echo_mq/admin.ex` — `del_job` (`:152`, the **FIXED** `DEL jk, jk..':logs', jk..':lock'`)
    + `@drain`'s `wipe()` (`:90`, `DEL jk, jk..':logs'`) — **DO NOT EDIT** (the outbox + `:dependencies`/`:processed`
    lifecycle carry is the emq.3.x rung's, not emq.3.3's; `admin.ex` stays untouched — B5/INV9).
  - The pin tests: `test/conformance_run_test.exs:41` (`{:ok, 46}` → `{:ok, 47}`) +
    `test/conformance_scenarios_test.exs` (`@run_order` + "forty-six" → "forty-seven", append `:flow_cross_queue`).
- **The v1 capability reference (READ-ONLY — the SHAPE to PORT, the FORM not to lift):**
  `echo/apps/echomq/lib/echomq/flow_producer.ex` (`add/2` `:123`, `add_bulk/2` `:183` — **OUT, emq.3.4**; the
  per-node `queue_name` spanning `:28-30`, the parent in `orders` + children in
  `validation`/`inventory`/`payments`; the data-value `parent_key = "#{queue_key}:#{job_id}"` `:354` threaded
  through the child's `parent_key` field `:327` — **the form v2 does NOT lift**: the host reads the child's
  `parent`/`parent_queue` fields HOST-SIDE and builds **declared** keys, the emq.3.1 pattern). The v1 cross-queue
  fan-in (`moveToFinished`/`moveToWaitingChildren`) is a SEPARATE cross-queue mechanism — the precedent the
  outbox+sweep replaces A-1-clean.
- **Design:** [`../emq.design.md`](../../../emq.design.md) §6 (the grammar — the slot constraint forcing the fork,
  `:298-324`; the `job:<id>:<sub>` closed set + the `type` registry the outbox joins additively), §11.10 (the
  flow design + the deferral), S-6 (the A-1 declared-keys law — the slot-rooted-ARGV form, `:95-112`), S-1/§6
  (the braced keyspace — the slot constraint), §5 (no new wire class). **Program law:**
  [`../../../.claude/skills/echo-mq-program.md`](../../../../../.claude/skills/echo-mq-program.md) (the v2 laws, the
  gate ladder, the additive-minor law, the ≥100 loop). **Surface map:**
  [`../../../.claude/skills/echo-mq-surface.md`](../../../../../.claude/skills/echo-mq-surface.md).

## Requirements (numbered; each traced back to a story, forward to an invariant/check)

1. **The cross-queue add** (US2 → INV4, INV5/B2, INV10). Extend `EchoMQ.Flows.add/3` to ADMIT a child whose
   `:queue` differs from the parent's queue (remove/replace `reject_cross_queue/2`'s refusal). Host-orchestrate
   the add, **NON-atomic across slots**, **parent-first**, **fail-closed**: (a) land the parent FIRST — held,
   `state = awaiting_children`, `:dependencies` = N (the **total** child count), on the parent's slot; (b) land
   each child on its OWN slot, its row carrying `parent` (the bare parent id, emq.3.1) **plus** `parent_queue`
   (the parent's queue). On a partial add (a child fails to land) leave the parent HELD; the caller retries by
   id. Gate every id (parent + each child) at `Keyspace.job_key/2` BEFORE the wire. Return `{:ok, {parent_id,
   [child_id]}}`. *Same-queue children still take the existing atomic `@enqueue_flow`* — the cross-queue path is
   the new branch; a mixed flow (some same-queue, some cross-queue children) is permitted (each child routed by
   its queue) but the cross-queue legs are individually-landed.
2. **The outbox emit — the additive `@complete` branch** (US3 → INV1, INV3, INV7). Add a NEW branch to the
   shipped `@complete` (`jobs.ex:152`) that fires ONLY when the host supplies the outbox key (a cross-queue
   child): `RPUSH` the completion entry `(parent_queue, parent_id, child_id, result)` into the outbox key
   **inside the same EVAL** as the active-set `ZREM ARGV[1]` (the emission is atomic with completion — one EVAL
   on the child's slot {C}). Encode the entry as a single string the deliver can parse (e.g. a delimiter-joined
   tuple or a `cjson.encode`d object — pick the form the deliver decodes; cite it). The EXISTING single-queue
   fan-in branch (`:181-188`) and the non-flow path (`:148-151`) stay **BYTE-UNCHANGED** (only ADDED lines). The
   host `complete` wrapper detects `parent_queue` HOST-SIDE (extend `parent_of/3` to read `parent_queue`) and
   supplies the outbox key (`Keyspace.queue_key(child_queue, "flow:outbox")`) as a new declared `KEYS[n]` + the
   cross-queue ARGV; a same-queue flow child still supplies the `:dependencies`/`:processed`/parent-row keys (the
   byte-frozen branch); a non-flow job supplies neither.
3. **The sweep-deliver — `deliver_flow_completions` + `@flow_deliver`** (US4 release + US5 idempotency → INV2,
   INV5, INV6, INV10). Add a third pass to `EchoMQ.Pump.sweep/1` (`pump.ex:91`) after promote + fire_repeats;
   grow the return to `{:ok, %{promoted, fired, delivered}}`. The pass drains `emq:{queue}:flow:outbox` (LIMIT
   `:batch` — e.g. `LRANGE 0 batch-1` then `LTRIM`, or `LPOP count`) and, **per entry**, issues `@flow_deliver`
   on the **parent's slot** (the parent key rebuilt HOST-SIDE via `Keyspace.job_key(parent_queue, parent_id)`
   from the entry — the v1 data-value key is NOT lifted). `@flow_deliver` (declared keys `KEYS[1]` = parent's
   `:dependencies`, `KEYS[2]` = parent's `:processed`, `KEYS[3]` = parent row, all on the parent's slot; ARGV[1]
   = `child_id`, ARGV[2] = `result`; the parent's pending key derived from a declared queue-base root the way
   `@complete` derives `p .. 'pending'`):
   `if redis.call('HSETNX', KEYS[2], ARGV[1], ARGV[2]) == 1 then local left = redis.call('DECR', KEYS[1]); if
   left <= 0 then redis.call('ZADD', <parent pending>, 0, <parent id>); redis.call('HSET', KEYS[3], 'state',
   'pending') end end; return ...` — the **`:processed` HSETNX guard** (D-3): DECR fires only on the first record;
   a re-delivery is a no-op. Remove the drained entry from the outbox **only after** the deliver succeeds (a
   crash before removal re-delivers → idempotent). The deliver is **at-least-once → effectively-once**.
4. **The lifecycle disposition — NAMED, deferred** (US6 → INV9). Do **NOT** edit `admin.ex`. The spec body names
   the outbox's cleanup home (both FIXED-list destructive sweeps + the owning emq.3.x lifecycle rung); emq.3.3's
   touch-set adds **zero** `DEL`/`HDEL`/`UNLINK` of a flow subkey. The outbox is self-clearing in steady state.
5. **The conformance scenario `flow_cross_queue`** (US7 → INV8). APPEND `flow_cross_queue:` to
   `Conformance.scenarios/0` (`:51`) + a `defp apply_scenario(:flow_cross_queue, conn, q)` probe; the prior **46**
   scenarios byte-unchanged; re-pin the count **46 → 47** in **both** pinning tests + the moduledoc/`run/2` doc.
   The probe adds a cross-queue flow (a parent in q.parent, a child in a DIFFERENT sub-queue), completes the
   child, asserts the parent **still held** pre-sweep, runs `deliver_flow_completions` (or a `Pump` tick),
   asserts the parent **released** (eventually-consistent — INV5), and runs the deliver **twice** for one child
   asserting `:dependencies` decremented **once** (idempotent — INV6).
6. **The proof** (US7 + US-GATE → INV1, INV2, INV3, INV5, INV8). The `:valkey` cross-queue suite green per-app
   (`TMPDIR=/tmp mix test --include valkey` inside `echo/apps/echo_mq`); the **≥100 determinism loop** green for
   the mint/process-touching cross-queue scenario (owning the machine); the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2}
   suites + `Conformance.run/2` pass unchanged (no regression); the **single-queue `@complete` fan-in branch
   byte-unchanged** (`git diff` of `@complete` shows only ADDED lines; the `:152-191` existing branches
   byte-identical); a **declared-keys grep** over the emit branch + `@flow_deliver` (every key a `KEYS[n]` or a
   declared-root derivation; the emit's keys all on {C}, the deliver's all on {P} — the F-1 cross-slot trap the
   6390 single-node engine will NOT catch); honest-row reporting (Valkey on 6390); **Apollo MANDATORY** (the
   dedicated evaluator — HIGH-risk).

## Execution topology

**Runtime shape (the cross-queue fan-in, end to end):**
1. **Add** (host, `Flows.add/3`): parent lands held on `{P}` with `:dependencies` = N; each cross-queue child
   lands claimable on its own `{Cᵢ}` carrying `parent` + `parent_queue`. (Non-atomic across slots; parent-first;
   fail-closed.)
2. **Work + complete** (worker, `complete/5`): a child runs; on completion the host reads its `parent_queue`
   (cross-queue) and the child's `@complete` **RPUSHes** `(parent_queue, parent_id, child_id, result)` into
   `emq:{Cᵢ}:flow:outbox` **atomically with the active-ZREM** (one EVAL on {Cᵢ}). The child is gone from `active`
   AND signalled — no drop window.
3. **Sweep + deliver** (pump on the child queue, `Pump.sweep/1`'s third pass): `deliver_flow_completions` drains
   `emq:{Cᵢ}:flow:outbox` and per entry issues `@flow_deliver` on `{P}`: `HSETNX` the child into the parent's
   `:processed`, and on first-record `DECR` the parent's `:dependencies`; at zero, `ZADD` the parent to its
   pending + `HSET` the row `state = pending`. The drained entry is removed. (Eventually-consistent: the parent
   releases on this tick, not on the completion. Idempotent: a re-delivery is a no-op.)
4. **Consume** (parent worker, emq.3.2): once released + claimed, the parent reads its legs via
   `children_values/3` (the `:processed` results) — the cross-queue fan-in payload.

**The build-order DAG (each step gated before the next):**
- **T1 — the cross-queue add** (Req 1, `flows.ex`): the admit path + the `parent_queue` field. Gate: a cross-queue
  `add/3` lands the parent held on {P} + each child claimable on its {C} carrying `parent_queue`; a partial add
  leaves the parent held; an ill-formed id raises. (No emit/deliver yet — the child completes but the parent
  stays held, which is correct pre-deliver.)
- **T2 — the outbox emit** (Req 2, `jobs.ex`): the additive `@complete` branch + the host `complete`/`parent_of`
  extension. Gate: a cross-queue child's completion RPUSHes one outbox entry on {C} AND removes it from `active`
  (one EVAL); the single-queue fan-in branch + non-flow path byte-unchanged (per-attr `git diff`).
- **T3 — the sweep-deliver** (Req 3, `pump.ex`): `deliver_flow_completions` + `@flow_deliver`. Gate: after a
  cross-queue child completes (T2), running the sweep delivers the decrement on {P}, releases the parent at zero,
  and a second deliver of the same child is a no-op (`:dependencies` decremented once).
- **T4 — the conformance scenario** (Req 5, `conformance.ex` + pins): `flow_cross_queue` appended + probe + the
  count re-pinned 46 → 47. Gate: `Conformance.run/2` returns `{:ok, 47}`; both pins assert 47; the prior 46
  byte-unchanged.
- **T5 — the proof** (Req 6): the `:valkey` suite + the ≥100 loop + the regression suites + the byte-diff + the
  declared-keys grep, then **Apollo MANDATORY**. Gate: all green; `@complete` only-added-lines; the slot grep
  clean; Apollo's BUILD-GRADE verdict.

**The EXACT files touched** (the boundary — `echo/apps/echo_mq` + NO `echo_wire`):
- `lib/echo_mq/flows.ex` (EDIT — the cross-queue admit path; `reject_cross_queue/2` replaced).
- `lib/echo_mq/jobs.ex` (EDIT — the additive `@complete` cross-queue branch; the host `complete`/`parent_of`
  extension; the single-queue branch `:181-188` byte-frozen).
- `lib/echo_mq/pump.ex` (EDIT — `deliver_flow_completions` + the `@flow_deliver` script; `sweep/1`'s return grows).
- `lib/echo_mq/conformance.ex` (EDIT — `flow_cross_queue` + its probe + the count re-pin).
- `test/flow_cross_queue_test.exs` (NEW — `:valkey`).
- `test/conformance_run_test.exs` + `test/conformance_scenarios_test.exs` (EDIT — the count re-pin to 47).
- **UNTOUCHED:** `lib/echo_mq/keyspace.ex` (the outbox key composes via the existing `queue_key/2`; no grammar
  allowlist), `lib/echo_mq/admin.ex` (the lifecycle carry — B5/INV9), `@enqueue_flow` (the add is host-orchestrated),
  every other shipped `Script.new/2` body, `echo_wire`, `apps/echomq`, `docs/echo/mesh/**`.

## Agent stories (each a Directive + an Acceptance gate — the contract Apollo + the Director accept at)

- **AS1 — the cross-queue add.** *Directive:* extend `Flows.add/3` to admit cross-queue children; host-orchestrate
  parent-first, non-atomic across slots, fail-closed; write `parent` + `parent_queue` on each cross-queue child;
  gate every id at `Keyspace.job_key/2`; replace `reject_cross_queue/2`. *Acceptance gate (precondition →
  postcondition → invariant):* GIVEN a flow with a cross-queue child → `add/3` returns `{:ok, {parent_id,
  [child_id]}}`, the parent is held on its slot (`state = awaiting_children`, `:dependencies` = N), each child is
  claimable on its own slot carrying `parent_queue`; INVARIANT: a partial add leaves the parent held
  (fail-closed); an ill-formed id raises (INV4). Cite the spec line (D2) for the public contract.
- **AS2 — the outbox emit (the additive `@complete` branch).** *Directive:* add a cross-queue branch to
  `@complete` that RPUSHes `(parent_queue, parent_id, child_id, result)` into `emq:{C}:flow:outbox` atomically
  with the active-ZREM; extend the host `complete`/`parent_of` to detect `parent_queue` and supply the outbox key.
  *Acceptance gate:* GIVEN a cross-queue child completes → the outbox holds one entry for it AND it is gone from
  `active` (one EVAL, both effects); INVARIANT: the single-queue fan-in branch (`:181-188`) + the non-flow path
  are BYTE-IDENTICAL (per-attr `git diff` shows only added lines — INV3); no parent-slot key enters the
  child-slot EVAL (the declared-keys grep — INV2). Cite D3.
- **AS3 — the sweep-deliver (`deliver_flow_completions` + `@flow_deliver`).** *Directive:* add the third
  `sweep/1` pass draining the outbox (LIMIT `:batch`) + the `@flow_deliver` script (the `:processed` HSETNX guard
  on the parent's slot); grow `sweep/1`'s return to include `delivered`; remove the drained entry only after the
  deliver succeeds. *Acceptance gate:* GIVEN a cross-queue child has completed → running the sweep DECRs the
  parent's `:dependencies`, at-zero releases the parent (claimable, `dependencies/3` == 0, row `pending`);
  INVARIANT: the parent is held until the sweep (eventually-consistent — INV5); a re-delivery of the same child
  is a no-op (`:dependencies` decremented exactly once — INV6); every `@flow_deliver` key is on the parent's slot
  (INV2). Cite D4.
- **AS4 — the conformance scenario + the count re-pin.** *Directive:* append `flow_cross_queue:` + a probe to
  `scenarios/0`; re-pin 46 → 47 in both pins + the docs; keep the prior 46 byte-unchanged. *Acceptance gate:*
  `Conformance.run/2` returns `{:ok, 47}`; both pins assert 47; the `scenarios/0` `git diff` shows only additions;
  the probe exercises the eventually-consistent release + the idempotent re-deliver (INV5, INV6, INV8). Cite D6.
- **AS5 — the proof + Apollo.** *Directive:* run the gate ladder (per-app compile warnings-as-errors; the
  `:valkey` cross-queue suite; the ≥100 loop owning the machine; the regression suites; the `@complete` byte-diff;
  the declared-keys/slot grep), then hand to **Apollo (MANDATORY)**. *Acceptance gate:* all green; `@complete`
  only-added-lines (the single-queue branch byte-frozen); the emit's keys all {C} + the deliver's all {P} (no
  cross-slot key — the F-1 trap); the ≥100 loop green; Apollo's BUILD-GRADE verdict + the byte-check. Cite D6,
  INV1, INV3.

## What NOT to do (the boundary + the no-invent guardrails)

- **Do NOT lift the v1 data-value key form.** The v1 child carries `parent_key = "#{queue_key}:#{job_id}"`
  (`flow_producer.ex:354`) and v1 scripts root keys in that data value. emq.3.3 does NOT: the host reads the
  child's `parent`/`parent_queue` fields HOST-SIDE and builds **declared** keys (`Keyspace.job_key(parent_queue,
  parent_id)`); every Lua key is `KEYS[n]` or a declared-root derivation (S-6 — INV2).
- **Do NOT mix slots in any script.** The emit branch touches ONLY the child's slot {C} (the active set + the
  outbox); `@flow_deliver` touches ONLY the parent's slot {P} (the parent's `:dependencies`/`:processed`/row).
  The 6390 single-node engine will NOT raise on a cross-slot key — the review + the declared-keys grep is the
  gate (the F-1 trap).
- **Do NOT edit the single-queue `@complete` fan-in branch** (`jobs.ex:181-188`), `@enqueue_flow`, any other
  shipped `Script.new/2` body, `keyspace.ex`'s grammar, or `admin.ex`. The `@complete` edit is the ONE shipped
  script touched, and ONLY additively.
- **Do NOT claim "atomic across queues"** anywhere (code comment, doctest, scenario contract). The cross-queue
  fan-in is eventually-consistent; the add is non-atomic across slots. State both honestly (INV5, B1, B2).
- **Do NOT build the OUT scope** (failure-policy, `add_bulk`, grandchildren/deep recursion — emq.3.4) or the
  outbox cleanup (the lifecycle rung). emq.3.3 is FLAT cross-queue only.
- **Run NO git** (the Director commits by pathspec at the rung's close). Per-app testing only
  (`TMPDIR=/tmp mix test` inside `echo/apps/echo_mq`; never umbrella-wide). Watch for the Operator's out-of-band
  `[emq]`/`docs/echo/mesh/**` commits — exclude them.

A short comprehensive prompt that leaves no decision the spec has not already fixed: the forks are ruled
(D-1..D-5), the seams are pinned (re-probe at Stage-0), the boundary is `echo/apps/echo_mq`, the one shipped-script
edit is the additive `@complete` branch (the single-queue branch byte-frozen), the conformance grows 46 → 47, and
the proof is the `:valkey` cross-queue suite + the ≥100 loop + Apollo MANDATORY. Build to the body; when the brief
and the body disagree, the body wins.
