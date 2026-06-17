# B4.2 · Coherence by Mint Time

> Module hub · route `/bcs/cache/coherence-by-mint-time` · teaches `content/bcs4.2.md` · the rung is
> `bcs_rung_4_2_check.exs`, its committed record `bcs_rung_4_2_check.out` closes `PASS 6/6`.

Twenty-nine bytes, two lanes, and no clock but the one inside the name.

Chapter 4.1 bounded staleness by the clock; this chapter bounds it by the write. The coherence message of
EchoCache is twenty-nine bytes — a cached name, a colon, and the writer's mint-time version — and everything
else falls out of the order theorem: because a branded id's payload bytes sort in mint order, *newer wins* is a
comparison of two names, with no coordinator, no lock, and no clock but the one already inside every id. Two
lanes carry the same message and the committed record prices them side by side: `broadcast median 72 us
fire-and-forget, job lane median 148 us at-least-once -- the guarantee costs 2.1 times the latency`.

One production module lands (`EchoCache.Coherence`), the table grows version-aware, and the connector gains the
send-only push path the broadcast lane stands on. The rung gates the vocabulary, newer-wins with teeth, the
broadcast lane against its derived band, the loss of fire-and-forget, the job lane through a consumer crash, and
the price on one row — six gates, `PASS 6/6`.

## §1 A message that carries its own order

A TTL is a promise about the past — *this row was true within the last N milliseconds* — and for quotes on a
screen that promise is enough. For a position limit, a halted instrument, or a risk parameter, it is not: the
desk needs *this row reflects the latest write*, and the latest write is exactly what the comparison set cannot
say. Valkey's own tracking sends an unversioned *forget this key*; Nebulex synchronizes by deletion; neither
message carries an order, so a late invalidation and a fresh write race, and the loser is whoever applied last.
The fix the literature reached in 1978 is a total order constructed from timestamps, and this series has carried
that order in every identity since Part I. The version of a cached row is a branded id; comparing two versions
is comparing eleven payload bytes; and a coherence protocol whose conflicts resolve by comparison needs no
coordination. The manuscript plans the measured face-off — **B4.5 · The Cache Referee** — and until that chapter
ships, the comparison set is characterized, never measured.

The chapter's decisions:

- **The version is a name.** Not a counter, not a wall-clock reading, not a vector: a branded id whose payload
  bytes already total-order by mint time across every kind.
- **Coherence drops; it never writes.** A message means *the writer already placed the newer value in L2*; the
  receiver's only move is to discard its older L1 copy.
- **Stale messages bounce off both layers.** The L1 comparison in the owner and the L2 comparison in one Lua
  script are the same predicate in two places.
- **The job-lane consumer lives in the application's tree.** An EchoMQ consumer is a real supervised worker with
  a lease and a lane; hiding one inside a cache table would falsify the supervision tree.
- **The connector's push path is send-only and RESP3-only.** A SUBSCRIBE confirmation arrives as a push, so
  awaiting it on the FIFO starves the queue; protocol 2 is refused with a typed `:requires_resp3`.
- **The applier is the owner — for now.** Pushes apply inline in the table's process; **B4.3 · The Single Writer
  and the Ring** moves application onto the ring without touching the semantics gated here.

The writer's side, after its store write (source: `content/bcs4.2.md`, How):

```elixir
version = BrandedId.generate!("TXN")           # the write's own identity
:ok = Table.put(:quotes, ast_id, "px=106.00", version)
{:ok, _heard} = Coherence.broadcast(conn, "quotes", ast_id, version)
# or, when at-least-once matters:
{:ok, :enqueued} = Coherence.enqueue(conn, "quotes", group, ast_id, version)
```

## §2 The proof

