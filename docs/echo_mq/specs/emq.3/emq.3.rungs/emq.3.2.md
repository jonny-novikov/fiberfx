# EMQ.3.2 · The child-result reads — the second sub-rung (Movement I, the flow family)

> **Status: SHIPPED 2026-06-15 at CONFORMANCE 46/46** (the SECOND sub-rung of the emq.3 parent/flow family — the
> family contract + the carve + the forks are [`./emq.3.md`](../../emq.3.md); the first slice
> [`./emq.3.1.md`](emq.3.1.md) SHIPPED 2026-06-15 at CONFORMANCE 45/45). emq.3.2 carved the **child-result
> reads** — the host API a flow's parent handler reads its children's outcomes through:
> `EchoMQ.Flows.children_values/3` over the parent's `:processed` subkey and `EchoMQ.Flows.dependencies/3` over
> the parent's `:dependencies` counter (the v1 `get_children_values` / `get_dependencies` parity). It **closed
> the emq.3.1 honest bound O1** (the `:processed` value is now a **real result**, not a `child_id → child_id`
> presence marker) by extending the flow child's completion to carry a result — passed through the **EXISTING
> `ARGV[5]` slot** emq.3.1 already wired, so **the shipped `@complete` Lua is BYTE-UNCHANGED** (only the host
> `complete` wrapper extended, `complete/4` → `complete/5` with `result \\ nil`). The v1 line
> (`apps/echomq/lib/echomq/flow_producer.ex` / `echomq/job.ex` `get_children_values`/`get_dependencies`) is a
> **capability reference** — the behaviour ported, NEVER the form lifted. **Risk: NORMAL** — emq.3.2 edited
> **no shipped Lua script** (R1·B touched only the host signature + two pure reads), so no dedicated Apollo
> evaluator was required (the Director's solo review + the gate ladder were the gate); the ≥100 determinism
> loop ran over the mint/process-touching flow read suite (120/120 green). The forks were ruled **R1·B + R2·A**
> ([`./emq.3.md`](../../emq.3.md) — the recommended arms this triad was authored to).

## 0 · The slice — what emq.3.2 carves, and why second

emq.3.1 founded the single-queue flow: the parent → child dependency graph rides **declared §6 subkeys of the
parent** (`emq:{q}:job:<parent>:dependencies` the outstanding-child STRING counter, `…:processed` the
completed-children HASH), the parent held out of `pending` until fan-in, the fan-in hook on `@complete`
recording each completing child in `:processed`. But emq.3.1 is **write-side only**: it *writes* `:processed`
(as a **presence marker** — `child_id → child_id`, because `complete/4` carries no result argument, the honest
bound **O1**) and it adds **no read API**. A parent handler cannot yet read what its children produced — the
half of the v1 flow contract a fan-in consumer actually consumes (`get_children_values` / `get_dependencies`).

emq.3.2 is that second half: the **read API** over the subkeys emq.3.1 writes, **plus** the completion change
that makes `:processed` carry a **real result** instead of a placeholder (closing O1). It is the **second**
sub-rung because the read is meaningless until a flow can be added and fanned in (emq.3.1), and it stays inside
the **single-queue** carve (the cross-queue read — a parent reading children on a different slot — is part of
the emq.3.3 cross-queue crossing, the honest **Out**). The smallest coherent slice that makes a flow's result
**consumable** within one queue.

## Goal

emq.3.2 builds, inside `echo/apps/echo_mq`, the **child-result reads** for a single-queue flow:
(1) **`EchoMQ.Flows.children_values/3`** — returns the completed children's **results** keyed by child id,
reading the parent's `emq:{q}:job:<parent>:processed` HASH (a pure `HGETALL`-class read);
(2) **`EchoMQ.Flows.dependencies/3`** — returns the parent's **outstanding-child count**, reading the parent's
`emq:{q}:job:<parent>:dependencies` STRING counter (a pure `GET`-class read);
(3) **the real-result-carrying completion** (Fork R1·B) — `EchoMQ.Jobs.complete/4` gained a **result argument**
(`complete/5` with `result \\ nil`, `jobs.ex:365`) passed through the **existing `ARGV[5]` slot** the emq.3.1
fan-in hook already `HSET`s into `:processed` (`jobs.ex:183`), so `:processed[child_id]` holds the **real
result** the child produced — **the shipped `@complete` Lua body is byte-unchanged**, only the host `complete`
wrapper extended, and the **non-flow completion is byte-unchanged** (the `nil` default sends `ARGV[5] = job_id`,
the emq.3.1 presence marker; a non-flow job has `KEYS[3]` nil, the fan-in branch unreached);
(4) the conformance scenario `flow_children_values` (additive minor, `45 → 46`), the prior set byte-unchanged;
(5) the `:valkey` read suite (the mint/process-touching read scenario under the ≥100 determinism loop).
The flow subkeys' **lifecycle/cleanup is a NAMED CARRY** to the emq.3.x lifecycle rung (D5) — emq.3.2 reads the
subkeys, it does not retire them. The shipped `@enqueue`/`@claim`/`@complete` **Lua** is **untouched**; the
shipped `@enqueue_flow` is **untouched**; `apps/echomq` is **untouched** (the capability reference).

## Rationale (5W)

- **Why** — emq.3.2 makes a flow's outcome **consumable**: until a parent handler can read its children's
  results, the flow family delivers fan-in (the parent runs after the children) but not **fan-in with a
  payload** (the parent runs *on* what the children produced) — the second half of the v1 `flow_producer`
  contract (`get_children_values` is the documented parent-handler call,
  `echo/apps/echomq/lib/echomq/flow_producer.ex:64`). It also **closes emq.3.1's honest bound O1**: emq.3.1
  shipped `:processed` as a deliberate placeholder, naming the real-result write as emq.3.2's (emq-3-1 L-3);
  emq.3.2 discharges that named obligation. It is the **smallest** rung that does so, and the **cheapest**: the
  emq.3.1 fan-in hook already `HSET`s `ARGV[5]` into `:processed`, so the real result rides the seam already
  built — **no Lua change**.
- **What** — emq.3.2 builds two **pure read** functions on `EchoMQ.Flows` (`children_values/3`,
  `dependencies/3`) and one **host-side completion extension** (`EchoMQ.Jobs.complete` gains a result argument
  threaded into the existing `ARGV[5]` slot), plus the `flow_children_values` conformance scenario and the
  `:valkey` read suite. **Authored to Fork R1·B** (the real-result-carrying completion) and **Fork R2·A** (the
  `dependencies/3` outstanding **count**).
- **Who** — the program (the rung that makes single-queue flows result-consumable and closes O1); the bus's
  consumers, who gain `children_values` / `dependencies` (the parent handler reads what its legs produced, the
  v1 surface); the conformance harness, which grows by `flow_children_values` (additive minor). **codemoji**
  (prospective): a same-queue parent that aggregates its child legs' results — *it names no flows today*
  ([`../emq.features.md`](../../../emq.features.md) — recorded, not asserted).
- **When** — Movement I, the flow family's **second** sub-rung, after emq.3.1 shipped (emq.3.2 reads the
  `:processed`/`:dependencies` subkeys emq.3.1 writes; it extends the `complete`/`ARGV[5]` seam emq.3.1 built).
  SPECCED this design cycle; **built only after the Operator rules Fork R1** (the real-result-carrying
  completion is the recommended arm; an R1·A ruling narrows emq.3.2 to a pure presence read before the build).
  Fork R2 is a cheap representation choice (surface, optionally rule).
