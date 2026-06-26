# Rate limiting

> Route: `/redis-patterns/flow-control/rate-limiting` · R6.01 module hub · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).

**Rate-limiting caps work to a budget per unit of time: count what is admitted in the current window, refuse or
defer once the count reaches the limit, and reset when the window rolls.** It is the simplest form of flow control —
a number, a window, and a comparison — and it is the first thing a shared service reaches for when one caller, one
tenant, or one burst could otherwise consume the whole system.

The store does the counting. A single counter key in Valkey, incremented once per admitted request and given a
lifetime equal to the window, is enough to answer one question for every worker at once: *has this budget been
spent?* Because the counter lives in the store and not in any process, the budget is the same number everywhere —
which is the property that makes a distributed rate limiter correct.

## How it works

A rate limit needs three things: a **counter**, a **window**, and a **limit**. The window counter is the smallest
arrangement that supplies all three with two commands.

On each admitted request, increment the counter for the current window:

```
INCR emq:{orders}:limiter        # → the running count for this window
```

`INCR` returns the new value after the increment, so the count comes back in the same round trip that records
it. If the returned count is `1`, this request opened the window — set the window's lifetime so it expires when the
window rolls:

```
PEXPIRE emq:{orders}:limiter 1000   # only on the first increment of the window
```

From then on, every request compares the returned count against the configured limit. While the count is at or below
the limit, the request is admitted. Once the count has reached the limit, the request is refused or deferred, and the
back-off is exactly the time left on the key — the window does the resetting for you:

```
PTTL emq:{orders}:limiter        # → ms until the budget resets (the back-off)
```

The window *is* the key's TTL. There is no separate timer, no scheduled reset, no clean-up sweep: when the key
expires, the count is gone and the next `INCR` recreates it at `1`. The counter is self-resetting because expiry is
the reset.

## Redis/Valkey commands used

- **`INCR`** — atomically increment the counter and return the new value. One round trip records the admission and
  reports the count.
- **`PEXPIRE`** (or **`EXPIRE`** for second precision) — set the counter's lifetime to the window length, applied on
  the first increment so the window starts when the first request of it arrives.
- **`SET … PX`** — an alternative first-write that sets the value and the expiry together; used where the count is
  written rather than incremented.
- **`PTTL`** (or **`TTL`**) — read the time remaining on the key. When over budget, this is the precise back-off a
  caller waits before retrying.
- **`GET`** — read the current count without changing it; the read side of a limiter check.
- **`HGET`** — read the configured limit from a side hash (`HGET emq:{orders}:meta max`) so the cap is data, not a
  hard-coded constant.

> **Notes on Valkey — INCR + EXPIRE atomicity.** `INCR` on a missing key creates it at `0` and increments to `1`
> atomically, so two concurrent first-requesters cannot both be told they opened the window. `INCR` and `EXPIRE` are
> two commands, though: between them a process could die and leave a counter with no expiry, which would never reset.
> The robust form binds them — a `SET key 1 PX <window> NX` first-write, or a short Lua script that increments and
> sets the expiry under one execution — so the window's lifetime is established in the same atomic step that opens it.
> See valkey.io/commands/incr and valkey.io/commands/pexpire.

## The four algorithms

The window counter is the simplest member of a family. Four algorithms trade simplicity against smoothness:

- **Fixed window** — one counter per fixed clock window (the shape above). Cheap and exact within a window, but
  bursty at the boundary: a caller can spend the full budget at the end of one window and again at the start of the
  next, admitting up to twice the limit across the seam.
- **Sliding window** — weight the previous window's count by the fraction still in view, or keep a sorted set of
  request timestamps trimmed to the last window. Smooths the boundary burst at the cost of more state.
- **Token bucket** — tokens accrue at a fixed rate up to a bucket size; each admitted request spends one. Permits
  bursts up to the bucket and sustains the refill rate — the right shape when short bursts are acceptable.
- **Leaky bucket** — a queue drained at a fixed rate, so output is constant regardless of how arrivals clump.
  Smooths the output rather than the input.

Each algorithm has its own dive:

- **Fixed & sliding windows** — `/redis-patterns/flow-control/rate-limiting/fixed-and-sliding-windows`
- **Token & leaky buckets** — `/redis-patterns/flow-control/rate-limiting/token-and-leaky-buckets`
- **Global, not local** — `/redis-patterns/flow-control/rate-limiting/global-not-local`

## Applied in EchoMQ

