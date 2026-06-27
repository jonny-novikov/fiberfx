# Keep it consistent

> Route: `/redis-patterns/caching/workshop/keep-it-consistent` · Module R1.07 · stage 2 of 3 · Source: none — a
> **capstone** dive synthesizing cache invalidation (R1.01) and the consistency policy choice (R1.02 / R1.04) applied
> to codemojex's emoji set; no single `content/…md.txt` author source. · Grounding:
> `EchoStore.Coherence` over `EchoStore.Table` (`echo/apps/echo_store`).

A change must reach the cache. When a room is re-templated with a new emoji set, drop the stale L1 row and resolve
newer-wins, then choose the lane each surface needs — the fast broadcast lane or the durable job lane. The cache from
stage 1 keeps serving a set's old copy after it changes; coherence closes that gap. The deeper functional-Elixir craft
behind the writer is [`/elixir`](/elixir).

## A message about a name

EchoStore's coherence message carries exactly two identities and nothing else: the cached name and the writer's
mint-time version — twenty-nine bytes, `id <> ":" <> version` (`EchoStore.Coherence.payload/2`). Everything else falls
out of the order theorem: a branded id's eleven payload bytes sort in mint order, so *newer wins* is a comparison of
two names — `Coherence.newer?/2` compares the eleven-byte snowflake payloads, ignoring the namespace — with no
coordinator, no lock, and no clock but the one already inside every id.

The dangerous case is not the fresh invalidation; it is the **stale** one arriving late — a slow lane, a retry, a
replay. Newer-wins handles it by construction. On the L1 side, `apply_coherence/4` drops the row only when the
incoming version is newer than the row's framed version; on the L2 side, the conditional Lua `Coherence.drop_l2/4`
(`@drop = Script.new(:coherence_drop, …)`) reads the framed version, compares payloads, and deletes only if newer —
one transition, one script, so a late stale invalidation can never erase a newer row. The same comparison is the
idempotence story: applying a version twice answers `:stale` the second time, with no dedup table anywhere.

- `Coherence.payload/2` — the message: two branded ids, twenty-nine bytes, `id <> ":" <> version`.
- `Coherence.newer?/2` — `<<_::binary-3, pa::binary-11>>, <<_::binary-3, pb::binary-11>> -> pa > pb`; mint order
  across kinds, the order theorem.
- `apply_coherence/4` — drops the L1 row only if `version` is newer than the row's framed version; idempotent by
  comparison.
- `Coherence.drop_l2/4` — the conditional Lua over `@drop`: delete L2 only when the incoming version is newer.

Deleting, not overwriting, is the safe move on the L1 side: a coherence message means the writer already placed the
newer value in L2, so the row is dropped and the next read re-fills from the now-current L2.

## Choose the lane per surface

Two lanes carry the same twenty-nine bytes, and the cache's surfaces do not all need the same one. The choice is a
trade between latency and durability. The **broadcast lane** — `Coherence.broadcast/4` — is a `PUBLISH` on the table's
channel (`ecc:{<table>}:coh`): fire-and-forget, one wire hop, at-most-once. A lost message costs one TTL of staleness —
the stage-1 bound — so it fits a surface where that is acceptable. The **job lane** — `Coherence.enqueue/5` — is an
enqueue on the table's coherence queue (`ecc.coh.<table>`) over EchoMQ's fair lanes: at-least-once, crash-surviving,
for a surface where a stale read costs money. The committed gate prices them side by side: the broadcast lane at
`72 us`, the job lane at `148 us` — the guarantee costs `2.1 times` the latency.

Pick a surface and a lane, and the readout reports the delivery guarantee and the staleness exposure each lane gives
that surface. A round's close (its `:closed` status) or a guess fee needs the durable lane — a stale read here is
real-money play, so the job lane earns its cost. A room's display name tolerates one TTL of lag for a cheaper hop — the
broadcast lane fits. The right answer is per surface, not per cache, and the table's declared coherence mode records
the choice.

The lane is a per-surface choice: broadcast for a fast, at-most-once hop bounded by one TTL, the job lane for
at-least-once delivery a crash survives — `2.1 times` the latency, where a stale read costs money.

