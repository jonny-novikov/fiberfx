# Quicklist & memory

> R8.04.2 · Twitter/X: internals & custom structures — dive 2 · route
> `/redis-patterns/production-operations/twitter-internals/quicklist-and-memory`

A timeline is a list of ids, and Twitter held an enormous number of them — *"over 100 TB of live memory per
datacenter."* At that scale the per-entry overhead of a Redis list is not a detail; it is the budget. This dive
measures the two earlier list representations, shows the encoding that combined them, and reads the figure that
makes the case. It then ties back to the one EchoMQ list that stays in a single node by design.

Grounding: the Twitter source pack (Matt Stancliff, *Redis Quicklist — From a More Civilized Age*; redis/redis PR
#2143) for the case study; the BCS echo — the wake list in `echo/apps/echo_mq/lib/echo_mq/lanes.ex`. Valkey is the
BCS engine; Twitter's own Redis is the case study.

## §1 · The memory problem

A Redis list can be represented two ways, and each trades the other's weakness.

**A linked list** holds one element per node, and each node carries pointers and allocator headers. Matt Stancliff
puts the cost plainly: *"Regular linked lists have overhead of 40+ bytes per entry."* For a list of small integers,
the overhead dwarfs the data — forty-plus bytes of bookkeeping to hold an eight-byte value. The upside is cheap
edits at either end: pushing or popping is a pointer update.

**A ziplist** packs many entries into one contiguous block of memory, with *"overhead ranging from 1 byte to 10
bytes per entry."* That is an order of magnitude less than the linked list, because there are no per-element nodes —
only lengths and the values, laid end to end. The downside is the cost of editing a long block: inserting into the
middle, or growing past the allocation, can mean copying the whole block, so a single large ziplist becomes
expensive as it grows.

So the two representations sit at opposite ends: the linked list is flexible but heavy per entry; the ziplist is
compact but costly to edit when long. A list of a billion entries wants both — compact storage and cheap edits.

## §2 · Quicklist: a linked list of ziplists

Quicklist is the combination. It is *"a quicklist looks like: [ziplist 0] <-> [ziplist 1] <-> … <-> [ziplist N]"* —
a doubly-linked list whose nodes are ziplists (listpacks in modern Valkey). Each node packs many entries compactly;
the linked list of nodes keeps edits local to one node and keeps any single node short enough to edit cheaply.

The two costs are bounded at once:

- **Per-entry overhead stays near the ziplist's** — a few bytes per entry inside a node, not the linked list's 40+,
  because entries are packed.
- **Edit cost stays bounded** — a push or a middle insert touches one node, and a node is kept short, so no operation
  copies a billion-entry block.

The figure makes the saving concrete. Storing **200 lists of 1 million integers** used **1.0 GB** of allocated
memory at the optimal ziplist length versus **11.86 GB** for traditional linked lists — roughly twelve times less
memory for the same data. At Twitter's reported scale — *"over 10,000 Redis servers per data center"* holding *"over
100 TB of live memory per datacenter"* — a twelve-times reduction in the cost of a list is the difference between a
fleet that fits and one that does not.

```
# the quicklist shape (Matt Stancliff, verbatim)
[ziplist 0] <-> [ziplist 1] <-> … <-> [ziplist N]
#  each node packs many entries (1–10 B overhead/entry);
#  the linked list of nodes keeps edits local and nodes short.
```

A node's length is the tuning dial. Too short and the quicklist approaches a per-entry linked list; too long and a
node approaches an expensive-to-edit block. The figure above is measured at the length that minimised allocated
memory.

## §3 · The BCS echo — the wake list is one small node

EchoMQ does not store million-entry lists, but it has one list whose whole purpose is to stay in a single node — the
wake list. When a job is admitted, the enqueue script signals a parked consumer and trims the signal list to 64
elements:

```
# echo/apps/echo_mq/lib/echo_mq/lanes.ex — the enqueue script
redis.call('LPUSH', KEYS[7], '1')      # signal a parked consumer
redis.call('LTRIM', KEYS[7], 0, 63)    # hold the wake list to 64 elements
```

A 64-element list of one-byte tokens lives as **one small listpack node of a quicklist**. That is the precise case
quicklist and listpack were built for — a short list that should be one compact, cheap-to-edit block. The `LTRIM …
0, 63` is what keeps it there: no matter how often work arrives, the wake list never grows past one node, so the
signal stays cheap.

The bridge:

- **The pattern** — pack a list into ziplist/listpack nodes and keep each node short, so a list is both compact per
  entry and cheap to edit; a short list is a single node.
- **Its EchoMQ application** — the wake list is held to 64 elements with `LTRIM … 0, 63`, so it stays one small
  listpack node; the lane ring and the wake signal are native Redis lists, and the encoding that keeps them cheap is
  the one Twitter's scale drove into core Redis.

The honest framing: EchoMQ does not configure quicklist — it cannot. Quicklist is the list encoding, and **all
Valkey lists are quicklists**. The only thing the script controls is the cap, which keeps the wake list inside a
single listpack node. The node-size thresholds that govern when any list splits across nodes are the subject of
R7.02 (memory optimization) — the listpack and the limits that decide a node's size.

### Notes on Valkey

In modern Valkey a quicklist's nodes are **listpacks**, which replaced ziplists in 7.0. The
`list-max-listpack-size` setting bounds a node by entry count or by bytes; a list that stays under it is a single
node. A 64-element wake list of one-byte tokens is far under any reasonable bound, so it is always one compact node.
See [valkey.io/topics/data-types](https://valkey.io/topics/data-types/).

## §4 · Recap — compact entries, short nodes

The two early list representations each gave up what the other kept: the linked list was flexible but spent 40+
bytes per entry; the ziplist was compact at 1–10 bytes per entry but costly to edit when long. Quicklist combined
them — a linked list of ziplist (now listpack) nodes — and the figure proves it: 200 million integers in 1.0 GB
against 11.86 GB. EchoMQ's wake list is the small-scale echo: held to 64 elements with `LTRIM … 0, 63`, it is one
compact node by design. The next dive reads the precise story of how that technique became core Redis — and who
wrote it.

## References

### Sources

- [Matt Stancliff — Redis Quicklist — From a More Civilized Age](https://matt.sh/redis-quicklist) — the encoding's
  author on the memory problem (linked-list 40+ B/entry against ziplist 1–10 B/entry), the `[ziplist 0] <-> … <->
  [ziplist N]` shape, and the 1.0 GB-against-11.86 GB figure for 200 lists of 1 million integers.
- [redis/redis — Quicklist (linked list + ziplist), PR #2143](https://github.com/redis/redis/pull/2143) — the pull
  request that brought quicklist into core Redis, shipped in 3.2.
- [Valkey — Data types](https://valkey.io/topics/data-types/) — the list as a quicklist of listpack nodes, and the
  `list-max-listpack-size` threshold that keeps a short list in one node.

### Related in this course

- [R8.04 · Twitter/X: internals & custom structures](/redis-patterns/production-operations/twitter-internals) — the
  module hub.
- [R8.04.1 · Timeline fan-out](/redis-patterns/production-operations/twitter-internals/timeline-fan-out) — the
  previous dive: the per-follower Redis lists.
- [R8.04.3 · What became core](/redis-patterns/production-operations/twitter-internals/what-became-core) — the next
  dive: the technique that became quicklist.
- [R7.02 · Memory optimization](/redis-patterns/data-modeling/memory-optimization) — the listpack node-size
  thresholds behind the wake list.
- [/echomq/queue](/echomq/queue) — the Queue pillar: jobs, lanes, the lists behind the bus.
