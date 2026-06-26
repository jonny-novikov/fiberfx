# R6 · Flow Control & Scale — staying stable under load

> The chapter landing for `/redis-patterns/flow-control`. The teaching arc: overview → why & when →
> the patterns → how to apply → the workshop → up next → references. The grounding is the real, shipped
> EchoMQ flow-control surface — the limiter, the fair-lane ring, and the bulk enqueue — backed by Valkey.

**Kicker:** R6 · Flow Control & Scale
**H1:** Staying stable under load.

**Lede:** A queue that runs and orders work has not yet learned to survive a flood. Flow control is the set of
moves that keep the system stable under load: bound throughput to a budget, keep tenants fair so no one starves,
enqueue in bulk without a round trip per job, and plan worker capacity against the real fetch cost — all without
losing correctness.

The grounding is EchoMQ's real, shipped flow-control layer (`echo/apps/echo_mq`), backed by Valkey. The rate
limiter reads down a counter key (`emq:{q}:limiter`) against a configured `max` over its own window with
`EchoMQ.Metrics.get_rate_limit_ttl/3`; the fair-lane ring in `EchoMQ.Lanes` rotates one step per claim so every
lane is served in turn; and `EchoMQ.Jobs.enqueue_many/4` admits many jobs in one wire flush. Worked through
codemojex's traffic, with doors into the EchoMQ Queue pillar and the BCS bus.

---

## §1 Why & when

A queue that distributes and orders work still trusts every caller to be well-behaved. Under load that trust
breaks: one tenant floods the engine, a burst of writes outpaces the workers, a thousand small enqueues each pay a
full round trip. Flow control is how the system stays correct and stable when demand exceeds what one moment can
absorb. Each demand below has one matching technique, and the chapter is the set of those answers.

**The use cases (a 4-grid):**

- **Throughput must stay under a budget.** Cap how much work is admitted per unit of time — count what is admitted
  in the current window, refuse or defer once the count reaches the limit, and reset when the window rolls. The
  budget is a counter in the engine, not in any one worker.
- **Every tenant gets a fair turn.** Under contention, no single tenant should starve the rest. A rota serves every
  lane in turn, and a weight tilts the share without ever letting a lane jump the line — fairness is constructed,
  not hashed.
- **Bulk work must not pay per-item round trips.** Admitting a thousand jobs one wire call at a time is a thousand
  round trips. One flush admits them all, all-or-nothing under the same idempotency as a single add.
- **Worker capacity must be planned, not guessed.** Each claim costs a fetch from the engine. Concurrency is bounded
  by that per-claim cost and by the per-lane ceiling — capacity is planned against the real fetch, never assumed.

**The flow-control lifecycle (an interactive SVG):** a job moves left to right — `enqueue` → the **limiter gate**
(a counter spent against `max` over a window) → the **fair-lane ring** (the rota rotates one step) → `claim`. The
diagram carries short labels; the readout names the surface behind each stage.

**Take:** Every technique in this chapter answers one demand load makes on the queue — bound the throughput, keep
tenants fair, enqueue in bulk, and plan capacity — each one a real move in EchoMQ's flow-control layer.

---

## §2 The patterns

One module is built; the rest are specified. Rate limiting is the one new catalog pattern in this chapter; the
others are flow-control techniques that compose primitives from earlier chapters. Each module is a hub with its
dives, grounded in the real EchoMQ flow-control layer.

Legend: **built** = ready to read · **soon** = specified.

| Module | Title | Abstract |
|---|---|---|
| **R6.01** (built) | Rate limiting | Cap work to a budget per window — the `emq:{q}:limiter` counter spent to `max`, read with `EchoMQ.Metrics.get_rate_limit_ttl/3`. |
| R6.02 (soon) | Fairness under load | Prevent starvation — the rota serves every lane in turn, weights tilt the share. |
| R6.03 (soon) | Groups & multi-tenant fairness | Share capacity fairly across tenants — round-robin lanes with a per-group concurrency ceiling. |
| R6.04 (soon) | Batches & pipelining | One round-trip, all-or-nothing bulk enqueue. |
| R6.05 (soon) | Worker concurrency | The per-claim fetch ceiling and how to plan capacity. |
| R6.06 (soon · workshop) | Workshop | Rate-limit and fairly schedule codemojex's API and jobs. |

