# One fill per herd

**Route:** `/echomq/cache/single-flight-and-jittered-ttl/one-fill-per-herd`  
**Module:** Single-flight & jittered TTL · dive 01  
**Grounding:** `echo/apps/echo_store/lib/echo_store/table.ex` — `handle_call({:fill, id})` + `launch_flight/2` + `handle_info({:flight, …})` + the `:DOWN` handler.

## The second law

The read path of `EchoStore.Table` never enters the owner on a hit: `fetch/3` does a caller-side
`:ets.lookup` and returns `{:ok, value, :hit}` without a GenServer call. On a miss it sends `{:fill, id}`
to the owner.

The owner's `handle_call({:fill, id})` is where the second law holds: **one fill per herd**. Before
starting any flight it re-checks L1 (the race may have been won while the message was in the mailbox), then:

- If a flight for `id` already exists in `state.flights`, append `from` to its waiters and count
  `:coalesced` — start **no** second flight.
- Otherwise call `launch_flight/2` and record `{ref, [from]}` in `state.flights[id]`.

The owner is never blocked: both branches reply `{:noreply, …}` and let the flight do its work asynchronously.

## The flight

`launch_flight/2` is a `spawn_monitor`d anonymous function. It holds a copy of the owner's connector,
loader, TTL, and a freshly minted `kind_version`. Its logic:

```elixir
# launch_flight/2 — a spawn_monitor'd task; the owner is never blocked
defp launch_flight(state, id) do
  owner = self()
  l2 = Keyspace.key(state.table, id)      # "ecc:{table}:id"
  loader = state.loader                    # the declared 1-arity fun
  conn   = state.conn
  ttl    = state.spec.ttl_ms
  kind_version = EchoData.BrandedId.generate!(state.spec.kind)  # the fill's own mint-time version

  {_pid, ref} =
    spawn_monitor(fn ->
      result =
        case Connector.command(conn, ["GET", l2]) do
          {:ok, nil} ->
            # L2 miss — run the declared loader, write both layers
            case loader.(id) do
              {:ok, value} when is_binary(value) -> {:ok, value, kind_version}
              {:ok, value, <<_::binary-14>> = v} when is_binary(value) -> {:ok, value, v}
              {:error, _} = err -> err
              other -> {:error, {:bad_loader_result, other}}
            end
            |> case do
              {:ok, value, version} ->
                # SET L2 with PX; the frame is version <> value
                {:ok, "OK"} =
                  Connector.command(conn, ["SET", l2, version <> value, "PX", Integer.to_string(ttl)])
                {:fill, value, version}
              {:error, _} = err -> err
            end

          {:ok, <<version::binary-14, value::binary>>} ->
            {:l2, value, version}           # L2 hit — split the frame

          {:ok, _short} ->
            {:error, :corrupt_l2_frame}
        end

      send(owner, {:flight, id, result})    # one message back to the owner
    end)

  ref   # the monitor ref recorded in state.flights[id]
end
```

## Receiving the flight

`handle_info({:flight, id, result})` pops the flight from `state.flights`, demonitors the process,
classifies the result, updates the counters, inserts into L1 via `insert/4`, and **replies the one answer to
every waiter** with `Enum.each(waiters, &GenServer.reply(&1, reply))`.

A flight that crashes before sending its message fires `handle_info({:DOWN, ref, :process, _pid, reason})`.
The owner finds the matching entry in `state.flights` and replies `{:error, {:flight_crashed, reason}}` to
every waiter — no caller wedges indefinitely.

## The coalesced counter

Each call that finds an existing flight and appends instead of starting a new one increments `:coalesced`.
The `stats/1` surface exposes this counter so a coalescing rate is observable without a trace.

## Pattern ↔ implementation

**The pattern (stampede prevention):** on a cache miss under load, avoid sending N concurrent requests to the
backing store. A "lock on miss" or "single-flight" pattern serializes fills: the first waiter runs the load;
the rest wait on the result.

**The implementation (EchoStore.Table):** the owner's mailbox is the serialization point. The first `{:fill,
id}` message starts a flight; every subsequent one appends its caller. The flight runs in its own process so
the owner's mailbox drains normally. One answer is sent back; one load touches the store.

## Recap

The single-flight coalescing is a three-part contract: the owner serializes concurrent misses (its mailbox
is the lock), the flight is non-blocking (it is a spawned process, not a Task.await), and the result fan-out
is the last act of the flight's receive side — one answer, one reply per waiter, the `:coalesced` counter as
the observable proof.

## References

### Sources
- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — the read-concurrent L1 table the fill writes.
- [Valkey — GET](https://valkey.io/commands/get/) — the L2 probe the flight issues.
- [Valkey — SET](https://valkey.io/commands/set/) — the write that frames `version <> value` in L2.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the mint-time id minted as the fill's version.

### Related in this course
- `/echomq/cache` — the Cache chapter landing.
- `/echomq/cache/single-flight-and-jittered-ttl` — this module's hub.
- `/echomq/protocol` — the keyspace and branded-id gate.
- `/bcs/store` — the manuscript chapter: B4.2 "one fill per herd".
