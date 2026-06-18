# EMQ.3.5 · agent brief — grandchildren / deep recursion (Mars's build brief)

> **✅ SHIPPED 2026-06-15 (NORMAL-risk, Arm A) — this brief drove the ship run; it is retained as the build record.**
> The spec body [`./emq.3.5.md`](emq.3.5.md) is **authoritative** + synced to the as-built; this brief derives from
> it — when they disagree, the body wins. **Framing (the propagation clause — carry it into any sub-brief):** third
> person for any agent reference; no gendered pronouns; no perceptual or interior-state verbs for agents or software
> (components **read**, **compute**, **refuse**, **return**, **emit**, **deliver**, **propagate**, **recurse**); no
> first-person narration. emq.3.5 was **the fifth and final flow sub-rung — closing it CLOSED Movement I**.
>
> **Risk: the risk TIER was a FORK (S1), decided by the recursive-failure-mechanism fork (S2) — RULED → NORMAL-risk.**
> Under the ruled arm (**S2 · Arm A — a host/sweep-orchestrated re-emit over the byte-frozen scripts**), emq.3.5
> edited **no shipped Lua script** → **NORMAL-risk** (Apollo the fast finisher, the emq.3.2 precedent + the 2026-06-15
> rebalance). The build held it: all 19 `Script.new/2` bodies byte-frozen (extract-and-diff against HEAD empty). **S2
> was ruled to Arm A before the build's risk tier was fixed.** This brief was authored to — and built to — Arm A.

## The forks — RULED (the recommended arms; the build held them)

The spec body §"The surfaced forks" surfaced **S1** (risk tier) / **S2** (recursive-failure mechanism, the
keystone) / **S3** (recursive-enqueue shape) + **S-Bound** (depth cap). **All RULED to the recommended arms** —
S2 · Arm A → S1 · NORMAL-risk, S3 · Arm A, S-Bound · 8 — and the build was performed to those rulings (every shipped
Lua byte-frozen). The arms below are retained as the build directive + the record of why each was chosen:

- **S2 · Arm A (RECOMMENDED) — the recursive failure hook is HOST/SWEEP-orchestrated over the byte-frozen
  failure machinery.** When a node is moved to `dead` (the `@retry` `sq:fp`/`xq:fp` arm `jobs.ex:286-302`, or the
  sweep's `@flow_fail_deliver` fp arm `pump.ex:79-84`), a **host/sweep** step re-emits the node's death to the
  node's own parent by the node's `parent_policy` (read HOST-SIDE via the reused `parent_fail_of/3:535`), over the
  **same** `@retry`/`@flow_fail_deliver`/`flow:outbox`+sweep machinery — **no shipped Lua script edited** (S1 ·
  NORMAL-risk). The natural trigger is the **sweep's fail-deliver itself**: when a fail-deliver moves a node to
  `dead` AND the node has a parent, the deliver loop re-emits the next hop's fail-entry (one more outbox push,
  drained on the next tick). **Build to this.**
- **S2 · Arm B (NOT recommended):** an additive in-script recursive emit on `@retry`/`@flow_fail_deliver` → edits a
  shipped script → S1 · HIGH-risk + Apollo MANDATORY. The body explains why Arm A is preferred (Arm B still needs
  the host to walk the ancestry — the parent's-parent ref is a DATA field, an A-1 violation to read in Lua — so it
  gains little while re-opening the most-scrutinized scripts). Do **NOT** edit a shipped script unless the Operator
  rules S2 · Arm B.
- **S3 · Arm A (RECOMMENDED) — the recursive enqueue is a CLAUSE of the existing `EchoMQ.Flows.add/3`** (a child
  spec may carry its own `:children`; a flat flow is the unchanged depth-1 case). **Build to this** (an S3 · Arm-B
  ruling re-scopes it to a separate `add_tree/3` verb).
- **S-Bound · 8 (RECOMMENDED) — the host caps recursion depth at 8 levels** (a typed depth-limit error on a deeper
  tree). Build to a small finite default of 8 (the Operator may set another value).

**The headline finding the build stands on (body §0, grounded against the as-built tree):** COMPLETION composes
recursively for FREE over the **byte-frozen** `@complete` — an intermediate node, when its children complete, is
released to `pending` by the existing fan-in (`jobs.ex:216-217`) as a REAL claimable job whose completion fans into
the root. So **emq.3.5 builds NO new completion script** (D3 is a proof, not a build). The **recursive failure
hook** (D4) is the **sole genuinely-new mechanism** — and under Arm A it is host/sweep-orchestrated over the
byte-frozen failure machinery.

## References (read first — links/paths first)

- **The spec body (authoritative):** [`./emq.3.5.md`](emq.3.5.md) — Goal · 5W · Scope (In/Out + the honest
  bounds B1–B7) · D1–D6 · INV1–INV11 · the surfaced forks S1/S2/S3/S-Bound · DoD.