- **Where** — `echo/apps/echo_mq` only: `flows.ex` (EDIT — `children_values/3` + `dependencies/3`, two pure
  reads), `jobs.ex` (EDIT — **host only**: `complete` gains a result argument, threaded into the existing
  `ARGV[5]`; the `@complete` **Lua attribute is byte-unchanged**, D3), `conformance.ex` (EDIT —
  `flow_children_values` + the count re-pin), `test/flow_children_values_test.exs` (NEW — `:valkey`), the two
  pinning tests (EDIT — the count). `echo_wire` is **untouched** (the reads ride the shipped connector
  `command`/`eval` — no new transport, no new connector verb). `apps/echomq` is **untouched**. The §6 grammar
  in `keyspace.ex` is **unedited** (the read keys are the already-registered `:processed`/`:dependencies`
  subkeys emq.3.1 composes). Exact line anchors pinned at the pre-build reconcile (the lag-1 law — emq.3.1
  moved the surface).

## Scope

- **In** — the single-queue child-result reads: (1) `EchoMQ.Flows.children_values/3` (a pure read of the
  parent's `:processed` HASH → the completed children's results keyed by child id); (2)
  `EchoMQ.Flows.dependencies/3` (a pure read of the parent's `:dependencies` STRING counter → the outstanding
  count, Fork R2·A); (3) the **real-result-carrying completion** (Fork R1·B): `EchoMQ.Jobs.complete` gains a
  result argument passed through the existing `ARGV[5]` slot, so `:processed[child_id]` holds the real result
  (closing O1) — **the `@complete` Lua byte-unchanged**, the non-flow completion byte-unchanged; (4)
  `flow_children_values` conformance (additive minor, the prior count byte-unchanged); (5) the `:valkey` read
  suite; the mint/process-touching read scenario under the **≥100-iteration determinism loop**; honest-row
  reporting (Valkey on 6390 the truth row).
