# emq.throttle — agent brief (Mars build sheet)

> Derived FROM `emq.throttle.md` (authoritative) + `emq.throttle.stories.md`. Build to THIS; the body wins.
> DESIGN/SPEC doc — Mars writes the production code. No git. **HIGH-risk wire rung — Apollo mandatory.**
> Load the `echo-mq-implementor` skill (this is an `emq.*` rung).

## References (read first, in order)

1. **`echo/CLAUDE.md` §4** — the v2 master invariant (declared keys, server `TIME`, inline `Script.new/2`,
   braced/reserve keyspace). The law this rung must not break.
2. **`emq.throttle.md`** — the contract (§3) + the master-invariant compliance (§3.3 INV-K/INV-CLK/
   INV-SCRIPT). The what.
3. **`echo/apps/echo_mq/lib/echo_mq/jobs.ex:165-176`** — the `@claim` script: the EXACT server-clock idiom
   to mirror (`local t = redis.call('TIME'); local now = t[1] * 1000 + math.floor(t[2] / 1000)`) and the
   `Script.new/2` + `Connector.eval/5` call convention.
4. **`echo/apps/echo_mq/lib/echo_mq/lanes.ex:171-184`** — `claim/3`: a real `Connector.eval(conn, @script,
   keys, argv)` call site with KEYS/ARGV split and result mapping. Mirror the shape.
5. **`echo/apps/echo_wire/lib/echo_mq/connector.ex:65`** (`eval/5`) + **`script.ex:13`** (`Script.new/2`) —
   the wire path. **Frozen** — do not edit; call them.
6. **`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`** — the key builders (`queue_key/2` at `:14`,
   `reserve/1` at `:27`, `version_key/0` at `:30`). The throttle key is built HERE (host-side), per D-5.
7. **`echo/apps/echo_mq/lib/echo_mq/conformance.ex`** — the scenario registry; the `rate_consult` scenario
   (`:949`) as a pattern for a new scenario. **`conformance_run_test.exs:48`** pins `{:ok, 59}` — re-pin to
   `{:ok, 60}` (+ the scenario-list pinning test).

## Requirements (numbered; each traces to a story + an invariant)

| R | Requirement | Story | Invariant |
|---|---|---|---|
| R1 | `EchoMQ.Throttle` module + inline `@throttle = Script.new(:throttle, …)` — refill on server `TIME`, take-or-wait | S1, S2 | INV-CLK, INV-SCRIPT |
| R2 | `take/3..4` host API → `:ok \| {:wait, ms} \| {:error, term}` via `Connector.eval/5` | S1, S3, S4 | — |
| R3 | bucket key is the host-built `KEYS[1]` (the `name` reaches Lua only as `KEYS[1]`, never an ARGV-derived key); built in `Keyspace` per D-5 (`{emq}:throttle:<name>` reserve, recommended) | S5 | **INV-K** |
| R4 | the bucket starts full (burst = rate), idle buckets TTL out, all state on `KEYS[1]` | S1, S4 | — |
| R5 | one `throttle` conformance scenario, additive; re-pin `{:ok, 59}→{:ok, 60}` in both pinning tests; prior 59 byte-unchanged + git-verified | S6 | additive-minor |

## Execution topology

**Runtime shape:** a stateless host module + one Valkey-resident bucket per name. No GenServer (the bucket
state lives in Valkey, read/modified atomically by the script). The send path (cmn.2) calls
`Throttle.take(conn, "tg:broadcast", 27, 1000)` before each send; `{:wait, ms}` → the worker's existing
`enqueue_in` defer+ack.

**Build-order DAG:**
```
Keyspace.throttle_key/1 (host key builder, declared) ─▶ @throttle Script.new ─▶ take/3..4 (Connector.eval)
                                                                                      │
                                                              conformance `throttle` scenario ─▶ re-pin {:ok,60}
```

