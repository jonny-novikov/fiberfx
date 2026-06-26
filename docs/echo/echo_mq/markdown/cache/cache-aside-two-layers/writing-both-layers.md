# Writing both layers

**Dive 03 of Cache-aside, two layers · `/echomq/cache/cache-aside-two-layers/writing-both-layers`**

`EchoStore.Table.put/3`, `put/4`, `invalidate/3` — every write frames the value with its mint-time version.

## The write path

A write goes to both layers in order: L2 first (the durable shared store), then L1 (the local ETS row).
There are two arities:

- `put(name, id, value)` — mints a version of the table's `kind` now. The version is
  `EchoData.BrandedId.generate!(spec.kind)`, a fresh 14-byte branded id at the millisecond of the write.
  The write is its own event.
- `put(name, id, value, <<_::binary-14>> = version)` — carries the caller's own 14-byte version. Used when
  the writer already has a branded id it wants to pin to the value (e.g. the id of the entity being cached).

Both arities share the same internal handler:

```elixir
# EchoStore.Table — handle_call({:put, id, value, version}, ...)
# Both layers, in order: L2 first, then L1.
# The value is framed version <> value — a 14-byte branded id prepended
# to the binary — so every L2 entry carries its own mint-time version.
def handle_call({:put, id, value, version}, _from, state) do
  # L2 first: SET the framed value with PX ttl_ms
  l2 = Keyspace.key(state.table, id)

  {:ok, "OK"} =
    Connector.command(state.conn, [
      "SET",
      l2,
      version <> value,
      "PX",
      Integer.to_string(state.spec.ttl_ms)
    ])

  # L1: insert the row {id, value, expires_at, version}
  # expires_at is jittered: ttl ± ttl·jitter (monotonic ms)
  insert(state, id, value, version)
  {:reply, :ok, state}
end
```

The Valkey key is `ecc:{table}:id`. The value stored is `version <> value` — a binary with the 14-byte
branded id prepended. `PX ttl_ms` sets the key's expiry in milliseconds.

The L1 row is `{id, value, expires_at, version}` — the version is stored separately in the ETS tuple so a
coherence comparison can read it without decoding the value.

## The L2 frame in detail

```elixir
# The L2 frame: version <> value
# version is a 14-byte branded id (e.g. "RMM0Kp7qW2Nmnx")
# value is the application's binary payload
# The frame is split on read: <<version::binary-14, value::binary>>
# so a fill or l2-source fetch can recover both from one GET.
```

This frame is what makes the cache self-describing. A `GET ecc:{table}:id` returns the frame, and the
flight splits it into `(version, value)` in one binary match without a separate metadata key.

## The admin verb: invalidate

`invalidate/3` is the unguarded drop — it does not compare versions:

```elixir
# EchoStore.Table — handle_call({:invalidate, id}, ...)
# The admin verb: DEL L2, :ets.delete L1, unconditionally.
# Distinct from the coherence drop (module 03), which guards on version.
def handle_call({:invalidate, id}, _from, state) do
  l2 = Keyspace.key(state.table, id)
  {:ok, _} = Connector.command(state.conn, ["DEL", l2])
  :ets.delete(state.name, id)
  {:reply, :ok, state}
end
```

`DEL` removes the L2 key. `:ets.delete(state.name, id)` removes the L1 row. No version check — this is the
operator path, used when correctness requires unconditional eviction regardless of which version is current.

## The version as the seed of coherence

Every value framed with its mint-time version carries the information module 03 needs: two versions can be
compared with newer-wins (a comparison of two 14-byte branded ids, where the time component in the snowflake
makes "newer" well-defined). The `coherence_drop` Lua script (module 03, out of scope here) guards on that
comparison. The point here is: the version is written with the value, always, so that comparison is always
available — it costs nothing extra.

## Pattern ↔ implementation

**Pattern:** cache-aside write — the application writes to the source of truth and to the cache in the same
operation. The cache value is stamped with the write's identity so a later reader can detect staleness.

**Implementation:** `put/3-4` writes L2 with `SET … PX` and L1 with `insert/4`. The frame `version <> value`
is the stamp. `invalidate/3` is the operator's escape hatch — unconditional, no version guard. The version
guard (newer-wins) is module 03's coherence path.

## Recap

`put/3` mints a version, `put/4` carries the caller's own. Both write L2 first (`SET ecc:{table}:id
(version <> value) PX ttl_ms`) then L1 (`insert/4` → the `{id, value, expires_at, version}` row).
`invalidate/3` deletes both unconditionally — the admin verb, distinct from the version-guarded coherence
drop. Every value in L2 carries its mint-time version so a fill or coherence comparison can read it from a
single `GET`.

## References

### Sources
- Valkey — SET command: https://valkey.io/commands/set/
- Valkey — DEL command: https://valkey.io/commands/del/
- Erlang/OTP — the ets module: https://www.erlang.org/doc/apps/stdlib/ets.html
- King — Announcing Snowflake (2010): https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake
- Helland — Life Beyond Distributed Transactions: https://ics.uci.edu/~cs223/papers/cidr07p15.pdf

### Related in this course
- `/echomq/cache` — the Cache chapter landing
- `/echomq/cache/cache-aside-two-layers` — module hub
- `/echomq/bus` — the broadcast wire a coherence message travels over
- `/echomq/protocol` — the branded-id gate
- `/bcs/store` — the BCS manuscript chapter this module realizes
