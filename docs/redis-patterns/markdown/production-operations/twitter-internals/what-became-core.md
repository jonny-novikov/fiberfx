# What became core

> R8.04.3 · Twitter/X: internals & custom structures — dive 3 · route
> `/redis-patterns/production-operations/twitter-internals/what-became-core`

Quicklist is the default Redis list encoding today, and the story of how it got there is precise — and easy to tell
wrong. The technique was used internally at Twitter; the core feature was written independently by someone else, and
Twitter's own code was never upstreamed. This dive states the attribution exactly, follows the evolution to the
listpack, and ties back to what EchoMQ inherits for free.

Grounding: the Twitter source pack (Matt Stancliff, *Redis Quicklist — From a More Civilized Age*; redis/redis PR
#2143) for the case study; the BCS echo — `EchoMQ.Lanes` in `echo/apps/echo_mq/lib/echo_mq/lanes.ex`. Valkey is the
BCS engine; Twitter's own Redis is the case study.

## §1 · The precise attribution

It is tempting to say Twitter contributed quicklist. That is wrong, and the encoding's author says so directly:
*"Twitter started doing this years ago to store everybody's timelines, but for various reasons they haven't
contributed their implementation back to the world."*

The honest version has three parts:

1. **The technique was internal at Twitter and elsewhere.** Storing lists as ziplists inside a linked list was a
   known scale technique, used to hold timelines affordably. It lived in private codebases.
2. **It became core Redis as a separate, independent implementation.** Quicklist shipped in **Redis 3.2**,
   **authored by Matt Stancliff** (redis/redis PR #2143) — written from the idea, not from Twitter's source.
3. **Twitter's own code was never upstreamed.** The implementation that ran Twitter's timelines did not become the
   core feature; the core feature was re-built in the open.

So the lesson is a scale-driven internal technique becoming a core encoding — not a corporate code donation. A
pattern proven privately at scale was independently implemented as a primitive everyone ships. The credit for the
core feature is the implementer's; the motivation came from a problem several large deployments had already solved
in private.

Each of the three parts is independently verified: the internal technique (source: matt.sh), the independent author
(source: redis/redis PR #2143 — Matt Stancliff, Redis 3.2), and the never-upstreamed code (source: matt.sh,
*"haven't contributed… back to the world"*). None of them is the "Twitter donated the code" myth — together they
say to credit the open re-implementation, not the deployment that first used the technique.

## §2 · The evolution to the listpack

Quicklist did not stop at ziplists. The node encoding evolved.

A ziplist was the original packed block — compact, but with a known sensitivity to cascading updates: changing one
entry's size could ripple through the encoding of following entries. The **listpack** was introduced to replace it,
removing that cascade and simplifying the format. In **Redis 7.0** the listpack became the node encoding for lists,
so a modern quicklist is *a doubly-linked list of listpacks*, not of ziplists.

The shape is unchanged — a linked list of packed nodes — but the packed node is now a listpack. That is why this
course says "ziplists/listpacks" when describing a quicklist node: the original is the ziplist, today's is the
listpack, and the principle is identical. Small lists are stored as a single packed node directly; only when a list
grows past the node-size threshold does it become a multi-node quicklist. Those thresholds — the subject of R7.02 —
are what decide when a single listpack becomes a quicklist of many.

## §3 · The BCS echo — inherited for free

EchoMQ writes to Valkey lists, so it gets the modern encoding without asking. There is no setting to turn quicklist
on and no code that chooses it; it is the list encoding, and **all Valkey lists are quicklists**. The lane ring and
the wake list are native Redis lists:

```
# echo/apps/echo_mq/lib/echo_mq/lanes.ex
redis.call('RPUSH', KEYS[3], ARGV[3])              # the lane ring — a Redis list
redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')  # rotate it one step
redis.call('LPUSH', KEYS[7], '1')                  # the wake list — a Redis list
redis.call('LTRIM', KEYS[7], 0, 63)                # held to 64 — one listpack node
```

Each of these runs on a quicklist whose nodes are listpacks. The wake list, capped at 64, is a single listpack node;
the ring holds the lanes serviceable right now and is short by construction. EchoMQ inherits, at no cost, the
encoding that Twitter's scale drove into core Redis a decade ago.

The bridge:

- **The pattern** — a scale-driven technique (ziplists in a linked list), proven privately, became a core encoding
  (quicklist, Redis 3.2; listpack nodes, 7.0) that every Redis and Valkey list now uses.
- **Its EchoMQ application** — EchoMQ's lists get that encoding automatically; the only choice the bus makes is to
  keep the wake list short with `LTRIM … 0, 63`, so it stays one compact listpack node. The bus does not select
  quicklist; it benefits because the encoding is universal.

The honest framing carries through to the end: the credit is Matt Stancliff's, the motivation was a problem Twitter
and others had at scale, and EchoMQ's gain is only that the primitive is in the engine. The thing to remember is
the arc — a private technique can become everyone's default, and a system built on the primitive inherits the work.

### Notes on Valkey

Valkey inherited quicklist and the listpack node from Redis: a list is a quicklist of listpack nodes, with
`list-max-listpack-size` bounding a node by entries or bytes. A system that writes lists gets this encoding with no
configuration; the only lever is keeping a list short enough to stay one node, which is what the wake list's
`LTRIM … 0, 63` does. See [valkey.io/topics/data-types](https://valkey.io/topics/data-types/).

## §4 · Recap — a technique, not a donation

Quicklist's story is precise: the technique of packing ziplists into a linked list was used internally at Twitter
and never upstreamed; the core feature was written independently by Matt Stancliff and shipped in Redis 3.2 (PR
#2143); the node encoding later became the listpack in 7.0. A pattern proven privately at scale became a primitive
everyone ships. EchoMQ inherits it for free — all Valkey lists are quicklists — and the only thing the bus controls
is keeping the wake list short enough to stay one node. The chapter continues to R8.05, where Uber's resilience
techniques meet the connector's recovery behaviour.

## References

### Sources

- [Matt Stancliff — Redis Quicklist — From a More Civilized Age](https://matt.sh/redis-quicklist) — the encoding's
  author, stating that Twitter used the technique internally but did not contribute its implementation, and
  describing the quicklist's shape and memory saving.
- [redis/redis — Quicklist (linked list + ziplist), PR #2143](https://github.com/redis/redis/pull/2143) — the pull
  request that brought quicklist into core Redis (shipped in 3.2), authored independently of Twitter's internal
  code.
- [Valkey — Data types](https://valkey.io/topics/data-types/) — the modern list as a quicklist of listpack nodes,
  and the `list-max-listpack-size` threshold that keeps a short list in one node.

### Related in this course

- [R8.04 · Twitter/X: internals & custom structures](/redis-patterns/production-operations/twitter-internals) — the
  module hub.
- [R8.04.2 · Quicklist & memory](/redis-patterns/production-operations/twitter-internals/quicklist-and-memory) — the
  previous dive: the memory figure.
- [R8.05 · Uber: resilience & staggered sharding](/redis-patterns/production-operations/uber-resilience) — the next
  module: resilience under failure.
- [R7.02 · Memory optimization](/redis-patterns/data-modeling/memory-optimization) — the listpack node-size
  thresholds.
- [/echomq/queue](/echomq/queue) — the Queue pillar: jobs, lanes, the lists behind the bus.
