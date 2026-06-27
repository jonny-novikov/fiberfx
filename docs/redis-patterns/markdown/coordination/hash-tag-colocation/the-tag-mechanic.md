# The tag mechanic

> Route: `/redis-patterns/coordination/hash-tag-colocation/the-tag-mechanic` · Dive R2.05.1 · Source:
> `content/fundamental/hash-tag-colocation.md.txt` (slice: *How hash tags work* + *Placement rules and footguns*).
> · Grounding: `EchoMQ.Keyspace.hashtag/1` and `slot/1` (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`) —
> `hashtag(key)` is the substring inside the first non-empty `{…}`; `slot(key) = rem(crc16(hashtag(key), 0), 16384)`
> is CRC16-XMODEM (polynomial `0x1021`) modulo 16384, computed client-side, with the known vector
> `slot("123456789") == 12739` asserted in the code. `queue_key(q, type)` → `emq:{q}:<type>`, so
> `emq:{orders}:pending` and `emq:{orders}:active` hash identically.

Valkey cluster hashes only the substring inside the first non-empty `{…}` and ignores the rest of the key. So
`emq:{orders}:pending` and `emq:{orders}:active` both hash `orders` and share one slot.

A key's slot usually depends on the whole key. A hash tag overrides that: when a key holds a non-empty span between
a `{` and the next `}`, the cluster hashes that span alone.

## Only the tag is hashed

Valkey cluster computes a key's slot from a CRC16 of its bytes, modulo 16384. The hash tag changes the *input* to
that CRC16. When a key holds a non-empty substring between a `{` and the next `}`, the cluster hashes that substring
alone; the prefix, the suffix, and the colons are ignored for slot placement.

```
SET user:{123}:profile  …   # hashes "123"
SET user:{123}:settings …   # hashes "123"
SET user:{123}:sessions …   # hashes "123"  -> all on one slot
```

That is the whole point of the tag: it lets an application name related keys distinctly while guaranteeing they
co-locate. Strip the braces and each full key hashes on its own, the three keys scatter across three slots, and a
multi-key command over them raises `CROSSSLOT`. The braces are the lever; the substring between them is what Valkey
actually hashes.

## The exact rule

`EchoMQ.Keyspace` states the rule precisely. `hashtag/1` scans for the first `{`, then for the next `}`, and returns
the substring between them only when that substring is non-empty — otherwise it returns the whole key. `slot/1` then
runs CRC16-XMODEM over that substring, modulo 16384:

```elixir
# echo/apps/echo_mq/lib/echo_mq/keyspace.ex
def slot(key) when is_binary(key), do: rem(crc16(hashtag(key), 0), 16384)

def hashtag(key) do
  with [_, rest] <- :binary.split(key, "{"),
       [tag, _] when tag != "" <- :binary.split(rest, "}") do
    tag
  else
    _ -> key
  end
end
```

In words, three steps, then the modulo:

1. Find the first `{`.
2. From there, find the next `}`.
3. If a `}` exists and the span between the braces is non-empty, the hashed substring is exactly that span;
   otherwise the hashed substring is the whole key.

Then the slot is `CRC16(substring) % 16384`. The `crc16/2` in the same module is a real inline Elixir XMODEM with
polynomial `0x1021` — the cluster specification's algorithm — so the slot a client computes matches the slot the
cluster assigns. The known vector is asserted: `slot("123456789") == 12739` (CRC16 `0x31C3`).

- **first `{`** — the scan takes the first opening brace and looks no further for a better one.
- **next `}`** — the closing brace is the first one after that opening brace; the span between them is the candidate.
- **non-empty** — an empty span (`{}`) is rejected; the rule falls back to hashing the whole key.

## Placement rules and footguns

The rule is short, but three placements catch people out. Each follows directly from "first brace, then the next
closing brace, non-empty."

**The first `{` wins.** `{user:123}:profile` hashes `user:123` (slot 12893), not `123`. The scan takes the first
opening brace in the key and stops. So `{user:123}:profile` will *not* co-locate with `user:{123}:settings`
(slot 5970) — the hashed substrings differ.

**Braces in the wrong place hash the wrong thing.** `user:123:{profile}` hashes `profile` (slot 16237). It is a
valid tag, but it tags the suffix, so it scatters away from the `user:{123}:*` family. The convention that avoids
this: put the entity id in the tag, at the same position in every related key.

**An empty tag `{}` hashes the whole key.** `key:{}:suffix` has a `{` immediately followed by a `}`, so the span is
empty; the rule falls back to hashing the entire key `key:{}:suffix` (slot 14786). An empty tag gives no
co-location.

**With multiple tags, only the first is used.** `{a}:{b}:key` hashes `a` (slot 15495). The scan stops at the first
closing brace after the first opening brace; the `{b}` is ignored. Two tags do not combine.

## In EchoMQ — the mechanic behind `emq:{q}:`

This is the mechanic behind every EchoMQ queue key. `EchoMQ.Keyspace.queue_key/2`
(`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`) wraps the queue name in a hash tag:

```elixir
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])
```

So `emq:{orders}:pending`, `emq:{orders}:active`, `emq:{orders}:schedule`, and a job's own row
`emq:{orders}:job:ORD0NgWEfAEJfs` all hash the substring `orders` — the whole queue lives on one slot. The
manuscript froze the figure: *"the hashtag IS the queue name, so every key of one queue answers one slot: pending,
active, meta, and the job row of `{orders}` all answer slot 105; `{fills}` answers 4165"*
(`docs/echo/bcs/content/bcs3.1.md`). That single slot is exactly what lets a per-queue multi-key Lua transition run
as one atomic call. The slot is computed by the same `slot/1` this dive traces:
`slot("emq:{orders}:pending") == 105`.

The bridge: Valkey hashes only the `{tag}` substring, so wrapping the shared part of related keys forces them onto
one slot — `CRC16(substring) % 16384`. In EchoMQ the braced `emq:{q}:` form makes that automatic, and `slot/1`
computes the slot client-side from the `{q}` hashtag with the vector `slot("123456789") == 12739` asserted.

Next: this dive shows a queue's keys *can* share a slot. R2.05.2 is what that buys — why a multi-key command off one
slot raises `CROSSSLOT`, and how the `{q}` tag keeps a queue's multi-key claim legal.

## References

### Sources
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — hash tags, the 16384 slots, and the
  `{…}` rule: the first non-empty brace span, else the whole key.
- [Valkey — CLUSTER KEYSLOT](https://valkey.io/commands/cluster-keyslot/) — the command that returns a key's slot,
  the live equivalent of the client-side `slot/1` traced here.
- [Redis — Cluster specification](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/) — the
  CRC16 slot model and the single-slot `MULTI`/`EXEC` atomicity co-location keeps legal.

### Related in this course
- [R2.05 · Hash-tag co-location](/redis-patterns/coordination/hash-tag-colocation) — the module hub: the placement
  rules, the hot-slot problem, and the EchoMQ exemplar.
- [R2.04 · Cross-shard consistency](/redis-patterns/coordination/cross-shard-consistency) — what a multi-key write
  loses when keys do not share a slot, and how to detect the tear.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the single-slot `MULTI`/`EXEC` and Lua
  atomicity co-location preserves.
- [EchoMQ — the protocol](/echomq/protocol) — the `emq:{q}:` keyspace and the version fence in depth.
