# The reserve

> Dive 3 · The owned keyspace · The Protocol · route `/echomq/protocol/the-owned-keyspace/the-reserve`
> Grounding: all real code in `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`. No `[RECONCILE]` markers.

## The fact

Not everything the protocol stores belongs to a queue. The version fence is one record for the whole wire, shared by
every queue and every speaker. It needs a home that no queue can occupy. That home is the **reserve**: the braced base
`{emq}:`. `EchoMQ.Keyspace` builds the reserve's keys with `reserve/1`, and the one in use today is the version fence,
`version_key/0` → `{emq}:version`.

The reserve is **first-byte-disjoint** from every per-queue key, and that is what makes it safe:

- A per-queue key starts with the literal `emq:` — `emq:{orders}:pending` begins `e`, `m`, `q`, `:`, `{`.
- A reserve key starts with `{emq}:` — it begins `{`.

So a queue named `emq` is impossible: its keys would be built as `emq:{emq}:<type>`, which still starts `emq:` — it can
never collide with the reserve `{emq}:` that starts `{`. The two spaces are structurally separate. The reserve is also
its own hashtag: `{emq}` routes every cross-queue key to one slot, the same way a queue's `{q}` does, so the fence is
single-slot too.

## The worked example — `reserve/1` and `version_key/0`

The reserve is a module constant; `reserve/1` appends a suffix to it, and `version_key/0` is the one reserved key the
core uses:

```elixir
# echo_mq — EchoMQ.Keyspace
# The reserve is the braced base {emq}: — the cross-queue space, structurally
# disjoint from a queue's emq: prefix (different first byte). reserve/1 builds
# any cross-queue key; version_key/0 is the one in use — the version fence.
@reserve "{emq}:"
@version_key @reserve <> "version"

def reserve(suffix) when is_binary(suffix), do: @reserve <> suffix

def version_key, do: @version_key
```

So `version_key()` is `{emq}:version`, and `reserve("anything")` is `{emq}:anything`. Every cross-queue key the core
ever needs is built from the one reserved base, so there is exactly one place the core's own state lives — and it is a
place no queue can name.

## The reserve in use — the version fence

The fence is the reserve's reason to exist. The connector reads `{emq}:version` before it runs a single command: if the
record is absent it claims it (set-if-not-exists, then read back); if it is present it must match the wire version the
connector was built for; a mismatch is fatal. A speaker that does not agree on the wire is refused at boot — the fence
is what keeps a stale or foreign client from writing into a keyspace it does not understand. (The mechanism — how the
fence is checked, and the constant it checks against — is the immutability module; here the point is only *where* the
fence lives: in the reserve, not in any queue.)

## The bridge — pattern → implementation

- **The pattern (Redis Patterns Applied):** reserve a disjoint key prefix for system-owned state so application keys
  and infrastructure keys can never collide — a namespace partition by construction.
  (`/redis-patterns/coordination/hash-tag-colocation`.)
- **The implementation (echo_mq):** `EchoMQ.Keyspace.reserve/1` builds the `{emq}:` base, first-byte-disjoint from any
  queue's `emq:`, so the version fence at `{emq}:version` has a home no queue can occupy.

## Recap

The reserve is `{emq}:` — the cross-queue space, built by `reserve/1`, holding `version_key/0` → `{emq}:version`. It is
first-byte-disjoint from every per-queue `emq:` key, so a queue named `emq` cannot collide with it, and it is its own
single-slot hashtag. The reserve is where the wire's own state lives. The module's three dives — grammar, slot, reserve
— complete the *where* of the protocol; the next module reads the *what*: the record hash.

## References

### Sources
- Valkey — Documentation — `https://valkey.io/docs/` — the store the reserve and the fence live in; the substrate of record.
- Valkey — SET (with NX) — `https://valkey.io/commands/set/` — the set-if-not-exists the fence uses to claim the version
  record once.
- Redis — Keyspace & cluster hash tags — `https://redis.io/docs/` — the hashtag rule that makes `{emq}` its own slot.

### Related in this course
- `/echomq/protocol/the-owned-keyspace` — the module hub.
- `/echomq/protocol/the-owned-keyspace/the-braced-grammar` — the per-queue grammar the reserve sits beside.
- `/echomq/protocol/the-owned-keyspace/the-hashtag-and-the-slot` — the slot the reserve is its own hashtag for.
- `/echomq/protocol/immutability-and-branded-ids` — the version fence the reserve holds, in depth.
- `/redis-patterns/coordination/hash-tag-colocation` — the near side of the door.
