# emq.throttle — `EchoMQ.Throttle`: a Valkey server-clock token-bucket primitive

> **Status:** SPEC (Venus). Source of truth = this body. DESIGN/SPEC ONLY — Mars builds. Canon:
> `docs/codemojex/notifications/notifications.design.md` §6 (D-1, ruled) + `echo/CLAUDE.md` §4 (the v2 master
> invariant). **Risk:** HIGH — a NEW wire primitive + a NEW keyspace position under the master invariant;
> **Apollo mandatory**. This rung lives in `echo/apps/echo_mq` (the bus), an `emq.*` rung.

## 1. Intent

Add `EchoMQ.Throttle` — a **cluster-wide, server-clock token bucket** the Broadcast send path gates on for
the 27 req/s Telegram cap (90% of 30/s). The existing `EchoMQ.Lanes.limit/4` is a *concurrency ceiling*
(`lanes.ex:216`), NOT a requests-per-second limiter, and `EchoMQ.Meter` is `:telemetry`-only — **no
server-clock token bucket exists in echo_mq today** (reconcile, design §1.3). This rung is that primitive.

It is the only echo_mq surface the Broadcast system needs; everything else is codemojex (cmn.*). It is an
**additive protocol minor** (a new registered script + one conformance scenario), NOT a wire break.

## 2. Deliverables

| # | Deliverable | Surface |
|---|---|---|
| D1 | The `@throttle` Lua script (inline `Script.new/2`) — refill on server `TIME`, take-or-wait | `EchoMQ.Throttle` (new module) |
| D2 | `take/3` and `take/4` — the host API | `EchoMQ.Throttle.take(conn, name, rate, per_ms)` / `take(conn, name, rate, per_ms, cost)` |
| D3 | The keyspace position (declared, under the master invariant) | per D-5: `{emq}:throttle:<name>` reserve (recommended) |
| D4 | One conformance scenario `throttle`, additive | `EchoMQ.Conformance` — re-pin `{:ok, 59} → {:ok, 60}` |

## 3. The contract

### 3.1 `take/3..4`
- **`take(conn, name, rate, per_ms, cost \\ 1) :: :ok | {:wait, ms} | {:error, term}`**
  - `name` — the bucket name (a binary; e.g. `"tg:broadcast"`). The bucket is keyed per-name (§3.3).
  - `rate` — tokens per `per_ms` window (e.g. `27` per `1000` ms = 27/s).
  - `per_ms` — the window in ms.
  - `cost` — tokens to take (default 1).
- **Pre:** `rate > 0`, `per_ms > 0`, `cost >= 1`, `name` a binary.
- **Post:** `:ok` iff `cost` tokens were **atomically** taken (the bucket had them after refill); else
  `{:wait, ms}` where `ms` = the minimum delay until a retry of the same `cost` could succeed.
