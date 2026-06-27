# Cluster auto-detect

> Route: `/redis-patterns/coordination/hash-tag-colocation/cluster-auto-detect` · Dive R2.05.3 · Source:
> `content/fundamental/hash-tag-colocation.md.txt` (slice: *Design guidelines* + *Limitations*).
> · Grounding: `EchoMQ.Keyspace.slot/1` (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`) computes the cluster slot
> **client-side** — `rem(crc16(hashtag(key), 0), 16384)`, CRC16-XMODEM over the hashtag — the cluster
> specification's algorithm, so the connector can route and partition without a server round trip. The "auto-detect"
> is exactly this: the client derives the slot a key would land on before it acts, with the known vector
> `slot("123456789") == 12739` asserted in the code.

Compute a key's slot on the client, ahead of any command — so the connector routes every key to its node without a
server round trip.

The previous dives showed the tag *placing* keys on a slot and what placing them buys. This one moves the slot
decision to the client. Rather than ask the server which node owns a key, the connector runs the cluster's own slot
arithmetic locally — the same CRC16 the cluster runs — and routes from the answer.

## The slot is pure arithmetic

A key's cluster slot is `CRC16(substring) % 16384` over the part the cluster hashes. That formula is deterministic:
given the key bytes, the slot is fixed. So a client does not need to ask the server — it can compute the slot itself
and reach the same number the cluster would assign. That is what makes client-side routing possible: a cluster-aware
client maps a key to its slot, the slot to its node, and sends the command straight to the owner, with no detour
through a wrong node and a redirect.

The live server-side counterparts confirm the same arithmetic. `CLUSTER KEYSLOT <key>` returns a key's slot;
`CLUSTER SLOTS` returns the slot-to-node map. A client that computes the slot itself can skip the first round trip
entirely and consult only the cached slot map for the second.

## EchoMQ computes the slot client-side

`EchoMQ.Keyspace.slot/1` (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`) is exactly that client-side computation:

```elixir
# echo/apps/echo_mq/lib/echo_mq/keyspace.ex — the cluster slot, computed client-side
def slot(key) when is_binary(key), do: rem(crc16(hashtag(key), 0), 16384)

defp crc16(<<>>, crc), do: crc
defp crc16(<<b, rest::binary>>, crc) do
  crc = Bitwise.band(Bitwise.bxor(crc, Bitwise.bsl(b, 8)), 0xFFFF)
  crc =
    Enum.reduce(1..8, crc, fn _, c ->
      shifted = Bitwise.band(Bitwise.bsl(c, 1), 0xFFFF)
      if Bitwise.band(c, 0x8000) != 0, do: Bitwise.bxor(shifted, 0x1021), else: shifted
    end)
  crc16(rest, crc)
end
```

`crc16/2` is a real inline Elixir XMODEM with polynomial `0x1021` — the cluster specification's algorithm, byte for
byte. The module's own moduledoc states the intent: *"Cluster slot of a key, computed client-side … so the
connector can route and partition without a server round trip. Known vector: `slot("123456789") == 12739` (CRC16
`0x31C3`)."* The vector is the contract: a client that produces `12739` for `123456789` is running the same
arithmetic the cluster runs.

Because `queue_key/2` always braces the queue name, a queue's keys answer one slot, and the client resolves it
locally rather than over the wire. The manuscript froze the figures against the live wire: *"the slot law held client-side —
`emq:{orders}:*` mapped to `slot 105 == 105` against `8507` for the payments queue, with the specification vector
answering `12739`"* (`docs/echo/bcs/content/bcsA.md`). Two queues, two slots, computed entirely on the client.

## The two lives of the slot function

Today EchoMQ's topology is a single Valkey instance. On one node there is one keyspace and no slot boundary, so
multi-key commands are always legal and the slot is never consulted for routing. The function is computed,
asserted against its vector, and parked. The manuscript records the discipline: the slot function stays *"committed,
correct, and parked, because single-instance is the part's stated topology."*

On the clustered day the same function becomes routing. The co-location law — every per-queue key wraps the queue
name in `{q}` — means each queue's keys answer one slot, so the per-queue transition scripts written today (claim
moves a job between `pending` and `active`; retry touches the job row and a schedule) stay single-slot legal on the
clustered day with no edit. The slot function carries the move: *"today it is partition arithmetic the connector can
run without a round trip; on the clustered day it becomes routing, and the co-location law means the scripts written
between now and then need no edits to survive the move"* (`docs/echo/bcs/content/bcs3.1.md`).

The transferable pattern: when a process will run a multi-key command, compute the keys' slots on the client from
the same `CRC16 % 16384`, so routing and co-location checks cost no server round trip and a cross-slot layout is
visible before a command is sent rather than after it is refused.

The bridge: hash-tag co-location lands related keys on one slot, and `slot/1` computes that slot client-side from
the `{q}` hashtag (CRC16 % 16384) — so the connector routes and partitions without a server round trip, with the
vector `slot("123456789") == 12739` asserted.

## A door, not a depth

This dive cites one real surface — `EchoMQ.Keyspace.slot/1` — as proof. The closed `emq:{q}:<type>` grammar, the
`{emq}:` reserve of exactly four members, the version fence the connector negotiates before the first command, and
the slot function's role on the clustered day are the subject of the dedicated
[EchoMQ course](/echomq) and the [BCS keyspace chapter](/bcs/bus/the-keyspace) — the companion
courses that teach the keyspace and the connector in full.

R2.05 ends here; the chapter closes with the [R2.06 workshop](/redis-patterns/coordination/workshop), where the
coordination patterns combine on a real codemojex guess submission.

## References

### Sources
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the 16384-slot model, hash tags, and
  the same-slot rule the client-side `slot/1` computes ahead of time.
- [Valkey — CLUSTER SLOTS](https://valkey.io/commands/cluster-slots/) — the command that returns a cluster's
  slot-to-node map; the cached map a client consults after computing the slot itself.
- [Valkey — CLUSTER KEYSLOT](https://valkey.io/commands/cluster-keyslot/) — the command that returns a key's slot,
  the server-side equivalent of the client-side `slot/1`.

### Related in this course
- [R2.05 · Hash-tag co-location](/redis-patterns/coordination/hash-tag-colocation) — the module hub: the placement
  rules, the hot-slot problem, and the EchoMQ exemplar.
- [R2.05.2 · CROSSSLOT prevention](/redis-patterns/coordination/hash-tag-colocation/crossslot-prevention) — the
  previous dive: what co-location buys, and the `CROSSSLOT` a shared tag prevents.
- [R2.06 · Coordination workshop](/redis-patterns/coordination/workshop) — the chapter's codemojex exemplar
  workshop, where the coordination patterns combine.
- [EchoMQ — the protocol](/echomq/protocol) — the `emq:{q}:` keyspace, the version fence, and the connector in depth.
