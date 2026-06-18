# Batch lease extension — re-score the many under one clock read

**Route:** `/echomq/queue/batches/batch-lease-extension` · **section:** queue · **pillar:** The Queue · **surface:** dive

> Source-of-record. All grounding is real code in `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — no `[RECONCILE]` markers.

## The fact

A worker holding several jobs at once needs to checkpoint all their leases together, on one clock. `EchoMQ.Jobs.extend_locks/4`
re-scores **every matching `active` member under one server-clock read** and returns the **`failed` list** — the ids it
could not extend.

The lease in this Queue is the active-set score: a claimed job sits in the `active` set scored at its deadline, and its
`attempts` field is the fencing token. So extending a lease is **re-scoring the active member to a fresh deadline** —
there is no separate lock string. The batch verb does it for many ids at once:

1. **Gate every id first.** Before the wire, every id is gated at `Keyspace.job_key/2` — an ill-formed id raises and
   never reaches a key.
2. **Flatten the held pairs into ARGV.** Each `{id, token}` pair becomes two ARGV slots (`id`, then the token as a
   string), after the queue base root and the lease window.
3. **One script, one clock read.** `@extend_locks` declares a single key — the `active` set — and reads the server
   `TIME` **once**. It then walks the ARGV pairs: for each id it reads the row's `attempts` and, if it matches the
   passed token, re-scores the active member at `now + lease`; otherwise it adds the id to a `failed` table. It returns
   that `failed` list.

The verb answers `{:ok, failed}` — the list of ids whose lease could **not** be extended (a stale token, or a row that
is gone). Every job whose token still matches is re-leased on the same `now`; every job whose token has moved on (it was
reaped and reclaimed, so its `attempts` no longer matches) is reported, not extended.

### The contrast — the single extend_lock

The single `EchoMQ.Jobs.extend_lock/5` re-scores **one** member. It declares two keys (the `active` set and the job
row), is token-fenced, and **returns an error** on a stale token (`{:error, :stale}`, the `EMQSTALE` wire class) or a
gone row (`{:error, :gone}`). The shapes differ by design:

| | single `extend_lock/5` | batch `extend_locks/4` |
|---|---|---|
| ids | one | many |
| keys declared | `[active, job_row]` | `[active]` (per-job key derived in-script: `base .. 'job:' .. id`) |
| clock reads | one | one (shared across all ids) |
| a non-matching token | **errors** — `{:error, :stale}` | **collected** — the id joins the `failed` list |
| a gone row | **errors** — `{:error, :gone}` | **collected** — the id joins the `failed` list |
| return | `:ok` \| `{:error, …}` | `{:ok, failed}` |

The batch does not error on a single bad id — it **collects** it, so one stale lease among many does not abort the
others. The single verb errors, because there is nothing to collect.

## The worked example — extend_locks/4 + @extend_locks on the real grounding

**Beat one — the named handle.** `extend_locks/4` gates every id, flattens the `{id, token}` pairs into ARGV, and runs
the `@extend_locks` script declaring only the `active` set.

```elixir
# echo_mq — EchoMQ.Jobs
# extend_locks/4 re-scores MANY active members under ONE server-clock read.
# Gate every id first (an ill-formed id raises before the wire). Flatten the
# held {id, token} pairs into ARGV after the queue base root + the lease window.
# The declared key is [active]; each per-job key is derived IN-SCRIPT from the
# base root. Answers {:ok, failed} — the ids that could NOT be extended.
def extend_locks(conn, queue, held, lease_ms)
    when is_list(held) and is_integer(lease_ms) and lease_ms > 0 do
  Enum.each(held, fn {id, _token} -> Keyspace.job_key(queue, id) end)   # gate every id

  pairs = Enum.flat_map(held, fn {id, token} -> [id, Integer.to_string(token)] end)
  argv = [Keyspace.queue_key(queue, ""), Integer.to_string(lease_ms) | pairs]

  case Connector.eval(conn, @extend_locks, [Keyspace.queue_key(queue, "active")], argv) do
    {:ok, failed} when is_list(failed) -> {:ok, failed}                 # the ids not re-leased
    other -> other
  end
