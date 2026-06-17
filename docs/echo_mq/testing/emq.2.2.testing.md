# emq.2.2 — testing tasks

> Living test ledger for the **operator plane (queue lifecycle + job mutation)** rung (`76fc947c`,
> conformance 24 → 32). Strategy: [`../emq.testing.md`](../emq.testing.md). Spec triad:
> [`../specs/emq.2.2.md`](../specs/emq.2/emq.2.rungs/emq.2.2.md) · [`.stories.md`](../specs/emq.2/emq.2.rungs/emq.2.2.stories.md) ·
> [`.llms.md`](../specs/emq.2/emq.2.rungs/emq.2.2.llms.md). Re-probe the tree before trusting a `file:line` here.

## Proof state (as-built)

- **10 user stories**, all proven: 8 wire (3 queue-scope + 5 job-mutation), 1 ledger, 1 gate.
- **Test files**: `admin_test.exs` (10, wire — pause/resume/drain/obliterate) · `jobs_ops_test.exs`
  (17, wire — the five job mutations + the progress-event seam).
- **Conformance**: +8 scenarios — `queue_pause`, `drain`, `obliterate`, `update_data`, `update_progress`,
  `job_logs`, `remove_job`, `reprocess_job` → `{:ok, 32}`; new wire classes `EMQLOCK` / `EMQSTATE`
  registered with probes.
- **Surface**: `EchoMQ.Admin.pause/2`·`resume/2`·`drain/3`·`obliterate/3`; `Jobs.update_data/4`·
  `update_progress/4`·`add_log/5`·`get_job_logs/3`·`remove_job/4`·`reprocess_job/3`.

## Proof table

| US | Proven by | Lane | Conf. |
|---|---|---|---|
| US1 pause/resume | `admin_test.exs` | wire | `queue_pause` |
| US2 drain | `admin_test.exs` | wire | `drain` |
| US3 obliterate | `admin_test.exs` | wire | `obliterate` |
| US4 update_data | `jobs_ops_test.exs` | wire | `update_data` |
| US5 update_progress (+ event) | `jobs_ops_test.exs` | wire | `update_progress` |
| US6 logs (add/get, keep-N) | `jobs_ops_test.exs` | wire | `job_logs` |
| US7 remove_job (+ `EMQLOCK`) | `jobs_ops_test.exs` | wire | `remove_job` |
| US8 reprocess (+ `EMQSTATE`) | `jobs_ops_test.exs` | wire | `reprocess_job` |
| US9 design gate | `emq.2.2.md` D1 ADR | ledger | — |
| US10 · GATE | conformance tests | wire+pure | all 32 |

## Hot places (this rung)

- **Destructive ops are the §11.2 destructive-probe surface.** `drain`/`obliterate` delete state; the
  guarantee is "active survives, the act is gated behind a green precondition." `obliterate` is **bounded by
  `budget`** (returns `:more`/`:ok`) — the iterative path to completion is the easy thing to under-test.
- **`[RECONCILE]` bounded-completeness limits have no regression guard.** `obliterate` does **not** sweep
  `de:*` dedup orphans (no `SCAN` under declared keys); `drain` protects the repeat registry. These are
  deliberate — a future "fix" that breaks declared-keys must be caught by a test that pins the limit.
- **The cross-rung lock seam.** `remove_job` refuses a **locked** job (`EMQLOCK`), but the `:lock` subkey
  only became real at emq.2.3's `EchoMQ.Locks` plane — the 2.2 test sets the lock **by hand**. There is no
  integration test where a real held lease drives the refusal.
- **Pause is form-b (`meta.paused`), read by both claim paths.** The gate must hold on `@claim` **and**
  `@gclaim` (the lane path), not just the flat claim.

## Near-term tasks

### Harden (close the thin proofs)
- [ ] **Obliterate budget completion**: a large-queue test that drives `:more → :more → :ok`, proving
      bounded-completeness actually terminates and clears every set.
- [ ] **Pause covers both claim paths**: assert a queue-wide `pause/2` gates `@gclaim` (grouped/lane claim)
      as well as the flat `@claim` — the form-b promise.

### Gaps (missing tests)
- [ ] **`de:*` orphan regression**: pin that `obliterate` leaves a referrer-less `de:<id>` and that it is
      released at `remove`/`drain` time — so a declared-keys-breaking change is caught (strategy §5.5).
- [ ] **Cross-rung lock integration** (with emq.2.3): hold a real lease via `EchoMQ.Locks`, then assert
      `remove_job` refuses `EMQLOCK` untouched — replacing the hand-set lock key (strategy §5.4).
- [ ] **No-phantom-emit**: assert `update_progress` on a **missing** job does **not** publish (the PUBLISH
      is after the existence check) — the honesty edge.

### Maintenance (keep green)
- [ ] Keep the `emq.2.2.md` D1 ADR link live (US9 ledger-proven).
- [ ] Re-pin conformance on any operator-verb change; keep the `EMQLOCK`/`EMQSTATE` probes; the five-code
      fence union stays unextended.

## Done-when

`TMPDIR=/tmp mix test --include valkey` green in `echo/apps/echo_mq` → `Conformance.run/2` carries the 8
operator scenarios → the destructive paths (`drain`/`obliterate`) verified against a green precondition
(never a silent drop).
