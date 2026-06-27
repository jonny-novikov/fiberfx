# Cache the catalog

> Route: `/redis-patterns/caching/workshop/cache-the-catalog` · Module R1.07 · stage 1 of 3 · Source: none — a
> **capstone** dive synthesizing cache-aside (R1.01) applied to codemojex's emoji set; no single
> `content/…md.txt` author source. · Grounding: `EchoStore.Table.fetch/3` in front of `Codemojex.Cache`
> (`echo/apps/echo_store`, `echo/apps/codemojex`).

Put a cache-aside read in front of one real consumer surface — the emoji set `Codemojex.Guesses.submit/3` checks
every guess against. One read path, an L1 ETS hit or a single-flight fill. The play API validates the keyboard via
`Codemojex.Cache.fetch_set/1` and `EmojiSet.valid_guess?/2` (→ `{:error, :bad_guess}` for a code the round's
keyboard does not expose), and that emoji set is read far more often than it changes — immutable for the round's
life — the workload cache-aside is built for. `EchoStore.Table.fetch/3` is the read path. The deeper
functional-Elixir craft behind the loader is [`/elixir`](/elixir).

## Two reads, one declared cache

The cache read resolves an emoji set by its branded id. `EchoStore.Table.fetch/3` is the whole surface, and it
answers from one of three sources, in order: an **L1 hit** in the caller's own process, an **L2 hit** on the shared
Valkey, or a **fill** through the declared loader. The return is `{:ok, value, source}` with source `:hit | :l2 |
:fill` — the source tag is observability, not ceremony.

The key form is the cache's own: `ecc:{cm_emojisets}:<id>`, built by `EchoStore.Keyspace.key/2` as `"ecc:{" <> table
<> "}:" <> id`. The table name is hash-tagged inside the braces so every key of one cache lands in one cluster slot
the day clustering arrives — a fresh prefix beside the bus's `emq:`, never inside it. The id in the key's value
position is checked for shape before any key is composed; a malformed name never reaches the wire.

The read path never enters the table's owner process on a hit. A hit is a caller-side `:ets.lookup` against a public,
read-concurrent table, plus the kind gate and one atomic counter bump. The owner is consulted only on a miss — and
that is the second law: one fill per herd, the next dive's territory by construction.

- `EchoStore.Table.fetch/3` — the read. Returns `{:ok, value, :hit | :l2 | :fill}`, `{:error, :kind}` for a
  wrong-namespace id, or the loader's error.
- `ecc:{cm_emojisets}:<id>` — the L2 key form (`EchoStore.Keyspace.key/2`), the table name hash-tagged for one slot.
- the kind gate — `byte_size(id) == 14 and binary_part(id, 0, 3) == kind and BrandedId.valid?(id)`; a
  wrong-namespace id is refused at the door, before either layer is touched.
- L1 ETS — the hit path: a public, read-concurrent table read in the caller's process at memory speed.

Keeping the cache consistent on a change — and resolving newer-wins — is the next dive, R1.07.2 · Keep it consistent.

## Lazy fills, read by read

A cold cache fills itself from real traffic. The first guess against an emoji set misses, and `fetch/3` routes
through the owner to a **single-flight fill** — `launch_flight/2` runs `GET ecc:{cm_emojisets}:<id>`; on `{:ok, nil}`
it calls the declared loader, then writes both layers with `SET … PX`. Every read after it — until the row expires or
is dropped — hits L1 in its own process. The cost of a cold start is a number that falls as sets warm: the loader
runs once per fill.

A trace is a fixed sequence of reads against a cache that starts empty. The first touch of each emoji set is a miss
and a fill; a repeat touch within the window is an L1 hit. The L2 row carries the declared TTL on the server's own
clock — `PTTL 300 ms of 300` in the committed gate — written with `SET … PX` so the second layer expires itself even
if every node forgets.

A cold cache warms read by read: the first touch of each emoji set misses and fills with `SET … PX`; every later
touch hits L1 at ETS speed. The loader runs once per fill, and the L1 hit is `40 times cheaper` than the L2 round trip
it replaces.

## The emoji-set read path on EchoStore

Take one read: `Codemojex.Guesses.submit/3` resolves the round's emoji set to validate a guess. The call is
`EchoStore.Table.fetch/3` against the `:cm_emojisets` table. On a hit it returns from L1 ETS; on a miss the owner
launches a single flight that checks L2, falls through to the loader, writes both layers, and replies to the caller —
and to any waiter that coalesced behind it — with the one answer. The play API receives the emoji set or, for a code
the round's keyboard does not expose, `{:error, :bad_guess}` from `EmojiSet.valid_guess?/2`; the hit-or-miss branch
lives in the cache. The deeper functional-Elixir and OTP craft of the loader and the play API is [`/elixir`](/elixir).

```elixir
# The emoji-set read path — one fetch/3, three sources, the source tag is observability.
{:ok, set, source} = EchoStore.Table.fetch(:cm_emojisets, set_id)
# source :: :hit | :l2 | :fill

