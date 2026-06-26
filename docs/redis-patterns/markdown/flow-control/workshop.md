# R6.06 · Workshop — codemojex under load

> Route: `/redis-patterns/flow-control/workshop` · the chapter capstone (single page, no dives) ·
> pattern: **every R6 flow-control technique composed once, end to end, into one consumer that stays stable under
> load.**
>
> Grounding: the **codemojex** consumer (`echo/apps/codemojex`) on the real shipped `echo/apps/echo_mq` bus, backed
> by Valkey. The consumer surfaces, all verified on disk: `Codemojex.RateLimiter` (the token bucket),
> `Codemojex.Guesses` (the play API + per-tenant control), `Codemojex.NotificationWorker` (the three-layer
> notification job), `Codemojex.ScoreWorker` / `Codemojex.CommandWorker` (the other drains), `Codemojex.Notifier`
> (the enqueue side). The bus surfaces: `EchoMQ.Lanes` (the fair-lanes engine), `EchoMQ.Jobs.enqueue_in/5` /
> `enqueue_many/4`, `EchoMQ.Consumer` (the claim loop), `EchoMQ.Metrics.get_rate_limit_ttl/3` (the work-side cap).
> The manuscript figure home is `docs/echo/bcs/bcs.7.md` (B7, codemojex). Engine: Valkey 9. Doors: `/echomq/queue`,
> `/bcs/bus`, `/bcs/codemojex`.

A workshop is not a new pattern. It is the chapter's techniques assembled into one working thing. R6 taught five
ways to keep a queue stable when load arrives — rate limiting, fairness, groups, batches, worker concurrency — and
codemojex, the Telegram code-breaking game, applies all five at once on the same bus. The honest spine is already
written into the consumer: `Codemojex.NotificationWorker`'s own moduledoc names **three layers of control —
Fairness, Rate, Delivery**. Guesses and outbound notifications are both bus traffic, and both have to keep moving
when one room floods the engine. This page traces a guess and a notification through every gate.

## The scenario — a room floods, the engine stays fair

A popular room fills with players hammering guesses; a finished game fans a burst of result notifications back out
to Telegram. Two pipelines, one bus. Without flow control, the loudest room starves the quiet ones, the engine
sends faster than Telegram allows and gets throttled, and a worker stall backs everything up. R6's five techniques
each address one of those failures, and codemojex wires them together:

1. **Rate** — cap outbound sends to a budget per window so Telegram never throttles the bot
   (`Codemojex.RateLimiter`, applied by `Codemojex.NotificationWorker`); over budget, defer instead of drop.
