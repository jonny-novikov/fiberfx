# R6.01.1 · Fixed & sliding windows

> Route: `/redis-patterns/flow-control/rate-limiting/fixed-and-sliding-windows` · dive
> Grounding: `echo/apps/echo_mq/lib/echo_mq/metrics.ex` (`EchoMQ.Metrics.get_rate_limit_ttl/3`, the `@rate_ttl`
> Lua — the fixed-window counter, read side) · `meter.ex` (`EchoMQ.Meter.rate_limit_hit/2` — the receipt) ·
> Valkey `INCR` / `PEXPIRE` / `PTTL` / `GET` / `HGET`.

The simplest rate limiter is a counter and a clock: count what is admitted in the current slice of time, refuse
once the count reaches the cap, and let the count reset when the slice rolls. That is the **fixed window**, and
it is the exact shape EchoMQ ships — a `emq:{q}:limiter` counter spent down against a configured `max`, where
the window *is* the key's own TTL. This dive reads that real counter, shows the one place it gives more away
than intended — the **boundary burst** at the seam between two windows — and then sharpens it into a **sliding
window**: either by weighting the previous window's count, or by keeping a sorted log of timestamps and counting
only those still in view.

## The fixed window

Pick a window — one second, one minute — and a cap `max`. Keep one counter per window. On each admitted request,
increment the counter; on the first increment, set the counter to expire when the window ends; refuse any request
that arrives while the counter has already reached `max`. The reset is not a scheduled job — it is the key
expiring. When the key is gone, the next request recreates it at one, and a fresh window has begun.

Two Valkey commands carry the whole algorithm. `INCR` creates the key at one if it does not exist and returns the
new value atomically — the count and the create are a single operation, so two concurrent admits can never both
read zero and both write one. `PEXPIRE` arms the window: set it once, on the first hit, to the window length in
milliseconds, and never reset it again — resetting it on every hit would slide the deadline forward forever and
the window would never roll. The remaining lifetime, read with `PTTL`, is precisely how long until the budget
resets — the back-off a request over budget must wait.

EchoMQ ships this as a read. `EchoMQ.Metrics.get_rate_limit_ttl/3` declares two keys — the limiter counter
`emq:{q}:limiter` and the queue's meta hash `emq:{q}:meta` — and answers the remaining window in milliseconds,
or `0` when the queue is not over budget:

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

The script reads the cap (`HGET emq:{q}:meta max` when the caller passes zero), compares the live counter against
it (`GET emq:{q}:limiter`), and — only when the counter has reached `max` and the window still has time left —
returns the remaining `PTTL`. A `0` means admit; any positive number is the milliseconds to wait. Every key the
script touches is declared in `KEYS[]`, so the `{q}` hashtag pins both keys to one cluster slot and the read is
atomic and slot-legal. When a limit is hit, `EchoMQ.Meter.rate_limit_hit/2` emits `[:emq, :rate_limit, :hit]`
with the delay — a telemetry receipt, zero-cost when `:telemetry` is not loaded.

## The boundary burst

The fixed window has one flaw, and it lives at the seam. The counter resets the instant the window rolls, with no
memory of how the previous window was spent. A client that times its requests to the boundary can spend the whole
budget at the very end of one window and the whole budget again at the very start of the next — `max` requests in
the last moment of window one, `max` more in the first moment of window two. Across the short span straddling the
seam, the client sent up to **2 × `max`** requests, while every window's own counter stayed within its limit.

The cause is that the fixed window measures against a fixed grid of slices, not against a span that moves with the
request. A burst that lands inside one slice is bounded; a burst that lands across a slice boundary is bounded per
slice but not across the seam, because the two slices are counted independently. The window the limiter enforces
and the window the client experiences are not the same window.

For most coarse budgets the boundary burst is acceptable — a queue capped at a thousand jobs a minute that briefly
admits closer to two thousand across one boundary is rarely a problem, and the fixed window's single counter and
single TTL make it the cheapest limiter to run. The boundary burst matters when the cap is the real protection —
a tight per-user budget guarding a scarce downstream — and that is where the sliding window earns its extra state.

## The sliding refinement

A sliding window measures against a span that ends *now* and reaches back exactly one window, so there is no grid
and no seam to exploit. Two refinements reach it, and they trade memory against exactness.

