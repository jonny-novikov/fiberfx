# Timeline fan-out

> R8.04.1 · Twitter/X: internals & custom structures — dive 1 · route
> `/redis-patterns/production-operations/twitter-internals/timeline-fan-out`

Twitter made reading a home timeline cheap by paying at write time. When a tweet is posted, a fanout service inserts
the tweet's id into every follower's home timeline — a Redis list — so a read of a timeline is a single range over
one list. The read is O(1); the write is O(n) in the follower count. This dive takes that trade apart, then ties it
back to the per-lane Redis lists EchoMQ runs.

Grounding: the Twitter source pack (HdM Stuttgart, VMware Tanzu) for the case study; the BCS echo — `EchoMQ.Lanes`
in `echo/apps/echo_mq/lib/echo_mq/lanes.ex`. Valkey is the BCS engine; Twitter's own Redis is the case study.

## §1 · Fan-out on write

A home timeline is a list of tweet ids, one per row, in time order. The write path that fills it is described
verbatim: *"the fanout … is responsible for spreading out the tweet to all people following the author by inserting
it to all their home timelines."*

The steps, in order:

1. A user posts a tweet. The tweet is written once to a tweet store and given a unique id.
2. The fanout service asks the social-graph service for the author's follower set.
3. For each follower, the fanout service inserts the tweet id into that follower's home-timeline Redis list.

The cost is asymmetric, and that is the point. A read touches one list and returns a range; it does not consult the
social graph and does not scan other users' data. A write touches as many lists as the author has followers. Twitter
absorbed that asymmetry because reads vastly outnumber writes: a reported *"300K QPS … spent reading timelines and
only 6000 requests per second … on writes."* Paying O(n) once at write time, fifty times less often than reads
happen, buys an O(1) read every time a timeline is opened. The system delivers a tweet *"within 5 seconds"* and
serves the HTTP read *"within 50 milliseconds."*

What is stored per entry is deliberately small: *"Every tweet is stored only by its unique tweet id, the author's id
and some additional bits."* The list holds identities and a little metadata, not tweet bodies — the body lives once
in the tweet store, fetched by id when a timeline is rendered. A small entry is what makes a list of a follower's
worth of tweets cheap to hold, and it is the same instinct EchoMQ's lanes follow.

## §2 · Replication, and the celebrity hybrid

Two facts complete the picture.

**Replication for fault tolerance.** A home timeline is not stored once. *"The user's home timeline is stored three
times in the clusters,"* so a node loss does not lose a user's feed and a read can be served from any copy. Three
copies is durability-through-redundancy in RAM — the timeline is a derived, rebuildable view, replicated for
availability rather than persisted as a system of record.

**The celebrity problem, and the hybrid.** Fan-out-on-write is cheap to read and bounded to write only while the
follower count is bounded. For the largest accounts it is not: delivery *"can take up to 5 minutes … when
celebrities like Lady Gaga or Kylie Jenner tweet,"* because inserting one tweet into tens of millions of lists takes
real time. The answer is a hybrid. Most accounts use fan-out-on-write; the few enormous accounts are handled by
fetch-and-merge-at-read — a reader's timeline is assembled from their own fanned-out list plus a live pull of the
handful of celebrity accounts they follow, merged at read time. The write amplification of the giant account is
traded for a small read-time merge, paid only by the readers who follow it.

The principle is a dial, not a binary. Fan-out-on-write optimises the read at the cost of the write; fetch-and-merge
optimises the write at the cost of the read. Twitter ran both, choosing per account by where the cost was bearable.

## §3 · The BCS echo — lanes are per-lane Redis lists

EchoMQ does not store timelines. But its queue is built on the same primitive Twitter chose — the native Redis list
— and one of those lists plays exactly the role of a readiness signal.

A lane is a per-group pending set, and a ring lists the lanes that can be served right now. Admitting a job pushes
onto the ring and signals any parked consumer; claiming rotates the ring one step. The relevant lines are verbatim
from the enqueue script:

