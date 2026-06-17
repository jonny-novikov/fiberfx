# BCS · Appendix H Specification — The Connector's Next Rows

<show-structure depth="2"/>

The rows Appendix H's table marks "specified": capabilities neither `EchoMQ.Connector` nor Redix carries today, written here as gated increments in the house style — surface first, laws second, the rung's gates sketched before any implementation exists, so that when each row ships it ships the way everything in this series ships. Nothing below is implemented; every claim is a design obligation, not a record.

## conn.1 — Streams: the verbs

**Why.** EchoMQ 2.x rides lists and hashes; the partitioned-stream lane is the 3.0 substrate (ROADMAP, Part V adjacency), and it needs first-class stream verbs on the connector rather than raw command lists at every call site.

**Surface.**

```elixir
Connector.xadd(conn, stream, id_or_auto, fields, opts)      # MAXLEN/MINID trim opts
Connector.xread_group(conn, group, consumer, streams, opts)  # COUNT, BLOCK, NOACK
Connector.xack(conn, stream, group, ids)
Connector.xautoclaim(conn, stream, group, consumer, min_idle_ms, cursor, opts)
```

**Laws.** Branded at the door: stream names derive from `Keyspace` (one hash tag per lane); entry ids are server-minted but every payload field set carries the branded job id, and the verbs validate it before the wire. `BLOCK` rides the existing single-owner socket — a blocking read parks the connection exactly as the wake key does today, and the verb refuses a `BLOCK` while pipelined traffic is pending (`{:error, :busy_socket}`) rather than silently serializing behind it.

**Gates (sketch).** S-gates: round-trip a field set through `xadd`/`xread_group` with kind validation refusing a garbage id; `xautoclaim` recovering an abandoned entry after `min_idle_ms` with the cursor law (resumption returns no duplicates); a `BLOCK` park-and-wake median beside the committed BLPOP row (`129` µs class on this wire); trim opts holding length under a fill of 10k.

## conn.2 — Streams: partitioned lanes

**Why.** The group-lane fairness of 3.4 (pause, resume, limit, depth behind one identity) re-expressed on consumer groups, so a lane is a stream partition and a consumer group is the claim ledger the server keeps.

**Surface.** A `StreamLanes` sibling to `Lanes`: `enqueue/5` (partition by branded group id), `claim/3` via `xread_group`, `complete/4` via `xack`, `reap/2` via `xautoclaim` — verb-for-verb the 3.x contract, lists swapped for streams.

**Laws.** The 3.4 control vocabulary survives the substrate: pause and resume and limit act per group, and depth is `XLEN` plus pending-entries arithmetic. Replay inherits the journal contract — admission dedup by branded id holds across `xadd` retries.

**Gates (sketch).** The 3.4 rung's eight gates re-run on the stream substrate, beside the committed list-lane figures; the conformance harness (3.6's fourteen contracts) extended with stream rows.

## conn.3 — Messaging: sharded and registered

**Why.** `subscribe/2` today is RESP3 on the data connection with the table's restart as the resubscription story. Cluster topologies want `SSUBSCRIBE` (sharded channels riding the hash slot), and every topology wants subscriptions that survive a reconnect without the caller noticing.

**Surface.**

```elixir
Connector.ssubscribe(conn, channel)                 # sharded; slot follows the hash tag
Connector.psubscribe(conn, pattern)
Connector.subscriptions(conn)                       # the registry, observable
# opts: resubscribe: true (default) -- replay the registry inside do_connect
```

**Laws.** The connector keeps a subscription registry in state; `do_connect` replays it after the fence and before the connection event fires, so a `:connection` telemetry event means *subscriptions live*, not merely socket up. Pushes keep their one delivery path (`push_to`); a registry replay that partially fails is a failed connect, not a silent half-subscription.

**Gates (sketch).** Kill the connection server-side with two channels and one pattern registered; gate the sequence disconnection → connection → both channels delivering again with no caller action, and the registry observable identical before and after. Sharded: two channels with different hash tags landing on their slots (single-node Valkey accepts `SSUBSCRIBE`; the slot law gates by `CLUSTER KEYSLOT` agreement).

## conn.4 — TLS transport (merges emq.7)

**Why.** The transport rung emq.7 proposed TLS pricing; the unix-socket row landed in Appendix H, leaving TLS the remaining transport. Fly-internal traffic rides private networking, but the portable-secondary posture (Valkey anywhere) needs the option.

**Surface.** `Connector.start_link(tls: true, tls_opts: [...])` — `:ssl.connect/4` swapped for `:gen_tcp.connect/4` behind the existing `do_connect`, verify-peer defaulted, the heartbeat and fence unchanged.

**Laws.** One transport per connection, chosen at boot; the fence and script preload run identically over TLS; `send_timeout` semantics preserved.

**Gates (sketch).** A TLS-enabled Valkey (self-signed, rung-provisioned); PONG through the fence; the H3/H4 rows re-priced over TLS beside the committed loopback cells, the delta printed as the handshake-amortized per-op cost.

## conn.5 — Tracking, broadcast mode

**Why.** Chapter 4.5 shipped default tracking (per-key, read-registered). `BCAST` mode trades precision for prefix subscriptions — invalidation for keys never read on this connection — which fits warm-standby caches that fill from elsewhere.

**Surface.** `Connector.tracking(conn, :on | :bcast, prefixes \\ [])` — a typed wrapper over `CLIENT TRACKING` with the mode law enforced client-side (prefixes only with `:bcast`).

**Laws.** Pushes keep the single path; the 4.5 lag methodology applies unchanged (only wire-read keys for `:on`, prefix writes for `:bcast`), and the rung must reuse its committed `p50 10 us` row as the `:on` anchor.

**Gates (sketch).** A `:bcast` connection receiving invalidation for a never-read key under its prefix and *not* for a sibling outside it; lag distribution printed beside the 4.5 anchors.

## Sequencing

conn.1 → conn.2 carry the 3.0 substrate and go first; conn.3 unblocks cluster messaging and is independent; conn.4 and conn.5 are envelope work, schedulable opportunistically. Each rung lands with its article section or ledger entry, its committed record, and the regression suite re-run — the connector is the spine, and Appendix H's forty-eight-gate regression is the floor every increment re-clears.