- **The stories (the acceptance face):** [`./emq.3.5.stories.md`](emq.3.5.stories.md) — US1–US7 + US-GATE + the
  Coverage map.
- **This rung's ledger:** [`../progress/emq-3-5.progress.md`](../../progress/emq-3-5.progress.md) — A-1 (the headline
  design finding: completion composes for free; failure is the new design) + A-2 (the lag-1 reconcile delta — every
  flat-core anchor MATCHED on disk).
- **The family contract + the carve:** [`./emq.3.md`](../emq.3.md) — emq.3.5 is the **"grandchildren"** row of the
  carve (`:198`); the A-1-compatible flow design (§"The A-1-compatible flow design"); INV3 (byte-unchanged) + INV7
  (the cross-queue honesty); the surfaced-forks PATTERN (Arm 1/Arm 2 + costs + RECOMMENDATION) this triad
  replicates.
- **The shipped slices (the flat core emq.3.5 composes over — read all four):**
  [`./emq.3.1.md`](emq.3.1.md) (the same-queue atomic add, the `:dependencies`/`:processed` subkeys, the
  **byte-frozen** `@complete` fan-in branch, `awaiting_children`, the L-5 lifecycle carry) +
  [`./emq.3.2.md`](emq.3.2.md) (`children_values/3`/`dependencies/3`, the real-result `complete/5`, the N1 carry)
  + [`./emq.3.3.md`](emq.3.3.md) (the `flow:outbox` + `EchoMQ.Pump.sweep/1`'s `deliver_flow_completions` + the
  **byte-frozen** `@flow_deliver` + the `:processed` HSETNX idempotency guard + the `parent_queue` field + the B5
  carry — **the cross-queue completion mechanism the multi-level fan-in composes over**) +
  [`./emq.3.4.md`](emq.3.4.md) (the failure-policy + bulk: `parent_policy`, the **byte-frozen** `@retry`
  `sq:*`/`xq:*` failure arms + `@flow_fail_deliver`, `parent_fail_of/3`, `policy_arm/1`, `ignored_failures/3`, the
  `:failed`/`:unsuccessful` subkeys, `add_bulk/3` — **the failure machinery the recursive failure hook re-emits
  over, and the host tree-walk precedent**).
