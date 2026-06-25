# The Lua layer — module hub

**Route:** `/echomq/protocol/the-lua-layer` · **Surface:** module hub · **Pillar:** The Protocol

> Source-of-record for the hub page. As-shipped voice, no version labels. All grounding is real code in
> `echo/apps/echo_mq` + `echo/apps/echo_wire` — **no `[RECONCILE]` markers** (nothing here is ahead of code).

## The fact

Every state change EchoMQ makes is **one atomic Lua script**, run inside Valkey. The wire is not a set of commands a
client issues in sequence — it is the set of scripts. To enqueue a job is to run the `@enqueue` script; to claim one is
to run `@claim`; to finish one is to run `@complete`. Each script is the whole transition: it reads, decides, and
writes in a single server-side step that no other client can interleave. That is why the scripts *are* the protocol —
the transitions live below the language line, identical wherever the wire runs.

Three properties make the Lua layer a protocol rather than a convenience:

1. **One transition, one script, atomic.** `@enqueue` admits by kind, refuses a duplicate, writes the row, and inserts
   the pending entry — all or nothing, on the server, in one step. There is no window in which the row exists but the
   pending entry does not.
2. **Every key is declared.** A script touches only keys passed in `KEYS[]`; it constructs none from data. The host
   (the keyspace) builds the keys; the script receives them declared.
3. **Loaded once, run by SHA.** `EchoMQ.Script.new/2` precomputes each script's SHA1; `EchoMQ.Connector.eval/5` runs it
   with `EVALSHA`, reloading on a `NOSCRIPT` miss. The script source crosses the wire at most once per connection.

## The worked surface — the three dives

| Dive | Teaches | Real grounding |
|---|---|---|
| **scripts-are-the-protocol** | the two-beat form: the `@enqueue` handle, then its decoded Lua body — the `EMQKIND` gate, `EXISTS` idempotency, `HSET` the row, `ZADD` pending | `EchoMQ.Jobs` `@enqueue` (real Lua) + `enqueue/4` |
| **declared-keys** | every key passed in `KEYS[]`, none constructed in-script — and why this is the law (one Valkey Cluster slot per queue) | the `KEYS[1]`/`KEYS[2]` contract in `@enqueue`; `enqueue/4` building the keys host-side |
| **evalsha-dispatch** | load-once, run-by-SHA: `EchoMQ.Script.new/2` (SHA1 precomputed) + `EchoMQ.Connector.eval/5` (EVALSHA-first, NOSCRIPT fallback) | `EchoMQ.Script.new/2`, `EchoMQ.Connector.eval/5` |

## The interactive

A **script catalog** over a fixed dataset of the real `EchoMQ.Jobs` scripts (`@enqueue`, `@claim`, `@complete`): pick a
verb and read its named handle, the keys it declares, and the one-line transition it performs. Pure lookup; the readout
is computed from the dataset, no network. It frames the chapter's claim — each verb is one declared-key script.

## The pairing — the pattern → the implementation

`/redis-patterns` teaches **"patterns become protocol"** (R0.3) and **atomic updates + one-slot Lua** (R2 Coordination):
a Redis pattern, pushed below the language line, becomes a protocol. This module is where that move lands — the scripts
are the protocol.

## Recap

The Lua layer is the protocol's *how*: one atomic script per transition, every key declared, loaded once and run by
SHA. The three dives read the `@enqueue` script in two beats, the declared-keys law, and the EVALSHA dispatch.

## References

### Sources
- Valkey — *EVALSHA* — `https://valkey.io/commands/evalsha/` — load-once, run-by-SHA dispatch of a declared-keys script.
- Redis — *EVAL* — `https://redis.io/commands/eval/` — atomic server-side scripting, the mechanism the Lua layer is.
- Valkey — *Documentation* — `https://valkey.io/docs/` — the substrate of record EchoMQ is backed by.
- Valkey — *Cluster specification* — `https://valkey.io/topics/cluster-spec/` — the `{hashtag}`→hash-slot routing the
  declared-key discipline is built for: every key of a queue on one slot, where a multi-key script is legal.

### Related in this course
- `/echomq/protocol` — the chapter this module belongs to.
- `/echomq/protocol/the-owned-keyspace` — where the keys the scripts declare are built.
- `/echomq/protocol/the-record-hash` — the row the scripts write.
- `/redis-patterns/overview/patterns-become-protocol` — the near side of the door.
- `/redis-patterns/coordination` — atomic updates and one-slot Lua.
