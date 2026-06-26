# Twitter/X: internals & custom structures

> R8.04 · Production & Operations — module hub · route `/redis-patterns/production-operations/twitter-internals`

Twitter ran one of the largest Redis deployments ever reported: *"Twitter runs over 10,000 Redis servers per data
center and their Redis deployment uses over 100 TB of live memory per datacenter."* Home timelines lived in that
tier — the VMware Tanzu case study framed it at roughly **30 billion Redis updates per day**, serving more than
**400 million tweets a day**. A home timeline was a **native Redis list**: each entry was a tweet stored by its id,
its author's id, and a few bits of metadata, inserted into every follower's list as the tweet was posted.

This module reads three things Twitter's scale taught the Redis world, and ties each back to one verified surface in
the BCS bus. Twitter's own stack legitimately names Redis — that is their history, quoted as theirs. The BCS bus is
Valkey-only; the worked consumer is codemojex.

Grounding: the Twitter source pack — *How to Scale: Real-time Tweet Delivery Architecture at Twitter* (HdM
Stuttgart), *Staple Yourself to a Tweet … 30 Billion Redis Updates Per Day* (VMware Tanzu), and *Redis Quicklist —
From a More Civilized Age* (Matt Stancliff, matt.sh) with redis/redis PR #2143 — for the case study; the as-built
`echo/apps/echo_mq` (`Lanes`) and `echo/apps/echo_data` (`BrandedId`) for the applied half. Every external claim
cites a real source; no Twitter number, Redis command, or echo surface is invented.

## §1 · The scale: timelines in Redis lists

The home timeline is the feed a user reads. Twitter's choice was to make that read cheap by paying at write time:
when a tweet is posted, a fanout service inserts the tweet id into every follower's home timeline, which is a Redis
list. A read of a timeline is then a single range over one list — O(1) in the sense that it does not touch the
social graph or scan other users' data.

The numbers report the scale of that design. *"Twitter runs over 10,000 Redis servers per data center and their
Redis deployment uses over 100 TB of live memory per datacenter."* The VMware Tanzu case study frames the
home-timeline Redis tier at **about 30 billion Redis updates per day**, against more than **400 million tweets a
day**. Reads dominate: a reported *"300K QPS … spent reading timelines and only 6000 requests per second … on
writes."*

Three things follow from putting that much data in that many lists, and each is a lesson worth taking apart:

1. **The fan-out write path** — how a tweet reaches every follower, and why a read is cheap.
2. **The memory cost of a list** — what a billion list entries cost, and the encoding that made it affordable.
3. **What became core Redis** — a scale-driven technique that turned into a list encoding everyone ships.

## §2 · The three ideas it proves

**Fan-out on write.** *"The fanout … is responsible for spreading out the tweet to all people following the author
by inserting it to all their home timelines."* A tweet goes to the fanout service, which asks the social-graph
service for the author's follower set, then inserts the tweet id into each follower's Redis list. The read is O(1);
the write is O(n) in the follower count. Very-large accounts are the exception: delivery *"can take up to 5 minutes
… when celebrities like Lady Gaga or Kylie Jenner tweet,"* which motivates a hybrid path — fan-out-on-write for most
accounts, fetch-and-merge-at-read for the few enormous ones.

**The memory cost of a list, and quicklist.** A naive Redis list is a doubly-linked list of single-element nodes,
and *"regular linked lists have overhead of 40+ bytes per entry."* A ziplist packs many entries into one contiguous
block, with *"overhead ranging from 1 byte to 10 bytes per entry"* — far smaller, but a single block grows
expensive to edit as it gets long. Quicklist combines them: a doubly-linked list of ziplists, *"a quicklist looks
like: [ziplist 0] <-> [ziplist 1] <-> … <-> [ziplist N]."* The figure: storing **200 lists of 1 million integers**
used **1.0 GB** of allocated memory at the optimal ziplist length versus **11.86 GB** for traditional linked lists —
roughly twelve times less.

