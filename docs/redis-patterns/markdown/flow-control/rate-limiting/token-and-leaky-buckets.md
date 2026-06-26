# Token & leaky buckets

> R6.01.2 · Flow Control & Scale · Rate limiting — dive

Two rate-limiting algorithms shape the same budget differently: the **token bucket** allows controlled bursts and the **leaky bucket** removes them. Both are catalog algorithms — patterns you build over a small piece of Valkey state — not shipped EchoMQ surfaces. EchoMQ's own limiter is the fixed-window counter from the previous dive; the buckets are the family that trades a little more state for a smoother or burstier shape. The worked code here is real: codemojex ships a token bucket of exactly this form.

## The token bucket — a refilling allowance

A token bucket holds an allowance. Tokens accrue at a fixed **refill rate** up to a maximum **bucket size**. Each admitted request spends one token; a request that finds the bucket empty is deferred until a token has accrued. Two numbers define it — the refill rate (the sustained throughput) and the bucket size (how large a burst is tolerated).

The shape this produces: a caller that has been quiet accumulates up to a full bucket of tokens, so a sudden burst of up to *bucket size* requests passes immediately. Once the bucket drains, admission falls back to the refill rate — one token every `1 / rate` seconds. Bursts are absorbed; the long-run average is capped at the refill rate. That is the token bucket's signature: **burst-tolerant, rate-bounded**.

The state is small. A bucket needs two fields — the current token count and the timestamp of its last refill. There is no background timer. The bucket is recomputed **lazily** on each admit: read the two fields, add `elapsed × rate` tokens (clamped to the bucket size), then spend one if the count reached at least one. In Valkey that is a small HASH `{tokens, last_refill}` and a single atomic Lua read-modify-write. The lazy recompute is what lets one limiter serve every caller with no per-caller timer.

### Grounded — `Codemojex.RateLimiter`

codemojex — a Telegram emoji-guessing game on the echo stack (`echo/apps/codemojex`) — ships a token bucket for exactly this reason. Telegram caps sends at roughly 30 messages per second in aggregate and about one per second to a single chat, with short bursts tolerated. `Codemojex.RateLimiter` models both: a global bucket (rate 30, burst 30) and a per-chat bucket (rate 1, burst 3), and a send is allowed only when both grant a token. `take/2` answers `:ok` or `{:wait, ms}` — the smallest delay after which a retry can succeed, which the notification worker turns into a delayed re-enqueue.

The refill is the lazy-recompute described above, in real Elixir:

```elixir
defp refill(%Bucket{} = b, now) do
  elapsed = max(now - b.updated_ms, 0)
  refilled = min(b.burst * 1.0, b.tokens + elapsed * b.rate / 1000.0)
  %{b | tokens: refilled, updated_ms: now}
end
```

A `%Bucket{tokens, updated_ms, rate, burst}` is the `{tokens, last_refill}` HASH made concrete. The bucket holds no timer; `elapsed × rate / 1000` is the tokens that have accrued since the last touch, clamped to `burst`. When the refilled count is below one, `take/2` defers with `{:wait, ms}` instead of spending. The same two-field state, the same lazy refill, whether it lives in an Elixir struct or a Valkey HASH.

## The leaky bucket — a constant drain

The leaky bucket inverts the emphasis. Picture a bucket with a hole: arrivals pour in at whatever rate they come, and the bucket drains at a **fixed rate** through the hole. The output is the drain rate, constant, regardless of how bursty the arrivals were. If arrivals exceed the bucket's capacity, the overflow is dropped.

Modelled as a queue, it is a FIFO drained at a constant rate: requests enter the tail, leave the head one every `1 / rate` seconds. A burst of arrivals does not produce a burst of output — it produces a longer queue and the same steady output. Where the token bucket lets a saved-up burst through, the leaky bucket **smooths** the burst into an even stream.

The two are mirror images of one budget. The token bucket asks "do I have credit to go now?" and rewards a caller that saved its credit with a burst. The leaky bucket asks "is it my turn yet?" and serves everyone at the same even cadence no matter how they arrived. Choose the token bucket when an occasional burst is acceptable and you care about the long-run rate; choose the leaky bucket when the thing downstream needs a genuinely constant rate — a steady drip to a fragile external API, a smoothed write rate to a disk.

