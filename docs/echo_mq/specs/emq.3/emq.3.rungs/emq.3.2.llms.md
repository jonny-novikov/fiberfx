# EMQ.3.2 · agent brief — the child-result reads (Mars's build brief)

> The brief Mars (the implementor) builds from. The spec body [`./emq.3.2.md`](emq.3.2.md) is **authoritative**;
> this brief derives from it and may lag a resolved body — when they disagree, the body wins. **Framing (the
> propagation clause):** third person for any agent reference; no gendered pronouns; no perceptual or
> interior-state verbs for agents or software (components **read**, **compute**, **refuse**, **return**); no
> first-person narration; **forward tense** for the unbuilt surface ("emq.3.2 builds …"). emq.3.2 is **NORMAL-risk**
> (no shipped Lua script is edited) — a dedicated Apollo evaluator is **not mandatory**; the Director's solo
> review + the gate ladder are the gate. **Load the `echo-mq-implementor` skill** before building.

## References (read first — links/paths first)

- **The spec body (authoritative):** [`./emq.3.2.md`](emq.3.2.md) — Goal · 5W · Scope (In/Out + the honest
  bounds N1/N2/N3) · D1–D6 · INV1–INV8 · DoD.
- **The stories (the acceptance face):** [`./emq.3.2.stories.md`](emq.3.2.stories.md) — US1–US6 + US-GATE +
  the Coverage map.
- **The family contract + the carve + the forks:** [`./emq.3.md`](../../emq.3.md) — emq.3.2 is the **child-result
  reads** row of the carve (`children_values/3` + `dependencies/3` over `:processed`/`:dependencies`).
- **The first slice (SHIPPED — the floor emq.3.2 reads + extends):** [`./emq.3.1.md`](emq.3.1.md) +
  [`./emq-3-1.progress.md`](../../progress/emq-3-1.progress.md) — `EchoMQ.Flows.add/3`, the `:processed`/`:dependencies`
  subkeys, the fan-in hook, and the honest bounds **O1** (the `:processed` presence marker emq.3.2 closes),
  **O2** (the `parent_of` `HGET` emq.3.2 may optionally fold), **L-5** (the flow-subkey lifecycle emq.3.2
  names + carries). Read O1/O2/L-5 at `emq.3.1.md` lines 108-137 + `emq-3-1.progress.md` T-11.