# Inside the owner, on a miss — launch_flight/2 (echo_store/table.ex:391):
case Connector.command(conn, ["GET", l2]) do   # l2 = "ecc:{cm_emojisets}:" <> set_id
  {:ok, nil} ->                                  # miss: run the loader, then fill both layers
    {:ok, value, version} = run_loader(loader, set_id)
    {:ok, "OK"} = Connector.command(conn, ["SET", l2, version <> value, "PX", ttl_ms])
    {:fill, value, version}

  {:ok, <<version::binary-14, value::binary>>} -> # L2 hit: frame the version off the front
    {:l2, value, version}
end
```

The L2 value is framed — a 14-byte branded version prefix in front of the bytes — so a later read can compare the
version newer-wins. Both layers are written under one TTL, on the server's clock for L2 and a jittered monotonic clock
for L1. How the loader reads and shapes the source is [`/elixir`](/elixir), not repeated here.

**The pattern → EchoStore.** Cache-aside read: check the cache, and on a miss run the loader and fill — the cache
fills lazily, one requested emoji set at a time. On codemojex `EchoStore.Table.fetch/3` runs that read path over the
emoji set `Codemojex.Guesses.submit/3` checks, returning `:hit | :l2 | :fill`; a wrong-namespace id is refused at the
door. One read path serves every emoji set: one `fetch/3`, three sources, and a cache that warms from real traffic.

## Recap — the base layer is in place

The emoji set now reads through EchoStore. Every lookup is one `fetch/3`: an L1 ETS hit, an L2 hit, or a
single-flight fill that runs the loader and writes both layers with `SET … PX`. The cache warms lazily and every L2
fill carries a TTL. What it does not yet do is react to a change — a room re-templated with a new emoji set keeps
serving its old cached copy until the TTL expires. The next dive drops the L1 row on a change and resolves
newer-wins.

Next in the workshop: **R1.07.2 · Keep it consistent** — `Coherence.broadcast/4` or `Coherence.enqueue/5` on a
change, with `Coherence.newer?/2` the comparison.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set/) — `SET … PX` sets a value and its TTL in one atomic command; the L2 fill of the single-flight load.
- [Valkey — Topics](https://valkey.io/topics/) — the engine the EchoStore gate is measured against, Valkey.
- [Redis — GET](https://redis.io/commands/get) — the read that opens the L2 path; returns the framed value or nil on a miss.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on expiry and treating cached values as a disposable copy.

### Related in this course
- [R1.07 · Caching workshop](/redis-patterns/caching/workshop) — the workshop hub.
- [R1.07.2 · Keep it consistent](/redis-patterns/caching/workshop/keep-it-consistent) — the next stage.
- [R1.01 · Cache-aside](/redis-patterns/caching/cache-aside) — the base pattern.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/bcs](/bcs/cache/cache-aside) — the EchoStore cache-aside manuscript chapter.
- [/elixir](/elixir) — the functional-Elixir and OTP craft behind the loader.