end
```

**Beat two — the script body.** `@extend_locks` reads the clock once, then walks the ARGV pairs (`id`, then `token`),
re-scoring each matching member and collecting the rest.

```lua
-- the @extend_locks script — one clock read, many members re-scored
-- KEYS[1] is the active set. ARGV[1] is the queue base root, ARGV[2] the lease
-- window in ms; ARGV[3..] is (id, token, id, token, …). The per-job key is
-- DERIVED in-script from the base root — never read out of a data value.
local base = ARGV[1]
local lease = tonumber(ARGV[2])
-- ONE server-clock read shared by every id in the batch.
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
local failed = {}
local i = 3
while i < #ARGV do
  local id = ARGV[i]
  local token = ARGV[i + 1]
  local jk = base .. 'job:' .. id
  -- the fencing check: re-lease only if the row's attempts still matches the
  -- token the caller holds. A moved token (reaped and reclaimed) is NOT extended.
  local att = redis.call('HGET', jk, 'attempts')
  if att and att == token then
    redis.call('ZADD', KEYS[1], now + lease, id)   -- re-score the active member
  else
    table.insert(failed, id)                       -- stale token or gone row — collect it
  end
  i = i + 2
end
return failed
```

The per-job key is built in-script as `base .. 'job:' .. id` from the declared queue base root — never read out of a
hash value. The single key the script declares is the `active` set; the active-set score is the lease, so re-scoring it
is the whole extension.

## Interactive — the batch extension (hero) + single-vs-batch verdicts (main)

- **Hero — extend a batch of leases.** A fixed set of held `{id, token}` pairs over a fixed keyspace, one with a moved
  token (it was reaped and reclaimed). Step the extension to read which members are re-scored at the shared `now + lease`
  and which join the `failed` list. Pure over the fixed dataset.
- **Main — single vs batch.** Pick a job's fate (token matches / token moved / row gone) and a verb (single
  `extend_lock/5` vs batch `extend_locks/4`) to read the two answers: the single verb errors, the batch collects the id
  into `failed`. Pure lookup.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** a batch over a sorted set should read its reference point — the clock —
  once, so every member is scored against the same instant, not a drifting one. `/redis-patterns/queues` teaches
  reliable queues; the one-clock-many-members angle is the near side of this door.
- **The implementation (echo_mq):** `extend_locks/4` runs `@extend_locks`, which reads the server `TIME` once and
  re-scores every `active` member whose token matches, returning the `failed` list — where the single `extend_lock/5`
  re-scores one member and errors on a stale token.

## Recap

Batch lease extension re-scores the many under one clock read: gate every id, walk the held pairs, re-lease each
matching active member at the shared `now + lease`, and return the ids that could not be extended. The single verb
errors on a bad id; the batch collects it — one stale lease does not abort the rest.

## References

### Sources
- Valkey — ZADD (`https://valkey.io/commands/zadd/`) — the active-set re-score that extends a lease (the score is the deadline).
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the run-by-SHA dispatch the batch script runs under.
- Valkey — HSET (`https://valkey.io/commands/hset/`) — the row write whose `attempts` field is the fencing token the script checks.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record EchoMQ is backed by.

### Related in this course
- `/echomq/queue/batches` — Batches, the module this dive belongs to.
- `/echomq/queue/batches/bulk-flows` — compose many flows in one call, fail-closed per flow.
- `/echomq/queue/the-lifecycle/claim-and-the-lease` — the lease the active-set score is, claimed for one job.
- `/echomq/protocol/the-lua-layer/scripts-are-the-protocol` — a transition read in two beats.
- `/redis-patterns/queues` — reliable queues, the near side of the door.
