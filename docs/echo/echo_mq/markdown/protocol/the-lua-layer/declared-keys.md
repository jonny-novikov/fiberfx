# Declared keys

**Route:** `/echomq/protocol/the-lua-layer/declared-keys` · **Surface:** dive · **Pillar:** The Protocol

> Source-of-record. As-shipped voice, no version labels. All grounding is real code in `echo/apps/echo_mq` +
> `echo/apps/echo_wire` — **no `[RECONCILE]` markers**. Lua in two beats, no `file:line`.

## The fact

Every key a script touches is **declared in `KEYS[]`**. The script constructs none from data; the host builds them and
passes them in. `ARGV` carries values only. This is the law of the Lua layer — `EchoMQ.Script`'s own moduledoc states
it: *every key a script touches is declared in KEYS; ARGV carries values only.* The discipline is what makes the wire
portable to a thread-per-shard engine, and it is what keeps the keyspace the single owner of where data lives.

## The worked example — the host builds, the script declares

### Beat one — the host builds the keys

`EchoMQ.Jobs.enqueue/4` builds both keys through `EchoMQ.Keyspace`, then hands them to the script as `KEYS`. The values
go in `ARGV`. The script never sees the queue name; it sees two opaque keys and two opaque values.

```elixir
# echo_mq — EchoMQ.Jobs
# The host builds KEYS through the keyspace, the single owner of where data
# lives. The script receives [row, pending] declared and [id, payload] as
# values. The script does not know the queue name, the braces, or the slot —
# only the two keys it was handed.
def enqueue(conn, queue, job_id, payload) when is_binary(job_id) and is_binary(payload) do
  keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "pending")]
  Connector.eval(conn, @enqueue, keys, [job_id, payload])
  # ... verdict mapping omitted; see scripts-are-the-protocol
end
```

### Beat two — the script touches only declared keys

`@enqueue` references `KEYS[1]` and `KEYS[2]` and nothing else. It does not `..`-concatenate a key from `ARGV`. The
branded id rides `ARGV[1]` as a *value* — it is the member written into the set, never spliced into a key name.

```lua
-- the @enqueue script — KEYS[1] = the job row, KEYS[2] = the pending set
-- Both keys arrive declared; the script constructs neither. ARGV[1] (the id)
-- is a VALUE — the member written into KEYS[2], never concatenated into a key.
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

## Why declared keys is the law — three reasons

1. **Atomicity needs co-location.** A Valkey cluster guarantees one script's keys are on one node only if they hash to
   one slot. The per-queue hashtag `{q}` puts every key of a queue on one slot; declaring those keys is how the engine
   verifies the script stays on its slot.
2. **The keyspace stays the single owner of address.** If a script built a key from data, the rule for *where* a job
   lives would be split between the keyspace and the script. Declaring keys keeps that rule in one place —
   `EchoMQ.Keyspace`.
3. **Thread-per-shard placement.** A multithreaded engine like Dragonfly places a script on a thread by its declared
   key set (`--lock_on_hashtags`). A key constructed inside the script is invisible to that placement — so an
   undeclared key is not portable to a thread-per-shard engine. Conformance is phrased against Valkey; the declared-key
   discipline is what makes the multithreaded placement reachable.

## The pairing — the pattern → the implementation

- **The pattern (Redis Patterns Applied):** hash-tag co-location and one-slot atomic Lua — `/redis-patterns`
  Coordination teaches keys on one slot so one script can touch them atomically.
- **The implementation (echo_mq):** `@enqueue` declares `KEYS[1]`/`KEYS[2]`, both built by `EchoMQ.Keyspace` on the
  `{q}` slot; the script constructs no key from data.

## Recap

Declared keys is the law: the host builds every key, the script touches only `KEYS[]`, values ride `ARGV`. It keeps
atomicity sound on a cluster, keeps the keyspace the single owner of address, and keeps the wire portable to a
thread-per-shard engine. The next dive reads how the declared-keys script is dispatched — loaded once, run by SHA.

## References

### Sources
- Redis — *EVAL* — `https://redis.io/commands/eval/` — the `KEYS`/`ARGV` contract: keys declared, values separate.
- Redis — *Keyspace & hash tags* — `https://redis.io/docs/` — cluster routing by the hashtag inside `{...}`, which the
  declared keys must share to stay atomic.
- Valkey — *Documentation* — `https://valkey.io/docs/` — the substrate of record; Redis-semantics Lua and slot routing.
- DragonflyDB — *Server flags* — `https://www.dragonflydb.io/docs/managing-dragonfly/flags` — `--lock_on_hashtags`, the
  thread-per-shard placement the declared keys enable.

### Related in this course
- `/echomq/protocol/the-lua-layer` — the module this dive belongs to.
- `/echomq/protocol/the-lua-layer/scripts-are-the-protocol` — the transition this dive reads the keys of.
- `/echomq/protocol/the-owned-keyspace` — the keyspace that builds the declared keys.
- `/redis-patterns/coordination/hash-tag-colocation` — keys on one slot, the near side of the door.
- `/redis-patterns/coordination` — atomic updates and one-slot Lua.