- **Burst:** the bucket capacity (burst) = `rate` (a full window's worth). A bucket starts full.

### 3.2 The script (shape — Mars writes the exact bytes; this fixes the algorithm + the invariant compliance)

A single inline `Script.new(:throttle, …)` executed via `EchoMQ.Connector.eval/5` (the path every echo_mq
script uses, e.g. `Lanes.claim` → `Connector.eval(conn, @gclaim, keys, argv)`). The body:
1. Read the server clock — **the canonical idiom from `jobs.ex:172-173`**:
   ```lua
   local t = redis.call('TIME')
   local now = t[1] * 1000 + math.floor(t[2] / 1000)   -- ms, server-authoritative
   ```
2. Read the bucket state from the bucket key (`KEYS[1]`): `tokens` and `updated_ms` (a hash, or two fields).
   Missing → start full (`tokens = burst`, `updated_ms = now`).
3. Lazy refill: `tokens = min(burst, tokens + (now - updated_ms) * rate / per_ms)`.
4. If `tokens >= cost`: `tokens = tokens - cost`; write back `tokens`, `updated_ms = now`; set a TTL on the
   bucket key (idle buckets expire); return `0` (host maps → `:ok`).
5. Else: compute `wait_ms = ceil((cost - tokens) / rate * per_ms)`; write back the refilled `tokens` +
   `updated_ms`; return `wait_ms` (host maps → `{:wait, wait_ms}`).

`rate`, `per_ms`, `cost`, `burst` are passed as `ARGV`. **All state reads/writes are on `KEYS[1]`** — the
single declared bucket key.

### 3.3 The keyspace (the master-invariant-critical part)

Per **D-5** (Operator/design-canon's call — it touches the wire grammar):
- **Recommended:** a single first-byte-disjoint reserve `{emq}:throttle:<name>` — the `{emq}:` reserve is
  the v2 grammar's disjoint namespace for cross-cutting keys (the version record lives there). One hashtag
  `{emq}`, no per-name brace proliferation; all throttle buckets co-locate on one slot.
- **Alternative:** a per-name braced key `emq:{throttle:<name>}:tb` — buckets shard across slots by name.

**Invariant compliance (the master invariant, `echo/CLAUDE.md` §4):**
- **INV-K (declared keys):** the bucket key is the script's `KEYS[1]` — host-built, passed in `KEYS`, never
  derived from an `ARGV` value inside Lua. The `name` reaches Lua only as the host-built `KEYS[1]`. *(This is
  the exact rule the emq.2.1 F-1 finding hard-pinned — an `ARGV`-passed base is NOT a declared root.)*
- **INV-CLK (server clock):** the bucket's time is `redis.call('TIME')` inside the script — never a
  host/node clock. This is what makes the cap genuinely cluster-wide (every node reads one clock). *(The
  lease-clock rule extended to the bucket window — a rate window IS a lease on throughput.)*
- **INV-SCRIPT (inline):** the script is `Script.new/2` in the module, never `priv/`.
- **INV-BRAND:** `Throttle` buckets are NOT branded-`JOB`-id-keyed (a throttle is a named cross-cutting
  budget, not a job) — but the key is a *declared, grammar-total* position (the reserve), so the keyspace
  totality holds. The bucket name charset must exclude the brace/separator bytes (the §6 charset) so the key
  is unambiguous; the host validates `name`.

### 3.4 Conformance — additive-minor (the `echo/CLAUDE.md` §3 law)
- Add ONE scenario `throttle`: a bucket of `rate=2, per_ms=1000` grants the 1st and 2nd `take` (`:ok`),
  **refuses the 3rd** within the window (`{:wait, ms}` with `ms > 0`), and — after the server clock advances
  a window — grants again. **Positive proof of liveness:** the scenario MUST drive `take` past the rate and
  assert the `{:wait, _}` refusal — a no-op that never exceeds the rate must NOT pass it (design's
  gate-liveness law).
- **Prior 59 scenarios byte-unchanged + git-verified;** the new one probe-registered; re-pin the count to
  `{:ok, 60}` in **both** pinning tests (`conformance_run_test.exs:48` and the scenario-list test).

## 4. Out of scope (named)

- The per-chat 1/s fairness stays the in-memory `Codemojex.RateLimiter` (no round-trip; correct
  per-node-per-chat). `Throttle` is the GLOBAL cap only.
- The send path that CALLS `Throttle` → **cmn.2** (codemojex). This rung ships the primitive + its
  conformance, callable but not yet wired into the worker.
- Any second `Throttle` use (a future bot, a webhook budget) — the primitive generalizes, but this rung
  proves it once.

## 5. Acceptance (full Given/When/Then in `emq.throttle.stories.md`)

- A bucket grants up to `rate` takes per window, then `{:wait, ms}`; refills on the server clock.
- The wait is the true minimum delay (a retry after `ms` succeeds).
- `cost > 1` takes `cost` tokens (or waits for them).
- Two notional callers on ONE Valkey share ONE bucket (cluster-wide proof: two connections, one bucket key,
  combined takes obey the single cap).
- The conformance scenario passes and the count re-pins to `{:ok, 60}` with the prior 59 byte-unchanged.

## 6. Gate ladder (per-app, echo_mq — wire rung)

From `echo/apps/echo_mq`: re-probe `asdf current` / `.tool-versions`; `valkey-cli -p 6390 ping` → `PONG`;
`TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test --include valkey`;
`EchoMQ.Conformance.run/2 → {:ok, 60}` (additive-minor: prior 59 byte-unchanged + git-verified, the new
`throttle` probe-registered, count re-pinned in both pinning tests). **The ≥100 determinism loop applies** —
`Throttle` is a lease/clock surface (server-clock window contention is the same-ms hazard class), so ratify
with `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done`.
