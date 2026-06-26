# The cache-aside read

**Dive 02 of Cache-aside, two layers · `/echomq/cache/cache-aside-two-layers/the-cache-aside-read`**

`EchoStore.Table.fetch/3` — the read path never enters the owner.

## The kind gate

Before either layer is touched, the kind gate runs. The table declares a `kind` — a 3-byte namespace. Every
id that arrives at `fetch/3` is checked: 14 bytes, first 3 bytes match the table's kind, and
`BrandedId.valid?/1` is true. A wrong-namespace id is refused at the door with `{:error, :kind}` — it
never reaches L1 or L2.

```elixir
# EchoStore.Table — gate/2 (private)
# The kind law: every id is checked against the table's declared namespace
# before either layer is touched. A 14-byte branded id has its namespace
# in the first 3 bytes. BrandedId.valid?/1 checks the Base62 encoding.
defp gate(kind, id) do
  if is_binary(id) and byte_size(id) == 14 and binary_part(id, 0, 3) == kind and
       BrandedId.valid?(id) do
    :ok
  else
    {:error, :kind}
  end
end
```

## The L1 fast path

A hit costs only a lookup, in the caller's own process:

```elixir
# EchoStore.Table — fetch/3
# The read path: gate first, then an L1 lookup in the caller's process.
# A hit is valid if now (monotonic ms) is before the row's expires_at.
# A miss is the only message sent to the owner.
def fetch(name, id, timeout \\ 10_000) do
  case EchoStore.spec(name) do
    :error ->
      {:error, :no_such_cache}

    {:ok, spec} ->
      # The kind gate: wrong namespace → refused before any layer is touched
      with :ok <- gate(spec.kind, id) do
        now = System.monotonic_time(:millisecond)

        case :ets.lookup(name, id) do
          [{^id, value, expires_at, _version}] when now < expires_at ->
            # Hit: the row exists and has not expired — answer from L1, in this process
            :counters.add(spec.counters, @counters[:hits], 1)
            {:ok, value, :hit}

          _ ->
            # Miss (absent or expired): ask the owner to fill
            :counters.add(spec.counters, @counters[:misses], 1)
            GenServer.call(name, {:fill, id}, timeout)
        end
      end
  end
end
```

`:ets.lookup(name, id)` runs in the caller's scheduler thread. No GenServer call, no mailbox — reads scale
with the number of schedulers, not with the throughput of one process.

## The miss path

On a miss, `GenServer.call(name, {:fill, id})` hands off to the owner. The owner's `handle_call/3`:

1. Re-checks L1 (the race may have been won between the caller's miss and this call).
2. If a flight for `id` already exists, the caller is appended to its waiters (`:coalesced`).
3. Otherwise, `launch_flight/2` starts a `spawn_monitor`d task.

The flight runs:
- `GET ecc:{table}:id` via `EchoMQ.Connector.command/2`.
- `{:ok, nil}` → run `loader.(id)`, `SET ecc:{table}:id (version <> value) PX ttl_ms`, send `{:fill,
  value, version}`.
- `{:ok, <<version::binary-14, value::binary>>}` → send `{:l2, value, version}` — the L2 frame is
  self-describing.
- `{:ok, _short}` → send `{:error, :corrupt_l2_frame}`.

`handle_info({:flight, id, result})` replies **the same answer** to every waiter and clears the flight.
A flight crash (`:DOWN`) replies `{:error, {:flight_crashed, reason}}` to all waiters — no caller wedges.

## The three sources

`fetch/3` returns `{:ok, value, source}` with `source` ∈ `:hit | :l2 | :fill`:

- `:hit` — answered from L1, in the caller's process.
- `:l2` — missed L1, found in Valkey (`GET` returned a frame).
- `:fill` — missed both layers, the declared loader ran.

## The L2 frame

Every value stored in Valkey is framed: `version <> value`. The flight splits it as
`<<version::binary-14, value::binary>>`. This makes a cached value self-describing — wherever it came from,
it carries the 14-byte mint-time branded id that the write placed there. Module 03 compares two such
versions with newer-wins.

## Pattern ↔ implementation

**Pattern:** cache-aside — the application reads the cache first; on a miss it goes to the source of truth,
fills the cache, and returns.

**Implementation:** `fetch/3` tries L1 (caller-side `:ets.lookup`), then L2 (via `GET`), then the declared
`loader.(id)`. The kind gate enforces the namespace contract before any tier is touched. The source tag
(`:hit | :l2 | :fill`) tells the caller exactly where the answer came from.

## Recap

`fetch/3` gates on kind, then tries L1 in the caller's process (a hit returns immediately), then on a miss
asks the owner to fill. The owner starts exactly one flight per id, coalesces concurrent misses onto it, and
replies the same answer to every waiter. The L2 value is the frame `version <> value`, split on read. The
three sources tag the reply with where the answer came from.

## References

### Sources
- Erlang/OTP — the ets module: https://www.erlang.org/doc/apps/stdlib/ets.html
- Valkey — GET command: https://valkey.io/commands/get/
- Valkey — SET command: https://valkey.io/commands/set/
- King — Announcing Snowflake (2010): https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake

### Related in this course
- `/echomq/cache` — the Cache chapter landing
- `/echomq/cache/cache-aside-two-layers` — module hub
- `/echomq/protocol` — the branded-id gate the kind gate extends
- `/bcs/store` — the BCS manuscript chapter
