# EchoWire — testing strategy

The posture for an **additive layer above the wire**. The wire's own correctness is already pinned by the
`echo_wire` suite and the `echo_mq` 52-scenario conformance; a client-core rung adds unit coverage for the new
construction surface and **re-proves the floor is byte-stable**, rather than registering new conformance
scenarios. Scope is [`ewr.roadmap.md`](ewr.roadmap.md).

## The three bands

1. **Construction unit tests (no Valkey).** A `EchoWire.Pipe` is a pure accumulator: a verb appends one
   command-list, `exec` is the only side effect. So most coverage is offline and deterministic — assert that
   `new |> set(...) |> get(...)` accumulates exactly `[["SET",...],["GET",...]]` in order, that `command/2`
   appends a raw command-list verbatim, that an empty pipe's `exec` answers `{:error, :empty_pipeline}`. These
   run without a server and never flake.
2. **The `:valkey` round-trip gate.** A `@tag :valkey` suite drives a real pipeline through `Connector` (and
   the `Pool`) against Valkey on `6390`: `exec/1` returns replies 1:1 with the appended commands; `exec_txn/1`
   returns the `EXEC` array; `exec_noreply/1` answers `:ok`; the same `%Pipe{}` works against both a `Connector`
   and an `EchoMQ.Pool` for `exec/1`, while `exec_txn` / `exec_noreply` require a `Connector` (the pool carries
   no `transaction_pipeline`/`noreply_pipeline`). Run with `TMPDIR=/tmp mix test --include valkey` from inside
   `echo/apps/echo_wire/`.
3. **The frozen-floor proof (standing).** Every rung re-pins, byte-stable: the facade-freeze
   (`echo_wire_facade_test.exs`, 11 verbs unchanged) and the conformance count (`echo_mq`,
   `Conformance.run/2 → {:ok, 52}`, `conformance_run_test.exs:45`). The new layer is *above* the conformance
   boundary, so the additive-minor law is **not engaged** — no scenario is registered, no `registry.json` is
   written, and `grep redis.call` on the lib diff is `0`.

## Determinism posture

A Movement-I rung adds **no id-mint, no new process, and no lease** — the construction surface is synchronous
pure functions and the round-trips are deterministic request/reply. The same-millisecond branded-id mint hazard
cannot arise, so the **≥100-iteration determinism loop is not run** (running it would forge load the rung does
not introduce). The honest posture is a **multi-seed sweep** of the construction + round-trip suites
(`for s in 0 1 42 312540 999999; do TMPDIR=/tmp mix test --seed $s || break; done`) plus this statement. A
later caching rung that introduces a tracking process *does* re-engage the loop.

## The per-app gate ladder (from `echo/apps/echo_wire/`)

```bash
# re-probe the toolchain from the app dir — never hardcode it
cat .tool-versions
valkey-cli -p 6390 ping                         # → PONG
TMPDIR=/tmp mix compile --warnings-as-errors
TMPDIR=/tmp mix test                            # + --include valkey for the round-trip gate
```

Green means: the construction suite passes, the `:valkey` round-trips pass, the facade is still 11 verbs, and
`Conformance.run/2 → {:ok, 52}`.

---

Roadmap: [`ewr.roadmap.md`](ewr.roadmap.md) · Founding rung stories:
[`specs/ewr.1/ewr.1.1.stories.md`](specs/ewr.1/ewr.1.1.stories.md)
