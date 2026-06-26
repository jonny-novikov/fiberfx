# The claims-only id — dive 03

> Route: `/echomq/bus/the-stream-log/the-claims-only-id` · module 02, dive 3.
> Surface: `EchoMQ.Stream.read/6`, `stream_key/2`, the `id`-field storage contract. Forward doors named:
> `read_window/6` / `read_since/5` (time-travel, module 04), `trim/4` → `EchoStore.StreamArchive` (the archive,
> module 05). No Lua — `XRANGE` issued direct.

## Why the id is a field, not merely a position

Every `XADD` entry already has an entry id — the `"<ms>-<seq>"` position the writer derived. So why does the writer
**also** store the branded id as a field, `id <branded>`, inside the entry?

Because the entry-id position is a wire detail, and the branded id is the canonical receipt. The contract is
**claims-only**: a reader — including a polyglot reader on another runtime that speaks the wire — recovers the
canonical 14-byte branded id by reading the `id` field, without having to re-encode it from the `"<ms>-<seq>"`
position. The stored field is the truth the writer minted; the position is how Valkey happens to index it. They
agree by the order theorem, but the reader reads the receipt, not the index.

## The minimal read-back

`read/6` is the minimal un-grouped read-back — the order-theorem proof surface. It is deliberately **not** a
consumer group (`XREADGROUP` and at-least-once delivery are module 03); it is the plain range read that recovers
entries in mint order:

```elixir
# echo_mq — EchoMQ.Stream
# read/6: the MINIMAL un-grouped read-back. Wraps XRANGE <key> <from> <to>
# [COUNT n] and parses the nested-array reply into {branded, fields_map} tuples
# IN MINT ORDER. from/to default to the full range "-"/"+". This is the
# order-theorem proof surface, NOT a consumer group.
def read(conn, queue, name, from \\ "-", to \\ "+", count \\ nil)
    when is_binary(queue) and is_binary(name) do
  key = stream_key(queue, name)
  parts = ["XRANGE", key, from, to] ++ if(count, do: ["COUNT", Integer.to_string(count)], else: [])

  case Connector.command(conn, parts) do
    {:ok, entries} when is_list(entries) -> {:ok, Enum.map(entries, &parse_entry/1)}
    {:error, _} = err -> err
  end
end
```

The reply shape is `[[xadd_id, [field, value, …]], …]`. `parse_entry/1` turns each entry into the canonical
`{branded, fields_map}` tuple — the stored `id` field becomes the branded receipt, the remaining pairs become the
payload map:

```elixir
# echo_mq — EchoMQ.Stream
# Parse one XRANGE entry [xadd_id, [field, value, …]] into {branded, map}:
# the branded record id is the stored "id" field (the claims-only receipt the
# reader sorts by), the remaining pairs are the payload as a map. The xadd_id
# is only the wire position; the BRANDED id is the canonical id.
defp parse_entry([_xadd_id, kv]) when is_list(kv) do
  map = pairs(kv)
  {Map.get(map, "id"), Map.delete(map, "id")}
end

defp pairs([k, v | rest]), do: Map.put(pairs(rest), k, v)
defp pairs([]), do: %{}
```

So a round trip is closed: `append/4` returns `{:ok, branded}`; `read/6` returns `{:ok, [{branded, fields_map},
…]}` with the **same** branded id recovered from the entry's `id` field. The receipt the writer handed back and the
receipt the reader reads back are the same 14 bytes — and they come back in mint order, which is the whole reason
the log is a faithful record.

The key both ends use is `stream_key/2`:

```elixir
# echo_mq — EchoMQ.Stream
# The braced stream key emq:{q}:stream:<name> via the shipped total
# Keyspace.queue_key/2 — no grammar edit; the stream shares the queue's {q}
# hashtag slot, so a queue and its stream co-locate on one of 16384 slots.
def stream_key(queue, name) when is_binary(queue) and is_binary(name),
  do: Keyspace.queue_key(queue, "stream:" <> name)
```

## Two doors out of the plain read

The plain `read/6` is the floor. Two named capabilities are built on top of it, in later modules — named here, not
built:

- **Time-travel** (module 04). `read_since(conn, queue, name, t0)` and `read_window(conn, queue, name, t0, t1)`
  read the log by a **mint instant**: a `%DateTime{}` becomes an `XRANGE` bound (`minid_floor/1` the lower floor,
  `maxid_ceil/1` the inclusive upper inverse), and the read delegates to `read/6` — zero new Lua. The same order
  theorem is what makes a time window a server-side range filter rather than a scan-and-compare.

- **Retention and the archive** (module 05). A log that only grows is a leak, so `trim/4` bounds it by length
  (`XTRIM MAXLEN`) or by age (`XTRIM MINID`). What a stream trims is **not lost**: `EchoStore.StreamArchive` folds
  the trimmed segments into the durable Graft floor — readable beside the live tail through a watermark merge-read.
  That durable floor is taught in full at `/echo-persistence`.

## Pattern & implementation

- **The pattern (Redis Patterns Applied).** Reading a stream recovers entries and their payloads in order; a
  consumer replays from a position.
- **The implementation (echo_mq).** The canonical id is a stored **field**, not the wire position, so any reader
  recovers the 14-byte branded receipt without re-encoding it — the claims-only contract. `read/6` is the minimal
  range read-back that returns `{branded, fields_map}` in mint order; time-travel and the archive are named doors
  built on the same surface.

## Recap

The branded id is stored as the entry's `id` field — the claims-only contract — so `read/6` recovers the canonical
receipt and the payload map in mint order, closing the round trip from `append/4`. The plain read is the floor under
two named doors: time-travel by mint instant (module 04) and retention folding into the durable archive (module
05). That archive is the door to `/echo-persistence`.

## References

### Sources
- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — the range read the minimal read-back wraps.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the entry, its fields, and ordered iteration.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hashtag co-locates the stream with its queue.
- [Kreps — The Log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — replaying the log from a position.

### Related in this course
- `/echomq/bus/the-stream-log` — the module hub.
- `/echomq/bus/the-stream-log/the-host-side-mint` — the append that returns the receipt.
- `/echomq/bus/the-stream-log/the-order-theorem` — why the read-back is in mint order.
- `/echomq/bus` — the pillar landing (consumer groups, time-travel, and retention are the later modules).
- `/echo-persistence` — the durable floor a trimmed stream history folds into.
- `/bcs/bus` — the manuscript chapter (B3.3) this realizes.
