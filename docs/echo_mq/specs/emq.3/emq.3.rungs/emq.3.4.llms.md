# EMQ.3.4 · agent brief — the flow failure-policy + bulk add (Mars's build brief)

> **[SHIPPED 2026-06-15 — this brief is DISCHARGED.** emq.3.4 built + Apollo-verified BUILD-GRADE (Y-4); the
> as-built `file:line` are re-pinned in the body's As-built-surface block. This brief is retained as the build's
> historical directive — its forward-tense ("emq.3.4 builds …") and its PRE-build anchors (`jobs.ex:254-259` etc.)
> are design-time; for the shipped surface read the body. Two realizations landed and are recorded in the body's
> DoD: **E-1** — `@enqueue_flow_child` stayed BYTE-FROZEN (R1); `parent_policy` is written by a host `HSET` on the
> child row (every child, same-queue AND cross-queue), NOT a script ARGV edit. **add_bulk/3** lands flows
> **SEQUENTIALLY** (one `add/3` per flow, fail-closed per flow), not pipelined.]**
>
> The brief Mars (the implementor) builds from. The spec body [`./emq.3.4.md`](emq.3.4.md) is **authoritative**;
> this brief derives from it and may lag a resolved body — when they disagree, the body wins. **Framing (the
> propagation clause):** third person for any agent reference; no gendered pronouns; no perceptual or
> interior-state verbs for agents or software (components **read**, **compute**, **refuse**, **return**,
> **emit**, **deliver**, **propagate**); no first-person narration; **forward tense** for the unbuilt surface
> ("emq.3.4 builds …"). emq.3.4 was **HIGH-risk** — it (a) **edits a shipped Lua script** (`@retry`'s dead-letter
> arm gained an additive failure-propagation branch; the existing dead-letter body `jobs.ex:254-259` →
> as-built `:281-303` is **byte-frozen**) and (b) crosses the same slot boundary the cross-queue completion does (a
> cross-queue child's DEATH reaches the parent over the **same** `flow:outbox` + sweep emq.3.3 founded) →
> **Apollo MANDATORY** + the **≥100 determinism loop**, both PASSED.

## The scope is RULED → Arm A — build to this (V-1 → D-2, this rung's ledger)

The **V-1 scope fork** ([`./emq-3-4.progress.md`](../../progress/emq-3-4.progress.md)) — does emq.3.4 include **grandchildren /
deep recursion**, or is that a separate later rung? — is **RULED → Arm A** (the Director, recorded as **D-2**).
Build to **Arm A**:
- **Arm A (RULED, the family carve [`./emq.3.md`](../emq.3.md):198):** emq.3.4 = **failure-policy + `add_bulk`**
  only. Grandchildren (a cross-queue child that is itself a flow-parent — the recursive tree) is the **locked
  Out → emq.3.5** (a separate later rung, recorded NOT built). **Build to this.**
- **Arm B (NOT chosen):** grandchildren joins emq.3.4 — it was the steelmanned alternative, a cheap re-scope that
  would have only **ADDED** the recursive-tree add + the multi-level fan-in deliverables; the failure-policy core
  (the `@retry` branch, the fail-deliver, the policy flags) is identical either way, so the Arm-A ruling stays a
  zero-cost Operator option to revisit later — but it is **not this rung**. Do **NOT** build the grandchildren
  deliverables.

The **failure-policy mechanism** is decided by the body + the inherited emq.3.3 arms. Build to these:
- **Same-queue child death** → an **additive branch** in the shipped `@retry`'s dead-letter arm (the existing
  body `jobs.ex:254-259` **BYTE-FROZEN**), routing the death atomically by policy (one EVAL, one slot).
- **Cross-queue child death** → a **fail-entry** into the child's own-slot `flow:outbox` (the **same** outbox
  emq.3.3 founded, a distinct KIND) atomically with the dead-letter transition; the existing sweep
  (`deliver_flow_completions`) drains it; a new **`@flow_fail_deliver`** applies it on the parent's slot.
- **Idempotency** → the **same** `:processed`-class HSETNX guard the complete-deliver uses, now over
  `:failed`/`:unsuccessful` (a re-delivered fail is a no-op).