The full committed transcript, verbatim, derive lines and the staged consumer kill included (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_2_check.out`):

```
F1 surface ok -- the vocabulary is whole: channel, queue, a twenty-nine-byte payload of two names, parse refusing garbage; tables declare their lane in the directory; and the connector's push path refuses a protocol 2 connection with a typed :requires_resp3
F2 newer-wins ok -- a late stale invalidation bounced off both layers -- the L1 row survived holding px=105.00 and the L2 drop script answered 0 -- while a genuinely newer version applied and the replay of the old one stayed stale: idempotence is a comparison, not a log
derive (broadcast): the lane is one PUBLISH hop on the wire whose committed sequential floor is 29,456 round trips per second, near 34 us each -- expect a median push latency between 30 and 500 us, and the receiver's apply is one ETS comparison on top
F3 broadcast ok -- median push latency 72 us over 100 messages, inside the derived band; the cross-node round trip holds -- the writer put px=106.00, 3 subscribers heard the name, and the other node's next read fell through its dropped L1 to the shared L2 and answered fresh
F4 loss ok -- the price of fire-and-forget, stated as a gate: :qc declared the job lane and holds no subscription, so the broadcast passed it by and it still serves px=100.00 -- bounded staleness until its own lane delivers, which is the next gate's business
derive (job lane): a consumer crash after claim strands the coherence job on a lease; the reaper returns it, a second consumer applies it with token 2, and reapplication is harmless because newer-wins is a comparison -- expect attempts 2 and exactly one effective drop

01:36:22.839 [error] GenServer #PID<0.203.0> terminating
** (stop) killed
Last message: {:EXIT, #PID<0.202.0>, :killed}
State: %{backoff: 100, buf: "", client_name: nil, connect_timeout: 3000, counters: {:write_concurrency, #Reference<0.595650664.2344747009.170073>}, database: 0, hb_ref: #Reference<0.595650664.2344615937.170091>, heartbeat_ms: 30000, host: {127, 0, 0, 1}, label: :emq, max_pending: 10000, overloads: 0, password: nil, pending: {[], []}, pending_n: 0, port: 6390, protocol: :auto, protocol_live: 3, push_to: nil, pushes: 0, sock: #Port<0.13>}
F5 job lane ok -- the lane that survives: the first consumer died holding the job, the reaper returned it, the healer applied it -- :qc dropped its stale row and now serves px=107.00 from the shared L2 -- the completed job left no row to browse, and replaying the same version answers stale: at-least-once delivery, exactly-once effect
derive (price): the broadcast lane is one wire hop; the job lane pays three to five hops -- enqueue, wake, claim, complete -- so a parked consumer should land its median between 80 us and 2 ms, the same order as the bus's committed 0.3 ms end-to-end median, carrying the guarantee the push cannot
F6 price ok -- the two lanes on one row: broadcast median 72 us fire-and-forget, job lane median 148 us at-least-once -- the guarantee costs 2.1 times the latency, and gates F4 and F5 are the reason a surface pays it
PASS 6/6
```

The mid-record `[error] GenServer … terminating` block is the staged consumer kill of the F5 drill — part of
the frozen record, kept whole here. The derive lines are part of the record too: each measurement is preceded
by the band the rung derived for it, and F3 and F6 land inside their bands.

## §3 The dives

1. **The Twenty-Nine Bytes** (`the-twenty-nine-bytes`) — F1, the vocabulary: channel `ecc:{<table>}:coh`, queue
   `ecc.coh.<table>`, "a twenty-nine-byte payload of two names, parse refusing garbage", the typed
   `:requires_resp3`; F2, newer-wins with teeth — the late stale invalidation bounced off both layers,
   "idempotence is a comparison, not a log"; Lamport's total order carried in the name.
2. **The Broadcast Lane** (`the-broadcast-lane`) — F3 — "median push latency 72 us over 100 messages, inside the
   derived band", the cross-node round trip; the substrate's at-most-once contract taken whole; F4, the loss
   gated — the job-lane table "still serves px=100.00 -- bounded staleness until its own lane delivers".
3. **The Job Lane** (`the-job-lane`) — F5, the crash choreography — "the first consumer died holding the job,
   the reaper returned it, the healer applied it … at-least-once delivery, exactly-once effect"; F6, the price —
   "broadcast median 72 us fire-and-forget, job lane median 148 us at-least-once -- the guarantee costs 2.1
   times the latency".

## References

Sources:

- Valkey — Pub/Sub — https://valkey.io/topics/pubsub/ (the broadcast lane's contract, taken whole: at-most-once,
  unpersisted, lost on disconnect)
- Valkey — Client-side caching — https://valkey.io/topics/client-side-caching/ (the comparison set's
  deletion-shaped coherence: no version, no order)
- Lamport, L. — Time, Clocks, and the Ordering of Events in a Distributed System —
  https://dl.acm.org/doi/10.1145/359545.359563 (the total order newer-wins carries in the name)

Related:

- /bcs/cache — B4 · EchoCache, the chapter landing; Part IV's arc
- /bcs/cache/cache-aside — B4.1 · Cache-Aside at ETS Speed, the declared L1 this module keeps coherent
- /bcs/cache/single-writer-ring — B4.3 · The Single Writer and the Ring, the engine that applies this stream
- /bcs/bus — B3 · The Bus, the bus the job lane rides
- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the lease, the reaper, and the fencing token under
  the job lane
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the enqueue the job lane reuses
- /bcs/elixir-core/property-stores — B2.2 · Property Stores on ETS, the stores being cached
- /echomq — EchoMQ, the protocol in rung-level depth on the far side of the door
- /redis-patterns — Redis Patterns Applied, the substrate: pub/sub, Lua, the caching patterns
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/cache` · next `/bcs/cache/coherence-by-mint-time/the-twenty-nine-bytes`.