## Bucket vs window — choosing the shape

The fixed-window counter from the previous dive — EchoMQ's real limiter — is the simplest of the family. A counter key (`emq:{q}:limiter`) is incremented per admit and refused once it reaches `max`; the window is the key's own TTL, and `EchoMQ.Metrics.get_rate_limit_ttl/3` reads the remaining `PTTL` as the back-off. Its read side is one inline Lua script, verbatim:

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

The trade is state against shape:

- **Fixed window** — one integer plus a TTL. O(1), trivial to reason about. The flaw is the boundary burst: a caller can fire `max` at the end of one window and `max` at the start of the next, admitting up to 2× `max` across the seam.
- **Token bucket** — two fields per bucket. Smooths the boundary (admission is continuous, not reset on a tick) and tolerates a configured burst on purpose. More state, more arithmetic, but burst-aware.
- **Leaky bucket** — a queue plus a drain timestamp. Produces a genuinely constant output rate, at the cost of holding the queue and dropping overflow.

There is no single best. The window is right when simplicity wins and an edge burst is harmless. The token bucket is right when you want a known sustained rate but a saved-up burst is acceptable. The leaky bucket is right when the rate must be constant downstream. EchoMQ ships the window because the queue's budget is a coarse safety cap; codemojex ships a token bucket because Telegram's limits explicitly tolerate a short burst over a strict per-second rate.

### The bridge

> **The token bucket** — tokens accrue at a refill rate up to a bucket size, each admit spends one, an empty bucket defers; bursts pass, the long-run rate is capped **↔** **`Codemojex.RateLimiter`** ships exactly this — a `%Bucket{tokens, updated_ms, rate, burst}` refilled lazily by `elapsed × rate`, `take/2` answering `:ok` or `{:wait, ms}`; a global bucket and a per-chat bucket, a send allowed only when both grant.

EchoMQ's own claim-point budget is the fixed-window counter, not a bucket — the buckets are the family a consumer reaches for when it needs a different shape. The enforcement loop that increments a counter on each claim and sends an over-budget job back to wait lives in EchoMQ's scaling layer.

## When to use which

- A burst is acceptable and the sustained rate is what matters → **token bucket**.
- The downstream rate must be constant and smooth → **leaky bucket**.
- Simplicity wins and an edge burst is harmless → **fixed window** (EchoMQ's limiter).

## References

### Sources

- Valkey — *EVAL* (`https://valkey.io/commands/eval/`) — the atomic Lua read-modify-write a lazy-refill bucket needs: read both fields, recompute, spend, in one server-side step.
- Valkey — *Scripting* (`https://valkey.io/topics/programmability/eval-intro/`) — why a multi-step refill belongs in one script, not a client GET-then-SET.
- Valkey — *HSET* (`https://valkey.io/commands/hset/`) — the `{tokens, last_refill}` HASH a bucket recomputes against.
- Stripe — *Scaling your API with rate limiters* (`https://stripe.com/blog/rate-limiters`) — the token-bucket and leaky-bucket policies, why bursts are tolerated, and the GCRA refinement.

### Related in this course

- R6.01 · Rate limiting (`/redis-patterns/flow-control/rate-limiting`) — the module hub: the budget-per-window pattern and the four algorithms.
- R6.01.1 · Fixed & sliding windows (`/redis-patterns/flow-control/rate-limiting/fixed-and-sliding-windows`) — the window counter the buckets are contrasted against, and its boundary-burst flaw.
- R6.01.3 · Global, not local (`/redis-patterns/flow-control/rate-limiting/global-not-local`) — why the counter lives in Valkey, shared across every worker.
- /echomq/queue — EchoMQ's Queue pillar: the limiter wired at the claim point and the scaling layer.
- /bcs/codemojex — the codemojex consumer in the manuscript, the token bucket in context.
- /bcs/bus — the Valkey-native bus the limiter keys live beside.