2. **Fairness** — drain a set of lanes by rotation so one player's flood cannot starve the field
   (`Codemojex.Guesses.submit/3` → `EchoMQ.Lanes.enqueue/5` on the player's lane).
3. **Groups** — the lane is the tenant; pause or resume one without touching the rest
   (`Codemojex.Guesses.pause/1` / `resume/1` / `depth/1` → `EchoMQ.Lanes`).
4. **Batches** — a burst could be admitted in one wire flush and drained in one batch claim
   (`EchoMQ.Jobs.enqueue_many/4` + `EchoMQ.Lanes.bclaim/3` — the pattern-level path).
5. **Worker concurrency** — a pool of claim loops drains the queues, each claim one round-trip
   (`EchoMQ.Consumer` loops: `Codemojex.ScoreWorker`, `Codemojex.NotificationWorker`, `Codemojex.CommandWorker`).

Each section below recalls the R6 module, then lands it on the real codemojex surface.

## R6.01 — rate: a token bucket sized for Telegram

Rate limiting caps work to a budget per unit of time. R6.01 taught two algorithms with the same job: the
fixed-window counter (the real `emq:{q}:limiter`, spent down to `max` over its own `PTTL` window) and the token
bucket (a refilling allowance, bursts up to the bucket, sustained at the refill rate). codemojex applies the
**token bucket** on the delivery side. `Codemojex.RateLimiter` is a token-bucket limiter sized for Telegram's send
limits: a global bucket (about 30 messages per second, burst 30) and a per-chat bucket (about one per second, burst
3), and a send is allowed only when **both** grant a token. Those rates are configuration — the limits Telegram
enforces — not measured throughput.

```
# Codemojex.RateLimiter.take/2 — the delivery gate (echo/apps/codemojex/lib/codemojex/rate_limiter.ex)
RateLimiter.take(chat)
#=> :ok            both buckets grant — send now
#=> {:wait, ms}    a bucket is empty — the smallest delay before a retry could succeed
```

The buckets refill lazily from elapsed time, so the limiter holds no timers and one process serves every chat.
`take/2` answers `:ok` or `{:wait, ms}`. The `NotificationWorker` does not block the consumer when over budget: it
re-enqueues the same notification with `EchoMQ.Jobs.enqueue_in/5` after the reported wait and acks — the
notification stays durable on the bus, **deferred, not dropped**. That is the back-off the rate limit reads turn
into a delayed retry. On the work side, the server-side `emq:{cm}:limiter` fixed-window counter is the same idea in
Valkey, read by `EchoMQ.Metrics.get_rate_limit_ttl/3` (the remaining window in ms, the over-budget back-off) — one
budget shared across every bot worker because it lives in the engine, not in any process.

## R6.02 — fairness: each player rides their own lane

Fairness under load is keeping every producer's work moving when one floods the queue. A single FIFO line lets one
heavy producer starve the rest; R6.02 taught the fix — a queue is a set of lanes, each a per-group pending set, and
every claim rotates the ring one step before serving, so service spreads across lanes by construction. codemojex
enqueues each guess on the **player's** lane. `Codemojex.Guesses.submit/3` validates the guess, charges the room's
currency, then enqueues a branded `JOB` keyed by the player's `PLR`:

```
# Codemojex.Guesses.submit/3 — a guess on the player's fair lane (echo/apps/codemojex/lib/codemojex/game.ex)
job = EchoData.BrandedId.generate!("JOB")
payload = :erlang.term_to_binary({:guess, game, player, guess})
Lanes.enqueue(Bus.conn(), "cm", player, job, payload)   # the PLR is the lane group
```

The module's own words: *"the lane is named by the player's `PLR`, so the bus rotates service across players and
one keyboard masher cannot starve the field."* Notifications are fair the same way: `Codemojex.Notifier` enqueues
each notification on a **fair lane keyed by chat id**, so the bus spreads a chat's notifications behind the rate
limit rather than firing them at once. This is the `NotificationWorker`'s layer 1 — fairness *per chat*. R6.02's
retarget holds here: there is no numeric per-job priority; "served more" is a property of the identity (a higher
lane weight), not a number stapled to the work, and mint order plus the rota already give fairness.

## R6.03 — groups: the lane is the tenant

A group is a tenant given its own lane. R6.03 taught two controls over a tenant lane: round-robin across tenants
(the ring rotation of R6.02) and a per-group concurrency ceiling, plus the ability to park one tenant without
touching the rest of the queue. In codemojex the tenant is a **player** (a `PLR`) — its lane is the unit of
control. `Codemojex.Guesses` exposes that control directly, each call delegating to `EchoMQ.Lanes`:

```
# Codemojex.Guesses — per-tenant control without touching the rest of the queue (game.ex)
def pause(player),  do: Lanes.pause(Bus.conn(),  "cm", player)
def resume(player), do: Lanes.resume(Bus.conn(), "cm", player)
def depth(player),  do: Lanes.depth(Bus.conn(),  "cm", player)
```

`pause/1` parks one player's lane — held while the rest of the field runs; `resume/1` unparks it; `depth/1` reads
how much work that one lane has pending. One tenant is held while the others run, which is exactly the manuscript's
*"group-aware pause and resume act on a lane without touching the queue."* The ceiling and the de-ring mechanics
(`EchoMQ.Lanes.limit/4` → `glimit`/`gactive`) are the bus's, taught in the EchoMQ Queue pillar; codemojex reaches
the per-tenant control through the lane.

## R6.04 — batches: the burst path the bot could take

R6.04 taught the pipelined batch: many writes in one wire round-trip, each item atomic and idempotent, the batch
**not** a transaction — partial verdicts are the honest model, by design over MULTI/EXEC rollback. codemojex
enqueues **one guess per `submit/3`** today, not a batch — so this technique is pattern-level here, the path the bot
*could* take when a burst of inbound commands arrives. The honest framing: a burst could be admitted in one flush
via `EchoMQ.Jobs.enqueue_many/4` (a per-item idempotent `@enqueue` script `EVALSHA`'d once per item through
`EchoWire.Pipe`, flushed once, a verdict per item — `:enqueued` / `:duplicate` / `{:error, :kind}` — in input
order) and drained in one batch claim via `EchoMQ.Lanes.bclaim/3` (rotate to a serviceable lane, serve up to a
batch of heads on one shared `TIME` lease). One round-trip in, one round-trip out — the throughput path R6.04
taught. codemojex does not batch-enqueue guesses; the per-guess `submit/3` is the live path, and the batch path is
the documented option when volume demands it.

## R6.05 — worker concurrency: a pool of claim loops

The BEAM gives cheap concurrency — thousands of processes — but the wire is the shared resource: real parallelism
on Valkey is pool width (N sockets), not N processes sharing one connector. R6.05 taught the trio —
`EchoMQ.Consumer` (the claim loop that parks on a wake key rather than polling), `EchoMQ.Pool` (the concurrency
primitive), and the per-claim `ZPOPMIN` fetch (one job per claim, one round-trip), amortized by the batch claim
`EchoMQ.Lanes.bclaim/3`. codemojex runs a `Consumer` loop per queue:

- `Codemojex.ScoreWorker.handle/1` drains the `cm` guess queue — *"`EchoMQ.Consumer` drains the guess queue through
  `Lanes.claim`, the player id arriving as the lane group."* It scores, writes a `GES`, and for a classic game
  publishes a `scored` event.
- `Codemojex.NotificationWorker.handle/1` drains the `cm.notify` queue and delivers each notification under the
  three layers of control.
- `Codemojex.CommandWorker.handle/1` drains the `cm.bot.commands` lane — keeping inbound command handling on the
  bus makes it durable, per-chat ordered, and replayable, with the reply going back out through `Codemojex.Notifier`
  so it inherits the same rate limiting and retries.

Each claim is one `ZPOPMIN` round-trip — the per-claim fetch is the throughput ceiling, and pool width sets the
floor. A busy event (many rooms guessing at once) is the case where batch claim and pool width matter.

## Putting it together — one pipeline, every gate

Trace one guess and one notification end to end:

- A **guess** enters at `submit/3`, is charged and validated, and is enqueued on the player's fair **lane**
  (`Lanes.enqueue`, R6.02). The **ring** rotates and a `ScoreWorker` `Consumer` claims one head (`Lanes.claim`,
  R6.05), scores it, and writes a `GES`. If that player's lane is paused (R6.03), the ring skips it.
- A **notification** enters at `Notifier.notify` on a fair lane per chat (R6.02), is claimed by the
  `NotificationWorker` `Consumer` (R6.05), and hits the **rate gate** — `RateLimiter.take/2` (R6.01). On `:ok` it is
  delivered; on `{:wait, ms}` it is re-enqueued with `EchoMQ.Jobs.enqueue_in/5` after the wait and acked — deferred,
  not dropped.

Five techniques, one bus: the rate gate is the ceiling, the lanes keep it fair, the groups give per-tenant control,
the batch path is the burst option, and the pool of consumers is the floor. Each gate is a real surface, and the
identity — the branded `JOB`, `GES`, `NOT`, `PLR` ids — is the thread that ties the guess to its lane, its score,
and its receipt.

## The bridge

| R6's techniques | codemojex's pipeline under load |
|---|---|
| Rate-limit to a budget, fair lanes drained by a rota, per-tenant groups, a pipelined burst path, a pool of claim loops. | `Codemojex.RateLimiter.take/2` defers over-budget sends with `EchoMQ.Jobs.enqueue_in/5`; `Codemojex.Guesses.submit/3` enqueues each guess on the player's `PLR` lane (`EchoMQ.Lanes.enqueue/5`), `pause/1`/`resume/1`/`depth/1` give per-tenant control, and a pool of `EchoMQ.Consumer` loops (`ScoreWorker`, `NotificationWorker`, `CommandWorker`) drains every queue. |

The five flow-control techniques are not five systems; they are five gates on one pipeline. The guess that floods
in is the same identity that comes out scored, and every gate it passes is a real surface in the consumer — the
chapter's whole catalog, working at once.

## Notes on Valkey

Every key of the `cm` queue — the lanes, the ring, the limiter counter — carries the queue's `{cm}` hash tag, so
they all hash (CRC16 of the brace bytes) to one of the 16384 cluster slots and co-locate. That co-location is what
keeps a multi-key claim or limiter script legal — no `CROSSSLOT` error — and what makes the limiter counter one
shared key every bot worker increments. The braced keyspace is by design — `valkey.io/topics/cluster-spec`.

## References

### Sources

- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{cm}` hash tag forces the
  queue's keys onto one of the 16384 slots so a multi-key claim or limiter script stays legal.
- [Valkey — INCR](https://valkey.io/commands/incr/) — the atomic counter behind a fixed-window rate limit; the
  spend-down the `emq:{cm}:limiter` cap is built on.
- [Valkey — PTTL](https://valkey.io/commands/pttl/) — the time until the limiter window resets; the over-budget
  back-off `EchoMQ.Metrics.get_rate_limit_ttl/3` returns.
- [Valkey — ZPOPMIN](https://valkey.io/commands/zpopmin/) — the per-claim pop behind `EchoMQ.Lanes.claim/3`; one
  job per round-trip, the throughput ceiling pool width amortizes.
- [Valkey — pipelining](https://valkey.io/topics/pipelining/) — many commands in one round-trip, the wire mechanic
  behind the burst path `EchoMQ.Jobs.enqueue_many/4` takes.
- [Stripe — Scaling your API with rate limiters](https://stripe.com/blog/rate-limiters) — the token-bucket and
  fixed-window algorithms in production, the family `Codemojex.RateLimiter` applies.

### Related in this course

- [R6.01 · Rate limiting](/redis-patterns/flow-control/rate-limiting) — the budget-per-window pattern the delivery
  gate applies.
- [R6.02 · Fairness under load](/redis-patterns/flow-control/fairness) — the rota that keeps one player from
  starving the field.
- [R6.03 · Groups & multi-tenant fairness](/redis-patterns/flow-control/groups) — the lane as the tenant; pause and
  resume one without the rest.
- [R6.04 · Batches & pipelining](/redis-patterns/flow-control/batches) — the one-round-trip burst path the bot could
  take.
- [R6.05 · Worker concurrency](/redis-patterns/flow-control/worker-concurrency) — the pool of claim loops that sets
  the throughput floor.
- [EchoMQ · the Queue](/echomq/queue) — the scaling layer in depth: the limiter at the claim point, fair lanes, and
  concurrency.
- [BCS · the Bus](/bcs/bus) — the Valkey-native bus and the fair-lanes architecture these figures draw from.
- [BCS · codemojex](/bcs/codemojex) — the worked consumer as the manuscript tells it (B7).