```
# echo/apps/echo_mq/lib/echo_mq/lanes.ex — the enqueue script
redis.call('RPUSH', KEYS[3], ARGV[3])     # push the lane onto the ring
redis.call('LPUSH', KEYS[7], '1')         # signal a parked consumer
redis.call('LTRIM', KEYS[7], 0, 63)       # hold the wake list to 64 elements
```

`RPUSH` appends to the ring; `LPUSH` then `LTRIM … 0, 63` writes a one-byte token to a **wake list and trims it to
64 elements**, so a consumer blocked on that list wakes when work appears. The claim side rotates the ring with a
single `redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')` — moving the head to the tail so service spreads
round-robin across lanes. Every one of these is a list operation on a native Redis list.

The bridge:

- **The pattern** — a feed is a list of ids; the read is cheap because the entry is only an identity, and a list is
  the right structure when order matters and the entry is small.
- **Its EchoMQ application** — a lane is a Redis list of branded `JOB` ids, and the wake list is a Redis list held
  to 64 elements with `LTRIM … 0, 63`. The element is the id; the bus rotates service across lanes with one
  `LMOVE`.

The honest difference: Twitter's list is the feed itself, replicated three ways and read by range; EchoMQ's lists
are a work ring and a wake signal, single-key and rotated. The shared move is the one to keep — store an identity in
an ordered list and keep the entry small, so the list stays cheap.

### Notes on Valkey

A Redis or Valkey list is stored as a quicklist: a doubly-linked list whose nodes are listpacks. A 64-element wake
list lives in a single listpack node, so the `LTRIM … 0, 63` keeps it compact regardless of how often it is pushed
to. The node-size thresholds that decide when a list splits across nodes are the subject of R7.02. See
[valkey.io/topics/data-types](https://valkey.io/topics/data-types/).

## §4 · Recap — pay once at write, read cheaply forever

Fan-out on write is a deliberate trade: spread a tweet into every follower's list at post time so a timeline read is
O(1) forever after. Twitter replicated each timeline three times for fault tolerance and ran a hybrid path for the
few accounts whose follower counts made write-time fan-out too slow. EchoMQ uses the same primitive — a native Redis
list — for its lane ring and its wake signal, storing an id per entry and capping the wake list at 64 with
`LTRIM … 0, 63`. The next dive measures what a list of ids costs in memory, and the encoding Twitter's scale drove
into core Redis.

## References

### Sources

- [HdM Stuttgart CS Blog — How to Scale: Real-time Tweet Delivery Architecture at Twitter](https://blog.mi.hdm-stuttgart.de/index.php/2021/03/10/how-to-scale-real-time-tweet-delivery-architecture-at-twitter/)
  — fan-out on write, the per-follower Redis-list home timeline, what is stored per entry, 3× replication, the read
  / write asymmetry, and the celebrity hybrid.
- [VMware Tanzu — Staple Yourself to a Tweet … 30 Billion Redis Updates Per Day](https://blogs.vmware.com/tanzu/case-study-staple-yourself-to-a-tweet-to-understand-30-billion-redis-updates-per-day)
  — the home-timeline Redis tier framed at roughly 30 billion Redis updates per day, against 400 million tweets a
  day.
- [Valkey — Data types](https://valkey.io/topics/data-types/) — the list as a quicklist of listpack nodes, and the
  node-size thresholds the wake list stays under.

### Related in this course

- [R8.04 · Twitter/X: internals & custom structures](/redis-patterns/production-operations/twitter-internals) — the
  module hub.
- [R8.04.2 · Quicklist & memory](/redis-patterns/production-operations/twitter-internals/quicklist-and-memory) — the
  next dive: what a list of ids costs.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echomq/queue](/echomq/queue) — the Queue pillar: jobs, lanes, the lists behind the bus.
- [/bcs/overview](/bcs/overview) — the branded id, the identity stored in a lane.
