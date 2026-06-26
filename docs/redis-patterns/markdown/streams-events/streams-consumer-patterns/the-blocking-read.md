# R5.02.1 · The blocking read

> Route: `/redis-patterns/streams-events/streams-consumer-patterns/the-blocking-read` · dive
> Grounding: `echo/apps/echo_mq/lib/echo_mq/stream_consumer.ex` — `read_group_block/1` (the
> `XREADGROUP ... BLOCK` on a private lane) and the dedicated-connection law.

A reader of a stream has to wait for the next entry. There are two ways to wait, and only one of them is
cheap. A busy-poll asks `XREADGROUP ... >` over and over with no entries to show for it, burning round trips
and CPU between arrivals. A blocking read asks once with `BLOCK <ms>` and parks until an entry arrives or the
timeout elapses — one round trip, no spin. The blocking form is the documented starting point, and it carries
one pitfall worth the whole dive: a blocked read holds its connection for the entire block.

## Busy-poll versus block

A busy-poll loop reads, gets an empty reply, sleeps a little, and reads again. Its latency is the sleep
interval — shrink the sleep to lower latency and you raise the request rate against an idle stream; raise the
sleep to lower the rate and you raise latency. There is no setting that is both responsive and cheap.

A blocking read removes the trade. `XREADGROUP GROUP g <self> BLOCK <ms> COUNT <n> STREAMS <key> >` parks
server-side until either an entry is appended — and it returns immediately, sub-millisecond latency — or `ms`
elapses with nothing, and it returns an empty reply so the caller can re-arm. The latency is the network
round trip, not a poll interval, and an idle stream costs one parked connection rather than a stream of empty
reads.

## The connection cost

The blocking form has one hazard: a parked read holds its connection for the whole block. With a pool of ten
connections and ten worker threads each issuing `XREADGROUP ... BLOCK 5000`, all ten connections are parked at
once. Any other code that needs the store — even a simple `GET` — waits for a connection that will not free
for five seconds. The blocking verb did not deadlock the stream; it starved everything else of connections.

The three standard mitigations all point the same way:

- **Dedicated connections** — give each blocking consumer its own connection, separate from the shared pool.
- **Shorter block times** — a two-to-three-second block re-arms often enough to notice shutdown, rather than
  an infinite `BLOCK 0` that never returns on its own.
- **Timeout coordination** — the server-side `BLOCK` timeout must be shorter than the client socket timeout,
  or the socket gives up before the server replies.

## The dedicated lane

EchoMQ takes the dedicated-connection mitigation as a law, not an option. `EchoMQ.StreamConsumer` holds a
**private** connector lane and parks the blocking read on it:

```elixir
defp read_group_block(s) do
  parts =
    ["XREADGROUP", "GROUP", s.group, s.consumer, "BLOCK", Integer.to_string(s.beat_ms),
     "COUNT", Integer.to_string(s.count), "STREAMS", s.key, ">"]

  case Connector.command(s.conn, parts, s.beat_ms + 5_000) do
    {:ok, reply} -> group_entries(reply, s.key)
    {:error, _} -> []
  end
end
```

This is the only blocking verb in the consumer, and it rides the consumer's own lane — the same rule the job
consumer follows for `BLPOP`, so the single-owner socket the rest of the system shares is never stalled. The
block time is the `:beat_ms` cadence (default `1_000`), short enough that the loop re-arms once a second and
notices a stop request between entries. The command timeout is `beat_ms + 5_000` — deliberately longer than the
block — so the server's `BLOCK` returns first with either entries or an empty reply, and the socket timeout
is the backstop, never the thing that fires.

A timeout returns an empty list — no new entries this beat — and the loop comes round again. The cost of
an idle stream is one parked connection on a lane that exists for exactly this, not a spin and not a stalled
shared socket.

## The pattern, applied

A codemojex activity-feed reader (`echo/apps/codemojex`) is a long-lived consumer of a game's stream. It is
idle most of the time — a round is appended only when a guess is scored or a round opens — so a busy-poll would
spend almost all of its requests on empty reads. On its own lane it parks on `XREADGROUP ... BLOCK 1000` and
wakes the instant an entry lands, rendering the live timeline with round-trip latency, while a separate
`GET`-the-board call elsewhere in the app never waits on the feed's parked connection.

## References

### Sources

- [Valkey — XREADGROUP](https://valkey.io/commands/xreadgroup/) — the `BLOCK <ms>` form that parks for a new
  entry and the `>` cursor that delivers only new entries.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — blocking reads, the consumer
  group, and the connection a block holds.
- [Valkey — XREAD](https://valkey.io/commands/xread/) — the un-grouped blocking read the long-poll starts from.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag that keeps a
  queue's stream key on one of 16384 hash slots.

### Related in this course

- [R5.02 · Stream consumer patterns](/redis-patterns/streams-events/streams-consumer-patterns) — the module
  hub.
- [R5.02.2 · Consumer groups](/redis-patterns/streams-events/streams-consumer-patterns/consumer-groups) — the
  group read this block rides.
- [R5.02.3 · MAXLEN trimming](/redis-patterns/streams-events/streams-consumer-patterns/maxlen-trimming) —
  bounding the log the reader drains.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar, the retained log in depth.
