# emq.2.1 — testing tasks

> Living test ledger for the **read plane (introspection & metrics)** rung (`7d98ef86`, conformance
> 18 → 24). Strategy: [`../emq.testing.md`](../emq.testing.md). Spec triad:
> [`../specs/emq.2.1.md`](../specs/emq.2/emq.2.rungs/emq.2.1.md) · [`.stories.md`](../specs/emq.2/emq.2.rungs/emq.2.1.stories.md) ·
> [`.llms.md`](../specs/emq.2/emq.2.rungs/emq.2.1.llms.md). Re-probe the tree before trusting a `file:line` here.

## Proof state (as-built)

- **8 user stories**, all proven: 6 wire reads, 1 ledger, 1 gate.
- **Test file**: `metrics_test.exs` (20 cases, 6 `describe` blocks, all `:valkey`) maps one-describe-per-US
  to US1–US6.
- **Conformance**: +6 scenarios — `counts`, `state`, `metrics`, `dedup`, `rate`, `lane_depth` → `{:ok, 24}`.
- **Surface** (`EchoMQ.Metrics`, pure reads): `get_counts/3` · `get_job/3` · `get_job_state/3` ·
  `get_metrics/3` · `get_deduplication_job_id/3` · `get_rate_limit_ttl/3` · `get_global_rate_limit/2` ·
  `is_maxed/2` · `lane_depth/3` · `lane_depths/3`.

## Proof table

| US | Proven by (`metrics_test.exs` describe) | Lane | Conf. |
|---|---|---|---|
| US1 counts | counts (cardinality; unknown-state error; read mutates nothing) | wire | `counts` |
| US2 job + state | lookup (3-field row; holding set; missing→absent; bad id raises) | wire+pure | `state` |
| US3 metrics | metrics (terminal counters; `:data` honest-0) | wire | `metrics` |
| US4 dedup read | dedup (`de:<id>`→branded id; absent→absent) | wire | `dedup` |
| US5 rate / is_maxed | rate (TTL read; `EMQRATE` at ceiling) | wire | `rate` |
| US6 lane depth | lane (per-group backlog over `Lanes.depth/2`) | wire | `lane_depth` |
| US7 design gate | `emq.2.1.md` D1 (the `EchoMQ.Metrics` placement ADR) | ledger | — |
| US8 · GATE | conformance tests | wire+pure | all 24 |

## Hot places (this rung)

- **Pure-column thinness** — all six reads are `:valkey`-only; an offline `mix test` proves *none* of the
  read plane. The arg-validation guards (unknown state, ill-formed id raising at the key builder) are the
  one part that could run offline but are mostly folded into the wire tests.
- **The `:data` rolling series is honest-0** (deferred to emq.8). Nothing pins that it *stays* 0 — when
  emq.8 wires it, a silent shape change could pass unnoticed.
- **The G1 rate-gate fork is open.** `is_maxed`/`EMQRATE` ships as a pure-read primitive; emq.2.4 (Arm 2)
  wires it into the claim transition. The current behavior has no pinning test, so the fork risks being a
  silent drift instead of a deliberate, diffable change.

## Near-term tasks

### Harden (close the thin proofs)
- [ ] Add a **pure guard column** for the read verbs: unknown-state → `{:error, {:unknown_state, _}}`,
      ill-formed branded id raises at the key builder before any wire — so the read plane has offline proof.

### Gaps (missing tests)
- [ ] **`:data` tripwire**: assert `get_metrics` `:data` series length `== 0` (honest-0); it fails loudly
      the day emq.8 wires the series, forcing the contract update (strategy §4 / emq.8).
- [ ] **Pin the G1 fork**: a test that fixes the current `is_maxed`/`EMQRATE` pure-read behavior so emq.2.4's
      Arm-2 claim-wiring shows as a deliberate diff (strategy §5.8).
- [ ] **No-phantom-set**: assert `get_counts("completed")` reads the metrics counter, not a set (the bus has
      no `completed` set) — pin the contract that prevents a phantom read.

### Maintenance (keep green)
- [ ] Keep the `emq.2.1.md` D1 placement ADR link live (US7 ledger-proven).
- [ ] Re-pin conformance (registry + `{:ok, N}`) on any read change; prior scenarios byte-unchanged.

## Done-when

`TMPDIR=/tmp mix test --include valkey` green in `echo/apps/echo_mq` → `Conformance.run/2` carries the 6
read scenarios → multi-seed sweep green (this is a **pure-read rung**: the strategy's determinism posture is
the seed sweep, **not** the ≥100 loop — running the loop would forge load this rung does not introduce).
