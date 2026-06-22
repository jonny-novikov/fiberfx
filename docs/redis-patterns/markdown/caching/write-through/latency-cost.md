# The latency cost

> Route: `/redis-patterns/caching/write-through/latency-cost` · Module R1.02 · dive 3 · Source:
> `content/fundamental/write-through.md.txt` (the *Disadvantages* + *Handling Partial Failures*) · Grounding:
> the synchronous `GenServer.call(name, {:put, …}, 10_000)` (`echo/apps/echo_cache/lib/echo_cache/table.ex:101`) —
> the caller waits for the L2 `SET` round-trip.

The freshness guarantee is not free: every write pays for the L2 round-trip on the hot path, and either layer can
fail. Write-through's consistency comes from doing the L2 `SET` and the L1 `insert` before the call returns — so the
write latency is the sum, not the faster of the two. This dive weighs that cost against write-behind and names the
failure modes.

## Every write pays for both layers

`EchoCache.Table.put` is a synchronous `GenServer.call(name, {:put, id, value, version}, 10_000)`: the caller blocks
until the owner has set the L2 Valkey row and inserted into the L1 ETS table. The L1 insert is cheap — an ETS write
is sub-microsecond — but the L2 `SET` is a network round-trip, the larger term, and write-through puts it on every
write. The committed figures size the gap: an L1 hit is `762 ns`, an L2 `GET` is `31 us` — the L1 hit is `40 times
cheaper` than the round trip (`bcs4.1`). Write-through pays that L2 cost on the write path rather than deferring it.

This is the trade write-behind makes differently. Write-behind writes the L1 cache, records the change locally, and
returns — so its hot-path latency is the cache write plus a small local record, and the database catches up
afterwards over the bus. Write-behind is faster on the write and risks losing the buffered write if the process dies
before it drains; write-through is slower on the write and never loses the source write, because it does not return
until the source has it. Choose the slower, safer write where read-after-write freshness and durability both matter;
choose write-behind where write throughput matters more than a few milliseconds of lag.

- **hot path** — the latency the caller waits on. Write-through puts the L2 round-trip on it; write-behind puts only
  the L1 write plus a local record.
- **write latency** — for write-through, the L2 `SET` round-trip + the L1 `insert`. For write-behind, the L1 write +
  a small local record.
- **durability** — write-through never loses the source write — it returns only after the source has it. Write-behind
  can lose a buffered write on a crash.
- **trade** — write-through buys freshness and durability with latency; write-behind buys latency with a window of
  risk.

## When one layer fails

Writing two layers in sequence means there are two ways to fail, and the order determines what state is left behind.
With the source written first and the cache second:

- **the source write fails** — source unchanged, cache unchanged; the write is reported as a failed write. The source
  is written first, so its failure stops the write before the cache changes.
- **the cache write fails** — source updated, cache write failed; the write is reported as failed rather than success
  with a stale cache; the next read takes a miss and re-reads the source.
- **both succeed** — source updated, cache updated; the put clause matches `{:ok, "OK"}` from Valkey, inserts into
  L1, and replies `:ok`. Both writes landed before the call returned.

Writing the source first bounds the damage: a source failure never leaves the cache ahead of the source, and a cache
failure is reported, not hidden behind a stale value. In the put clause, the strict `{:ok, "OK"} = …` match means a
non-OK L2 reply fails the call rather than falling through to the L1 insert.

## On EchoCache

On EchoCache's write path, `EchoCache.Table.put` sets the L2 Valkey row, inserts into the L1 ETS table, and returns
once both are done — all inside one `GenServer.call`. A caller that updates an instrument row waits for the L2
round-trip, and reads the fresh value back immediately. If the L2 `SET` does not answer `{:ok, "OK"}`, the match
fails the call rather than reporting success with a stale cache. The cost — the L2 round-trip on every write — is the
price of that guarantee.

```
# echo/apps/echo_cache/lib/echo_cache/table.ex
def put(name, id, value, <<_::binary-14>> = version) when is_binary(value) do
  # ... gate the kind ...
  GenServer.call(name, {:put, id, value, version}, 10_000)   # synchronous: the caller waits
end

# handle_call({:put, …}):
{:ok, "OK"} = Connector.command(state.conn, ["SET", l2, version <> value, "PX", ttl])  # L2 round-trip
insert(state, id, value, version)                                                       # L1 insert
# write latency = L2 SET round-trip + L1 insert   (both on the hot path)
```

How the bus carries a deferred write at-least-once — the write-behind alternative — is the EchoMQ protocol, taught in
depth at [`/echomq`](/echomq). This dive weighs the latency and names the failure modes; it does not repeat the
engine's internals.

Write-through trades write latency and a second point of failure for the consistency guarantee. The write-heavy,
stale-tolerant alternative is write-behind — the next module.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — the L2 write whose round-trip is added to every write-through write.
- [Valkey — Topics](https://valkey.io/topics/) — the engine the L2 layer runs on; the live line is Valkey, the round-trip the figures measured.
- [Redis — SET](https://redis.io/commands/set) — the string write-path command and its `PX` expiry.
- [Redis — Documentation](https://redis.io/docs/) — the persistence and durability options behind the cost and durability trade.

### Related in this course
- [R1.02 · Write-through](/redis-patterns/caching/write-through) — the module hub.
- [R1.02.2 · The consistency guarantee](/redis-patterns/caching/write-through/consistency) — the previous dive.
- [R1.02.1 · The synchronous dual write](/redis-patterns/caching/write-through/dual-write) — the write that costs this latency.
- [R1 · Caching](/redis-patterns/caching) — the chapter; R1.03 Write-behind is the latency-cheaper alternative.
- [/echomq](/echomq) — the bus the write-behind alternative defers the database write onto.