---

## §3 How to apply

The hard part is matching the flow-control technique to the load problem you have. Name the load problem, and the
technique — and the real EchoMQ surface that becomes it — follows.

**The interactive (name the load problem → the technique + the EchoMQ surface):**

- **Cap throughput to a budget** → the fixed-window counter: `emq:{q}:limiter` spent down to a configured `max`,
  the window being the key's own TTL. `EchoMQ.Metrics.get_rate_limit_ttl/3` reads the remaining window — the
  back-off an over-budget job waits — and `[:emq, :rate_limit, :hit]` is the telemetry receipt.
- **Keep tenants fair** → the fair-lane ring: `EchoMQ.Lanes` holds a rota of serviceable lanes and rotates it one
  step per claim (`claim/3`), so every lane is served in turn; `weight/4` tilts a lane's share without letting it
  jump the line.
- **Bound a tenant's concurrency** → the per-lane ceiling: `EchoMQ.Lanes.limit/4` sets a lane's `glimit`, and a
  lane at its ceiling is dropped from the ring until a job completes — a concurrency cap, distinct from the
  time-rate limiter.
- **Enqueue in bulk, one round trip** → `EchoMQ.Jobs.enqueue_many/4` pipelines every admit into one wire flush, with
  per-item verdicts in input order under the same idempotency as a single `enqueue/4`.

**Take:** There is no single flow-control trick — only the technique that answers the load problem you have, each
one a real move in EchoMQ's flow-control layer.

---

## §4 The workshop

The chapter closes with **R6.06**: rate-limit and fairly schedule codemojex's API and its jobs. codemojex is a
Telegram emoji-guessing game on the same stack; a flood of guesses from one room must not starve the engine for
everyone else. The budget is a per-queue counter — `emq:{q}:limiter` spent down to `max` over its window — global
across every bot worker, because the counter lives in Valkey, not in any one process. Fairness rides the same
fair-lane ring: each room (or tenant) is a lane the rota serves in turn, so a busy room takes its share and no
more.

**The doors:**

- **`/echomq/queue`** — EchoMQ's Queue pillar absorbed groups, batches, lifecycle, fairness, and the rate limit:
  the scaling-layer depth (the limiter wired at the claim point, fair lanes, concurrency) lives there.
- **`/bcs/bus`** — the Valkey-native bus and the fair-lanes architecture the figures draw from; the BCS law that a
  system gates ingress on one branded namespace.

**Notes on Valkey:** the `{q}` hashtag pins every key of one queue — `emq:{q}:limiter`, `emq:{q}:meta`, the ring,
the lanes — to one of the 16384 cluster hash slots (CRC16 of the hashtag bytes, modulo 16384;
`EchoMQ.Keyspace.slot/1`, vector `slot("123456789") == 12739`). One slot keeps a multi-key Lua script legal — no
CROSSSLOT — and co-locates the limiter counter every worker spends.

---

## §5 Up next

R6 keeps the queue stable under load. Each later chapter is a different concern over the same work — how the data
lives in RAM, then running the tier in production.

- **R7 · Data Modeling** — how data lives in RAM.
- **R8 · Production & Ops** — running the tier at scale.

---

## References

### Sources

- [Valkey — INCR](https://valkey.io/commands/incr/) — the atomic counter increment behind the fixed-window
  rate-limit count.
- [Valkey — EXPIRE](https://valkey.io/commands/expire/) — set the window's lifetime so the budget resets when the
  key expires.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forces a queue's
  keys onto one of the 16384 slots.
- [Stripe — Scaling your API with rate limiters](https://stripe.com/blog/rate-limiters) — the request-rate
  techniques (token bucket, fixed window, concurrency) a production limiter composes.

### Related in this course

- [EchoMQ · the Queue pillar](/echomq/queue) — the scaling layer in depth: the limiter at the claim point, fair
  lanes, concurrency.
- [The Branded Component System · the bus](/bcs/bus) — the Valkey-native bus and the fair-lanes architecture (B3).
- [R5 · Streams & Events](/redis-patterns/streams-events) — the durable, replayable log the previous chapter
  records.
