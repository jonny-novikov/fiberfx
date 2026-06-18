# emq.throttle — acceptance stories (Given/When/Then)

> Derived FROM `emq.throttle.md` (authoritative; the body wins). Connextra + Gherkin; each names its
> invariant(s); the Coverage map proves every Deliverable → its story. The role is the SEND PATH (cmn.2 is
> the first caller) and the bus operator.

## Story S1 — The bucket caps at `rate` per window (D1, D2, INV-CLK)

**As a** broadcast send path, **I want** a named bucket to grant at most `rate` takes per `per_ms` window,
**so that** the global Telegram cap (27/s) is never exceeded.

- **Given** a fresh bucket `"t1"` with `rate=2, per_ms=1000`,
- **When** `take/4` is called three times within the same window,
- **Then** the 1st and 2nd return `:ok`,
- **And** the 3rd returns `{:wait, ms}` with `ms > 0` — INV-CLK *(positive proof: the test drives PAST the
  rate and asserts the refusal; a sequence that never exceeds 2 must NOT pass this story).*

## Story S2 — The bucket refills on the SERVER clock (D1, INV-CLK)

**As a** the system, **I want** the refill timed by the Valkey server clock (`TIME`), not any node clock,
**so that** the cap holds across every node and FLAME worker.

- **Given** an exhausted bucket returning `{:wait, ms}`,
- **When** the server clock advances at least one window,
- **Then** the next `take/4` returns `:ok` again,
- **And** no node-local clock influences the result (the refill arithmetic uses only `redis.call('TIME')`).

## Story S3 — The wait is the true minimum delay (D2)

**As a** send path that defers over budget, **I want** `{:wait, ms}` to be the smallest delay after which a
retry of the same cost succeeds, **so that** a deferred send re-enqueues exactly long enough.

- **Given** a bucket that just refused a `take` with `{:wait, ms}`,
- **When** a retry is issued after `ms` (server time),
- **Then** the retry returns `:ok` — `ms` was sufficient and not grossly over (ceil to the next whole token).

## Story S4 — `cost > 1` takes or waits for `cost` tokens (D2)

**As a** a caller needing multiple tokens, **I want** `take/5` with `cost` to take `cost` at once, **so
that** a batched admit is one atomic decision.

- **Given** a bucket with `rate=5, per_ms=1000`, full,
- **When** `take(conn, "t4", 5, 1000, 3)` is called,
- **Then** it returns `:ok` and 3 tokens are consumed,
- **And** a subsequent `take` with `cost=5` returns `{:wait, ms}` (only 2 remain).

## Story S5 — One bucket is shared cluster-wide (D1, D3, INV-CLK, INV-K)

**As a** an operator running codemojex on >1 node, **I want** all nodes to share ONE bucket per name, **so
that** the 27/s cap is a single cluster budget, not per-node.

- **Given** TWO Valkey connections (notional two nodes) and one bucket name `"t5"` (`rate=2, per_ms=1000`),
- **When** connection A takes once and connection B takes twice within a window,
- **Then** the combined takes obey the single cap — the 3rd (whichever connection) gets `{:wait, ms}`,
- **And** the bucket key is the host-built `KEYS[1]` (the name reaches Lua only as the declared key, never an
  `ARGV`-derived key) — INV-K.

## Story S6 — Conformance registers the scenario additively (D4)

**As a** the bus maintainer, **I want** the `throttle` scenario added under the additive-minor law, **so
that** the protocol minor is provable and prior behavior is byte-unchanged.

- **Given** `EchoMQ.Conformance.run/2` returns `{:ok, 59}` at HEAD,
- **When** the `throttle` scenario is added (a bucket grants up to rate, refuses past it, refills on the
  clock),
- **Then** `run/2` returns `{:ok, 60}`,
- **And** the prior 59 scenarios are byte-unchanged (git-verified),
- **And** the count is re-pinned in both pinning tests.

---

## Coverage map

| Deliverable | Story | Invariant(s) |
|---|---|---|
| D1 `@throttle` script | S1, S2, S5 | INV-CLK, INV-K |
| D2 `take/3..4` | S1, S3, S4 | — |
| D3 keyspace position | S5 | INV-K, INV-SCRIPT (the bucket key is declared, the script inline) |
| D4 conformance scenario | S6 | additive-minor |

**Gate-liveness note:** S1 and the conformance scenario (S6) are proved POSITIVELY — the test MUST exceed
the rate and assert the `{:wait, _}` refusal; a no-op that never crosses the rate must fail the story. S5
proves the cluster-wide claim with TWO connections sharing ONE bucket key (a present multi-connection
precondition that actually exercises the shared cap), not a single-connection run that would pass vacuously.
