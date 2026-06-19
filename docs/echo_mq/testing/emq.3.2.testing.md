# emq.3.2 — testing tasks

> Living test ledger for the **child-result reads** rung (the SECOND sub-rung of the emq.3 parent/flow family —
> `EchoMQ.Flows.children_values/3` over the parent's `:processed` HASH + `EchoMQ.Flows.dependencies/3` over the
> `:dependencies` STRING counter; the `emq-3-2` cycle 2026-06-15, conformance 45 → **46**). Strategy:
> [`../emq.testing.md`](../emq.testing.md). Spec family + carve: [`../specs/emq.3.md`](../specs/emq1/emq.3/emq.3.md) · Rung
> triad: [`../specs/emq.3.2.md`](../specs/emq1/emq.3/emq.3.rungs/emq.3.2.md) · [`.stories.md`](../specs/emq1/emq.3/emq.3.rungs/emq.3.2.stories.md) ·
> Runbook: [`.prompt.md`](../specs/emq1/emq.3/emq.3.rungs/emq.3.2.prompt.md). The floor it
> reads: [`emq.3.1.testing.md`](./emq.3.1.testing.md). **NORMAL-risk rung** — it edited **no** shipped Lua
> script (the real-result completion rode the EXISTING `ARGV[5]` seam, the `@complete` Lua byte-unchanged), so
> a dedicated Apollo evaluator was not required (the Director's solo review + the gate ladder were the gate; the
> ≥100 determinism loop ran 120/120). Re-probe the tree before trusting a `file:line` here (the lag-1 law).

## Proof state (as-built)

- **A single-queue flow's outcome is now consumable.** The parent handler reads what its children produced
  (`children_values/3` over `:processed` → `{:ok, %{child_id => result}}`) and how many legs remain
  (`dependencies/3` over `:dependencies` → `{:ok, non_neg_integer()}`, the outstanding count, Fork R2·A). Both
  are **pure reads** (`HGETALL`/`GET`-class, no state transition — INV2) and gate `parent_id` at
  `Keyspace.job_key/2` before any wire (INV4).
- **emq.3.1's honest bound O1 is CLOSED.** The `:processed` value is now the **real result** the child produced,
  not the `child_id → child_id` presence marker emq.3.1 wrote. The mechanism is the **real-result-carrying
  completion** (Fork R1·B): `EchoMQ.Jobs.complete/4` → `complete/5` with `result \\ nil`, passing the result
  through the **EXISTING `ARGV[5]` slot** the emq.3.1 fan-in hook already `HSET`s into `:processed` — **the
  `@complete` Lua attribute is byte-unchanged** (SHA-verified; only the host-supplied *value* changed,
  `job_id` → the result), the non-flow completion byte-unchanged (`nil` default → `ARGV[5] = job_id`).
- **Test file** (`@moduletag :valkey`, `async: false`):
  - `flow_children_values_test.exs` — **10 tests** across 5 describes (the result read + the count read + the
    purity proof + the v1-parity depth + the lifecycle honest bound).
- **Conformance**: +1 scenario — `flow_children_values` → `{:ok, 46}` (the prior **45** byte-unchanged); the
  mint/process-touching flow read suite runs under the **≥100 determinism loop** owning the machine (the read
  stands on a flow that minted N+1 ids).

### Surface map (PIN — the two new reads + the host-only completion seam)

