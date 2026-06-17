# The hashtag and the slot

> Dive 2 · The owned keyspace · The Protocol · route `/echomq/protocol/the-owned-keyspace/the-hashtag-and-the-slot`
> Grounding: all real code in `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`. No `[RECONCILE]` markers.

## The fact

The braces in `emq:{q}:<type>` are the **cluster hashtag**. A Valkey cluster splits the keyspace into 16384 slots and
routes a key by a CRC16 of the substring inside its first `{...}` — not the whole key. So every key that shares a
hashtag shares a slot. By wrapping the queue name, EchoMQ guarantees that one queue's keys are all co-resident:
`emq:{orders}:pending`, `emq:{orders}:active`, and `emq:{orders}:job:<id>` all hash on `orders`, so they all land
together. That co-residence is what makes the Lua layer's single-slot, declared-key scripts legal.

`EchoMQ.Keyspace` computes the slot **client-side**, so the connector can route and partition without a server round
trip. It uses the cluster specification's exact algorithm: CRC16-XMODEM over the hashtag, modulo 16384.

## The worked example — `hashtag/1` and `slot/1`

First the hashtag extraction — the substring inside the first `{...}`, falling back to the whole key when there is no
non-empty tag:

```elixir
# echo_mq — EchoMQ.Keyspace
# The hashtag is the substring inside the first {...}. When the braces are
# absent, or empty, the whole key is hashed — the cluster rule. For an
# EchoMQ key the tag is always the queue name (emq:{orders}:* → "orders").
def hashtag(key) do
  with [_, rest] <- :binary.split(key, "{"),
       [tag, _] when tag != "" <- :binary.split(rest, "}") do
    tag
  else
    _ -> key
  end
end
```

Then the slot — CRC16-XMODEM over the hashtag, modulo 16384:

```elixir
# echo_mq — EchoMQ.Keyspace
# The cluster slot, computed client-side so the connector routes without a
# server round trip. CRC16-XMODEM over the hashtag (not the whole key),
# modulo 16384 — the cluster specification's algorithm. Known vector:
# slot("123456789") == 12739 (CRC16 0x31C3).
def slot(key) when is_binary(key), do: rem(crc16(hashtag(key), 0), 16384)
```

And the CRC16-XMODEM itself — the bit-level loop, polynomial `0x1021`, initial value 0:

```elixir
# echo_mq — EchoMQ.Keyspace
# CRC16-XMODEM: poly 0x1021, init 0, no reflection. One byte at a time —
# XOR the byte into the high half, then eight shift-and-conditional-XOR
# rounds, masked to 16 bits. This is the standard cluster CRC16.
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

The known vector pins the implementation: `slot("123456789") == 12739`. Any speaker of the protocol — in any language —
must compute the same slot for the same hashtag, or its keys would route to a different shard than everyone else's. The
algorithm is part of the wire.

## The interactive

Type a queue name. The page computes its hashtag (the name itself, when it carries no braces) and its slot the same way
`slot/1` does — CRC16-XMODEM modulo 16384 — and shows the family of keys that share it. The known vector `123456789`
is offered as a check: it must read 12739.

## The bridge — pattern → implementation

- **The pattern (Redis Patterns Applied):** hash-tag co-location — wrap the shared part of a key in `{...}` so a group
  of keys routes to one slot, where an atomic multi-key operation is legal.
  (`/redis-patterns/coordination/hash-tag-colocation/the-tag-mechanic`.)
- **The implementation (echo_mq):** `EchoMQ.Keyspace.slot/1` computes that slot client-side from the queue hashtag, so
  the connector can route and partition with no round trip, and the Lua scripts can declare a single-slot key set.

## Recap

The brace `{q}` is the cluster hashtag; the slot is CRC16-XMODEM over the hashtag modulo 16384, computed client-side,
pinned by the vector `slot("123456789") == 12739`. One queue, one slot, co-located keys — the precondition for atomic
multi-key Lua. Next: the reserve that sits beside every queue.

## References

### Sources
- Redis — Cluster specification (hash slots) — `https://redis.io/docs/` — the 16384-slot model and the CRC16-of-hashtag
  routing rule the slot computation follows.
- Valkey — Documentation — `https://valkey.io/docs/` — the cluster store the slot routes within; the substrate of record.
- DragonflyDB — Server flags — `https://www.dragonflydb.io/docs/managing-dragonfly/flags` — `--lock_on_hashtags`, the
  thread-per-shard placement the per-queue hashtag unlocks.

### Related in this course
- `/echomq/protocol/the-owned-keyspace` — the module hub.
- `/echomq/protocol/the-owned-keyspace/the-braced-grammar` — the grammar the hashtag lives in.
- `/echomq/protocol/the-owned-keyspace/the-reserve` — the next dive: the cross-queue reserve.
- `/echomq/protocol/the-lua-layer` — the declared-key scripts the single slot makes legal.
- `/redis-patterns/coordination/hash-tag-colocation/the-tag-mechanic` — the slot mechanism, the near side of the door.