## Coherence on EchoStore

Take one change: a room is re-templated with a new emoji set, and the writer has placed the new value in L2 with a
fresh mint-time version. Its one obligation after the store write is one coherence call carrying that version:
`Coherence.broadcast/4` on the fast lane, or `Coherence.enqueue/5` on the durable lane. Every node's table applies the
message newer-wins: the broadcast lane lands on a RESP3 push subscription that drops the L1 row; the job lane lands on
a consumer running `Table.coherence_handler/1` that calls `apply_coherence/4`. The next read of that set re-fills from
the already-updated L2. The deeper functional-Elixir and OTP craft of the writer and the consumer is [`/elixir`](/elixir).

```elixir
# Coherence on a change — one call after the L2 write, carrying the write's version.
# The fast lane: a PUBLISH on ecc:{cm_emojisets}:coh, at-most-once.
{:ok, _receivers} = EchoStore.Coherence.broadcast(conn, "cm_emojisets", id, version)

# The durable lane: an enqueue on ecc.coh.cm_emojisets over EchoMQ, at-least-once.
{:ok, :enqueued} = EchoStore.Coherence.enqueue(conn, "cm_emojisets", group, id, version)

# Either way, every node applies it newer-wins — a comparison, idempotent by construction:
def newer?(<<_::binary-3, pa::binary-11>>, <<_::binary-3, pb::binary-11>>), do: pa > pb
```

A re-applied version is harmless because application is a comparison, not a log: redelivery on the job lane answers
`:stale` the second time. The provenance machinery is not needed here — the version *is* the provenance. How the
writer commits the store and which surfaces declare which lane is [`/elixir`](/elixir), not repeated here.

**The pattern → EchoStore.** Invalidate on a change: place the newer value, then carry the version to every node and
resolve newer-wins. On codemojex a room's emoji-set change runs `Coherence.broadcast/4` (fast) or
`Coherence.enqueue/5` (durable), and every table applies it by `Coherence.newer?/2` — a late stale message bounces off
both layers. Consistency is invalidation plus a lane: the broadcast lane for a surface a TTL already covered, the job
lane for the few where a stale read costs money.

## Recap — the cache now tracks changes

A change reaches the cache. The writer places the newer value in L2, carries the version on a lane, and every node
drops its L1 row newer-wins — so the next read re-fills fresh and a late stale message bounces off both layers.
Surfaces that cannot tolerate a lost message ride the durable job lane. The cache is now correct under changes — but
the one emoji set every guess touches can still send a herd at the loader on expiry. The next dive shows how the
single-flight and jittered TTL absorb that herd by construction, and reads the hit rate off the counters.

Next in the workshop: **R1.07.3 · Harden and measure** — the single-flight `flights` map and the jittered TTL, and
the hit rate from `EchoStore.Table.stats/1`.

## References

### Sources
- [Valkey — PUBLISH](https://valkey.io/commands/publish/) — the broadcast lane's one wire hop; at-most-once by the engine's own definition.
- [Valkey — Pub/Sub](https://valkey.io/topics/pubsub/) — "a message will be delivered once if at all" — why a lost broadcast costs one TTL and the job lane exists.
- [Redis — EVALSHA](https://redis.io/commands/evalsha) — the conditional `drop_l2` Lua runs server-side; one transition, one script.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on cache invalidation and the cost of stale data.

### Related in this course
- [R1.07 · Caching workshop](/redis-patterns/caching/workshop) — the workshop hub.
- [R1.07.1 · Cache the catalog](/redis-patterns/caching/workshop/cache-the-catalog) — the previous stage.
- [R1.07.3 · Harden and measure](/redis-patterns/caching/workshop/harden-and-measure) — the next stage.
- [R1.04 · Client-side caching](/redis-patterns/caching/client-side-caching) — the pub/sub invalidation broadcast in depth.
- [R1.02 · Write-through](/redis-patterns/caching/write-through) — the consistency-first policy.
- [/echomq/cache](/echomq/cache) — the EchoStore near-cache kept coherent, in depth.
- [/bcs](/bcs/cache/coherence-by-mint-time) — the EchoStore coherence-by-mint-time manuscript chapter.