- **The §6 subkeys** → `:failed`/`:unsuccessful` are **already §6-reserved** (`emq.design.md:307`) — **no
  grammar edit, no new key type** (unlike emq.3.3's `flow:outbox`).

## References (read first — links/paths first)

- **The spec body (authoritative):** [`./emq.3.4.md`](emq.3.4.md) — Goal · 5W · Scope (In/Out + the honest
  bounds B1–B6) · D1–D7 · INV1–INV11 · DoD.
- **The stories (the acceptance face):** [`./emq.3.4.stories.md`](emq.3.4.stories.md) — US1–US7 + US-GATE + the
  Coverage map.
- **The scope fork (V-1):** [`./emq-3-4.progress.md`](../../progress/emq-3-4.progress.md) — T-1 (the reconcile delta, the
  re-pinned anchors) + V-1 (the grandchildren scope fork, both arms steelmanned + the recommendation).
- **The family contract + the carve:** [`./emq.3.md`](../emq.3.md) — emq.3.4 is the **"failure-policy + bulk"**
  row of the carve (`:198`); §0 names the `:failed`/`:unsuccessful` subkeys §6-reserved at the founding
  (`:46-61`); INV3 (byte-unchanged) + INV7 (the cross-queue honesty).
- **The shipped slices (the floor emq.3.4 extends):** [`./emq.3.1.md`](emq.3.1.md) (the same-queue atomic add,
  the `:dependencies`/`:processed` subkeys, the `@complete` fan-in branch, the L-5 lifecycle carry) +
  [`./emq.3.2.md`](emq.3.2.md) (`children_values/3` / `dependencies/3`, the real-result `complete/5`, the N1
  carry) + [`./emq.3.3.md`](emq.3.3.md) (the `flow:outbox` + `EchoMQ.Pump.sweep/1`'s `deliver_flow_completions`
  + `@flow_deliver` + the `:processed` HSETNX idempotency guard + the `parent_queue` field — the **cross-queue
  mechanism the fail-deliver rides**, the B5 lifecycle carry the failure subkeys join).
- **The as-built build target + the seams (re-probe at Stage-0 — line numbers DRIFT, grep/Read to confirm; these
  are re-pinned post-emq.3.3 in T-1):**
  - `echo/apps/echo_mq/lib/echo_mq/flows.ex` — **`EchoMQ.Flows.add/3`** (`:152`, the module emq.3.4 **extends**
    with the policy flags); `children_values/3` (`:190`, the `<> ":processed"` read precedent for
    `ignored_failures/3`); `dependencies/3` (`:227`); `add_cross_queue/5` (`:285`) + `land_children/4` (`:309`,
    where each child's row is written — `HSET ... 'parent', ARGV[3], 'parent_queue', ARGV[4]` at
    `@enqueue_flow_child` `:95`; emq.3.4 ADDS `parent_policy` here) + `add_same_queue/5` (`:249`) — the
    host-orchestration `add_bulk/3` reuses per flow. `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child` scripts
    **UNTOUCHED as scripts** (the policy is a host-passed ARGV field on the child row, not a new spanning script).
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **`@retry`** (`:225`); the **dead-letter arm** (`:254-259`,
    re-pinned at Stage-0 — the FULL **five-statement** morgue branch:
    `HSET KEYS[4] 'last_error', ARGV[5]` `:254`; at `att >= max` `HSET KEYS[4] 'state','dead'` `:256` +
    `ZADD KEYS[3] 0 ARGV[1]` `:257` + **`HINCRBY p..'metrics:failed' 'count' 1` `:258`** + `return 'dead'` `:259`)
    — the **BYTE-FROZEN** body (the `HINCRBY metrics:failed` is the fifth statement an earlier abbreviation
    omitted; freeze ALL five); ADD the failure branch AFTER it (the child lands in its own
    morgue first, then the parent is notified), gated on host-supplied parent-fail keys / a fail marker the
    shipped callers never pass; `retry/7` (`:474`, the host wrapper — extend to read `parent_policy` via
    `parent_of`-class read and supply the parent-fail keys (same-queue) or the outbox key + fail marker
    (cross-queue)); `parent_of/3` (`:459`, the `HMGET ... 'parent' 'parent_queue'` host read — **extend** to read
    `parent_policy` too, e.g. `HMGET ... 'parent' 'parent_queue' 'parent_policy'`); `@complete` (`:175`) with the
    fan-in branch (`:212-219`) + the cross-queue emit branch (`:205-206`, gated `ARGV[6]=='xq'`) — **BYTE-FROZEN,
    DO NOT EDIT**; `complete/5` (`:412`); **`@extend_locks`** (the A-1 slot-rooted-ARGV precedent
    `local jk = base .. 'job:' .. id` — the form `@flow_fail_deliver`'s host-built parent keys follow, gated).
  - `echo/apps/echo_mq/lib/echo_mq/pump.ex` — **`@flow_deliver`** (`:42`, the complete-deliver — **BYTE-FROZEN,
    DO NOT EDIT**); **`deliver_flow_completions/3`** (`:161`, the existing third pass — `LRANGE` non-destructive →
    per entry → `LTRIM`; emq.3.4 makes it dispatch by entry KIND: a complete-entry → the existing `@flow_deliver`,
    a fail-entry → the NEW `@flow_fail_deliver`); `split_entry/1` (`:236`, the `\0`-split entry parser — emq.3.4
    extends it to read the KIND tag); `sweep/1` (`:126`, `{:ok, %{promoted, fired, delivered}}` — `delivered`
    counts both kinds); `deliver_one/2` (`:202`, the per-entry deliver — gains the KIND branch). Add the
    `@flow_fail_deliver` `Script.new/2` attribute here (the deliver's home, beside `@flow_deliver`).
  - `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — **`queue_key/2`** (`:14`) + **`job_key/2`** (`:18`, gates
    `BrandedId.valid?/1`, **raises** — INV4). `job_key(queue, parent) <> ":failed"` / `<> ":unsuccessful"`
    composes the failure subkeys slot-soundly (the `children_values/3` `<> ":processed"` precedent at
    `flows.ex:191`); **NO registry allowlist edit needed**, `keyspace.ex` is **UNEDITED** (the subkeys are
    §6-reserved — `emq.design.md:307`).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — `scenarios/0` (a **keyword list**, **47** entries as-built;
    the last is `flow_cross_queue:` `:103`); APPEND `flow_fail_parent:`, `flow_ignore_dep:`, `flow_add_bulk:` +
    three `defp apply_scenario(...)` probes; the moduledoc/`run/2` doc "forty-seven"/`n == 47` →
    "fifty"/`n == 50`.
  - `echo/apps/echo_mq/lib/echo_mq/admin.ex` — `del_job` (`:152`, the **FIXED** `DEL jk, jk..':logs', jk..':lock'`)
    + `@drain`'s `wipe()` (`:90`, `DEL jk, jk..':logs'`) — **DO NOT EDIT** (the `:failed`/`:unsuccessful` +
    `:dependencies`/`:processed`/`flow:outbox` lifecycle carry is the emq.3.x rung's, not emq.3.4's; `admin.ex`
    stays untouched — B6/INV10).
  - The pin tests: `test/conformance_run_test.exs` (`{:ok, 47}` → `{:ok, 50}`) +
    `test/conformance_scenarios_test.exs` (`@run_order` + "forty-seven" → "fifty", append the three names).
- **The v1 capability reference (READ-ONLY — the SHAPE to PORT, the FORM not to lift):**
  `echo/apps/echomq/lib/echomq/flow_producer.ex` (the options `:78-82` `fail_parent_on_failure` (default true) /
  `ignore_dependency_on_failure` / `remove_dependency`; `encode_job_opts` `:468-483` threads `fpof`/`idof`; the
  recursive `build_flow_commands` `:238` + the reduce-over-children `:364-374` — **the grandchildren tree, OUT
  (V-1)**; `add_bulk/2` `:183` — the bulk parity to port; the data-value `parent_key` `:354/327` — **the form v2
  does NOT lift**: the host reads the child's `parent`/`parent_queue`/`parent_policy` fields HOST-SIDE and builds
  **declared** keys) + `echo/apps/echomq/lib/echomq/job.ex` (`get_ignored_children_failures/1` `:885` over
  `job_failed` `:298` the `:failed` HASH — the `ignored_failures/3` parity; `job_unsuccessful` `:302`). The v1
  failure propagation (`moveToFinished-15.lua`) is the SEPARATE cross-queue mechanism — the precedent the
  `@retry` branch + the outbox fail-entry replace A-1-clean.
- **Design:** [`../emq.design.md`](../../../emq.design.md) §6 (the grammar — `:failed`/`:unsuccessful` **already
  reserved** at `:307`; the slot constraint forcing the cross-queue fail-deliver, `:298-324`), §11.10 (the flow
  design + the deferral), S-6 (the A-1 declared-keys law — the slot-rooted-ARGV form, `:95-113`), S-1/§6 (the
  braced keyspace — the slot constraint), §5 (no new wire class). **Program law:**
  [`../../../.claude/skills/echo-mq-program.md`](../../../../../.claude/skills/echo-mq-program.md) (the v2 laws, the
  gate ladder, the additive-minor law, the ≥100 loop). **Surface map:**
  [`../../../.claude/skills/echo-mq-surface.md`](../../../../../.claude/skills/echo-mq-surface.md).

## Requirements (numbered; each traced back to a story, forward to an invariant/check)

1. **The failure-policy options + `add_bulk/3`** (US2 → INV4, INV11). Extend `EchoMQ.Flows.add/3` to accept
   per-child `fail_parent_on_failure` (default `true`) + `ignore_dependency_on_failure` (default `false`) flags
   (the v1 options). Record each child's policy: a **same-queue** child needs no new row field (the host has the
   parent keys at `retry` time); a **cross-queue** child's row carries a new **`parent_policy`** field (written by
   `@enqueue_flow_child` `flows.ex:95`, alongside `parent` + `parent_queue` — host-passed ARGV, not a data-rooted
   Lua key). Add **`EchoMQ.Flows.add_bulk/3`** (the v1 `add_bulk/2` parity): accept a list of flows, land each by
   the existing `add/3` mechanism (pipelined where the connector allows), **fail-closed per flow** (a flow that
   fails to land leaves its own parent HELD), return `{:ok, [{parent_id, [child_id]}]}`. Gate every id (parent +
   each child, every flow) at `Keyspace.job_key/2` BEFORE the wire.
2. **The same-queue failure propagation — the additive `@retry` dead-letter branch** (US3 → INV5, INV6, INV3,
   INV1). Add a NEW branch to the shipped `@retry` (`jobs.ex:225`) that fires ONLY when the host supplies the
   parent-fail keys (a same-queue flow child that has just dead-lettered). It runs **AFTER** the existing morgue
   transition (the child lands in its own morgue first), atomically in the same EVAL (one slot — the parent is
   same-queue): by the policy ARGV, `fail_parent_on_failure` → `HSET <parent :failed> child_id error` + move the
   parent to `dead` (`HSET <parent row> 'state','dead'`; `ZADD <parent dead> 0 parent`; clear the parent's
   `:dependencies`/`pending` membership as the morgue transition requires); `ignore_dependency_on_failure` →
   `HSET <parent :unsuccessful> child_id error` + `local left = DECR <parent :dependencies>`; `if left <= 0 then
   ZADD <parent pending> 0 parent; HSET <parent row> 'state','pending' end` (the satisfy-and-release, mirroring
   the `@complete` fan-in at-zero release `jobs.ex:212-219`). The EXISTING dead-letter body (`:254-259`) and the
   schedule arm stay **BYTE-UNCHANGED** (only ADDED lines). The host `retry` wrapper (`jobs.ex:474`) detects the
   parent + policy HOST-SIDE (extend `parent_of/3` to read `parent_policy`) and supplies the parent-fail keys +
   the policy ARGV; a non-flow `retry` supplies neither (the branch unreached).
3. **The cross-queue fail-deliver — the `flow:outbox` fail-entry + `@flow_fail_deliver`** (US4 → INV8, INV7,
   INV5, INV6, INV2). A **cross-queue** flow child's death: the `@retry` cross-flow branch (Req 2's branch,
   cross-queue arm) **RPUSHes a fail-entry** (a distinct KIND — e.g. a leading `"fail"` tag the splitter reads,
   carrying `parent_queue`, `parent_id`, `child_id`, `error`, `policy`) into the child's own-slot
   `emq:{C}:flow:outbox` **inside the same EVAL** as the dead-letter transition (atomic with completion of the
   morgue move — one EVAL on {C}, the same shape as emq.3.3's complete-emit). Extend `split_entry/1`
   (`pump.ex:236`) to read the KIND tag; extend `deliver_one/2` (`pump.ex:202`) to dispatch: a complete-entry →
   the existing `@flow_deliver` (byte-unchanged), a fail-entry → the NEW **`@flow_fail_deliver`** EVAL on the
   parent's slot (the parent key rebuilt host-side via `Keyspace.job_key(parent_queue, parent_id)`).
   `@flow_fail_deliver` (declared keys `KEYS[1]` = parent's `:dependencies`, `KEYS[2]` = parent's `:failed`,
   `KEYS[3]` = parent's `:unsuccessful`, `KEYS[4]` = parent row, all on the parent's slot; ARGV: `child_id`,
   `error`, `policy`; the parent's pending key derived from a declared queue-base root the way `@flow_deliver`
   does): by `policy`, `fail_parent_on_failure` → `if HSETNX(KEYS[2], child_id, error) == 1 then move the parent
   to dead end`; `ignore_dependency_on_failure` → `if HSETNX(KEYS[3], child_id, error) == 1 then local left =
   DECR(KEYS[1]); if left <= 0 then release the parent end end` — the **HSETNX guard** (idempotent: a re-delivered
   fail is a no-op). Remove the drained entry only after the deliver succeeds (deliver-before-remove, the existing
   `LTRIM`-after order `pump.ex:181-183`). `@flow_deliver` is **BYTE-UNCHANGED**.
4. **The ignored-failures read — `ignored_failures/3`** (US5 → INV6). Add `EchoMQ.Flows.ignored_failures/3`: a
   PURE `HGETALL` of the parent's `:unsuccessful` subkey → `{:ok, %{child_id => error}}` (the v1
   `get_ignored_children_failures` parity), composed via `Keyspace.job_key(queue, parent_id) <> ":unsuccessful"`
   (the `children_values/3` `<> ":processed"` precedent, `flows.ex:190-191`); a parent with no `:unsuccessful`
   key returns `{:ok, %{}}`. **NORMAL-risk** (host-only, no script).
5. **The lifecycle disposition — NAMED, deferred** (US6 → INV10). Do **NOT** edit `admin.ex`. The spec body names
   the `:failed`/`:unsuccessful` cleanup home (both FIXED-list destructive sweeps + the owning emq.3.x lifecycle
   rung); emq.3.4's touch-set adds **zero** `DEL`/`HDEL`/`UNLINK` of a flow subkey.
6. **The conformance scenarios `flow_fail_parent` / `flow_ignore_dep` / `flow_add_bulk`** (US7 → INV9). APPEND the
   three to `Conformance.scenarios/0` (`:103` is the current last) + three `defp apply_scenario(...)` probes; the
   prior **47** scenarios byte-unchanged; re-pin the count **47 → 50** in **both** pinning tests + the
   moduledoc/`run/2` doc. The `flow_fail_parent` probe adds a flow with `fail_parent_on_failure` (same-queue AND
   cross-queue forms), fails the child past max attempts, asserts the parent `dead` + the child in `:failed`
   (cross-queue: parent unchanged pre-sweep, failed post-sweep — INV5), and double-delivers the fail asserting
   the parent failed once (INV7). The `flow_ignore_dep` probe adds a flow with `ignore_dependency_on_failure`,
   fails the ignored child, asserts the parent proceeds (`:dependencies` decremented, child in `:unsuccessful`,
   not in `:processed`) and `ignored_failures/3` returns it (INV6). The `flow_add_bulk` probe adds N flows in one
   call, asserts N parents land + each flow's children claimable + the per-flow fail-closed.
7. **The proof** (US7 + US-GATE → INV1, INV2, INV3, INV5, INV6, INV9). The `:valkey` failure suite green per-app
   (`TMPDIR=/tmp mix test --include valkey` inside `echo/apps/echo_mq`); the **≥100 determinism loop** green for
   the mint/process-touching cross-queue failure scenario (owning the machine); the emq.1 + emq.2.{1,2,3,4} +
   emq.3.{1,2,3} suites + `Conformance.run/2` pass unchanged (no regression); the **`@retry` existing dead-letter
   body byte-unchanged** (`git diff` of `@retry` shows only ADDED lines; the `:254-259` body + the schedule arm
   byte-identical), and **`@complete` + `@flow_deliver` byte-unchanged**; a **declared-keys grep** over the
   `@retry` failure branch + the cross-queue fail-emit (all keys {C}) + `@flow_fail_deliver` (all keys {P}) — the
   F-1 cross-slot trap the 6390 single-node engine will NOT catch; honest-row reporting (Valkey on 6390); **Apollo
   MANDATORY** (the dedicated evaluator — HIGH-risk).

## Execution topology

**Runtime shape (the flow failure half, end to end):**
1. **Add** (host, `Flows.add/3` / `add_bulk/3`): each child's policy recorded (a cross-queue child's row carries
   `parent_policy`); the flow lands by the existing mechanism (same-queue atomic; cross-queue host-orchestrated
   parent-first, fail-closed per flow).
2. **Work + fail** (worker, `retry/7` past max attempts): a child dies. *Same-queue:* the `@retry` cross-flow
   branch routes the death atomically by policy (one EVAL on the parent's slot — the parent fails, or
   satisfies-and-releases). *Cross-queue:* the `@retry` branch RPUSHes a fail-entry into the child's own-slot
   `flow:outbox` **atomically with the morgue transition** (one EVAL on {C}). The child is in its own morgue AND
   signalled — no drop window.
3. **Sweep + fail-deliver** (pump on the child queue, `Pump.sweep/1`'s third pass): `deliver_flow_completions`
   drains the outbox, dispatching by entry KIND — a complete-entry → `@flow_deliver` (byte-unchanged), a
   fail-entry → `@flow_fail_deliver` on the parent's slot {P}: by policy, fail the parent (`:failed`, `dead`) or
   satisfy-and-record (`:unsuccessful`, HSETNX-guarded DECR, at-zero release). The drained entry is removed.
   (Eventually-consistent: the parent fails/proceeds on this tick, not on the death. Idempotent: a re-delivered
   fail is a no-op.)
4. **Consume** (parent handler, emq.3.2 + emq.3.4): a released parent reads `children_values/3` (the completed
   children's results) AND `ignored_failures/3` (the ignored children's errors) — the partial-outcome payload.

**The build-order DAG (each step gated before the next):**
- **T1 — the failure-policy options + `add_bulk/3`** (Req 1, `flows.ex`): the policy flags on `add/3`, the
  `parent_policy` field on the cross-queue child, `add_bulk/3`. Gate: `add/3` records each policy (a cross-queue
  child carries `parent_policy`); `add_bulk/3` lands N flows fail-closed per flow; an ill-formed id raises. (No
  propagation yet — a child that dies does not yet reach the parent, which is the pre-Req-2 state.)
- **T2 — the same-queue failure propagation** (Req 2, `jobs.ex`): the additive `@retry` dead-letter branch + the
  host `retry`/`parent_of` extension. Gate: a same-queue flow child dying with `fail_parent_on_failure` →
  parent `dead`, child in `:failed`; with `ignore_dependency_on_failure` → `:dependencies` DECR'd, child in
  `:unsuccessful`, at-zero release; the existing dead-letter body (`:254-259`) + schedule arm byte-unchanged
  (per-attr `git diff`).
- **T3 — the cross-queue fail-deliver** (Req 3, `jobs.ex` + `pump.ex`): the cross-queue fail-entry emit (in the
  Req-2 branch) + the KIND-dispatch in `deliver_flow_completions`/`split_entry`/`deliver_one` + `@flow_fail_deliver`.
  Gate: a cross-queue child dying RPUSHes a fail-entry on {C} AND lands in its own morgue (one EVAL); running the
  sweep applies it on {P} (parent failed / proceeded); a second fail-deliver of the same child is a no-op;
  `@flow_deliver` byte-unchanged.
- **T4 — the ignored-failures read** (Req 4, `flows.ex`): `ignored_failures/3`. Gate: after an
  `ignore_dependency_on_failure` death, `ignored_failures/3` returns the child → its error; an empty parent
  returns `{:ok, %{}}`; `:processed`/`:unsuccessful` disjoint.
- **T5 — the conformance scenarios** (Req 6, `conformance.ex` + pins): `flow_fail_parent`/`flow_ignore_dep`/
  `flow_add_bulk` appended + probes + the count re-pinned 47 → 50. Gate: `Conformance.run/2` returns `{:ok, 50}`;
  both pins assert 50; the prior 47 byte-unchanged.
- **T6 — the proof** (Req 7): the `:valkey` suite + the ≥100 loop + the regression suites + the `@retry`/`@complete`/
  `@flow_deliver` byte-diffs + the declared-keys grep, then **Apollo MANDATORY**. Gate: all green; `@retry`
  only-added-lines (the dead-letter body byte-frozen); the failure branch + fail-emit keys all {C}, the
  fail-deliver keys all {P}; the ≥100 loop green; Apollo's BUILD-GRADE verdict.

**The EXACT files touched** (the boundary — `echo/apps/echo_mq` + NO `echo_wire`):
- `lib/echo_mq/flows.ex` (EDIT — the policy flags on `add/3`; the `parent_policy` field on the cross-queue child
  (`@enqueue_flow_child`); `add_bulk/3` NEW; `ignored_failures/3` NEW).
- `lib/echo_mq/jobs.ex` (EDIT — the additive `@retry` dead-letter failure branch (same-queue route + cross-queue
  fail-emit); the host `retry`/`parent_of` extension to read `parent_policy`; the existing dead-letter body
  `:254-259` + the schedule arm + `@complete` byte-frozen).
- `lib/echo_mq/pump.ex` (EDIT — the KIND dispatch in `deliver_flow_completions`/`split_entry`/`deliver_one`; the
  `@flow_fail_deliver` script; `@flow_deliver` byte-unchanged; `sweep/1`'s `delivered` counts both kinds).
- `lib/echo_mq/conformance.ex` (EDIT — `flow_fail_parent`/`flow_ignore_dep`/`flow_add_bulk` + their probes + the
  count re-pin).
- `test/flow_failure_test.exs` (NEW — `:valkey`).
- `test/conformance_run_test.exs` + `test/conformance_scenarios_test.exs` (EDIT — the count re-pin to 50).
- **UNTOUCHED:** `lib/echo_mq/keyspace.ex` (the `:failed`/`:unsuccessful` subkeys are §6-reserved and compose via
  the existing `job_key/2`; no grammar allowlist), `lib/echo_mq/admin.ex` (the lifecycle carry — B6/INV10),
  `@complete` (incl. the fan-in `:212-219` + cross-queue emit `:205-206`), `@flow_deliver` (`pump.ex:42`),
  `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child` script bodies, every other shipped `Script.new/2` body,
  `echo_wire`, `apps/echomq`, `docs/echo/mesh/**`.

## Agent stories (each a Directive + an Acceptance gate — the contract Apollo + the Director accept at)

- **AS1 — the failure-policy options + `add_bulk/3`.** *Directive:* extend `Flows.add/3` to accept per-child
  `fail_parent_on_failure` (default `true`) + `ignore_dependency_on_failure`; write `parent_policy` on each
  cross-queue child; add `add_bulk/3` (N flows, fail-closed per flow); gate every id at `Keyspace.job_key/2`.
  *Acceptance gate (precondition → postcondition → invariant):* GIVEN a flow with per-child policy → `add/3`
  records each policy (a cross-queue child's row carries `parent_policy`); `add_bulk/3` returns `{:ok,
  [{parent_id, [child_id]}]}` for N flows; INVARIANT: a flow that fails to land leaves its parent held
  (fail-closed per flow); an ill-formed id raises (INV4). Cite the spec line (D2) for the public contract.
- **AS2 — the same-queue failure propagation (the additive `@retry` branch).** *Directive:* add a branch to
  `@retry`'s dead-letter arm (AFTER the existing morgue transition) that, by the child's policy, fails the parent
  (`:failed` + `dead`) or satisfies-and-records (`:unsuccessful` + DECR + at-zero release); extend the host
  `retry`/`parent_of` to read `parent_policy` and supply the parent-fail keys. *Acceptance gate:* GIVEN a
  same-queue flow child dies → with `fail_parent_on_failure` the parent is `dead` + the child in `:failed`; with
  `ignore_dependency_on_failure` `:dependencies` is DECR'd + the child in `:unsuccessful` + at-zero released;
  INVARIANT: the existing dead-letter body (`:254-259`) + the schedule arm are BYTE-IDENTICAL (per-attr `git
  diff` shows only added lines — INV3); the branch fires only on host-supplied parent-fail keys (INV1); all keys
  on the dead child's slot (the declared-keys grep — INV2). Cite D3.
- **AS3 — the cross-queue fail-deliver (the `flow:outbox` fail-entry + `@flow_fail_deliver`).** *Directive:* in
  the `@retry` branch's cross-queue arm, RPUSH a fail-entry (a distinct KIND) into the child's own-slot
  `flow:outbox` atomically with the morgue transition; extend `split_entry`/`deliver_one` to dispatch by KIND; add
  `@flow_fail_deliver` (the `:failed`/`:unsuccessful` HSETNX guard on the parent's slot); `@flow_deliver`
  byte-unchanged. *Acceptance gate:* GIVEN a cross-queue child dies → the outbox holds one fail-entry for it AND
  it is in its own morgue (one EVAL, both effects — INV8); running the sweep fails/proceeds the parent on {P};
  INVARIANT: the parent is unchanged until the sweep (eventually-consistent — INV5/INV6); a re-delivered fail is a
  no-op (the parent failed/satisfied exactly once — INV7); every `@flow_fail_deliver` key is on the parent's slot,
  the fail-emit's keys all on the child's slot (INV2); `@flow_deliver` byte-unchanged (INV3). Cite D4.
- **AS4 — the ignored-failures read (`ignored_failures/3`).** *Directive:* add `ignored_failures/3` — a pure
  `HGETALL` of the parent's `:unsuccessful` subkey → `{:ok, %{child_id => error}}` (host-only, no script).
  *Acceptance gate:* GIVEN a parent whose flow ignored a failure → `ignored_failures/3` returns the ignored child
  → its error; an empty parent returns `{:ok, %{}}`; INVARIANT: `children_values/3` (`:processed`) and
  `ignored_failures/3` (`:unsuccessful`) are disjoint (INV6). Cite D6.
- **AS5 — the conformance scenarios + the count re-pin.** *Directive:* append `flow_fail_parent`/`flow_ignore_dep`/
  `flow_add_bulk` + their probes to `scenarios/0`; re-pin 47 → 50 in both pins + the docs; keep the prior 47
  byte-unchanged. *Acceptance gate:* `Conformance.run/2` returns `{:ok, 50}`; both pins assert 50; the
  `scenarios/0` `git diff` shows only additions; the probes exercise the fail-parent + the ignore-dep proceed +
  the bulk add (INV5, INV6, INV9). Cite D7.
- **AS6 — the proof + Apollo.** *Directive:* run the gate ladder (per-app compile warnings-as-errors; the
  `:valkey` failure suite; the ≥100 loop owning the machine; the regression suites; the `@retry`/`@complete`/
  `@flow_deliver` byte-diffs; the declared-keys/slot grep), then hand to **Apollo (MANDATORY)**. *Acceptance
  gate:* all green; `@retry` only-added-lines (the dead-letter body byte-frozen); `@complete`/`@flow_deliver`
  byte-unchanged; the failure branch + fail-emit keys all {C} + the fail-deliver keys all {P} (no cross-slot key
  — the F-1 trap); the ≥100 loop green; Apollo's BUILD-GRADE verdict + the byte-check. Cite D7, INV1, INV3.

## What NOT to do (the boundary + the no-invent guardrails)

- **Do NOT lift the v1 data-value key form.** The v1 child carries `parent_key = "#{queue_key}:#{job_id}"`
  (`flow_producer.ex:354`) and v1 scripts root keys in that data value. emq.3.4 does NOT: the host reads the
  child's `parent`/`parent_queue`/`parent_policy` fields HOST-SIDE and builds **declared** keys
  (`Keyspace.job_key(parent_queue, parent_id) <> ":failed"`/`":unsuccessful"`); every Lua key is `KEYS[n]` or a
  declared-root derivation (S-6 — INV2).
- **Do NOT mix slots in any script.** The same-queue failure branch touches ONLY the dead child's slot {C} (the
  parent is same-queue); the cross-queue fail-emit touches ONLY the child's slot {C} (the morgue keys + the
  outbox); `@flow_fail_deliver` touches ONLY the parent's slot {P}. The 6390 single-node engine will NOT raise on
  a cross-slot key — the review + the declared-keys grep is the gate (the F-1 trap).
- **Do NOT edit the existing `@retry` dead-letter body** (`jobs.ex:254-259`) or the schedule arm, `@complete`
  (incl. the fan-in `:212-219` + the cross-queue emit `:205-206`), `@flow_deliver` (`pump.ex:42`),
  `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child`, any other shipped `Script.new/2` body, `keyspace.ex`'s
  grammar, or `admin.ex`. The `@retry` edit is the ONE shipped script touched, and ONLY additively (a new branch
  AFTER the byte-frozen morgue transition).
- **Do NOT add a §6 key type or a grammar edit.** `:failed`/`:unsuccessful` are ALREADY §6-reserved
  (`emq.design.md:307`); their "registration" is the conformance scenarios, not a `keyspace.ex` allowlist edit
  (unlike emq.3.3's `flow:outbox`, which was a new `type`). INV1 holds by construction.
- **Do NOT claim "atomic across queues"** anywhere (code comment, doctest, scenario contract). The cross-queue
  failure is eventually-consistent (the sweep tick); the same-queue failure IS atomic. State both honestly
  (INV5/INV6, B1).
- **Do NOT build the OUT scope** — **grandchildren / deep recursion** (the recursive tree, multi-level fan-in —
  V-1 RULED → Arm A, D-2: the locked Out → emq.3.5, NOT this rung), the TTL auto-cancel of a stuck flow (emq.6),
  `remove_dependency` (the v1 third option — deferred), or the flow-subkey cleanup (the lifecycle rung). emq.3.4
  is the FLAT failure-policy + bulk only.
- **Run NO git** (the Director commits by pathspec at the rung's close). Per-app testing only
  (`TMPDIR=/tmp mix test` inside `echo/apps/echo_mq`; never umbrella-wide). Watch for the Operator's out-of-band
  `[emq]`/`docs/echo/mesh/**` commits — exclude them.

A short comprehensive prompt that leaves no decision the spec has not already fixed: the scope is RULED → Arm A
(D-2 — failure-policy + bulk; grandchildren the locked Out → emq.3.5), the failure mechanism is the
additive `@retry` dead-letter branch (the existing body byte-frozen) routing a same-queue death atomically and a
cross-queue death over the same `flow:outbox` + sweep emq.3.3 founded (idempotent by the `:processed`-class HSETNX
guard, now over `:failed`/`:unsuccessful`), the `:failed`/`:unsuccessful` subkeys are §6-reserved (no grammar
edit), the conformance grows 47 → 50, and the proof is the `:valkey` failure suite + the ≥100 loop + Apollo
MANDATORY. Build to the body; when the brief and the body disagree, the body wins.