- **The as-built build target + the read seams (re-probe at Stage-0 — line numbers drift):**
  - `echo/apps/echo_mq/lib/echo_mq/flows.ex` — `EchoMQ.Flows.add/3` (the module emq.3.2 **extends** with
    `children_values/3` + `dependencies/3`); `@enqueue_flow` `SET KEYS[2] n` (`flows.ex:49`, the `:dependencies`
    STRING counter Fork R2·A reads); `KEYS[2] = parent_key <> ":dependencies"` (`flows.ex:85`).
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **`@complete`** the **byte-unchanged** Lua attribute
    (`jobs.ex:152-192`); the fan-in `:processed` write `HSET KEYS[4] ARGV[1] ARGV[5]` (`jobs.ex:183`, the seam
    R1·B extended — it already writes `ARGV[5]`). **As built:** `complete/5` (`result \\ nil`) the host wrapper
    (`jobs.ex:365-385`) passes `argv ++ [parent_id, result || job_id]` (`jobs.ex:376` — the result for a flow
    child, falling back to the `job_id` presence marker when no result is supplied); `parent_of/3`
    (`jobs.ex:397-405`, the O2 `HGET 'parent'`, fold DECLINED — N2); `add_log/5` the
    `Keyspace.job_key(q,id) <> ":logs"` subkey-compose precedent for `<> ":processed"` / `<> ":dependencies"`.
  - `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — `job_key/2` (`:17-24`, gates `BrandedId.valid?/1`, **raises** —
    INV4) + `queue_key/2`.
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — `scenarios/0` (a **keyword list**, 45 entries as-built; the
    last `obliterate_grouped:`; the additive edit **appends** `flow_children_values:` + a `defp apply_scenario(:flow_children_values, conn, q)` probe; moduledoc `"forty-five"` → `"forty-N"`; `run/2` doc `n == 45` → `n == N`).
  - `echo/apps/echo_mq/lib/echo_mq/admin.ex` — `del_job` (`admin.ex:150-153`, the **FIXED** `DEL jk, jk..':logs', jk..':lock'`) — **DO NOT EDIT** (the L-5/N1 lifecycle carry is the emq.3.x rung's, not emq.3.2's; `admin.ex` stays untouched).
  - The pin tests: `test/conformance_run_test.exs:41` (`{:ok, 45}` → `{:ok, N}`) + `test/conformance_scenarios_test.exs:20-68` (`@run_order` + `"forty-five"` → `"forty-N"`, append `:flow_children_values`).
- **The v1 capability reference (READ-ONLY — the behaviour to PORT, the form NOT to lift):**
  `echo/apps/echomq/lib/echomq/flow_producer.ex:64,70` (`get_children_values`/`get_dependencies` — the
  parent-handler reads) + `echo/apps/echomq/lib/echomq/job.ex:48,54` + `echo/apps/echomq/lib/echomq/keys.ex:288-294`
  (`processed/2` = `job <> ":processed"`). Port the **capability**; the v2 form is a pure read of the declared
  `:processed`/`:dependencies` subkeys.
- **Design:** [`../emq.design.md`](../../../emq.design.md) §6 (the `:processed`/`:dependencies` subkeys), §11.10 (the
  flow design), S-6 (the A-1 declared-keys law — the reads are A-1-trivial: pure reads of declared keys), §5 (no
  new wire class). **Program law:** [`../../../.claude/skills/echo-mq-program.md`](../../../../../.claude/skills/echo-mq-program.md)
  (the v2 laws, the gate ladder, the additive-minor law). **Surface map:**
  [`../../../.claude/skills/echo-mq-surface.md`](../../../../../.claude/skills/echo-mq-surface.md).

## Requirements (numbered; each traced to a story + forward to an invariant/check)

- **R1 — the fork gate FIRST (US1 → INV3/INV5).** Confirm the Operator ruled **Fork R1** (Arm B, the
  real-result-carrying completion — the recommended arm this triad is authored to; an Arm-A ruling narrows
  emq.3.2 to a pure presence read, dropping the `complete` result arg). Confirm **Fork R2** (Arm A, the count —
  surfaced, optionally ruled; R2·B is **not free**). Record the ruling BEFORE any build artifact. The triad is
  authored to **R1·B + R2·A** → Stage-0 confirms these arms are a **no-op re-derive** if ruled as recommended.
- **R2 — `EchoMQ.Flows.children_values/3` (US2 → INV2/INV4/INV5).** A **pure** read
  `children_values(conn, queue, parent_id) :: {:ok, %{binary() => binary()}} | {:error, term()}` over the
  parent's `:processed` HASH (`Keyspace.job_key(queue, parent_id) <> ":processed"`, the `add_log` precedent),
  issued via the shipped connector (`HGETALL`-class — `Connector.command(conn, ["HGETALL", key])` decoded to a
  map). Gate `parent_id` at `Keyspace.job_key/2` (raises — INV4) before the wire. `{:ok, %{}}` for none-yet.
  **No write** (INV2).
- **R3 — `EchoMQ.Flows.dependencies/3` (US3 → INV2/INV4, Fork R2·A).** A **pure** read
  `dependencies(conn, queue, parent_id) :: {:ok, non_neg_integer()} | {:error, term()}` over the parent's
  `:dependencies` STRING counter (`<> ":dependencies"`), `GET`-class, parsed to a non-negative integer (`0` at
  full fan-in). Gate `parent_id` at `Keyspace.job_key/2` before the wire. **As built:** a missing `:dependencies`
  → **`{:ok, 0}`** (the count's natural floor, no new error vocabulary; `flows.ex:176`). **No write** (INV2).
- **R4 — the real-result-carrying completion (US4 → INV1/INV3/INV5, Fork R1·B — HOST-ONLY).** Extend
  `EchoMQ.Jobs.complete` to take a **result** and pass it as `ARGV[5]` **instead of** `job_id` (the emq.3.1
  presence marker). **As built:** `complete/5` with a defaulted **`result \\ nil`** (`jobs.ex:365`), the flow
  branch passing `argv ++ [parent_id, result || job_id]` (`jobs.ex:376`) — the `nil` default keeps the non-flow
  caller (and every prior `complete/4` call site) on the shipped path. **The `@complete` `Script.new/2` body
  (`jobs.ex:152-192`) is BYTE-UNCHANGED** — it already does `HSET KEYS[4] ARGV[1] ARGV[5]`; only the
  host-supplied *value* of `ARGV[5]` changes. **No other Lua attribute is touched.** *This was the single
  highest-leverage requirement: it closed O1 at NORMAL-risk because the script did not change.*
- **R5 — the flow-subkey lifecycle disposition NAMED (US5 → INV7, the §2 guardrail).** The body **names** the
  cleanup disposition for `:processed`/`:dependencies` (the `obliterate`-sweep — `del_job` gains the two subkeys
  — **and** per-flow completion cleanup) and **routes both to the emq.3.x lifecycle rung**. emq.3.2 builds
  **zero** cleanup, **does not edit `admin.ex`**, leaves the subkeys (the reads need them). This is a **spec-body
  requirement** (already discharged in `emq.3.2.md` D5/N1) — Mars's job is to **not** add a `DEL`/`HDEL`/`UNLINK`
  of a flow subkey anywhere.
- **R6 — `flow_children_values` conformance, additive-minor (US6 → INV6).** Append `flow_children_values:` to
  `scenarios/0` **with its `defp apply_scenario(:flow_children_values, …)` probe in the same change**; keep the
  prior **45** byte-unchanged (no `-` line touches a prior probe/contract — re-pin only the moduledoc prose +
  the count); re-pin `45 → 46` in **both** pin tests + their `"forty-five"` → `"forty-six"`. (As built: the
  `dependencies/3` count read is exercised WITHIN `flow_children_values`, so no separate `flow_dependencies`
  scenario was added — the target is **46**, not 47.)
- **R7 — the proof (US6 → INV3/INV6).** Run the gate ladder (below) **independently**; the prior emq.1 +
  emq.2.{1,2,3,4} + emq.3.1 suites + `Conformance.run/2` pass **unchanged**; the mint/process-touching read
  scenario under the **≥100 determinism loop** owning the machine; a `git diff` of **every** `Script.new/2`
  attribute is **empty** (NORMAL-risk proven); honest-row reporting (Valkey on 6390).

## Execution topology (the runtime shape · the build-order DAG · the EXACT files)

**The runtime shape.** emq.3.2 adds **two pure reads** (`Connector.command`-issued `HGETALL`/`GET`) on
`EchoMQ.Flows` over the parent's already-written `:processed`/`:dependencies` subkeys, **plus one host-side
completion extension** (`EchoMQ.Jobs.complete` threads a result through the existing `ARGV[5]`). No new process,
no new transport, no new connector verb, **no new Lua script**, no grammar change. The reads ride the shipped
`EchoWire` connector; the result arg rides the shipped `@complete` Lua.

**The build-order DAG (one increment, dependency-ordered):**
1. **Stage-0 reconcile (Mars re-probes — the lag-1 law).** Confirm every anchor above against the post-emq.3.1
   tree (grep/Read, not trusting a pinned line): the `@complete` Lua at `jobs.ex:152-192` (the `ARGV[5]` HSET at
   `:183`), `complete/4` at `:350-370` (the `job_id`-as-`ARGV[5]` at `:361`), `@enqueue_flow` `SET KEYS[2] n`,
   `add_log` `<> ":logs"`, `job_key/2` raises, the live conformance count = **45**, `del_job`'s FIXED list. The
   forks ruled (R1·B + R2·A). Toolchain: `asdf current erlang` (28.5.0.1 as-built — a switch ⇒ a full rebuild),
   `redis-cli -p 6390 ping` → `PONG`.
2. **`jobs.ex` — the host-only result arg (R4).** `complete` gains the result; `ARGV[5]` becomes the result (not
   `job_id`); the non-flow caller byte-unchanged; **the `@complete` Lua untouched** (verify the `git diff` of the
   attribute is empty after the edit). (Optionally fold O2 — N2 — only if it stays correctness-neutral; else
   leave it.)
3. **`flows.ex` — the two pure reads (R2, R3).** `children_values/3` (`HGETALL` → map) + `dependencies/3`
   (`GET` → non-neg integer); both gate `parent_id` at `Keyspace.job_key/2`; both **read-only**.
4. **`conformance.ex` — `flow_children_values` + the probe + the re-pin (R6).** Append the scenario + the
   `apply_scenario` clause; the prior 45 byte-unchanged; `"forty-five"` → `"forty-six"`; `n == 45` → `n == 46`.
5. **The pin tests — the count (R6).** `conformance_run_test.exs` `{:ok, 45}` → `{:ok, 46}`;
   `conformance_scenarios_test.exs` `@run_order` append + `"forty-five"` → `"forty-six"`.
6. **`test/flow_children_values_test.exs` (NEW, `:valkey`) + the gate ladder (R7).** The read scenarios + the
   purity scenario + the ≥100 loop.

**The EXACT files touched** (the boundary — `echo/apps/echo_mq` only; **`echo_wire` untouched**, **`admin.ex`
untouched**, **`keyspace.ex` untouched**, **`apps/echomq` untouched**):
- `echo/apps/echo_mq/lib/echo_mq/flows.ex` — EDIT (`children_values/3` + `dependencies/3`).
- `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — EDIT (**host only**: `complete` + the result arg; the `@complete`
  Lua byte-unchanged).