- **The as-built build target + the seams (RE-PROBE at Stage-0 — line numbers DRIFT, grep/Read to confirm; these
  are the emq.3.4 POST-build surface, the lag-1 law — a later rung between this spec and the build would move them
  again):**
  - `echo/apps/echo_mq/lib/echo_mq/flows.ex` — **`EchoMQ.Flows.add/3`** (`:181`, the module emq.3.5 **extends**
    with the nested-tree clause + the host depth-first tree walk — S3 · Arm A); `add_bulk/3` (`:218`, the
    fold-over-flows precedent the tree walk extends — N flows fail-closed per flow); `children_values/3` (`:261`)
    + `ignored_failures/3` (`:295`) + `dependencies/3` (`:332`) (the read API, unchanged); `policy_token/1`
    (`:359`, the both-flags-true→`'id'` resolver, reused per node); **`add_cross_queue/5`** (`:420`) +
    **`land_children/4`** (`:452`) — the host-orchestration the recursive enqueue **extends** (each non-leaf node
    is enqueued by this machinery; the host `HSET` of `parent`/`parent_queue`/`parent_policy` on the child row
    after the byte-frozen `@enqueue_flow_child` EVAL is the per-node link write); `add_same_queue/5` (`:374`).
    **`@enqueue_flow`** (`:39`) / **`@hold_parent`** (`:73`) / **`@enqueue_flow_child`** (`:98`) script bodies
    **BYTE-FROZEN, DO NOT EDIT** (the recursion is the host tree-walk over them).
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **`@complete`** (`:175`) with the fan-in branch (`:212-219`, the
    at-zero `ZADD p..'pending' 0 ARGV[4]` + `HSET KEYS[5] 'state','pending'` that releases an intermediate node as
    a real job) + the cross-queue emit branch (`:204-211`, gated `ARGV[6]=='xq'`) — **BYTE-FROZEN, DO NOT EDIT**
    (multi-level completion composes over it — D3); `complete/5` (`:456`); `parent_of/3` (`:503`, the
    `HMGET ... 'parent' 'parent_queue'` host read — **reused** for an intermediate node's completion fan-in);
    **`@retry`** (`:252`) the dead-letter arm (`:281-303`) with the failure branch (`:286-302` — the
    `sq:fp`/`sq:id`/`xq:fp`/`xq:id` arms on combined marker `ARGV[7]`, **the flat-core failure machinery**) —
    **BYTE-FROZEN under Arm A, DO NOT EDIT**; **`parent_fail_of/3`** (`:535`, the `HMGET ... 'parent'
    'parent_queue' 'parent_policy'` host read — **REUSED** to read an intermediate node's own ancestry for the
    recursive re-emit); `policy_arm/1` (`:559`, the `'fp'`/`'id'` defaulter, reused); `retry/7` (`:593`, the host
    wrapper — under Arm A unchanged as a script caller; the recursive re-emit is the sweep's job); **`@extend_locks`**
    (the A-1 slot-rooted-ARGV precedent `local jk = base .. 'job:' .. id` — the form every host-built node key
    follows, gated).
  - `echo/apps/echo_mq/lib/echo_mq/pump.ex` — **`@flow_deliver`** (`:42`, the complete-deliver — **BYTE-FROZEN, DO
    NOT EDIT**); **`@flow_fail_deliver`** (`:78`, the fail-deliver, all keys `{P}`, the HSETNX-guarded
    `fp`/`id` arms — **BYTE-FROZEN under Arm A; the recursive re-emit re-USES it for the next hop**); the
    **host re-emit (the recursive failure hook, NEW under Arm A) lives HERE** — when a fail-deliver moves a node to
    `dead` AND the node carries a parent, the deliver loop re-emits the next hop's fail-entry; **`deliver_one/2`**
    (`:254`, the per-entry deliver + KIND-dispatch — extended host-side to detect "node moved to `dead` + has a
    parent" and re-emit; the `@flow_fail_deliver` Lua unedited); **`deliver_flow_completions/3`** (`:205`, the
    drain loop); `sweep/1` (`:170`); `split_entry/1` (`:318`) + `split_fail_entry`/`split_complete_entry` (the
    KIND-dispatch by leading-empty-field tag — the existing fail-entry KIND the recursive re-emit reuses);
    `deliver_one(_,_)` fall-through (`:302`).
  - `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — **`queue_key/2`** (`:14`) + **`job_key/2`** (`:18`, gates
    `BrandedId.valid?/1`, **raises** — INV4). Every node's subkeys compose `Keyspace.job_key(q, node) <>
    ":dependencies"`/`":processed"`/`":failed"`/`":unsuccessful"` (the existing precedent); **NO grammar edit**,
    `keyspace.ex` is **UNEDITED** (every flow subkey is §6-reserved — `emq.design.md:307`).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — `scenarios/0` (a **keyword list**, **50** entries as-built;
    the last is `flow_add_bulk:` `:112`); APPEND `flow_grandchild:`, `flow_grandchild_fail:` + two `defp
    apply_scenario(...)` probes (model them on `flow_fanin` `:1067` for completion and `flow_fail_parent` `:1218`
    for failure — extended to THREE levels: a root → an intermediate node → a grandchild); the moduledoc/`run/2`
    doc "fifty"/`n == 50` → "fifty-two"/`n == 52`.
  - `echo/apps/echo_mq/lib/echo_mq/admin.ex` — `del_job` (`:152`, the **FIXED** `DEL jk, jk..':logs', jk..':lock'`)
    + `@drain`'s `wipe()` (`:90`, `DEL jk, jk..':logs'`) — **DO NOT EDIT** (the flow-subkey lifecycle carry is the
    emq.3.x rung's, deepened by the recursion but the same cleanup home — B6/INV10; `admin.ex` stays untouched).
  - The pin tests: `test/conformance_run_test.exs` (`{:ok, 50}` `:44` → `{:ok, 52}`) +
    `test/conformance_scenarios_test.exs` (`@run_order` + "fifty" → "fifty-two", append the two names).
- **The v1 capability reference (READ-ONLY — the SHAPE to PORT, the FORM not to lift):**
  `echo/apps/echomq/lib/echomq/flow_producer.ex` — the recursive **`build_flow_commands`** (`:238`, the depth-first
  tree walk — the SHAPE to re-derive host-side under v2) + `build_parent_node_commands` (`:334`, a non-leaf node
  enqueued as a parent) + the **reduce-over-children recursion** (`:364-374`, `Enum.reduce(children, …, fn child →
  build_flow_commands(child, parent_info_for_children, …))`); the documented **`grandchild` example** (`:40-56`:
  `parent_job`/`main_queue` → `child2`/`queue2` → `grandchild`/`queue3`); `add/2` (`:122`, the single recursive
  producer verb — the S3 · Arm A precedent) / `add_bulk/2` (`:183`); **the data-value `parent_key = "#{queue_key}:#{job_id}"`**
  (`:354`, threaded into `parent_info_for_children` `:356-362`) — **the form v2 does NOT lift at ANY level**: the
  host reads each node's `parent`/`parent_queue`/`parent_policy` fields HOST-SIDE and builds **declared** keys.
- **Design:** [`../emq.design.md`](../../../emq.design.md) §6 (the grammar — the flow subkeys `lock,logs,dependencies,
  processed,failed,unsuccessful` **ALL reserved** at `:305-308`; the recursion adds no key type; the per-level slot
  constraint), §11.10 (the flow design + the deferral, `:447-450`), S-6 (the A-1 declared-keys law — the
  slot-rooted-ARGV form), S-1/§6 (the braced keyspace — the per-level slot constraint), §5 (no new wire class,
  `:278`), §11.12 (the escalation protocol — the fork-surfacing law, `:457-459`). **Program law:**
  [`../../../.claude/skills/echo-mq-program.md`](../../../../../.claude/skills/echo-mq-program.md) (the v2 laws, the
  gate ladder, the additive-minor law, the ≥100 loop). **Surface map:**
  [`../../../.claude/skills/echo-mq-surface.md`](../../../../../.claude/skills/echo-mq-surface.md).

## Requirements (numbered; each traced back to a story, forward to an invariant/check)

> **All requirements below are authored to S2 · Arm A (NORMAL-risk, host/sweep-orchestrated) + S3 · Arm A (the
> unified `add/3` clause) + S-Bound · 8. Re-derive if the Operator rules otherwise — chiefly S2 · Arm B flips
> Req 4 to an additive shipped-script branch + HIGH-risk + Apollo MANDATORY.**

1. **The recursive enqueue — `EchoMQ.Flows.add/3` accepts a nested tree + the host depth-first tree walk** (US2,
   US5 → INV2, INV4, INV8, INV11). Extend `EchoMQ.Flows.add/3` (`flows.ex:181`) to accept a flow whose children may
   themselves carry `:children` (a nested tree; the leaf shape is the emq.3.4 child spec incl. the per-child failure
   policy). Walk the tree **depth-first HOST-SIDE** (re-derive the v1 `build_flow_commands` `flow_producer.ex:238`/
   `:364-374` under v2), enqueuing each **non-leaf** node as a flow-parent over its **direct** children by the
   **existing** admit machinery: a node whose whole subtree is same-queue → the byte-frozen `@enqueue_flow`; a node
   with any cross-queue child → the byte-frozen `@hold_parent` + `@enqueue_flow_child` (`add_cross_queue` /
   `land_children`). Each intermediate node lands **held** (`awaiting_children`, its `:dependencies` = its OWN
   direct-child count) AND, because it is a child of its parent, carries its own `parent`/`parent_queue`/
   `parent_policy` (the SAME host `HSET` / `@enqueue_flow_child` ARGV the flat family uses). **Validate the tree
   ACYCLIC (no node id twice) + within the DEPTH CAP (S-Bound · 8) BEFORE any wire** (raise a typed cycle /
   depth-limit error). Fail-closed **per node** (a node that fails to land leaves its subtree's parent held).
   Return a nested result mirroring the input (each node's minted id). Gate every node's id at `Keyspace.job_key/2`
   BEFORE the wire. **A flat flow (no nested `:children`) is the emq.3.1–3.4 path BYTE-FOR-BYTE unchanged** (a leaf
   is the base case). **The v1 data-value `parent_key` is NOT lifted at ANY level** (every link is the declared
   subkey + host-read fields — INV2).
2. **Multi-level completion — PROVEN to compose over the byte-frozen `@complete` (NOT built)** (US3 → INV5, INV3,
   INV1). Build **no new completion script**. An intermediate node, when its direct children complete, is released
   to `pending` by the **byte-frozen** `@complete` fan-in (`jobs.ex:212-219` same-slot / the sweep's `@flow_deliver`
   `pump.ex:42` cross-slot) as a REAL claimable job; claimed + processed + completed, its own `complete/5`
   (`:456`, reading its `parent`/`parent_queue` via `parent_of/3:503`) fans into the root. The build's obligation
   is the **proof** (the `flow_grandchild` scenario), not a mechanism — D3 exists to record that completion
   recursion is free and `@complete`/`@flow_deliver` stay byte-unchanged.
3. **(folded into Req 1)** — the recursive enqueue (Req 1) is what makes the tree multi-level; there is no separate
   "recursion enabler" beyond the host tree-walk.
4. **The recursive failure hook — the host/sweep re-emit (S2 · Arm A)** (US4 → INV6, INV7, INV2, INV1, INV3). When
   a node is moved to `dead` — its grandchild died under `fail_parent_on_failure` (the `@retry` `sq:fp`/`xq:fp` arm,
   or the sweep's `@flow_fail_deliver` fp arm moved it), or the node itself exhausted retries — **re-emit** the
   node's death to the node's own parent by the node's `parent_policy`. The re-emit is **host/sweep-orchestrated**
   over the **byte-frozen** failure machinery: the natural home is **`EchoMQ.Pump`'s deliver loop** (`pump.ex` —
   `deliver_one/2`/`deliver_flow_completions/3`): when a fail-deliver moves a node to `dead` AND the node carries a
   parent (read HOST-SIDE via the reused `parent_fail_of/3:535`), the loop re-emits the **next hop's** fail-entry —
   a **same-queue** parent's hop applied to the parent's same-slot subkeys (a host-issued `@flow_fail_deliver`-shape
   call, OR a direct same-slot emit), and a **cross-queue** parent's hop RPUSHed as a **fail-entry** (the existing
   KIND — leading-empty-field + `'fail'`, `pump.ex:299-301` shape) into the node's own-slot `flow:outbox`, delivered
   on the parent's slot by the existing sweep + byte-frozen `@flow_fail_deliver`. **Idempotent per hop** by the
   **same** `:failed`/`:unsuccessful` HSETNX-class guard (re-emit ONLY when THIS hop's `:failed`/`:unsuccessful`
   HSETNX succeeded — a re-delivered death that finds the node already recorded does NOT re-push a duplicate next-hop
   entry — INV7). **Eventually-consistent per hop** (each hop on the next sweep tick — a D-deep cross-queue failure
   reaches the root in ≈ D ticks; B1). Recurses up EVERY level (the node's parent's death, if it too is an
   intermediate node, re-emits to ITS parent — INV6). **Under Arm A the shipped `@retry`/`@flow_fail_deliver`/
   `@complete` Lua is BYTE-UNCHANGED** (the re-emit is host/sweep code — INV1/INV3). *(S2 · Arm B re-scopes this to
   an additive in-script branch on `@retry`/`@flow_fail_deliver` → HIGH-risk + Apollo MANDATORY.)*
5. **The deepened lifecycle disposition — NAMED, deferred** (US6 → INV10). Do **NOT** edit `admin.ex`. The spec
   body names the flow subkeys' cleanup home (both FIXED-list destructive sweeps + the owning emq.3.x lifecycle
   rung); the recursion populates the SAME subkeys at intermediate nodes (a deepened carry, NO new subkey type);
   emq.3.5's touch-set adds **zero** `DEL`/`HDEL`/`UNLINK` of a flow subkey; `admin.ex` is **untouched**.
6. **The conformance scenarios `flow_grandchild` / `flow_grandchild_fail`** (US7 → INV9). APPEND the two to
   `Conformance.scenarios/0` (`:112` is the current last, `flow_add_bulk`) + two `defp apply_scenario(...)` probes;
   the prior **50** scenarios byte-unchanged; re-pin the count **50 → 52** in **both** pinning tests + the
   moduledoc/`run/2` doc. The `flow_grandchild` probe adds a THREE-level flow (a root → an intermediate node → a
   grandchild), completes the grandchild, asserts the node released to `pending` (claimable; `dependencies/3` of
   the node == 0), claims + completes the node, asserts the root released (same-queue atomic; cross-queue per sweep
   tick — model on `flow_fanin` `:1067` extended a level). The `flow_grandchild_fail` probe adds a three-level flow
   all `fail_parent_on_failure`, kills the grandchild past max attempts, asserts the node `dead` with the grandchild
   in the node's `:failed` AND — the recursive hook — the root `dead` with the node in the root's `:failed` (model
   on `flow_fail_parent` `:1218` extended a level); a variant with `ignore_dependency_on_failure` at the top hop →
   the root proceeds; a double re-deliver → a no-op (INV6, INV7).
7. **The proof** (US7 + US-GATE → INV1, INV2, INV3, INV5, INV6, INV9, INV11). The `:valkey` recursion suite green
   per-app (`TMPDIR=/tmp mix test --include valkey` inside `echo/apps/echo_mq`): multi-level completion + multi-level
   failure under each policy, same-queue AND cross-queue. The **≥100 determinism loop** green for the mint-dense
   recursion scenario (a recursive flow mints one branded `JOB` id per node across many queues — the same-ms mint
   hazard at its most exposed, B5 — owning the machine). The emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3,4} suites +
   `Conformance.run/2` pass unchanged (no regression — INV3). **Under Arm A: a per-attr `git diff` of every
   `@… Script.new/2` body in `jobs.ex` + `flows.ex` + `pump.ex` is EMPTY** (zero Lua-body changes — INV1/INV3). A
   **declared-keys grep** over the recursive enqueue + the failure re-emit confirms every flow script at every level
   touches keys of exactly one slot (the F-1 cross-slot trap the 6390 single-node engine will NOT catch — INV2).
   Honest-row reporting (Valkey on 6390). **Apollo's mandatoriness is set by S1** (NORMAL-risk under Arm A → a fast
   finisher; HIGH-risk under Arm B → MANDATORY + the byte-proof).

## Execution topology

**Runtime shape (the recursive flow, end to end — Arm A):**
1. **Add** (host, `Flows.add/3` nested-tree clause): the host walks the tree depth-first, enqueuing each non-leaf
   node as a flow-parent over its direct children by the existing admit machinery (same-queue atomic; cross-queue
   host-orchestrated parent-first); each intermediate node lands held with its own `:dependencies` AND carries its
   own `parent`/`parent_queue`/`parent_policy`; the tree validated acyclic + within the depth cap before any wire.
2. **Work + complete bottom-up** (worker + pump): a grandchild completes → the **byte-frozen** `@complete` fan-in
   (same-slot, or the sweep's `@flow_deliver` cross-slot) releases the intermediate node to `pending` as a REAL
   job → the node is claimed + processed + completed → its own `@complete` fans into the root → the root released.
   (Completion recursion is FREE — D3.)
3. **Work + fail up every level** (worker + pump, the recursive failure hook — D4/Arm A): a grandchild dies → the
   byte-frozen `@retry`/`@flow_fail_deliver` moves the intermediate node to `dead` (the emq.3.4 one-level
   propagation) → the **host/sweep deliver loop** detects the node moved to `dead` AND carries a parent → re-emits
   the node's death to the node's parent by the node's policy (same-queue applied to the parent's same-slot subkeys;
   cross-queue RPUSHed as a fail-entry into the node's own-slot outbox) → the next sweep tick delivers it on the
   parent's slot via the byte-frozen `@flow_fail_deliver` → recurse up to the root. (Eventually-consistent per hop;
   idempotent per hop by the HSETNX guard.)
4. **Consume** (any node's handler, emq.3.2 + emq.3.4): a released node reads `children_values/3` (its completed
   children's results) AND `ignored_failures/3` (its ignored children's errors) — at every level.

**The build-order DAG (each step gated before the next):**
- **T1 — the recursive enqueue** (Req 1, `flows.ex`): the nested-tree clause on `add/3` + the host depth-first tree
  walk + the acyclic/depth validation. Gate: a three-level flow lands (each intermediate node held with its own
  `:dependencies`, carrying its own `parent`/`parent_queue`/`parent_policy`); a flat flow is byte-for-byte unchanged
  (the flat scenarios pass); an ill-formed id raises; a cyclic / over-depth tree raises before any wire. (Completion
  recursion is already live the instant the tree is multi-level — the byte-frozen `@complete` does it.)
- **T2 — multi-level completion PROVEN** (Req 2, the `flow_grandchild` scenario): no code beyond T1 — the proof that
  the byte-frozen `@complete`/`@flow_deliver` releases an intermediate node and then the root. Gate: the
  `flow_grandchild` scenario green (grandchild completes → node released to `pending` → node completed → root
  released); `@complete`/`@flow_deliver` byte-unchanged.
- **T3 — the recursive failure hook** (Req 4, `pump.ex` host re-emit): the deliver loop re-emits a dead node's
  death to its own parent by the node's policy, over the byte-frozen failure machinery; idempotent per hop. Gate: a
  three-level `fail_parent_on_failure` flow — the grandchild's death fails the node, the node's death is re-emitted
  and fails the root; the `ignore_dependency_on_failure` top-hop variant lets the root proceed; a double re-deliver
  is a no-op; under Arm A every shipped Lua body is byte-unchanged (the per-attr `git diff` empty).
- **T4 — the conformance scenarios** (Req 6, `conformance.ex` + pins): `flow_grandchild`/`flow_grandchild_fail`
  appended + probes + the count re-pinned 50 → 52. Gate: `Conformance.run/2` returns `{:ok, 52}`; both pins assert
  52; the prior 50 byte-unchanged.
- **T5 — the proof** (Req 7): the `:valkey` recursion suite + the ≥100 loop + the regression suites + (Arm A) the
  empty Lua `git diff` + the declared-keys grep, then Apollo (mandatoriness per S1). Gate: all green; under Arm A
  zero Lua-body changes; every flow script's keys single-slot at every level; the ≥100 loop green; Apollo's verdict.
- **T6 — Movement I CLOSED** (the DoD's final box): the body + the dashboard record the flow family parity-complete;
  Movement II (emq.4–emq.8) opens.

**The EXACT files touched** (the boundary — `echo/apps/echo_mq` + NO `echo_wire`; Arm A):
- `lib/echo_mq/flows.ex` (EDIT — the nested-tree clause on `add/3` + the host depth-first tree walk + the
  acyclic/depth validation; `add_same_queue`/`add_cross_queue`/`land_children` reused per node).
- `lib/echo_mq/pump.ex` (EDIT under Arm A — the host recursive re-emit in `deliver_one/2`/`deliver_flow_completions/3`:
  on moving a node to `dead`, re-emit the next hop's fail-entry by the node's policy, idempotent per hop; the
  `@flow_fail_deliver` + `@flow_deliver` Lua **byte-unchanged**).
- `lib/echo_mq/conformance.ex` (EDIT — `flow_grandchild`/`flow_grandchild_fail` + their probes + the count re-pin
  50 → 52).
- `test/flow_recursion_test.exs` (NEW — `:valkey`).
- `test/conformance_run_test.exs` + `test/conformance_scenarios_test.exs` (EDIT — the count re-pin to 52).
- **UNTOUCHED (Arm A):** `lib/echo_mq/jobs.ex`'s shipped scripts — `@complete` (incl. the fan-in `:212-219` +
  cross-queue emit `:204-211`), `@retry` (incl. the dead-letter arm `:281-303` + the failure branch `:286-302`),
  every other `Script.new/2` body (the recursive failure hook reads `parent_fail_of/3` host-side, edits no Lua);
  `lib/echo_mq/flows.ex`'s scripts `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child` bodies; `pump.ex`'s
  `@flow_deliver`/`@flow_fail_deliver` bodies; `lib/echo_mq/keyspace.ex` (every flow subkey §6-reserved, composes
  via the existing `job_key/2`); `lib/echo_mq/admin.ex` (the lifecycle carry — B6/INV10); `echo_wire`,
  `apps/echomq`, `apps/mercury*`, `docs/echo/{art,mesh}/**`, `html/` (and **never** `html/ru/`).
  *(Under S2 · Arm B, `jobs.ex` + `pump.ex` gain an additive `@retry`/`@flow_fail_deliver` recursive branch → the
  shipped-script edit + HIGH-risk + Apollo MANDATORY.)*

## Agent stories (each a Directive + an Acceptance gate — the contract Apollo + the Director accept at)

- **AS1 — the recursive enqueue (`add/3` nested-tree clause + the host tree walk).** *Directive:* extend
  `Flows.add/3` to accept a nested tree (S3 · Arm A); walk it depth-first host-side, enqueuing each non-leaf node as
  a flow-parent over its direct children by the existing admit machinery, each intermediate node held with its own
  `:dependencies` AND carrying its own `parent`/`parent_queue`/`parent_policy`; validate the tree acyclic + within
  the depth cap (S-Bound · 8) before any wire; gate every node's id at `Keyspace.job_key/2`. *Acceptance gate
  (precondition → postcondition → invariant):* GIVEN a three-level flow → each intermediate node lands held
  (`awaiting_children`, its own `:dependencies` = its direct-child count, carrying its own `parent`/`parent_queue`/
  `parent_policy`); a flat flow is byte-for-byte unchanged (the flat scenarios pass); INVARIANT: the v1 data-value
  `parent_key` is NOT lifted at any level (every link is the declared subkey + host-read fields — INV2); an
  ill-formed id raises (INV4); a cyclic / over-depth tree raises before any wire (INV8). Cite D2.
- **AS2 — multi-level completion (proven, no new script).** *Directive:* build NO completion script; record the
  proof that the byte-frozen `@complete` fan-in releases an intermediate node to `pending` (a real job) whose
  completion fans into the root. *Acceptance gate:* GIVEN a three-level flow → the grandchild completes → the node
  is released to `pending` (claimable; node `dependencies/3` == 0; row `pending`) → the node is completed → the root
  is released; INVARIANT: `@complete` + `@flow_deliver` are byte-unchanged (INV3, INV1); completion propagates up
  every level (INV5). Cite D3.
- **AS3 — the recursive failure hook (the host/sweep re-emit — S2 · Arm A).** *Directive:* in `EchoMQ.Pump`'s
  deliver loop, when a fail-deliver moves a node to `dead` AND the node carries a parent (read host-side via
  `parent_fail_of/3`), re-emit the next hop's death to the node's parent by the node's policy over the byte-frozen
  failure machinery (same-queue applied to the parent's same-slot subkeys; cross-queue RPUSHed as a fail-entry into
  the node's own-slot outbox); idempotent per hop (re-emit only when this hop's `:failed`/`:unsuccessful` HSETNX
  succeeded); the shipped Lua byte-unchanged. *Acceptance gate:* GIVEN a three-level `fail_parent_on_failure` flow →
  the grandchild's death fails the node, the node's death is re-emitted and fails the root (the node in the root's
  `:failed`); GIVEN an `ignore_dependency_on_failure` top hop → the root proceeds (the node in the root's
  `:unsuccessful`, `:dependencies` DECR'd); INVARIANT: a re-delivered death propagates exactly once (the HSETNX
  guard — INV7); cross-queue propagation is eventually-consistent per hop (never synchronous, never "atomic across
  queues" — B1/INV6); under Arm A every shipped Lua body is byte-unchanged (the per-attr `git diff` empty — INV1/
  INV3); every flow script's keys single-slot at every level (the declared-keys grep — INV2). Cite D4.
- **AS4 — the deepened lifecycle disposition (NAMED, deferred).** *Directive:* do NOT edit `admin.ex`; the body
  names the flow subkeys' cleanup home (both FIXED-list sweeps + the owning emq.3.x rung) and records that the
  recursion deepens the population (more nodes hold them) with no new subkey type. *Acceptance gate:* GIVEN the
  recursion populates the flow subkeys at intermediate nodes → the body names their cleanup home; INVARIANT:
  emq.3.5's touch-set adds no `DEL`/`HDEL`/`UNLINK` of a flow subkey; `admin.ex` is untouched (INV10). Cite D5.
- **AS5 — the conformance scenarios + the count re-pin.** *Directive:* append `flow_grandchild`/`flow_grandchild_fail`
  + their probes to `scenarios/0`; re-pin 50 → 52 in both pins + the docs; keep the prior 50 byte-unchanged.
  *Acceptance gate:* `Conformance.run/2` returns `{:ok, 52}`; both pins assert 52; the `scenarios/0` `git diff`
  shows only additions; the probes exercise multi-level completion + multi-level failure (each policy) + a double
  re-deliver no-op (INV5, INV6, INV7, INV9). Cite D6.
- **AS6 — the proof + Apollo.** *Directive:* run the gate ladder (per-app compile warnings-as-errors; the `:valkey`
  recursion suite; the ≥100 loop owning the machine; the regression suites; under Arm A the per-attr empty Lua
  `git diff`; the declared-keys/slot grep at every level), then hand to Apollo (mandatoriness per S1). *Acceptance
  gate:* all green; under Arm A zero Lua-body changes (the per-attr `git diff` empty — INV1/INV3); every flow
  script's keys single-slot at every level (no cross-slot key — the F-1 trap — INV2); the ≥100 loop green over the
  mint-dense recursion (B5); Apollo's verdict (BUILD-GRADE; MANDATORY iff S1 · HIGH-risk under Arm B); the body +
  dashboard record **Movement I CLOSED**. Cite D6, INV1, INV3, INV11.

## What NOT to do (the boundary + the no-invent guardrails)

- **Do NOT lift the v1 data-value key form at ANY level.** The v1 recursion threads `parent_key = "#{queue_key}:#{job_id}"`
  (`flow_producer.ex:354`) into each child's `parent_info` and v1 scripts root keys in that data value. emq.3.5 does
  NOT — at EVERY level the host reads the node's `parent`/`parent_queue`/`parent_policy` fields HOST-SIDE and builds
  **declared** keys (`Keyspace.job_key(parent_queue, parent_id) <> ":failed"`/`":unsuccessful"`/etc.); every Lua key
  is `KEYS[n]` or a declared-root derivation (S-6 — INV2). The recursion is a HOST tree-walk + a HOST re-emit, not
  a deeper Lua.
- **Do NOT mix slots in any script at any level.** Each same-queue subtree's flow script touches keys of exactly one
  slot; each cross-queue boundary is host-orchestrated parent-first (separate one-slot EVALs); `@flow_fail_deliver`
  touches ONLY the parent's slot {P}; a cross-queue fail-emit touches ONLY the node's slot {C}. The 6390 single-node
  engine will NOT raise on a cross-slot key — the review + the declared-keys grep is the gate, RE-ASSERTED per hop
  (the F-1 trap — INV2/B4).
- **Do NOT edit a shipped Lua script under Arm A.** `@complete` (incl. the fan-in `:212-219` + the cross-queue emit
  `:204-211`), `@retry` (incl. the dead-letter arm `:281-303` + the failure branch `:286-302`), `@flow_deliver`
  (`pump.ex:42`), `@flow_fail_deliver` (`pump.ex:78`), `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child`, any
  other `Script.new/2` body, `keyspace.ex`'s grammar, `admin.ex` — ALL byte-frozen. The recursion is host/sweep
  code (the re-emit reads `parent_fail_of/3` host-side and reuses the existing fail-entry KIND + `@flow_fail_deliver`).
  **Only if the Operator rules S2 · Arm B** does `@retry`/`@flow_fail_deliver` gain an additive recursive branch
  (then HIGH-risk + Apollo MANDATORY + the only-added-lines byte-proof).
- **Do NOT build a completion mechanism** (D3 is a PROOF, not a build — the byte-frozen `@complete` composes
  recursively for free; §0's finding).
- **Do NOT support a re-converging DAG** (a node with two parents) — the input contract is a finite acyclic TREE
  (the v1 contract too — B-Out, INV8); validate acyclicity host-side and raise on a cycle.
- **Do NOT add a §6 key type, a wire class, or a transport.** Every node's subkeys are §6-reserved; the failure
  re-emit reuses the existing fail-entry KIND; the connector `eval`/`pipeline` carries the recursion (INV1).
- **Do NOT touch the boundary's outside.** `echo_wire`, `apps/echomq` (the v1 reference — READ-ONLY),
  `apps/mercury*`, `docs/echo/{art,mesh}/**`, the repo-root `html/` (and **never** `html/ru/`). Agents run **no
  git**; the Director commits by pathspec at the rung's close. Per-app testing only; `TMPDIR=/tmp`; Valkey on 6390;
  erlang re-probed from the app dir.
