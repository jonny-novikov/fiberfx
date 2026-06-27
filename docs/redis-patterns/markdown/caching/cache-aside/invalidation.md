# Explicit invalidation

> Route: `/redis-patterns/caching/cache-aside/invalidation` · Module R1.01 · dive 2 · Source:
> `content/fundamental/cache-aside.md.txt` (the write path + *Mitigating Staleness*) · Grounding:
> `EchoStore.Table.invalidate/3` (`table.ex:171`) and the version-safe `EchoStore.Coherence.drop_l2/4`
> (`coherence.ex:75`).

A write clears the cached key with an explicit `DEL`. The order matters: write the source first, delete the key
second, or a stale value comes back. This is the write half of cache-aside — the source's write path, focused on the
invalidate move and the write-then-invalidate ordering.

## Delete the key, do not rewrite it

On a write to the source, cache-aside removes the cached key with `DEL`; it does not write the new value into the
cache. The source of record is authoritative, so the cleanest move is to discard the stale copy and let the next
read fill a fresh one — the same miss-fill path the first dive built. Updating the cache on a write instead
duplicates the source's write logic and widens the race surface: two writes that interleave can leave the cache
holding a value neither intended. `DEL` fails safe — an absent key is never stale; it only forces one extra source
read on the next request. Deleting fails safe where rewriting can fail stale.

```
DEL ecc:{cm_emojisets}:EMS0ODMggk1d5N        # => 1 if it existed, 0 if already absent
```

## The resurrection race, step by step

The danger is a read that overlaps a write. A reader misses, reads the source, and fills the cache; a writer changes
the source and deletes the key. If the reader's fill lands *after* the writer's delete, the cache ends up holding
the value the reader read — which, if it read before the write committed, is the old one. That stale value then sits
in the cache until its TTL expires. Write the source first and delete the key second, so the delete is the last
word: a fill that lands after the delete caches whatever the reader read, so the delete must come last.

## On EchoStore

EchoStore offers two invalidations. The unconditional admin verb is `Table.invalidate/3` — a `DEL` on the L2 key
plus an `:ets.delete` on L1, dropping one name from both layers. But the sharper tool closes the resurrection race
by construction: `Coherence.drop_l2/4` runs one atomic Lua script (`coherence_drop`) that deletes the L2 row **only
when the incoming version is newer** than the version framed into the stored value — so a late stale invalidation
can never erase a newer row. The functional-Elixir craft behind the write is taught by the
[`/elixir` state chapter](/elixir/pragmatic/state).

```elixir
# Table.invalidate/3 (table.ex:171) — the admin verb: drop both layers unconditionally.
def handle_call({:invalidate, id}, _from, state) do
  l2 = Keyspace.key(state.table, id)
  {:ok, _} = Connector.command(state.conn, ["DEL", l2])
  :ets.delete(state.name, id)
  {:reply, :ok, state}
end
```

The version-safe lane runs instead when ordering across writers matters: `drop_l2/4` (coherence.ex:75) evaluates
the `coherence_drop` script, which compares the incoming version's snowflake payload against the stored frame and
deletes only on newer — one transition, one script, no resurrection.

## References

### Sources
- [Redis — DEL](https://redis.io/commands/del) — remove one or more keys; returns the count removed. The invalidate move on a write.
- [Redis — GET](https://redis.io/commands/get) — the read that misses on a deleted key and triggers the re-fill.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic script execution: the basis of the version-safe conditional drop.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on ordering, races, and treating the cache as derived state.

### Related in this course
- [R1.01 · Cache-aside](/redis-patterns/caching/cache-aside) — the module hub.
- [R1.01.1 · GET / SET PX miss-fill](/redis-patterns/caching/cache-aside/miss-fill) — the read path the re-fill uses.
- [R1.01.3 · TTL & staleness](/redis-patterns/caching/cache-aside/ttl-staleness) — the next dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq/cache](/echomq/cache) — EchoStore coherence drops the stale copy, in depth.
- [/elixir · State](/elixir/pragmatic/state) — the functional-Elixir craft behind the write.