- `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — EDIT (`flow_children_values` + probe + count re-pin).
- `echo/apps/echo_mq/test/conformance_run_test.exs` — EDIT (count).
- `echo/apps/echo_mq/test/conformance_scenarios_test.exs` — EDIT (count + `@run_order`).
- `echo/apps/echo_mq/test/flow_children_values_test.exs` — NEW (`:valkey`).

**The gate ladder (run before reporting — `echo-mq-program.md` §gate ladder):**
- `asdf current erlang` (re-probe; no hardcode) · `redis-cli -p 6390 ping` → `PONG`.
- `TMPDIR=/tmp mix compile --warnings-as-errors` (per-app, `echo_mq` — never umbrella-wide).
- `TMPDIR=/tmp mix test --include valkey` (per-app — the full `echo_mq` suite incl. the new `:valkey` reads;
  **umbrella-wide `mix test` is BANNED**).
- `Conformance.run/2` → `{:ok, N}`; the prior **45** byte-unchanged (re-verify any prior scenario the build did
  not intend to touch).
- **The ≥100 determinism loop** owning the machine over the flow read scenario (`for i in $(seq 1 100); do
  TMPDIR=/tmp mix test --include valkey || break; done`, tee'd) — the read stands on a flow that minted N+1 ids.
- **The byte-unchanged proof:** `git diff` of **every** `@… Script.new/2` attribute in `jobs.ex` + `flows.ex`
  (**all 15 as-built** — the 8 state-machine/flow scripts
  `@enqueue`/`@claim`/`@complete`/`@retry`/`@promote`/`@reap`/`@schedule`/`@enqueue_flow` **plus** the 7 emq.2.x
  mutation scripts `@update_data`/`@update_progress`/`@add_log`/`@remove_job`/`@reprocess`/`@extend_lock`/`@extend_locks`)
  is **empty** — the NORMAL-risk evidence.

## Agent stories (Directive + Acceptance gate — the contract Apollo/Director accept at)

- **AS-1 — confirm the forks (R1).** *Directive:* confirm Fork R1 = Arm B (real-result completion) + Fork R2 =
  Arm A (count) ruled/recommended; record before any build artifact. *Acceptance:* the ledger records the R1
  ruling; Stage-0 confirms R1·B + R2·A are the authored arms (a no-op re-derive if ruled as recommended).
- **AS-2 — the host-only result arg (R4).** *Directive:* `EchoMQ.Jobs.complete` takes a result, passes it as
  `ARGV[5]`; the `@complete` Lua byte-unchanged; the non-flow caller byte-unchanged. *Acceptance:* (post)
  `:processed[child_id]` holds the **result** (not `job_id`); (inv) a `git diff` of the `@complete` attribute is
  **empty**; the emq.3.1 + emq.2.x non-flow suites pass unchanged (INV3).
- **AS-3 — `children_values/3` (R2).** *Directive:* a pure `HGETALL`-class read of the parent's `:processed` →
  the results keyed by child id; gate the id. *Acceptance:* (post) two children completed with distinct results
  → `{:ok, %{a => "r-a", b => "r-b"}}`; (post) an empty parent → `{:ok, %{}}`; (inv) the read effects no state
  change (INV2); (pre) an ill-formed id raises at `Keyspace.job_key/2` (INV4).
- **AS-4 — `dependencies/3` (R3).** *Directive:* a pure `GET`-class read of the parent's `:dependencies` → the
  outstanding count; gate the id; the honest none-key sentinel. *Acceptance:* (post) after k of N children
  complete → `{:ok, N − k}`; `{:ok, 0}` at full fan-in; (post) a non-flow parent → the sentinel; (inv) no state
  change (INV2); (pre) an ill-formed id raises (INV4).
- **AS-5 — the lifecycle disposition NAMED (R5).** *Directive:* the body names the `obliterate`-sweep +
  per-flow cleanup, routed to the emq.3.x lifecycle rung; add **zero** cleanup. *Acceptance:* (inv) emq.3.2's
  touch-set contains no `DEL`/`HDEL`/`UNLINK` of a flow subkey; `admin.ex` untouched; the body names both
  mechanisms + the owning rung (INV7).
- **AS-6 — `flow_children_values` + the re-pin (R6).** *Directive:* append the scenario + probe; the prior 45
  byte-unchanged; re-pin `45 → 46` in both pin tests. *Acceptance:* (post) `Conformance.run/2 → {:ok, 46}`; (inv)
  the `git diff` shows only additions to `scenarios/0`; both pin tests assert the new total (INV6).
- **AS-7 — the proof (R7).** *Directive:* run the gate ladder independently; the ≥100 loop owning the machine;
  the byte-unchanged Lua proof. *Acceptance:* the `:valkey` read suite green; the ≥100 loop green; the prior
  emq.1 + emq.2.x + emq.3.1 suites + `Conformance.run/2` unchanged; a `git diff` of every `Script.new/2`
  attribute **empty** (NORMAL-risk proven); honest-row (Valkey on 6390).

**Agents run NO git** (the Director commits once at the rung's close by pathspec; the Operator commits
out-of-band mid-flight — watch for `AM`-status files and exclude them). The boundary is
`echo/apps/echo_mq` only; exclude the Operator out-of-band paths (`docs/echo/art`, `docs/mercury`,
`echo/apps/exchange`, `html`, the F# course, any `[emq]`/`[mercury]`/`[exchange]`/`[fsharp]` commits).
