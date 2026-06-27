# States as locations — the lifecycle as one atomic Lua move

> Route: `/redis-patterns/queues/states-as-locations` · Dive R3·2 · Chapter R3 Reliable Queues · BCS contract-sheet.
> Grounding: the real **EchoMQ** keyspace and state machine in `echo/apps/echo_mq` — `EchoMQ.Keyspace` and
> `EchoMQ.Jobs`. A job's state is the `emq:{q}:` location its branded `JOB` id lives in (`pending`/`active`/`schedule`
> sorted sets + the row hash + a `state` field). A transition is one inline `EchoMQ.Script.new/2` body run by
> `EchoMQ.Connector.eval/4` as a single EVALSHA — read-decide-write that cannot tear. Doors: `/echomq/queue`.

A job's state is not just a field on a record. It is the `emq:{q}:` key its branded `JOB` id lives in — and a
transition moves the id from one key to the next, in one atomic Lua move.

## The state is the location

A naive queue stores a status column and updates it as the job moves, so the location and the status can disagree
after a crash. EchoMQ holds the job's identity in a Valkey location and keeps a matching `state` field on the row,
written in the same atomic move. The pending set `emq:{q}:pending` is a score-0 sorted set so byte order is mint
order; the active set `emq:{q}:active` is a sorted set scored by each member's lease deadline; the schedule set
`emq:{q}:schedule` is scored by a future run-at; the dead set `emq:{q}:dead` holds terminal ids; and the row hash
`emq:{q}:job:<JOB>` carries the `state`, `attempts`, and `payload` fields.

`EchoMQ.Keyspace.queue_key/2` builds each location as `emq:{q}:<type>`, with the queue name braced as the cluster
hash-tag so every key of one queue lands on one slot. `EchoMQ.Keyspace.job_key/2` builds the row key
`emq:{q}:job:<JOB>` — and **gates the branded `JOB` id at the key builder**: it raises if the id is not a valid
branded id, so an ill-formed identity never reaches the keyspace. The state is where the id sits, and the location
can never be reached by an unbranded key.

```
# a job's state is the emq:{q}: key its branded JOB id lives in
emq:{cm}:pending          → ZSET  · score 0, byte order is mint order
emq:{cm}:active           → ZSET  · scored by lease deadline (server TIME)
emq:{cm}:schedule         → ZSET  · scored by a future run-at
emq:{cm}:dead             → ZSET  · terminal, dead-lettered ids
emq:{cm}:job:JOB0Nt…      → HASH  · state, attempts, payload
```

## The whole transition is one atomic Lua move

Moving a job from active to done is not one write. The transition reads the row's `attempts` to fence the caller,
checks the token, removes the id from the active set, retires the row, and bumps a metric — touching several keys.
Done as separate commands, a crash partway leaves the job in two places, or in none.

EchoMQ runs each transition as one inline `EchoMQ.Script.new/2` body, dispatched by `EchoMQ.Connector.eval/4` as a
single EVALSHA (the connector is EVALSHA-first, falling back to EVAL on `NOSCRIPT`). `EchoMQ.Jobs.complete/5` is the
active→done move: it `HGET`s `attempts`, refuses a stale token (`EMQSTALE`), `ZREM`s the id from the active set,
`DEL`s the row, and `HINCRBY`s the completed metric — all in one script. Valkey runs a Lua script to completion with
no other client interleaving, so the move applies in full or not at all. This is the R2.01 atomic-update pattern at
lifecycle scale: read, decide, write — in one move.

```lua
-- @complete (inline) — active → done, token-fenced, in one EVALSHA
local att = redis.call('HGET', KEYS[2], 'attempts')   -- KEYS[2] = the row
if not att then return 0 end
if att ~= ARGV[2] then
  return redis.error_reply('EMQSTALE complete token mismatch')
end
redis.call('ZREM', KEYS[1], ARGV[1])                  -- KEYS[1] = emq:{q}:active
redis.call('DEL', KEYS[2])                            -- retire the row
redis.call('HINCRBY', ARGV[3] .. 'metrics:completed', 'count', 1)
return 1
```

## Every key is declared, gated, and on one slot

The atomic move has a discipline behind it. Every key the script touches is passed in `KEYS[]` — the active set and
the row are declared keys, not derived inside the script from a data value. Every key of one queue carries the same
`{q}` brace, so the whole transition lands on one cluster slot and Valkey will run the multi-key script. And the
branded `JOB` id is gated at `EchoMQ.Keyspace.job_key/2` before any key is built. The script is the protocol: the
caller sends the SHA and the keys, the body lives in Valkey, and the transition is indivisible.

## In EchoMQ — the lifecycle the worker runs

The pattern and the application line up directly. A job's state is its `emq:{q}:` location plus a matching `state`
field written in the same move; every transition is one inline `EchoMQ.Script.new/2` body run by
`EchoMQ.Connector.eval/4` as a single EVALSHA; and the branded `JOB` id is gated at the key builder. `EchoMQ.Jobs`
holds the verbs — `claim/3` (pending→active), `complete/5` (active→done), `retry/7` (active→schedule or →dead),
`reap/2` (active→pending), `promote/3` (schedule→pending). States are locations, a transition is one atomic Lua
move, and no torn intermediate state exists to recover.

## References

### Sources

- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — a script
  runs to completion with no interleaving, so a transition applies in full or not at all.
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — run a cached script by its SHA; a `NOSCRIPT` reply falls
  back to `EVAL`, which caches the body — the connector's EVALSHA-first dispatch.
- [Valkey — ZREM](https://valkey.io/commands/zrem/) — removes the id from one state set, the move out of a location.
- [Redis — Cluster key hash tags](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/) — the
  `{q}` brace that lands every key of one queue on one slot, so a multi-key script is legal.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter: the reliable-queue family in one place.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — dive 1: the leased claim, at-least-once, and
  stalled reclaim.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move; this dive is that pattern
  at lifecycle scale.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the state machine and the inline Lua in depth.