**Exact files touched:**
- `echo/apps/echo_mq/lib/echo_mq/throttle.ex` — NEW (`EchoMQ.Throttle`, the script + `take/3..4`)
- `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — ADD `throttle_key/1` (the declared reserve key builder)
- `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — ADD the `throttle` scenario (additive)
- `echo/apps/echo_mq/test/conformance_run_test.exs` — re-pin `{:ok, 60}`
- `echo/apps/echo_mq/test/conformance_scenarios_test.exs` — re-pin the scenario list/count
- `echo/apps/echo_mq/test/throttle_test.exs` — NEW (S1–S5 acceptance, `--include valkey`)
- **NOT touched:** `echo_wire/*` (Connector/Script/RESP/Pool frozen — called, not edited); any third app;
  `mix.lock`.

## Agent stories (Directive + Acceptance gate)

- **A1 — The key builder.** *Directive:* add `Keyspace.throttle_key(name)` building the declared reserve
  `{emq}:throttle:<name>` (D-5); validate `name` excludes the §6 separator/brace bytes. *Acceptance:* the
  key is host-built and passed as `KEYS[1]` (INV-K, S5).
- **A2 — The script.** *Directive:* `@throttle = Script.new(:throttle, …)` — read `TIME`, refill
  `min(burst, tokens + elapsed*rate/per_ms)`, take `cost` or compute `wait_ms`, write back + TTL, all on
  `KEYS[1]`; `rate/per_ms/cost/burst` via ARGV. Mirror the `jobs.ex:172-173` clock idiom. *Acceptance:* S1,
  S2 (caps at rate; refills on server clock — INV-CLK, INV-SCRIPT).
- **A3 — `take/3..4`.** *Directive:* the host API mapping the script return (`0 → :ok`, `n → {:wait, n}`) via
  `Connector.eval/5`. *Acceptance:* S1, S3, S4.
- **A4 — Conformance.** *Directive:* add the `throttle` scenario (grant up to rate, refuse past it, refill on
  the clock — POSITIVE liveness); re-pin both tests. *Acceptance:* S6 (`{:ok, 60}`, prior 59 byte-unchanged
  git-verified).

## Gate (run before reporting — wire rung)

From `echo/apps/echo_mq`: `asdf current`; `valkey-cli -p 6390 ping` → `PONG`; `TMPDIR=/tmp mix compile
--warnings-as-errors`; `TMPDIR=/tmp mix test --include valkey`; `EchoMQ.Conformance.run/2 → {:ok, 60}`; the
≥100 determinism loop `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done`
(Throttle is a clock/lease surface — same-ms window contention is the hazard). Verify the lib diff: prior
`Script.new` bodies byte-unchanged (`grep redis.call` on the diff = only the new `@throttle`).

## Prompt (the comprehensive task)

> Build emq.throttle: `EchoMQ.Throttle`, a Valkey server-clock token bucket for a cluster-wide rate cap.
> Add `Keyspace.throttle_key(name)` building the DECLARED reserve key `{emq}:throttle:<name>` (D-5), the
> bucket key the script reads as `KEYS[1]` — the `name` reaches Lua ONLY as the host-built key, never an
> ARGV-derived key (the master invariant's declared-keys rule, the emq.2.1 F-1 class). Write the inline
> `@throttle = Script.new(:throttle, …)`: read `redis.call('TIME')` for the clock (mirror jobs.ex:172-173),
> lazily refill `min(burst, tokens + elapsed*rate/per_ms)` with burst=rate, take `cost` (default 1) or return
> the ceil wait_ms, write back tokens+updated_ms with a TTL, ALL state on KEYS[1], rate/per_ms/cost/burst via
> ARGV. `take(conn, name, rate, per_ms, cost \\ 1)` maps the return via `Connector.eval/5` →
> `:ok | {:wait, ms}`. Add ONE additive conformance scenario `throttle` proving the cap POSITIVELY (drive
> past the rate, assert `{:wait, _}`, advance the clock, grant again) and re-pin `{:ok, 59} → {:ok, 60}` in
> both pinning tests with the prior 59 byte-unchanged + git-verified. Do NOT edit echo_wire (Connector/Script
> frozen), any third app, or mix.lock. Frame propagation: no gendered pronouns for agents; no
> perceptual/interior verbs; no first-person narration. Run the full echo_mq wire gate + the ≥100
> determinism loop before reporting.
