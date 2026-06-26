# R7.02.3 · capped structures

> Route: `/redis-patterns/data-modeling/memory-optimization/capped-structures` · dive 3.

A compact encoding saves bytes on a structure; a cap bounds how many bytes it can ever take. A List or a Stream that grows without limit is a memory leak waiting for traffic. The fix is to trim it where it is written: `LTRIM list 0 N` keeps a List to its newest N entries; `XTRIM … MAXLEN ~` keeps a Stream to roughly its newest N. EchoMQ does both — the per-group wake list is capped at 64, the streams are `MAXLEN ~`-capped — so the memory ceiling is a property of the code, not a hope about volume.

## §1 · The unbounded structure is the hazard

Lists and Streams are append-friendly: `LPUSH`/`RPUSH` and `XADD` are O(1), so it is easy to write to them on a hot path and never remove. Left alone, they grow with traffic forever, and a structure that only grows will eventually exhaust memory — at which point, under `noeviction`, writes start failing. A cap removes the hazard at the source: bound the structure when you write it, and its size is fixed no matter how much traffic arrives.

A cap is also when a List or Stream leaves its compact encoding behind safely. The point of a cap is not the encoding, though — it is the absolute ceiling: a capped structure cannot leak, by construction.

## §2 · `LTRIM` — the wake list at 64

EchoMQ's fair-lanes layer keeps a per-group **wake list**: a short signal list a parked consumer watches, written on the hot admission path. If it were unbounded it would grow with every admitted job. It is not — it is capped the moment it is pushed:

```lua
-- EchoMQ.Lanes — the wake, verbatim from the grouped-admission script
redis.call('LPUSH', KEYS[7], '1')
redis.call('LTRIM', KEYS[7], 0, 63)
```

`LPUSH` adds a marker; `LTRIM KEYS[7], 0, 63` immediately keeps only indices 0 through 63 — at most 64 entries — and discards the rest. The list is a bounded ring, never an unbounded log: one wake is enough to rotate a parked consumer back to service, so 64 markers is generous headroom and the memory is fixed. The moduledoc frames the layer: *"the ring is the rota — a list holding exactly the lanes that can be served right now."*

## §3 · `XTRIM … MAXLEN ~` — the stream cap

A Stream is the retained, replayable log. EchoMQ trims it to a declared retention window over `XTRIM`, issued directly:

```elixir
# EchoMQ.Stream — trim/4, verbatim
def trim(conn, queue, name, {:maxlen, count, approx?})
    when is_binary(queue) and is_binary(name) and is_integer(count) and count >= 0 and
           is_boolean(approx?) do
  key = stream_key(queue, name)
  xtrim(conn, ["XTRIM", key, "MAXLEN", approx_flag(approx?), Integer.to_string(count)])
end

defp approx_flag(true), do: "~"
defp approx_flag(false), do: "="
```

The third argument, `approx?`, selects the trim mode — and it is the memory-vs-exactness trade. `true` selects `~` (the **safe** default): Valkey trims in whole macro-node boundaries, which is cheaper, may **under-trim** (the stream can briefly hold a few more than `count`), but **never over-trims** — it can never delete an entry inside the window. `false` selects `=`: trim exactly to the window edge, at a higher cost. Either way the blast radius is bounded by the window, and `trim/4` answers `{:ok, removed_count}` — the integer `XTRIM` returns. The `~` form is the right default precisely because the goal is a bound, not an exact count: a handful of extra entries costs almost nothing, and the cheaper trim keeps the hot path fast.

## The bridge — pattern → application

**Pattern.** Bound a structure so it cannot leak memory: `LTRIM list 0 N` keeps a List to its newest N; `XTRIM … MAXLEN ~` keeps a Stream to roughly its newest N, trading exactness for a cheaper trim.

**EchoMQ application.** The per-group wake list is `LTRIM KEYS[7], 0, 63`-capped at 64 (`lanes.ex`); the streams are `XTRIM … MAXLEN ~`-capped (`stream.ex`, with `~` the safe default). The memory ceiling is fixed in the code that writes the structure.

**Take.** The cheapest guarantee against a memory leak is a cap at the write. EchoMQ caps the wake list at 64 and trims its streams with the approximate `MAXLEN ~`, so neither structure can grow without bound — exactness given up only where a bound, not a precise size, is what matters. The same record discipline runs through R7.1's job HASH.

## References

### Sources

- [Valkey — LTRIM](https://valkey.io/commands/ltrim/) — keep a List to a range so it becomes a bounded ring; the wake-list cap at 64.
- [Valkey — XTRIM](https://valkey.io/commands/xtrim/) — trim a Stream to `MAXLEN`; the `~` flag trims in whole macro-nodes, never inside the window.
- [Valkey — XADD](https://valkey.io/commands/xadd/) — append with an inline `MAXLEN ~` cap on the same write.
- [Valkey — Streams intro](https://valkey.io/topics/streams-intro/) — the retained log, capped retention, and the approximate-trim trade.

### Related in this course

- [R7.02 · Memory optimization](/redis-patterns/data-modeling/memory-optimization) — the module hub.
- [R7.02.1 · listpack-and-intset](/redis-patterns/data-modeling/memory-optimization/listpack-and-intset) — the compact encodings a small structure earns.
- [R7.02.2 · short-field-names](/redis-patterns/data-modeling/memory-optimization/short-field-names) — keeping the row in the compact encoding.
- [R7.01 · Redis as a primary database](/redis-patterns/data-modeling/primary-database) — the same job HASH as the record of truth, under `noeviction`.