**A technique that became core.** Quicklist did not arrive as a corporate code donation. Matt Stancliff is explicit:
*"Twitter started doing this years ago to store everybody's timelines, but for various reasons they haven't
contributed their implementation back to the world."* The technique — ziplists in a linked list — was used
internally at Twitter and elsewhere; it became core Redis as **quicklist in Redis 3.2, independently re-implemented
by Matt Stancliff** (redis/redis PR #2143). The lesson is a scale-driven internal technique becoming a core
encoding, not a transfer of source.

## §3 · The applied half — the BCS bus

The Twitter case is the lens; the bus the reader is building is EchoMQ, backed by Valkey. EchoMQ does not store
timelines, but its queue is built on the same primitive Twitter chose — the native Redis list — and the connection
is exact and verified.

The bridge:

- **The pattern** — a feed is a list of ids, one id per entry; reads stay cheap because the id is the whole entry,
  and the list encoding (quicklist over ziplists/listpacks) keeps a billion such entries affordable.
- **Its EchoMQ application** — a lane is a Redis list of branded `JOB` ids, and readiness is signalled through a
  second list capped tight. `EchoMQ.Lanes` (`echo/apps/echo_mq/lib/echo_mq/lanes.ex`) runs
  `redis.call('RPUSH', KEYS[3], ARGV[3])` to push onto the ring,
  `redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')` to rotate it, and signals a parked consumer with
  `redis.call('LPUSH', KEYS[7], '1')` followed by `redis.call('LTRIM', KEYS[7], 0, 63)` — a **wake list held to 64
  elements**. A list that short lives as **one small listpack node of a quicklist**: exactly the case quicklist and
  listpack were built for.

Two honest framings hold the parallel straight:

- **The id is the thing in the list.** Twitter stored a timeline entry as *"its unique tweet id, the author's id and
  some additional bits"* — the id is the entry. EchoMQ's lane entry is a branded `JOB` id, a compact printable
  14-character name (`Codemojex.Guesses.submit/3` mints one with `EchoData.BrandedId.generate!("JOB")`). Both keep
  the list
  cheap by storing an identity, not a payload — the payload lives elsewhere, keyed by the id.
- **All Valkey lists are quicklists — echo_mq does not choose it.** Quicklist is the list encoding, not a per-list
  option a system turns on. EchoMQ's wake list benefits from listpack-node packing because **every** Valkey list is
  a quicklist; the only thing the script controls is the cap (`LTRIM … 0, 63`), which keeps the wake list in a
  single small node. The historical core feature is quicklist (Redis 3.2); today's node encoding is the listpack
  (which replaced the ziplist in 7.0). The list-encoding thresholds are the subject of R7.02 (memory optimization).

The worked consumer is **codemojex**. A guess is a job on a player's lane: `Codemojex.Guesses.submit/3` mints a
branded `JOB` (`EchoData.BrandedId.generate!("JOB")`) and runs `Lanes.enqueue(Bus.conn(), …)`, so the lane is a list
of ids and the bus rotates service across players.

### Notes on Valkey

A Valkey list is stored as a quicklist — a doubly-linked list whose nodes are listpacks. A short list lives in a
single listpack node; the list-max-listpack-size and entry-size limits decide when a node splits. A 64-element wake
list never crosses that threshold, so it stays one compact node — the same packing Twitter's scale drove into core
Redis. See [valkey.io/topics/data-types](https://valkey.io/topics/data-types/).

## The three dives

The module follows the arc — the write path, the memory it costs, and what came of it:

- **R8.04.1 · Timeline fan-out**
  (`/redis-patterns/production-operations/twitter-internals/timeline-fan-out`) — fan-out-on-write into per-follower
  Redis lists, O(1) read against O(n) write, the 3× replication for fault tolerance, and the celebrity hybrid. The
  BCS echo: EchoMQ's lanes are per-lane Redis lists; the wake list signals readiness with `LPUSH` + `LTRIM 0, 63`.
- **R8.04.2 · Quicklist & memory**
  (`/redis-patterns/production-operations/twitter-internals/quicklist-and-memory`) — the memory problem
  (linked-list 40+ B/entry against ziplist 1–10 B/entry), quicklist as a doubly-linked list of ziplists/listpacks,
  and the 1.0 GB-against-11.86 GB figure. The BCS echo: the 64-element wake list is one small listpack node;
  cross-links R7.02.
- **R8.04.3 · What became core**
  (`/redis-patterns/production-operations/twitter-internals/what-became-core`) — the precise attribution: the
  technique was internal at Twitter and never upstreamed, became core as quicklist (Redis 3.2, by Matt Stancliff),
  and evolved to the listpack in 7.0. The BCS echo: EchoMQ inherits the core encoding for free, because all Valkey
  lists are quicklists.

Read them in order: how a tweet reaches a timeline, what a timeline costs, and what the world took from it.

## References

### Sources

- [Matt Stancliff — Redis Quicklist — From a More Civilized Age](https://matt.sh/redis-quicklist) — the encoding's
  author on the memory problem (linked-list 40+ B/entry against ziplist 1–10 B/entry), the `[ziplist 0] <-> … <->
  [ziplist N]` shape, the 1.0 GB-against-11.86 GB figure, and Twitter's 10,000-server / 100 TB-per-datacenter scale.
- [redis/redis — Quicklist (linked list + ziplist), PR #2143](https://github.com/redis/redis/pull/2143) — the pull
  request that brought quicklist into core Redis (shipped in 3.2), authored independently of Twitter's internal
  code.
- [HdM Stuttgart CS Blog — How to Scale: Real-time Tweet Delivery Architecture at Twitter](https://blog.mi.hdm-stuttgart.de/index.php/2021/03/10/how-to-scale-real-time-tweet-delivery-architecture-at-twitter/)
  — fan-out on write, the per-follower Redis-list home timeline, what is stored per entry, 3× replication, the read
  / write asymmetry, and the celebrity hybrid.
- [VMware Tanzu — Staple Yourself to a Tweet … 30 Billion Redis Updates Per Day](https://blogs.vmware.com/tanzu/case-study-staple-yourself-to-a-tweet-to-understand-30-billion-redis-updates-per-day)
  — the home-timeline Redis tier framed at roughly 30 billion Redis updates per day.
- [Valkey — Data types](https://valkey.io/topics/data-types/) — the list as a quicklist of listpack nodes, and the
  node-size thresholds the wake list stays under.

### Related in this course

- [R8.04.1 · Timeline fan-out](/redis-patterns/production-operations/twitter-internals/timeline-fan-out) — fan-out
  on write into per-follower Redis lists.
- [R8.04.2 · Quicklist & memory](/redis-patterns/production-operations/twitter-internals/quicklist-and-memory) — the
  1.0 GB-against-11.86 GB figure and the listpack node.
- [R8.04.3 · What became core](/redis-patterns/production-operations/twitter-internals/what-became-core) — the
  technique that became quicklist.
- [R7.02 · Memory optimization](/redis-patterns/data-modeling/memory-optimization) — the listpack thresholds behind
  the wake list.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echomq/queue](/echomq/queue) — the Queue pillar: jobs, lanes, the lists behind the bus.