The **sliding-window counter** keeps the fixed window's cheap shape and corrects the seam by arithmetic. Keep two
counters — the current window and the previous one — and weight the previous window's count by the fraction of it
still inside the rolling span. If the rolling window is one minute and fifteen seconds have elapsed into the
current window, three-quarters of the previous window is still in view, so the estimate is the current count plus
three-quarters of the previous count. It is an approximation — it assumes the previous window's requests were
spread evenly — but it is bounded, smooth across the seam, and still costs only two integers per key. This is the
approximation a CDN edge uses to rate-limit billions of keys with one counter pair each.

The **sliding log** is exact. Keep a sorted set of request timestamps — the score is the time, the member is a
unique request id. On each request, trim everything older than the span with `ZREMRANGEBYSCORE` (remove every
member whose score is below `now − window`), then `ZCARD` is the live count of requests still inside the window;
admit if it is below `max` and `ZADD` the new timestamp. There is no seam because there are no slices — only a
moving span and the exact set of requests inside it. The cost is the trade: the set holds one member per request
in the window, so its memory is O(n) in the rate, where the counter is O(1).

The choice is the usual one. The fixed window is cheapest and bursts at edges; the sliding-window counter is
nearly as cheap and smooth; the sliding log is exact and the most expensive. EchoMQ's limiter is the fixed
window — one counter, one TTL — because a queue's budget is a coarse throughput cap where a boundary burst is
tolerable, and the cheapest limiter that holds the budget is the right one. A surface that needs an exact rolling
count reaches for the log; one that needs smoothness without the memory reaches for the counter pair.

## The pattern, applied

In EchoMQ the fixed-window algorithm is the `emq:{q}:limiter` counter spent down to `max` — the cap read from
`emq:{q}:meta` — over its own `PTTL` window. `EchoMQ.Metrics.get_rate_limit_ttl/3` reads the remaining window:
zero means admit, a positive value is the back-off a job over budget waits, and `[:emq, :rate_limit, :hit]` is
the receipt that a limit was reached. The window is not a timer the bus runs; it is the key's TTL, set once on the
first hit and left to expire. Incrementing the counter on each admitted job and deferring an over-budget job until
the window resets is the enforcement loop the queue's scaling layer wires at the dequeue point — that is the
`/echomq/queue` territory, taught there.

A consumer makes the budget concrete. In codemojex (`echo/apps/codemojex`) — a Telegram emoji-guessing game on the
same stack — a per-queue `emq:{q}:limiter` counter caps the work one room or one user can push at the engine, so a
flood of guesses from one chat cannot starve the others. Because the counter lives in Valkey, not in any worker,
the budget is one shared figure across every bot worker — the subject of the global-not-local dive.

## References

### Sources

- [Valkey — INCR](https://valkey.io/commands/incr/) — the atomic increment-and-create that counts admits in the
  current window without a read-then-write race.
- [Valkey — PEXPIRE](https://valkey.io/commands/pexpire/) — arming the window: set the counter to expire in N
  milliseconds, once, so the key's own TTL *is* the window.
- [Valkey — PTTL](https://valkey.io/commands/pttl/) — the remaining lifetime of the counter, which is the time
  until the budget resets — the over-budget back-off.
- [Valkey — ZREMRANGEBYSCORE](https://valkey.io/commands/zremrangebyscore/) — trimming the sorted log by score, so
  `ZCARD` counts only the timestamps still inside the rolling span.
- [Cloudflare — How we built rate limiting capable of scaling to millions of domains](https://blog.cloudflare.com/counting-things-a-lot-of-different-things/)
  — the sliding-window counter as a bounded approximation that weights the previous window by the fraction in view.

### Related in this course

- [R6.01 · Rate limiting](/redis-patterns/flow-control/rate-limiting) — the module hub: the four algorithms and
  the EchoMQ limiter.
- [R6.01.2 · Token & leaky buckets](/redis-patterns/flow-control/rate-limiting/token-and-leaky-buckets) — the
  burst-aware family that smooths instead of slicing.
- [R6.01.3 · Global, not local](/redis-patterns/flow-control/rate-limiting/global-not-local) — why the counter
  belongs in Valkey, so the budget is global across every worker.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: where the limiter is wired at the dequeue point.
- [/bcs/bus](/bcs/bus) — the Valkey-native bus and the `emq:{q}:` keyspace the limiter key lives in.
