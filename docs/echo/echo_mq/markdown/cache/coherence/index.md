# Coherence — newer wins on the Bus

> Route: `/echomq/cache/coherence` · Module 03 of the Cache pillar · hub.
> Grounded in `echo/apps/echo_store/lib/echo_store/coherence.ex` (+ `ring.ex`, `journal.ex`). All real code.

The third law of the near-cache: **a write on one node must not leave a stale read on another.** A cache that
serves reads from local ETS is fast precisely because it does not check the store on every hit — which means the
moment another node writes a new value, this node's L1 row is wrong, and nothing on the hot path will notice. The
first two modules made a single cache cheap and bounded; coherence makes a *fleet* of caches honest.

## Coherence is a message about a name

The whole mechanism is one sentence: **an invalidation carries exactly two identities — the cached `id` and the
writer's mint-time `version` — and nothing else.** Twenty-nine bytes: `id <> ":" <> version`. No value, no
timestamp, no node identity, no vector clock. `EchoStore.Coherence.payload/2` builds it; `parse/1` recovers the two
names, both checked with `BrandedId.valid?`.

**Newer wins** by comparing the two versions. But the comparison is not a clock read — it is `pa > pb` over the
**11-byte snowflake payloads** of the two branded ids (`newer?/2`). The order theorem makes text order equal mint
order, and it does so *across namespaces*: the three-byte namespace is dropped, so a `GAM` version and a `PLR`
version are still comparable. Coherence therefore needs **no coordinator, no lock, and no clock but the one already
inside every id**. And it is **idempotent by construction**: applying the same version twice is a comparison that
answers stale the second time.

## Two lanes, one payload

The same 29-byte message can travel two ways, and the choice is the **cost of staleness**, not a config default:

- **The broadcast lane** — `broadcast/4` issues a single `PUBLISH ecc:{table}:coh <payload>`: fire-and-forget, one
  wire hop, for surfaces where *a lost message costs one TTL of staleness*. It is applied by `EchoStore.Ring`, a
  Disruptor-shaped bounded ring that is **at-most-once** by its substrate's contract — under storm it refuses the
  publish and counts the drop, it never blocks and never overwrites.
- **The job lane** — `enqueue/5` puts the same payload on `ecc.coh.<table>` over EchoMQ's fair lanes:
  **at-least-once**, crash-surviving, for surfaces where *a stale read costs money*. It is remembered by
  `EchoStore.Journal`, a transactional outbox whose `applied` table survives the node, the cache, and the bus.

The table's declared spec carries `coherence: :none | :broadcast | :tracking`, which selects the lane (`:tracking` =
RESP3 server-assisted push, named only).

## The conditional drop — the one Lua

Receiving the message is the pillar's **one** inline Lua, `:coherence_drop`. The named handle is
`EchoStore.Coherence.drop_l2/4` — it runs `Connector.eval(conn, @drop, [Keyspace.key(table, id)], [version])`. The
script `GET`s the stored value, recovers the stored version from the `version <> value` frame, and `DEL`s the L2 row
**only when the incoming version's 11-byte payload is greater than the stored one** — one transition, one script, so
a late stale invalidation can never erase a newer row. This is the version-guarded contrast to module 01's
unconditional `invalidate/3` admin drop.

## The three dives

1. **A message about a name** — `payload/2`, `parse/1`, `newer?/2`: the 29-byte vocabulary and the cross-kind
   11-byte comparison that needs no coordinator.
2. **The two lanes** — broadcast vs job, one payload, chosen by the cost of staleness; `EchoStore.Ring` (at-most-once)
   and `EchoStore.Journal` (at-least-once) as the two substrates.
3. **Newer wins: the conditional drop** — the two-beat Lua dive: `drop_l2/4` (the handle), then the `:coherence_drop`
   body, deeply commented; the journal's `applied` memory that survives a crash → **Echo Persistence**.

## Doors

- `/redis-patterns/caching` (R1) — the cache-aside, stampede, and session patterns this pillar applies; bus-coherent
  invalidation is the depth behind R5 `/redis-patterns/streams-events`.
- `/bcs/store` (B4) — the manuscript chapter these figures realize (`docs/echo/bcs/bcs.4.md`), where coherence is
  *newer-wins where the version is the 14-byte branded id*.
- `/echo-persistence` — the durable floor the job lane's outbox folds into, so a replayed old intent answers stale
  from the journal even after the node forgot the row.
- Within the pillar: `/echomq/cache`, `/echomq/cache/cache-aside-two-layers`,
  `/echomq/cache/single-flight-and-jittered-ttl`. Across the system: `/echomq/bus`, `/echomq/queue`.

## References

- Erlang/OTP — the ets module (the L1 row a stale drop evicts).
- Valkey — PUBLISH (the broadcast lane), GET / DEL (the conditional drop), Cluster specification (the `{table}`
  hashtag co-locating the `ecc:` key with the coherence channel).
- King — Announcing Snowflake (the mint-time id whose order *is* the coherence comparison).
- Helland — Life Beyond Distributed Transactions (the entity addressed by a name; a message about a name).
- Related in this course: `/echomq/cache`, `/echomq/cache/single-flight-and-jittered-ttl`, `/echomq/bus`,
  `/bcs/store`, `/echo-persistence`.