| Symbol | Where | Role |
|---|---|---|
| `EchoMQ.Flows.children_values/3` | `flows.ex` | `children_values(conn, queue, parent_id) :: {:ok, %{binary() => binary()}} \| {:error, term()}`; a pure `HGETALL` of the parent's `:processed` HASH decoded by `hash_pairs/1` (RESP3 native map + RESP2 flat-list shapes); `{:ok, %{}}` for none-yet |
| `EchoMQ.Flows.dependencies/3` | `flows.ex` | `dependencies(conn, queue, parent_id) :: {:ok, non_neg_integer()} \| {:error, term()}`; a pure `GET` of the `:dependencies` STRING counter; `{:ok, 0}` none-key sentinel (the count's natural floor — no new error vocabulary) |
| `EchoMQ.Jobs.complete/5` | `jobs.ex` | `complete(conn, queue, job_id, token, result \\ nil)`; the flow branch passes `argv ++ [parent_id, result \|\| job_id]` — `ARGV[5]` is the result for a flow child, falls back to `job_id` (the byte-unchanged non-flow / old-arity path) |
| the `@complete` Lua attribute | `jobs.ex` | **BYTE-UNCHANGED** (the NORMAL-risk headline) — it already does `HSET KEYS[4] ARGV[1] ARGV[5]`; only the host-supplied value of `ARGV[5]` changed |
| `del_job` / `wipe()` | `admin.ex` | **UNTOUCHED** — the FIXED `:logs`/`:lock` enumeration that excludes the flow subkeys (the L-5/N1 lifecycle carry — emq.3.2 reads the subkeys, it does not retire them) |

## Proof table

| US | Given → When → Then (essence) | Proven by | Lane | Conf. |
|---|---|---|---|---|
| US1 fork gate | Fork R1 (Arm B, the real-result completion) + Fork R2 (Arm A, the count) ruled before any build artifact; the triad authored to the ruled arms (no pre-build re-scope) | the `emq-3-2` ledger (T-4 Operator gate) + the empty `@complete` diff | ledger | — |
| US2 children_values | two children completed with **distinct** results → `{:ok, %{c1 => "r-"<>c1, c2 => "r-"<>c2}}` (the results, provably not the ids); an empty parent → `{:ok, %{}}`; an ill-formed id raises | `flow_children_values_test.exs` (the O1-close describe — 3 tests) | wire | `flow_children_values` |
| US3 dependencies | the count is N before any completion, N−k after k complete, **0** at full fan-in (Fork R2·A); a non-flow parent → the `{:ok, 0}` sentinel; an ill-formed id raises | `flow_children_values_test.exs` (the dependencies describe — 3 tests) | wire | `flow_children_values` |
| US4 real-result completion (R1·B, host-only) | the result rides the EXISTING `ARGV[5]`; the `@complete` Lua byte-unchanged; the non-flow completion byte-unchanged; **O1 closed** | `flow_children_values_test.exs` (distinct-results) + the **15-attr empty-Lua-diff SHA proof** + the unchanged non-flow suites | wire+ledger | `flow_children_values` |
| US5 purity + the named lifecycle | a double-read leaves `:dependencies` + `:processed` **byte-identical** (the reads are pure); the flow-subkey cleanup disposition is **named** (the `obliterate`-sweep + per-flow cleanup → emq.3.x), emq.3.2 adds **zero** cleanup (`admin.ex` untouched) | `flow_children_values_test.exs` (the purity describe — double-read byte-identity; the lifecycle honest-bound describe) + the empty cleanup touch-set | wire+ledger | `flow_children_values` |
| US6 · GATE | prior **45** byte-unchanged + 1 new → `{:ok, 46}`; the read suite under the **≥100 loop**; the emq.1 + emq.2.{1–4} + emq.3.1 suites unchanged (INV3); Apollo OPTIONAL (NORMAL-risk) | `conformance_run_test.exs` · `conformance_scenarios_test.exs` + the ≥100 loop | wire+pure+proc | all 46 |

## Hot places (this rung)

- **The NORMAL-risk headline is the empty Lua diff.** emq.3.2 edits **no** shipped Lua script — the proof is a
  `git diff` of **every** `@… Script.new/2` attribute in `jobs.ex` + `flows.ex` (**15 as-built** — the 8
  state-machine/flow scripts + the 7 emq.2.x mutation scripts) is **empty** (per-attr SHA-256). This is what
  keeps emq.3.2 host-only and off the HIGH-risk path emq.3.1 was on. Any later read rung that finds itself
  editing a script has slipped tier — re-run this proof on every flow rung.
- **The reads must stay pure (INV2).** `children_values/3` and `dependencies/3` issue exactly `HGETALL` and
  `GET` — no `HSET`/`SET`/`DECR`/`ZADD`/`DEL`. The double-read byte-identity test is the regression guard; a
  read that mutates is a silent corruption a happy-path assertion would miss.
- **The flow-subkey lifecycle carry (L-5/N1) — now TESTED as a survival bound, not papered over.** emq.3.2 reads
  `:processed`/`:dependencies`; they **outlive** the parent's own completion AND `obliterate` (`del_job`'s FIXED
  list) AND `@drain`'s `wipe()` (a SECOND obliterate-class leak surface — `DEL jk, jk..':logs'`, no `:lock`, no
  flow subkeys, the same destructive-sweep-with-FIXED-subkey-list class). The
  `flow_children_values_test.exs` lifecycle describe **asserts they survive** today (the honest at-rest bound,
  caught — not a green-board blind spot). The cleanup (the `obliterate`-sweep gaining the two subkeys + per-flow
  completion cleanup) is the NAMED carry to the **emq.3.x lifecycle rung** — each would re-tier emq.3.2 out of
  NORMAL-risk (per-flow cleanup edits the shipped `@complete` → HIGH-risk; the `obliterate`-sweep is an
  `Admin`-surface change beyond a read rung). `admin.ex` stays untouched.
