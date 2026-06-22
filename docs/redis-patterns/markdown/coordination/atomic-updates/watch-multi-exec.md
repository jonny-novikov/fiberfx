# R2.01.1 · WATCH / MULTI / EXEC — optimistic locking

> Dive 1 · route `/redis-patterns/coordination/atomic-updates/watch-multi-exec`
> Source: `content/fundamental/atomic-updates.md.txt` (Pattern 1, *Optimistic Locking with WATCH*).
> Grounding: the generic optimistic-concurrency primitive, contrasted with EchoMQ's single inline Lua EVAL
> (`echo/apps/echo_mq/lib/echo_mq/jobs.ex` · `EchoMQ.Connector.eval/5`). Engine: Valkey.

Watch the key, read it, queue the write, and commit only if it has not changed. A conflict aborts the transaction;
the loser retries.

A read-modify-write reads a value, computes the next one, and writes it back. Between the read and the write,
another client can move the value — and a plain write would overwrite their change. `WATCH` closes that window: it
marks the key, and `EXEC` commits only if nothing touched it since. A change aborts the transaction (`EXEC` returns
nil), and the client runs the whole attempt again.

## Watch, read, queue, exec

A bare `MULTI`/`EXEC` runs its queued commands with nothing interleaved, but its writes are fixed *before* the
transaction opens. For a read-modify-write that is unsafe: a balance read outside the transaction can be stale by
the time the new balance is written. `WATCH` closes the gap. It marks one or more keys, and the following `EXEC`
commits only if none of the watched keys changed since the `WATCH`.

```
WATCH account:123:balance              # mark the key
balance = GET account:123:balance      # read the current value
new_balance = balance - 100            # compute outside the transaction
MULTI                                  # open the transaction
  SET account:123:balance new_balance  # queue the write
EXEC                                   # commit — or nil if the key changed
```

- **WATCH key [key …]** — mark keys for the next transaction. If any is modified before `EXEC`, the transaction is
  discarded.
- **MULTI** — open the transaction. The commands after it are queued, not run yet.
- **EXEC** — commit the queued commands, or return nil when a watched key changed since `WATCH`.
- **UNWATCH** — drop all watches on the connection without running a transaction; used when a guard rejects the
  operation before `MULTI`.

A discarded transaction is a conflict, not a failure. The fix is to read again and retry.

## The retry loop, bounded

A nil from `EXEC` is a signal to try again with a fresh read. Wrap the whole attempt — `WATCH`, the read, the
guard, `MULTI`, `EXEC` — in a loop with a retry ceiling. On a nil, loop; on a non-nil result, the write committed
and the loop returns. The ceiling turns a pathological live-lock under a hot key into a bounded, surfaced conflict.

```
max_retries = 5
for attempt in range(max_retries):
    WATCH account:123:balance
    balance = GET account:123:balance
    if balance < amount:
        UNWATCH                        # release the watch; no transaction
        raise InsufficientFunds()
    new_balance = balance - amount
    MULTI
      SET account:123:balance new_balance
    result = EXEC
    if result is not None:
        return                         # committed
    # EXEC returned nil — a watched key changed; retry
raise TooManyRetries()
```

The guard reads inside the watched window and calls `UNWATCH` before raising, so a rejected withdrawal leaves no
watch dangling on the connection. The ceiling bounds the cost: each retry is one more read and one more round trip,
so an unbounded loop under a hot key would spin. A bounded loop converts that into a conflict the caller can report.

## Watching more than one key

`WATCH` takes several keys, and `EXEC` discards if any one of them changed. That makes a multi-key
read-modify-write atomic: confirm stock and the order status together, then decrement stock and confirm the order
in one transaction — or commit nothing.

```
WATCH inventory:sku123 order:456:status
stock = GET inventory:sku123
if stock < quantity:
    UNWATCH
    raise OutOfStock()
MULTI
  DECRBY inventory:sku123 quantity
  SET order:456:status "confirmed"
EXEC
```

In a cluster every watched key must live on the same hash slot, because a transaction runs on a single node. The
keys are co-located with a hash tag — `inventory:{sku123}` and `order:{sku123}:456` share the `{sku123}` slot.
Colocation is its own module later in this chapter; here the rule is the boundary: a multi-key WATCH transaction is
a single-slot operation.

## Optimistic, never held — and what EchoMQ chose instead

`WATCH` is optimistic. It is built for the rare conflict: take no lock, and pay only when a conflict actually
happens — with a retry. A pessimistic lock is the opposite trade: acquire a lock, do the work, release it, and
serialize every caller whether or not a conflict would have occurred. Optimistic concurrency wins when contention
is low and the critical section is short — the common case for a single-key or single-slot read-modify-write. Under
a hot key the retries pile up, which is the signal to reach for a Lua script, the next dive, where the whole
read-modify-write runs on the server with no retry loop.

EchoMQ takes the script answer for every transition. It does not run a watched transaction with a retry loop.
`EchoMQ.Jobs.enqueue/4` runs the inline `@enqueue` script through `EchoMQ.Connector.eval/5`, and the script holds
the server for its whole duration, so no other client interleaves and there is nothing to retry. The whole
read-branch-write is one round trip.

### Bridge — the pattern, and its echo_mq application

| The pattern | Its EchoMQ application |
|---|---|
| WATCH/MULTI/EXEC is the read-modify-write where the logic lives in the client: watch the key, compute, and commit only if it has not changed. A conflict is a retry, never a held lock. | The transition path takes the other atomic-RMW tool. `enqueue/4` runs the inline `@enqueue` script — one EVAL via `EchoMQ.Connector.eval/5`, no watch and no retry loop, because the script itself admits no interleaving. |

The take: `WATCH` trades a retry for never holding a lock — cheap when conflicts are rare, and a script when they
are not.

### Door — the EchoMQ course

This dive cites one contrast — EchoMQ's single-script transition — to place `WATCH` among the atomic-RMW tools.
The full transition bundle and the EVALSHA dispatch are the subject of the dedicated **EchoMQ course** at
`/echomq`. The script tool itself is the next dive, R2.01.2 · Lua for logic.

## References

### Sources

- [Redis — Transactions](https://redis.io/docs/latest/develop/interact/transactions/) — MULTI/EXEC, and how WATCH
  adds optimistic locking to a transaction.
- [Valkey — WATCH](https://valkey.io/commands/watch/) — mark keys so EXEC discards if any of them is modified
  first.
- [Redis — MULTI](https://redis.io/commands/multi/) — open a transaction; following commands are queued, not run.
- [Redis — EXEC](https://redis.io/commands/exec/) — commit the queued commands, or return nil when a watched key
  changed.

### Related in this course

- R2.01 · Atomic updates — the module hub.
- R2.01.2 · Lua for logic — the script that holds no retry loop.
- R2 · Coordination — the chapter.
- `/echomq` — the EchoMQ protocol the single-script transition belongs to.
- `/elixir` — the functional-Elixir & OTP craft behind the echo umbrella.
