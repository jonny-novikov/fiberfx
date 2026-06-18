# emq.1 — testing tasks

> Living test ledger for the **scheduler + retry vocabulary** rung (`e0fa9b03`, conformance 14 → 18).
> Strategy: [`../emq.testing.md`](../emq.testing.md). Spec triad: [`../specs/emq.1.md`](../specs/emq.1/emq.1.md) ·
> [`.stories.md`](../specs/emq.1/emq.1.stories.md). Re-probe the tree before
> trusting a `file:line` here.

## Proof state (as-built)

- **7 user stories**, all proven (§ matrix below): 4 wire, 2 pure cores, 1 ledger.
- **Test files** (`echo/apps/echo_mq/test/`): `scheduled_enqueue_test` · `repeat_test` · `pump_test` ·
  `resubscribe_test` (wire) · `backoff_test` · `pump_core_test` · `consumer_spec_test` (pure) ·
  `consumer_test` (wire, the poison/retry path).
- **Conformance**: +4 scenarios — `schedule`, `repeat`, `backoff`, `resubscribe` → `{:ok, 18}`.
- **Surface**: `Jobs.enqueue_at/5`·`enqueue_in/5` + inline `@schedule`; `EchoMQ.Repeat`;
  `EchoMQ.Backoff.delay_ms/2`; `EchoMQ.Pump` + `EchoMQ.Pump.Core`; `Jobs.retry/7`·`promote/3`;
  `Connector` resubscribe in the `:reconnect` arm (`echo_wire`).

## Proof table

| US | Proven by | Lane | Conf. |
|---|---|---|---|
| US1 scheduled enqueue | `scheduled_enqueue_test.exs` | wire | `schedule` |
| US2 repeatables | `repeat_test.exs` | wire | `repeat` |
| US3 retry + poison drill | `backoff_test.exs` (pure) + `consumer_test.exs` (raise→retry→dead) | pure+wire | `backoff` |
| US4 promote pump | `pump_test.exs` + `pump_core_test.exs` (pure) | wire+pure | (via run) |
| US5 resubscribe | `resubscribe_test.exs` | wire | `resubscribe` |
| US6 design gate | `emq.1.md` D1 ADR + declared-keys analysis | ledger | — |
| US7 · GATE | `conformance_run_test.exs` + `conformance_scenarios_test.exs` | wire+pure | all 18 |

## Hot places (this rung)

- **Same-millisecond mint collision** — the order theorem (byte = mint) is proven by two occurrences, never
  under same-ms pressure, the exact condition that flaked the emq.0/emq.1 arc.
- **Pump determinism** — `pump_test` soft-skips on a wire hiccup; a skip reads as a pass. The pump beats on
  a timer, so it is a flake surface that belongs under the ≥100 loop.
- **Resubscribe timing** — `resubscribe_test` kills the socket (`CLIENT KILL`); the reconnect wait is a
  race if it leans on a sleep.
- **Poison-drill depth** — `:dead` at max attempts is asserted; the **content** of `last_error` browsable
  in the morgue (not just the tag) is the operator-facing promise.

## Near-term tasks

### Harden (close the thin proofs)
- [ ] Replace `pump_test`'s soft-skip-on-hiccup with a deterministic drive via `Pump.sweep/1`, so a wire
      failure fails loudly instead of skipping silently.
- [ ] Run the `pump` + `repeat` + mint suites under the **≥100 determinism loop** owning the machine;
      commit the run record (the same-ms mint surface — strategy §5.2/§5.7).
- [ ] De-race `resubscribe_test`'s `CLIENT KILL` → reconnect wait (poll for the re-issued subscription, no
      fixed sleep).

### Gaps (missing tests)
- [ ] **Property/stress test of the order theorem**: mint K repeat occurrences in a tight same-ms loop;
      assert all ids distinct and `pending` walked `REV BYLEX` = newest-first (strategy §5.7).
- [ ] **Poison drill content**: after exactly max attempts, assert the `last_error` payload is browsable in
      the morgue (byte-content, not just `:dead`).
- [ ] **Pump restart idempotency**: kill the supervised pump mid-sweep; assert no due entry is lost and none
      double-promoted (INV5).

### Maintenance (keep green)
- [ ] Keep the `emq.1.md` D1 ADR link live — US6 is ledger-proven; a dead link breaks its only proof.
- [ ] On any wire change to schedule/repeat/backoff/resubscribe: re-pin conformance in **both** tests
      (the registry name-order pin + the `{:ok, N}` run pin), prior scenarios byte-unchanged.

## Done-when

`asdf current` → `redis-cli -p 6390 ping` → `TMPDIR=/tmp mix test --include valkey` green in
`echo/apps/echo_mq` → `Conformance.run/2 → {:ok, 18}` (within the rolled-up 37) → the pump/mint suites green
across `seq 1 100`.
