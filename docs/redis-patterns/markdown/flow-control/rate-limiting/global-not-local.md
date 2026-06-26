# Global, not local

> R6.01.3 · Rate limiting — dive · Redis Patterns Applied (`/redis-patterns/flow-control/rate-limiting/global-not-local`)

A rate limit is only worth as much as the place its counter lives. Put the counter in a worker process and the budget is local to that worker; put it in Valkey and the budget is one number every worker shares. The whole value of a server-side limiter is that the budget is **global by construction** — it cannot scale with the fleet, because there is only one counter to spend.

This dive grounds in the real, shipped EchoMQ keyspace: the limiter counter is `emq:{q}:limiter`, the configured cap is `emq:{q}:meta max` read by `EchoMQ.Metrics.get_global_rate_limit/2`, and the `{q}` hashtag is what pins both keys to one cluster slot — `EchoMQ.Keyspace.slot/1`.

## Where the counter lives

A limiter has two parts: a **counter** that is spent down, and a **cap** the counter is measured against. In EchoMQ both are queue keys, and neither lives in a worker. The counter is `emq:{q}:limiter` — a plain string a worker `INCR`s on each admit. The cap is the `max` field of `emq:{q}:meta`, a HASH, written once when the queue is configured and read by every worker:

> `EchoMQ.Metrics.get_global_rate_limit/2` is one command — `HGET emq:{q}:meta max` — answering the queue's configured cap, `0` when unconfigured. There is one `max` per queue, and every worker reads the same one.

That placement is the entire point. A worker does not own its slice of the budget; it reads the shared cap and spends the shared counter. Ten workers, three runtimes, four nodes — they `INCR` the same key against the same `max`. The budget is a property of the queue, held in Valkey, not a property of any process. A worker can restart, a node can be added, a second runtime can join, and the budget does not change, because none of them carried a piece of it.

The contrast names what server-side buys: a server-side counter is **shared state with atomic arithmetic**. `INCR` returns the post-increment value in one round trip, so two workers incrementing at the same instant see two different values — there is no read-modify-write race to lose a count to. The budget is exact across the fleet because the fleet shares one atomic counter.

## The N× overshoot of a local limiter

The failure a server-side counter avoids is the **local limiter** — a limiter whose counter lives in each worker process. It looks correct in a single-worker test: count admits, refuse past `max`, reset on the window. It is correct, for one worker. The defect appears the moment a second worker starts.

With `N` workers each enforcing `max` against its own private counter, the system admits up to `N × max` per window. Each worker is individually within budget; the fleet is `N` times over it. Worse, the overshoot is silent and it tracks the fleet — scale from two workers to ten to handle load and the effective rate scales with them, from `2 × max` to `10 × max`, with nothing in the limiter to signal it. The number you configured is the per-worker rate, not the system rate, and the gap between them is exactly the worker count.

A shared server-side counter has no such gap. The rate is `max`, full stop, because there is one counter and `max` is measured against it regardless of how many workers spend it. This is why the limiter counter belongs in Valkey: not for speed, but because **shared is the only place a budget can be global**. A budget that is global by construction cannot drift as the fleet grows.

The interactive on this page runs the two side by side over the same admit trace: one shared `emq:{q}:limiter` counter capped at `max`, against `N` private counters each capped at `max`. The shared counter holds the line at `max`; the private counters sum to roughly `N × max`. The overshoot is the worker count, made visible.

## One key, one slot

A budget that is one counter raises one question: with the keys spread across a Valkey cluster, do all of a queue's workers reach the *same* counter? They do, and the mechanism is the `{q}` hashtag. Valkey Cluster shards the keyspace into **16384 hash slots**, and a key's slot is computed from the substring inside its first `{...}` braces when one is present — so every key of a queue carries the per-queue hashtag and they all hash to **one** slot.

EchoMQ computes the slot client-side, so the connector can route and partition without a server round trip:

> `EchoMQ.Keyspace.slot/1` is CRC16-XMODEM over the hashtag, modulo 16384 — the cluster specification's own algorithm. `hashtag/1` is the substring inside the first `{...}`. Known vector: `slot("123456789") == 12739`.

For queue `q`, both `emq:{q}:limiter` and `emq:{q}:meta` share the hashtag `q`, so they land on the same slot — and so does every other key of that queue. The consequence is twofold. First, every worker's `INCR emq:{q}:limiter` reaches one key on one slot — the counter is genuinely shared, atomic, not split per shard. Second, a multi-key Lua script over a queue's keys is legal, because all its keys are on one slot — there is no `CROSSSLOT` error to hit. The hashtag is what makes the limiter both global and co-located: one key, one slot, every worker's increment landing on it.

This is the local-vs-global lesson at the storage layer. The counter is not in a worker (so the budget is global across the fleet) and it is not spread across shards (so the budget is one atomic key, not one-per-slot). Server-side and co-located: the same counter, reachable the same way, from every worker.

## Applied in EchoMQ

The pattern lands on the shipped surface. A server-side counter spent against a shared cap is exactly the `emq:{q}:limiter` / `emq:{q}:meta max` pair: one number every worker `INCR`s, one cap every worker reads with `get_global_rate_limit/2`, both pinned by the `{q}` hashtag to one slot. Wiring the increment into the claim path — checking the counter as each job is claimed and deferring a job that is over budget — is EchoMQ's scaling layer, taught in depth in the EchoMQ course.

The worked consumer is **codemojex** (`echo/apps/codemojex`), a Telegram emoji-guessing game on the same stack and a multi-bot deployment by design. Its guesses ride one queue: `Codemojex.Guesses.submit/3` enqueues a branded `JOB` on the player's lane on the `cm` queue, so the keyspace is `emq:{cm}:`. A budget that capped guesses for that queue would be the `emq:{cm}:limiter` counter — one number shared across every bot worker, global because it is server-side, co-located because every key of the `cm` queue carries the `{cm}` hashtag onto one slot.

codemojex also shows the other half of the lesson honestly. Its outbound Telegram throttle, `Codemojex.RateLimiter`, is a process-local token bucket — and that is the right tool there, because the budget it enforces is one node's outbound API allowance to Telegram, not a budget the whole fleet must share. Local is correct when the resource is local; global is required when the resource is shared. The two limiters live in different places because they bound different things.

## References

### Sources

- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the 16384 hash slots and the hashtag rule that pins a queue's keys to one slot.
- [Valkey — INCR](https://valkey.io/commands/incr/) — the atomic increment a shared counter is spent down with; returns the post-increment value in one round trip.
- [Valkey — CLUSTER KEYSLOT](https://valkey.io/commands/cluster-keyslot/) — the server-side counterpart of the client-side `slot/1` computation, for verifying a key's slot.
- [Stripe — Scaling your API with rate limiters](https://stripe.com/blog/rate-limiters) — a production account of why limiter state is shared infrastructure, not per-process.

### Related in this course

- [R6.01 · Rate limiting](/redis-patterns/flow-control/rate-limiting) — the module hub: the four algorithms and the EchoMQ limiter surface.
- [R6.01.1 · Fixed & sliding windows](/redis-patterns/flow-control/rate-limiting/fixed-and-sliding-windows) — the window algorithm the shared counter runs.
- [/echomq/queue](/echomq/queue) — EchoMQ's scaling layer: the limiter wired at the claim point, fair lanes, concurrency.
- [/bcs/bus](/bcs/bus) — the Valkey-native bus and the `emq:{q}:` keyspace these keys live in.
- [/bcs/codemojex](/bcs/codemojex) — the multi-bot consumer whose guess queue the shared counter would bound.