- **The O2 perf fold was DECLINED (a NAMED open carry, not a defect).** `complete` still does one host-side
  `HGET <child> 'parent'` per completion (`parent_of/3`); folding the parent-read into the claim result was the
  optional emq.3.2 fold (emq.3.1 L-4), **declined** (correctness-neutral, out of the read API's scope, expands
  the surface to the claim path). O2 remains an open carry to whichever rung wants the round-trip removed.
- **The none-key sentinel is a choice, recorded.** `dependencies/3` returns `{:ok, 0}` for a missing
  `:dependencies` key (the count's natural floor) rather than a typed `{:error, :not_a_flow}` — the build chose
  the honest "zero outstanding" reading and no new error vocabulary; the sentinel test pins it.

## Near-term tasks

### Harden (close the thin proofs)
- [ ] **Author the durable harness `echo/rungs/bus/emq_3_2_check.sh`** (the emq.3.1 `emq_3_1_check.sh` form,
      `LOOP_N`-parameterized, keying off `, 0 failures` + the exit code) so the ≥100 loop is a committed,
      re-runnable artifact, not a `/tmp`-tee'd ephemeral run (the emq.2.4 "proof ≠ harness" lesson). *(Owned by
      the Stage-3 harden track — Mars-2 authors the harness; this ledger records the requirement.)*
- [ ] Keep `flow_children_values` under the **≥100 loop owning the machine** alongside `flow_add`/`flow_fanin`
      (the read mints/fans-in a flow first — the same mint-collision surface).

### Gaps (missing tests — routed forward)
- [ ] **The flow-subkey lifecycle CLEANUP (L-5/N1 → the emq.3.x lifecycle rung).** Today the lifecycle test
      asserts the subkeys **survive**; the cleanup rung flips it to assert they are **retired** (the
      `obliterate`-sweep + per-flow cleanup). Both `del_job` AND `@drain`'s `wipe()` need the two subkeys added
      to their FIXED enumeration when the rung lands.
- [ ] **The cross-queue read (→ emq.3.3).** `children_values/3`/`dependencies/3` read the parent's **own** slot;
      a parent reading children that ran on a **different** slot is the emq.3.3 cross-queue crossing (Out here —
      the single-queue, one-level carve, INV8/N3).
- [ ] **The failure-policy reads (→ emq.3.4).** Reading `:failed`/`:unsuccessful` arrives with
      `fail_parent_on_failure` / `ignore_dependency_on_failure` at emq.3.4; emq.3.2 reads `:processed`/
      `:dependencies` only.

### Maintenance (keep green)
- [ ] Keep the **surface map PIN** current — `complete/5`'s docstring + result arg already shifted the `jobs.ex`
      surface (e.g. `add_log/5` moved down); the next `jobs.ex` rung drifts it again.
- [ ] Re-pin conformance (`{:ok, 46}` → new) on any flow change; the prior 45 byte-unchanged. Keep the 15-attr
      empty-Lua-diff proof on every flow rung that claims NORMAL-risk.

## Done-when

`redis-cli -p 6390 ping` → `TMPDIR=/tmp mix test --include valkey` green in `echo/apps/echo_mq` →
`Conformance.run/2 → {:ok, 46}` → `flow_children_values` green across `seq 1 100` owning the machine →
the **15-attr empty-Lua-diff proof** (per-attr SHA-256, `jobs.ex` + `flows.ex`) → the emq.1 + emq.2.{1–4} +
emq.3.1 non-flow suites unchanged (INV3).
