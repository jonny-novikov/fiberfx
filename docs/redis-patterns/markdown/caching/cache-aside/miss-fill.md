# GET / SET PX miss-fill

> Route: `/redis-patterns/caching/cache-aside/miss-fill` · Module R1.01 · dive 1 · Source:
> `content/fundamental/cache-aside.md.txt` (the *How It Works* sequence + *Redis Commands Used*) · Grounding:
> `EchoCache.Table.launch_flight/2` (`echo/apps/echo_cache/lib/echo_cache/table.ex:391`).

Ask Valkey first. On a hit, serve it. On a miss, read the source and write it back with an expiry, so the next read
is a hit. This is the read half of cache-aside — the source's *How It Works* sequence, focused on the miss path,
with the two commands it runs.

## One GET, then a branch

The read path has exactly one decision: did `GET` return a value or `nil`. A value is a **hit** — serve it and stop;
the source is never touched. A `nil` is a **miss** — read the source of record, then write the value back to Valkey
with an expiry so the cache is warm for the next read. The fill step is the half that makes the cache earn its keep:
without it every read would be a miss and Valkey would be dead weight in front of the source. This is why the
strategy is called **lazy loading** — nothing is cached until it is asked for.

## Filling with an expiry, never without

```
GET ecc:{quotes}:AST0NuE6bV7FoH                       # => nil  (a miss)
SET ecc:{quotes}:AST0NuE6bV7FoH "{…value…}" PX 300    # fill the cache, value + TTL in one command
```

Set the value and the TTL in one command. A bare `SET` with a separate `EXPIRE` leaves an immortal key if the
process dies between the two, so the value never falls out of the cache and staleness has no ceiling. The `PX 300`
caps the lifetime of the filled value — the backstop the third dive measures.

## On EchoCache

The miss path is the real `EchoCache.Table.launch_flight/2`: the flight runs `GET ecc:{table}:id`; on `{:ok, nil}`
it calls the declared `loader.(id)`, then writes both layers with `SET … PX ttl`, framing the value with the
write's mint-time version. The whole read surface is `Table.fetch/3` — it returns `{:ok, value, source}` with
source `:hit | :l2 | :fill`, so a caller learns whether its answer came from L1 ETS, L2 Valkey, or a fresh loader
fill. The functional-Elixir craft behind the loader is taught by the
[`/elixir` state chapter](/elixir/pragmatic/state).

```elixir
# launch_flight/2 (table.ex:391), trimmed — GET, fall through to the loader, fill with PX.
case Connector.command(conn, ["GET", l2]) do
  {:ok, nil} ->                                     # miss: read the source, then fill
    {:ok, value, version} = loader.(id)
    Connector.command(conn, ["SET", l2, version <> value, "PX", Integer.to_string(ttl)])
    {:fill, value, version}

  {:ok, <<version::binary-14, value::binary>>} ->   # L2 hit: the framed value
    {:l2, value, version}
end
```

The key is `ecc:{<table>}:<id>` (`EchoCache.Keyspace.key/2`), the table name hash-tagged so the entity lands in one
cluster slot. The `PX` ties the L2 row to its expiry so a key the next dives never clear still cannot live forever.

## References

### Sources
- [Redis — GET](https://redis.io/commands/get) — the read that opens every cache-aside lookup; returns the value or nil on a miss.
- [Valkey — SET](https://valkey.io/commands/set/) — set a key with a value and the `PX` time-to-live in one command; the miss-fill move.
- [Redis — Documentation](https://redis.io/docs/) — strings, expiry, and the lazy-loading read pattern in context.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on expiry and treating cached values as disposable.

### Related in this course
- [R1.01 · Cache-aside](/redis-patterns/caching/cache-aside) — the module hub.
- [R1.01.2 · Explicit invalidation](/redis-patterns/caching/cache-aside/invalidation) — the next dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq](/echomq) — the EchoMQ protocol behind the connector.
- [/elixir · State](/elixir/pragmatic/state) — the functional-Elixir craft behind the loader.