- **Out** — the **cross-queue read** (a parent reading children that ran on a *different* slot — part of the
  **emq.3.3** cross-queue crossing, gated on Fork A); the **deep-recursive** result aggregation (a child that
  is itself a parent of grandchildren — emq.3.1 built one parent level; the recursive read is settled with the
  recursive write at emq.3.3/3.4, recorded NOT built here); the **failure-policy reads** (reading `:failed` /
  `:unsuccessful` — those subkeys arrive with `fail_parent_on_failure` / `ignore_dependency_on_failure` at
  **emq.3.4**; emq.3.2 reads `:processed` / `:dependencies` only); **`add_bulk`** (**emq.3.4**); the
  **flow-subkey CLEANUP/lifecycle** (the `obliterate`-sweep of `:dependencies`/`:processed` + the per-flow
  completion cleanup — a **NAMED CARRY** to the emq.3.x lifecycle rung, D5 + the honest bounds below; emq.3.2
  **reads** the subkeys, it does not retire them); the **O2 perf fold** (folding the `parent_of` `HGET` into
  the claim result — a *correctness-neutral* follow-up emq.3.2 **may** take since it touches the claim/complete
  host path, see the honest bounds — but it is **not required** and is **out of the read API's stated scope**);
  any **edit to a shipped Lua script** (`@enqueue`/`@claim`/`@complete`/`@enqueue_flow` — none; R1·B is
  host-only); any **new key type** or **new wire class** (none); any **`echo_wire`/transport** change; any
  **edit to the frozen v1 line**.

### The honest bounds + carried follow-ups (surfaced at authoring — recorded, not papered over)

emq.3.2 ships the single-queue child-result **reads** + the O1-closing real result; these are its honest
bounds, each a **correct-for-scope** limit, never a defect:

- **N1 — the flow-subkey lifecycle is STILL a carry (the §2 guardrail, named not discharged).** emq.3.2 READS
  `:processed`/`:dependencies`; per emq.3.1 L-5 they **outlive** the parent row (`@complete` `DEL`s only the row
  `KEYS[2]`, `jobs.ex:189`). **TWO** `Admin`-surface destructive sweeps enumerate a **FIXED** subkey list that
  **excludes** the flow subkeys, so the subkeys survive both: (a) `obliterate`'s `del_job` — `DEL jk`/`:logs`/`:lock`
  (`admin.ex:152`); (b) `@drain`'s `wipe()` — `DEL jk`/`:logs` (`admin.ex:90`, a two-key list, no `:lock`). This
  is **correct** for emq.3.2's read scope (the reads need the subkeys to exist). The cleanup disposition is
  **NAMED** (D5): (1) the destructive-sweep extension — **both** `del_job` (`admin.ex:152`) **and** `wipe()`
  (`admin.ex:90`) gain `:dependencies`/`:processed` in their enumerated `DEL` lists; (2) per-flow completion
  cleanup (the parent retiring its own subkeys once it has read `children_values` and completed) — **both routed
  to the emq.3.x lifecycle rung**, each would re-tier emq.3.2 out of NORMAL-risk (the per-flow cleanup edits the
  shipped `@complete` Lua → HIGH-RISK; the sweep extension is an `Admin`-surface change beyond a read rung's
  boundary). **NAMED, NOT left to discover (the L-5 lesson) — and NOT folded here.** The emq.3.1 `admin.ex`
  obliterate-moduledoc carry (a one-line honest-bound note **when** the lifecycle rung lands) is **re-affirmed**
  (`admin.ex` untouched here — re-verified clean).
- **N2 — O2 (the `parent_of` `HGET` per completion) was the optional fold; the build DECLINED it.** emq.3.1's
  O2: `complete` does one host-side `HGET <child> 'parent'` on **every** completion (flow or not, `parent_of/3`,
  `jobs.ex:397-405`). emq.3.1 L-4 named emq.3.2 as the rung that *could* fold the parent-read into the claim
  result (the worker already holds the row). emq.3.2 **declined** the fold (correctness-neutral and out of the
  read API's stated scope): the build kept the result arg + the two reads only, so `parent_of/3` stays a
  separate `HGET` and **the claim path was never touched** (the N2 decision Mars recorded — the fold expands the
  surface to the claim path for no correctness gain). O2 therefore **remains an open carry** to whichever rung
  wants the per-completion round-trip removed. **Not a deliverable; declined this rung.**
- **N3 — single-queue + one-level only.** emq.3.2's reads are the single-queue, one-level shape (the parent
  reads same-slot children's `:processed`). A cross-queue parent (children on another slot — emq.3.3) and a
  deep tree (grandchildren — emq.3.3/3.4) are **Out**; emq.3.2 does not pre-empt them.

## Deliverables

emq.3.2 builds (forward-named; the read API does not yet exist in `EchoMQ.Flows` — Stage-0 confirmed the
CLEAN SLATE: no `children_values`/`dependencies` symbol in `flows.ex`):

- **EMQ.3.2-D1 — the fork gate (FIRST):** Fork **R1** ([`./emq.3.md`](../../emq.3.md) the family + **V-1** in this
  rung's ledger) **settled by the Operator** before any build artifact — Arm B (the real-result-carrying
  completion; the carve this triad is authored to) vs Arm A (a pure presence read, no completion change).
  Recorded BEFORE any build story runs (the cluster precedent — the fork gate is the relocated gate). Fork
  **R2** (the `dependencies/3` count vs set — **V-2**) recorded with its recommendation (the **count**) — a
  cheap representation choice, surfaced for the Operator's optional ruling, **but note R2·B is NOT free** (it
  adds a `:children` roster subkey + an `@enqueue_flow` edit — a pre-build write-surface add, unlike R1·A→B
  which is a free narrowing). The triad re-derives to the ruled arms at the pre-build reconcile.
- **EMQ.3.2-D2 — `EchoMQ.Flows.children_values/3` (the result read):** a pure read
  `children_values(conn, queue, parent_id) :: {:ok, %{child_id => result}} | {:error, term()}` reading the
  parent's `:processed` HASH (composed `Keyspace.job_key(queue, parent_id) <> ":processed"`, the `add_log`
  `<> ":logs"` precedent, `jobs.ex:458`) via the shipped connector (`HGETALL`-class). The `parent_id` is gated
  at `Keyspace.job_key/2` (raises on an ill-formed id — INV4) BEFORE the wire. Returns the completed children
  keyed by child id, each value the **real result** the child carried at completion (R1·B shipped); a child
  completed through the shipped `complete/4` arity (no result) records the emq.3.1 presence marker (its own id)
  instead. A parent with no completed children yet returns `{:ok, %{}}`. **A pure read** — no write, no state
  transition (INV2). *As built:* `EchoMQ.Flows.children_values/3`, `flows.ex:135-143`.