EchoMQ exposes the read side of a fixed-window limiter as a shipped surface. `EchoMQ.Metrics.get_rate_limit_ttl/3`
reads two keys — `emq:{orders}:limiter` and `emq:{orders}:meta` — and answers the remaining window in milliseconds,
`0` when the queue is not over budget. Its inline Lua is the fixed-window read, verbatim:

```lua
local max = tonumber(ARGV[1])
if max == 0 then
  max = tonumber(redis.call('HGET', KEYS[2], 'max') or '0')
end
if max > 0 and max <= tonumber(redis.call('GET', KEYS[1]) or '0') then
  local pttl = redis.call('PTTL', KEYS[1])
  if pttl > 0 then return pttl end
end
return 0
```

The shape maps one to one onto the pattern: `KEYS[1]` is `emq:{orders}:limiter`, the counter; the limit is read from
the `emq:{orders}:meta` hash field `max` (or passed directly); when the counter has reached `max` and the window has
time left, the remaining `PTTL` is returned as the over-budget back-off. `EchoMQ.Metrics.get_global_rate_limit/2`
reads that configured cap on its own (`HGET emq:{orders}:meta max`, `0` when unconfigured). When a limit is hit,
`EchoMQ.Meter.rate_limit_hit/2` emits `[:emq, :rate_limit, :hit]` with `%{delay: delay}` — the telemetry receipt that
work was held back, zero-cost when `:telemetry` is not loaded.

**The bridge.** Rate-limiting — cap requests to a budget per window — becomes the `emq:{orders}:limiter` counter
spent down to `max` (from `emq:{orders}:meta`) over its own `PTTL` window; `EchoMQ.Metrics.get_rate_limit_ttl/3` reads
the remaining window — the over-budget back-off — and `[:emq, :rate_limit, :hit]` is the receipt.

**Honest scope.** The *enforcement loop* — incrementing the counter on each claim and sending an over-budget job back
to wait — is the scaling layer, not this read surface; EchoMQ's claim path is taught in the EchoMQ course at
`/echomq/queue`. The counter and its window are the shipped primitive; wiring them into the dequeue point is the
deeper protocol work that course covers.

## When to use

- A shared service where one caller, tenant, or runaway loop could consume capacity others need.
- An external dependency with its own published limits you must stay under (a third-party API, an outbound message
  channel).
- Fair access across tenants on one cluster, where each tenant gets a budget per window.
- Protecting a backend from a thundering herd by capping admitted work to what the backend can absorb.

## When to avoid

- When the constraint is **concurrency**, not rate — a ceiling on simultaneous in-flight work is a different
  primitive (a counter of active leases, EchoMQ's `glimit`/`gactive` per-lane ceiling), not a per-window count.
- When exact fairness down to the request matters more than throughput — a fixed window's boundary burst admits up to
  twice the limit across the seam; reach for a sliding window or a token bucket instead.
- When the limited resource is purely local to one process and never shared — an in-process guard is simpler than a
  round trip to the store.
- When the cost of a refused request (a dropped event, a lost signal) is higher than the cost of letting it through —
  back-pressure or a queue may serve better than a hard refusal.

## References

### Sources

- Valkey — *INCR* (valkey.io/commands/incr) — atomic increment-and-return; the counter primitive.
- Valkey — *PEXPIRE* (valkey.io/commands/pexpire) — set a key's lifetime in ms; the window is the key's TTL.
- Valkey — *PTTL* (valkey.io/commands/pttl) — read ms remaining; the over-budget back-off.
- Valkey — *SET* (valkey.io/commands/set) — `PX`/`NX` for an atomic first-write of value and expiry together.
- Valkey — *Cluster specification* (valkey.io/topics/cluster-spec) — the `{q}` hash tag pins the counter to one slot,
  so it is one shared key every worker increments.
- Stripe — *Scaling your API with rate limiters* (stripe.com/blog/rate-limiters) — the request-rate vs concurrency
  distinction and the token-bucket policy in production.

### Related in this course

- `/redis-patterns/flow-control` — R6 · Flow Control & Scale (the chapter).
- `/redis-patterns/flow-control/rate-limiting/fixed-and-sliding-windows` — the window algorithms and the boundary
  burst.
- `/redis-patterns/flow-control/rate-limiting/token-and-leaky-buckets` — the burst-aware and rate-smoothing buckets.
- `/redis-patterns/flow-control/rate-limiting/global-not-local` — why the counter lives in the store.
- `/echomq/queue` — EchoMQ's Queue pillar: the limiter wired at the claim point, fair lanes, concurrency.
- `/bcs/bus` — the Valkey-native bus and the fair-lane architecture the figures draw from.
