# R7.1.1 — System of record

> Route: `/redis-patterns/data-modeling/primary-database/system-of-record` · dive 1 of the
> **Redis as a primary database** module. Identity: the BCS contract sheet, redis-red accent. Grounded in the real
> as-built echo data layer — `echo/apps/echo_mq` and `echo/apps/codemojex` — never invented, never a `.out`
> transcript. The engine is Valkey.

When Redis is the *authoritative* store, the row is the record — there is no truth elsewhere to fall back on. A
cache holds a copy of a value that lives somewhere durable; a system of record holds the value itself. The
distinction is not about the data structure but about where the truth is: a primary-database datum is one whose
state has **no second home**. And it is a judgment made **per datum**, not a global switch.

## The row is the record

EchoMQ's job is the worked case. A job's identity is a branded id under the `JOB` namespace; its row is a hash at
the job key — and that hash is the job's only canonical state. There is no shadow copy in Postgres that the hash
mirrors. The hash carries three fields, written once on admission and mutated in place for the life of the job:

- `state` — `pending` · `active` · `scheduled` · `dead`.
- `attempts` — the integer fence, incremented on each delivery so a redelivery is detectable.
- `payload` — the job body, opaque to the bus.

The moduledoc of `EchoMQ.Jobs` states the shape directly (verbatim, `echo/apps/echo_mq/lib/echo_mq/jobs.ex`):

> *"Jobs are entities. A job's identity is a branded id under the `JOB` namespace; its row is a hash at the job
> key; the pending set is a same-score sorted set whose members are the ids themselves … Enqueue is one idempotent
> script: kind policy, duplicate refusal, row write, and pending insertion happen on the server in one atomic
> step."*

The write is a single inline script — `@enqueue`, run server-side, so admission is one atomic step rather than a
read-then-write race (verbatim, `jobs.ex`):

```lua
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

The script refuses a non-`JOB` id, refuses a duplicate (the existing key wins), then writes the row and inserts the
id into the pending set. After that, `claim` flips `state` to `active`, `complete` deletes the row, `retry`
increments `attempts` and re-parks the id — every one of those operations mutates **the same hash at the same
key**. The job's truth never leaves Valkey, so there is nothing to keep in sync and nothing to fall back to.

The key itself is built by `EchoMQ.Keyspace`, which gates the branded id before it is used (verbatim,
`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`):

```elixir
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])

def job_key(queue, branded) when is_binary(branded) do
  if EchoData.BrandedId.valid?(branded) do
    queue_key(queue, "job:") <> branded
  else
    raise ArgumentError, "job_key requires a valid branded id"
  end
end
```

The record's address is `emq:{q}:job:<JOB-branded-id>` — and an invalid id raises before any key is touched, so a
malformed identity never reaches the store.

## The per-datum decision

"Redis as a primary database" is not all-or-nothing for an application. codemojex — the live consumer of this stack
— **splits**. It keeps operational state in Valkey and money in Postgres, and the split runs straight through one
function.

The game's competitive state lives in Valkey, `cm:*`. The leaderboard is one sorted set per game,
`cm:<game>:board`, written by `Codemojex.Board` ("The competitive state, in Valkey"). A player's locked positions
are a per-player hash for the round, `cm:<round>:lock:<player>`, written by `Codemojex.Locks` ("Position locking, in
Valkey"). These are hot, operational, and tolerant of a roughly one-second loss bound — exactly what the store is
the right primary for.

Money lives in Postgres. `Codemojex.Wallet` holds the balances and mutates them inside database transactions; its
moduledoc is the contrast in one sentence (verbatim, `echo/apps/codemojex/lib/codemojex/wallet.ex`):

> *"The balances, on Postgres, mutated inside database transactions. A mutation locks the player row
> (`SELECT … FOR UPDATE`), checks the non-negative invariant, writes the new balance, and inserts the paired ledger
> row — all or nothing."*

`Codemojex.Ledger` is the append-only record of every balance change, "written by `Codemojex.Wallet` inside the
same database transaction as the balance update — so … no balance ever moved without a paired record." A balance is
the wrong datum for a one-second loss bound: it needs the non-negative invariant, the row lock, and the
all-or-nothing transaction. That truth has its home in Postgres.

The play path crosses the line in one call. `Codemojex.Guesses.submit/3` charges the guess through the wallet
(Postgres, transactional) and then enqueues the work as a branded `JOB` on the bus (Valkey). Its moduledoc names
the principle: *"The game's mutable state is read from the system of record; the cache is trusted only for the
immutable secret on the scoring path."* Same function, two stores, chosen per datum on loss-tolerance and the need
for ACID.

## The Oban trade

Putting the job's truth in Valkey buys an in-memory hot path and a durability dial — and it costs the coupling Oban
has. Oban keeps its jobs in the **same Postgres** as the application's data, so a job and the business row it
concerns commit in **one transaction**: enqueue-the-job and update-the-row either both happen or neither does.

EchoMQ separates the bus (the job hash in Valkey) from the store, so it cannot make that single-transaction
guarantee — the enqueue and a Postgres write are two operations, not one atomic step. What it gets in return is the
in-memory hot path (every dequeue and ack touches the store, not a database) and the durability dial: how much loss
the operator tolerates is a tuning choice, not a fixed cost paid on every write. State the trade plainly: Echo gives
up Oban's transactional coupling and buys the hot path and the dial. It does not have Oban's coupling; that is the
deliberate price.

The dial itself — and the persistence posture that keeps the job hash durable enough to be a record of truth — is
the subject of the next two dives and the `/bcs/persistence` door below.

## References

### Sources

- Valkey — *HSET* — `https://valkey.io/commands/hset/` — set fields on a hash; the job row is written and mutated as
  one hash.
- Valkey — *HGETALL* — `https://valkey.io/commands/hgetall/` — read a hash's fields; how the record is read back
  whole.
- Valkey — *Persistence* — `https://valkey.io/topics/persistence/` — AOF and RDB; the durability a primary store
  depends on.
- Valkey — *Cluster specification* — `https://valkey.io/topics/cluster-spec/` — the `{q}` hash tag forcing a
  queue's keys onto one of the 16384 slots.

### Related in this course

- `/redis-patterns/data-modeling/primary-database` — R7.1 · the module hub: Redis as a primary database.
- `/redis-patterns/data-modeling/primary-database/noeviction` — R7.1.2 · why a record of truth runs `noeviction`.
- `/redis-patterns/data-modeling/primary-database/persistence` — R7.1.3 · RDB vs AOF and the loss bound.
- `/bcs/persistence` — B5 · the durability dial and the Oban trade in depth.
- `/bcs/store` — B4 · EchoStore, the near-cache that is *not* a system of record.