- **EMQ.3.2-D3 — `EchoMQ.Flows.dependencies/3` (the outstanding-count read — Fork R2·A):** a pure read
  `dependencies(conn, queue, parent_id) :: {:ok, non_neg_integer()} | {:error, term()}` reading the parent's
  `:dependencies` STRING counter (`Keyspace.job_key(queue, parent_id) <> ":dependencies"`) via the shipped
  connector (`GET`-class), parsed to a non-negative integer (the outstanding child count; `0` once every child
  has completed). The `parent_id` gated at `Keyspace.job_key/2` BEFORE the wire. A parent with no
  `:dependencies` key (not a flow parent, or already swept) returns **`{:ok, 0}`** — the build chose the count's
  natural floor (no new error vocabulary; the honest "zero outstanding" reading), `flows.ex:176`.
  **A pure read** (INV2). *As built:* `EchoMQ.Flows.dependencies/3`, `flows.ex:172-181`.
- **EMQ.3.2-D4 — the real-result-carrying completion (Fork R1·B — HOST-ONLY, the `@complete` Lua
  byte-unchanged):** `EchoMQ.Jobs.complete` gains a **result argument** so a flow child's completion records the
  **real result** in the parent's `:processed`. The emq.3.1 fan-in hook **already** `HSET`s `ARGV[5]` into
  `:processed` (`jobs.ex:183`: `HSET KEYS[4] ARGV[1] ARGV[5]`), and emq.3.1 passed `job_id` as `ARGV[5]` (the
  presence marker). emq.3.2 changed **only the host**: the build chose **`complete/5` with a defaulted
  `result \\ nil`** (`jobs.ex:365-385`) — the flow branch passes `argv ++ [parent_id, result || job_id]`
  (`jobs.ex:376`), so `ARGV[5]` is the result for a flow child and falls back to the `job_id` presence marker
  when no result is supplied (the `nil` default = emq.3.1's behaviour byte-for-byte). **The `@complete` Lua
  attribute (`jobs.ex:152-192`) is
  BYTE-UNCHANGED** — it already writes `ARGV[5]`; the *value* changes from `job_id` to the result, but the
  **script body does not** (SHA-verified byte-identical vs HEAD). The **non-flow completion is byte-unchanged**
  (the `nil` default → `ARGV[5] = job_id`; a non-flow job has `KEYS[3]` nil → the fan-in branch unreached →
  `ARGV[5]` unused; every prior `complete/4` call site is unchanged). This is what keeps emq.3.2 **NORMAL-risk**
  (no shipped-script edit; INV3). *As built:* `EchoMQ.Jobs.complete/5`, `jobs.ex:365-385`.
- **EMQ.3.2-D5 — the flow-subkey lifecycle DISPOSITION (NAMED, a carry — the §2 guardrail discharged):**
  emq.3.2 **names** what retires `:processed`/`:dependencies` and **routes it forward**: (a) the
  destructive-sweep extension — **both** FIXED-list `Admin` sweeps gain `:dependencies`/`:processed` in their
  enumerated `DEL`: `obliterate`'s `del_job` (`admin.ex:152`, today `DEL jk`/`:logs`/`:lock`) **and** `@drain`'s
  `wipe()` (`admin.ex:90`, today `DEL jk`/`:logs`) — each a one-line, slot-sound, A-1-clean extension; (b)
  per-flow completion cleanup — the parent retiring its own `:dependencies`/`:processed` once it completes (it
  has read `children_values` first). **BOTH are routed to the emq.3.x lifecycle rung, NOT folded into emq.3.2**
  (each re-tiers out of NORMAL-risk — the per-flow cleanup edits the shipped `@complete` Lua → HIGH-RISK; the
  sweep extension is an `Admin`-surface change beyond a read rung). emq.3.2 itself adds **zero** cleanup. **The
  disposition is NAMED in the spec body (this deliverable) — not left to discover** (the L-5 lesson the §2
  guardrail codifies). *Check:* the body names **both** destructive sweeps + per-flow cleanup + the owning rung;
  emq.3.2's touch-set adds no `DEL` of a flow subkey; `admin.ex` is untouched.
- **EMQ.3.2-D6 — the proof:** the `:valkey` read suite green per-app; the mint/process-touching read scenario
  (a flow minting N+1 ids, fanned in, then read) under the **≥100-iteration determinism loop** owning the
  machine (one green run is NOT proof — the master-invariant hazard; a flow read stands on a flow that minted
  many ids); the prior emq.1 + emq.2.{1,2,3,4} + **emq.3.1** suites + `Conformance.run/2` pass **unchanged** (no
  regression — INV3); honest-row reporting (Valkey on 6390 the truth row); the `flow_children_values` scenario
  registered additive-minor with the prior set byte-unchanged; **Apollo OPTIONAL** (NORMAL-risk — no
  shipped-script edit; the Director's solo review + the gate ladder are the gate; D-3).

## Invariants (runnable checks)

- **EMQ.3.2-INV1 — the wire law (no break, no new type/class/transport, no shipped-script edit).** emq.3.2 adds
  **no §6 key type** (the read keys are the already-registered `:processed`/`:dependencies` subkeys); **no new
  wire class** (the reads are plain `HGETALL`/`GET`; no fence code); **no `SSUBSCRIBE`/new transport** (the
  reads ride the shipped connector); and edits **no shipped Lua script** (R1·B is host-only — the `@complete`
  Lua body is byte-unchanged). The five-code fence union stands unextended. *Check:* a `git diff` of **every**
  `@… Script.new/2` attribute in `jobs.ex` + `flows.ex` (**15 as-built** — the 8 state-machine/flow scripts
  `@enqueue`/`@claim`/`@complete`/`@retry`/`@promote`/`@reap`/`@schedule`/`@enqueue_flow` **plus** the 7 emq.2.x
  mutation scripts `@update_data`/`@update_progress`/`@add_log`/`@remove_job`/`@reprocess`/`@extend_lock`/`@extend_locks`)
  is **empty**; `keyspace.ex`'s grammar is unedited; the read fns issue only `HGETALL`/`GET`-class commands.
- **EMQ.3.2-INV2 — the reads are pure (no write, no transition).** `children_values/3` and `dependencies/3`
  perform **read-only** Valkey commands (`HGETALL` / `GET`-class) and effect **no** state change — calling them
  any number of times leaves the flow's state, the `:dependencies` count, and the `:processed` HASH **identical**.
  *Check:* a `:valkey` scenario reads `children_values/3` + `dependencies/3` twice and asserts the
  `:dependencies` count and the `:processed` contents are byte-identical before and after; the read fns contain
  no `HSET`/`SET`/`DECR`/`ZADD`/`DEL`.
- **EMQ.3.2-INV3 — the shipped surface is byte-unchanged (the non-flow path + every Lua script).** A job with
  **no parent** flows through `@enqueue`/`@claim`/`@complete` exactly as emq.3.1 shipped; the real-result arg
  (D4) is **host-only** — every `Script.new/2` Lua body is byte-identical; a non-flow `complete` caller (no
  result) takes the shipped path. *Check:* the emq.1 + emq.2.{1,2,3,4} + emq.3.1 suites + `Conformance.run/2`
  pass **unchanged**; the prior **45** conformance scenarios are byte-identical (name + contract + verdict body,
  git-verified); a `git diff` of **every** `@… Script.new/2` attribute in `jobs.ex` + `flows.ex` (all **15** —
  INV1's full enumeration) is empty (INV1's check is INV3's evidence — the no-shipped-script-edit property is the
  headline).
- **EMQ.3.2-INV4 — branded identity at the read boundary.** `children_values/3` and `dependencies/3` key the
  parent's subkeys through `Keyspace.job_key/2`, which gates `BrandedId.valid?/1` and raises before any wire; an
  ill-formed `parent_id` raises at the key builder (never a malformed read). *Check:* a read with an ill-formed
  `parent_id` raises at `Keyspace.job_key/2`; a read with a valid id issues a well-formed `:processed`/
  `:dependencies` key.
- **EMQ.3.2-INV5 — O1 closed (the result is real, R1·B shipped).** A child completed with a result records that
  **real result** in `:processed[child_id]`, and `children_values/3` returns it (NOT the `child_id` presence
  marker emq.3.1 wrote). *Check (the `flow_children_values` scenario, `conformance.ex:1096`):* a `:valkey`
  scenario completes two children with **distinct results** (`"r-" <> c1`, `"r-" <> c2`) and asserts
  `children_values/3` returns `%{c1 => "r-" <> c1, c2 => "r-" <> c2}` — the values are the results, provably not
  the child ids — and `dependencies/3` counts `2 → 1 → 0`. O1 is **closed**.
- **EMQ.3.2-INV6 — the additive-minor conformance law.** `flow_children_values` is registered in `scenarios/0`
  **with its probe in the same change**; the prior **45** scenarios pass **byte-unchanged**; the count re-pinned
  **45 → 46** in **both** pinning tests (`conformance_scenarios_test.exs` + `conformance_run_test.exs`). *Check:*
  the `git diff` shows only additions to `scenarios/0`; both pin tests assert the new total; `Conformance.run/2`
  prints the new line count.
- **EMQ.3.2-INV7 — the flow-subkey lifecycle is NAMED (the §2 guardrail).** The spec body **names** the cleanup
  disposition for the `:processed`/`:dependencies` subkeys emq.3.2 reads — the **two** FIXED-list destructive
  sweeps (`obliterate`'s `del_job` `admin.ex:152` **and** `@drain`'s `wipe()` `admin.ex:90`) gaining the subkeys,
  **plus** per-flow completion cleanup, all routed to the emq.3.x lifecycle rung (D5/N1); emq.3.2 adds **no**
  cleanup and leaves the subkeys (correct — the reads need them). *Check:* the body names **both** destructive
  sweeps + per-flow cleanup + the owning rung; emq.3.2's touch-set contains **no** `DEL`/`HDEL`/`UNLINK` of a
  flow subkey; `admin.ex` is untouched (the emq.3.1 moduledoc carry re-affirmed).
- **EMQ.3.2-INV8 — slot soundness + the family boundary (single-queue, one-level, read-only).** The reads touch
  only the parent's own `:processed`/`:dependencies` subkeys (the parent's `{q}` slot — the single-queue carve);
  emq.3.2 ships the **read** surface + the O1-closing result only — no cross-queue read (emq.3.3), no failure
  read (emq.3.4), no bulk (emq.3.4), no deep recursion; it re-ships no emq.2 surface and pre-empts no
  Movement-II family. *Check:* the read fns build keys of exactly the parent's `{q}`; the deliverable touch-set
  is the single-queue read + the host result arg; the body names the boundary and the honest bounds N1/N2/N3.

## Definition of Done

- [x] EMQ.3.2-D1: Fork R1 settled by the Operator (Arm B ruled) + Fork R2 (Arm A ruled), recorded BEFORE any
      build artifact (the gate that opened the build); the triad was authored to the ruled arms → no pre-build
      re-scope (the Stage-0 reconcile confirmed, T-5/Y-2).
- [x] `EchoMQ.Flows.children_values/3` built (D2): a pure `HGETALL` read of the parent's `:processed` HASH → the
      completed children's results keyed by child id; the `parent_id` gated; `{:ok, %{}}` for none-yet
      (`flows.ex:135-143`).
- [x] `EchoMQ.Flows.dependencies/3` built (D3, Fork R2·A): a pure `GET` read of the parent's `:dependencies`
      counter → the outstanding non-negative integer; the `parent_id` gated; the `{:ok, 0}` none-key sentinel
      (`flows.ex:172-181`).
- [x] The real-result-carrying completion built (D4, Fork R1·B — HOST-ONLY): `complete/5` (`result \\ nil`) threads
      the result into the existing `ARGV[5]` (`jobs.ex:365-385`); the `@complete` Lua byte-unchanged
      (SHA-verified); the non-flow completion byte-unchanged; **O1 closed** (`:processed` holds the real result).
- [x] The flow-subkey lifecycle disposition NAMED (D5): the `obliterate`-sweep + per-flow cleanup routed to the
      emq.3.x lifecycle rung; emq.3.2 added no cleanup; `admin.ex` untouched (INV7 — zero `DEL`/`HDEL`/`UNLINK`
      of a flow subkey).
- [x] `flow_children_values` registered (D6/INV6, additive minor): the prior 45 conformance scenarios
      byte-unchanged; the count re-pinned **45 → 46** in both pinning tests.
- [x] The proof (D6): the `:valkey` read suite green per-app (4 doctests, 272 tests, 0 failures; conformance
      46/46); the **≥100 determinism loop** green (120/120) for the mint/process-touching read scenario; the
      emq.1 + emq.2.{1,2,3,4} + emq.3.1 suites + `Conformance.run/2` passed unchanged (no regression — INV3); a
      `git diff` of all 15 `Script.new/2` attributes is **empty** (NORMAL-risk proven, per-attr SHA-256);
      honest-row reporting (Valkey on 6390); Apollo NOT required (NORMAL-risk).
- [x] INV1–INV8 verified as runnable checks; the spec body remains authoritative and this post-build reconcile
      (Stage 5) synced it to the as-built surface.

Stories: [`./emq.3.2.stories.md`](emq.3.2.stories.md) · Agent brief: [`./emq.3.2.llms.md`](emq.3.2.llms.md)
· Runbook: [`./emq.3.2.prompt.md`](emq.3.2.prompt.md) · Family: [`./emq.3.md`](../../emq.3.md) (the contract, the
carve, the forks — authoritative for the family) · The first slice (SHIPPED, the floor emq.3.2 reads):
[`./emq.3.1.md`](emq.3.1.md) (`EchoMQ.Flows.add/3`, the `:processed`/`:dependencies` subkeys, the fan-in hook,
the O1/O2/L-5 honest bounds emq.3.2 closes/carries) · The v1 capability reference (READ-ONLY, the form NOT to
lift): `echo/apps/echomq/lib/echomq/flow_producer.ex:64,70` (`get_children_values`/`get_dependencies` — the
parent-handler reads to port) + `echo/apps/echomq/lib/echomq/job.ex:48,54` (the same surface) + the subkey
names at `echo/apps/echomq/lib/echomq/keys.ex:288-294` (`processed/2` = `job <> ":processed"`, the §6
reservation) · As-built surface (SHIPPED): `echo/apps/echo_mq/lib/echo_mq/flows.ex`
(`add/3`; `children_values/3` at `:135-143` the `HGETALL` read of `:processed`; `dependencies/3` at `:172-181`
the `GET` read of the `:dependencies` STRING counter, `{:ok, 0}` none-key sentinel at `:176`; `@enqueue_flow`
`SET KEYS[2] n` the counter) + `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`@complete` the BYTE-UNCHANGED Lua at
`:152-192`, the `HSET KEYS[4] ARGV[1] ARGV[5]` `:processed` write at `:183`; `complete/5` at `:365-380`
(`result \\ nil`) the host wrapper that threads the result through `ARGV[5]` at `:376`; `parent_of/3` at
`:397-405` the O2 read, fold DECLINED; `add_log/5` the `<> ":logs"` subkey-compose precedent) + `keyspace.ex`
(`job_key/2` the gated builder, `queue_key/2`) + `conformance.ex` (the **46**-scenario set; `flow_children_values`
+ its `apply_scenario` probe at `:1096`) + `admin.ex` (`del_job` the FIXED `:logs`/`:lock` enumeration, the
L-5/N1 lifecycle carry — UNTOUCHED) · Design: [`../emq.design.md`](../../../emq.design.md) §11.10 (the
deferral + the owed flow design), §6 (the grammar — the `job:<id>:{processed,dependencies}` subkeys), §5 (no
new wire class), S-6 (the declared-keys A-1 law — the reads are A-1-trivial, pure reads of declared keys),
S-1/§6 (the braced keyspace — the single slot), §11.12 (the escalation protocol) · Roadmap:
[`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I (the parity thesis — the flow family closes it) · The
feature catalog: [`../emq.features.md`](../../../emq.features.md) (the emq.3 row) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
