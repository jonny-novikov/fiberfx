# R2.01.3 · Shadow key + bulk — swap whole, or admit whole

> Dive 3 · route `/redis-patterns/coordination/atomic-updates/shadow-key-bulk`
> Source: `content/fundamental/atomic-updates.md.txt` (Pattern 3, *Shadow Key + RENAME*, plus the bulk path).
> Grounding: EchoMQ's bulk admission — `EchoMQ.Jobs.enqueue_many/3` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:100`):
> `SCRIPT LOAD` once, then pipelined `EVALSHA` per item via `EchoMQ.Connector.pipeline/3`. Engine: Valkey.

Build the new value in a temporary key, then one atomic `RENAME`. A read returns the old complete value or the new
complete value — never a half-built one. The batch sibling admits many items in one wire flush.

A value written field by field is readable between the writes: a read landing mid-update returns two new fields and
one old one. The shadow key removes that window — assemble the value in `tmp:key`, off to the side, then swap it in
with one atomic step.

## The partial-update window

A value built field by field is readable between the writes. Update three fields in place — `HSET … field1`,
`HSET … field2`, `HSET … field3` — and a read landing after the second write returns two new fields and one old
one. That two-of-three state is never a value the application meant to publish; it is an artifact of the write being
three commands instead of one. The more fields, the wider the window.

The shadow key closes it. Build the whole new value in a temporary key, off to the side, which no reader of the
live key reads; then make the temporary key the live key in a single atomic step. A read either runs before
the swap and returns the old complete value, or after it and returns the new complete value. There is no instant at
which the live key holds a mix of the two.

- **tmp:key** — the shadow key. The new value is assembled here; no reader of the live key reads it.
- **the window** — the span between the first and last in-place write, where a read returns a partial value.
- **RENAME tmp final** — the atomic swap. The temporary key becomes the live key in one indivisible step.
- **complete value** — old-complete before the swap, new-complete after it; the live key never holds a mix.

## Build aside, then RENAME

The move is two phases: assemble in `tmp:key`, then `RENAME tmp:key final:key`. The build writes touch the
temporary key, which no reader of the live key reads, so the in-progress state is never observable. The swap is
the only command that touches the live key, and it is indivisible.

```
# Phase 1 — build the new value in a temporary key, as many writes as it takes
DEL tmp:user:123:cache
HSET tmp:user:123:cache field1 value1
HSET tmp:user:123:cache field2 value2
HSET tmp:user:123:cache field3 value3

# Phase 2 — atomic swap: the temporary key becomes the live key
RENAME tmp:user:123:cache user:123:cache
```

A read of `user:123:cache` returns the old complete value or the new complete value, never a partial one.

`RENAME` carries the source key's time-to-live to the destination. If `tmp:key` was built with no expiry but
`final:key` needs one, set it after the swap. On Redis 6.2 and later, `COPY … REPLACE` is the alternative when the
temporary key should survive the swap. Both keys of a `RENAME` or `COPY` must live in the same cluster slot — a
cross-slot rename is rejected. Hash tags co-locate them, the same colocation requirement multi-key WATCH carries.

## Bulk via the script cache: EchoMQ's atomic batch admission

The whole-value swap has a batch sibling: apply many independent writes in one wire flush. The classic Redis form
is `MULTI`/`EXEC` — queue every command, then run the queue with nothing interleaved. EchoMQ takes a sharper form
for bulk admission: one `SCRIPT LOAD` to prime the script cache, then a pipelined `EVALSHA` per item, so each
admission is the same single atomic `@enqueue` script and the whole list rides one wire flush.

`EchoMQ.Jobs.enqueue_many/3` (jobs.ex:100) loads the `@enqueue` source once, builds one `EVALSHA` command per
`{id, payload}` pair, and runs the list through `EchoMQ.Connector.pipeline/3`. The per-item verdicts return in
input order:

```elixir
# enqueue_many/3 (echo_mq/lib/echo_mq/jobs.ex:100) — SCRIPT LOAD once, then pipeline EVALSHA per item.
def enqueue_many(conn, queue, pairs) when is_list(pairs) do
  {:ok, _} = Connector.command(conn, ["SCRIPT", "LOAD", @enqueue.source])

  cmds =
    for {id, payload} <- pairs do
      ["EVALSHA", @enqueue.sha, "2",
       Keyspace.job_key(queue, id), Keyspace.queue_key(queue, "pending"),
       id, payload]
    end

  with {:ok, results} <- Connector.pipeline(conn, cmds) do
    {:ok, Enum.map(results, fn
      1 -> :enqueued
      0 -> :duplicate
      {:error_reply, "EMQKIND" <> _} -> {:error, :kind}
    end)}
  end
end
```

Each item is the same atomic `@enqueue` script — kind check, `EXISTS` duplicate refusal, `HSET` the row, `ZADD`
pending — so the per-item verdicts (`:enqueued`, `:duplicate`, `{:error, :kind}`) line up with the input. Every key
shares the queue's `{q}` hashtag, so every pipelined `EVALSHA` is single-slot legal. The committed connector record
holds `script_loads=1` and pipelined `EVALSHA` at `161192` ops/s (`docs/echo/bcs/content/bcsA.md`).

### Bridge — the pattern, and its echo_mq application

| The pattern | Its EchoMQ application |
|---|---|
| Commit the whole value, or the whole set of writes, in one step. `RENAME` swaps one value atomically; the script cache pipelines a batch in one wire flush. Both refuse the partial state. | `EchoMQ.Jobs.enqueue_many/3` does `SCRIPT LOAD` once then pipelines `EVALSHA` per item (`echo_mq/lib/echo_mq/jobs.ex`) — each item the same atomic `@enqueue` script, per-item verdicts in input order. |

The take: swap one whole value with `RENAME`, or admit a whole batch with `SCRIPT LOAD` + pipelined `EVALSHA` — a
reader never returns part of a value, a consumer never returns part of a batch.

### Door — the EchoMQ course

The full pipeline model — the `SCRIPT LOAD` preflight, the EVALSHA/NOSCRIPT dispatch, the per-item verdict mapping,
and the `echomq:2.0.0` version fence — is the dedicated **EchoMQ course** at `/echomq`. This dive cites one bulk
admission path as proof the pattern is real; the depth is the next course.

## References

### Sources

- [Valkey — RENAME](https://valkey.io/commands/rename/) — atomically rename a key to a destination, carrying the
  source TTL; the whole-value swap.
- [Redis — Transactions](https://redis.io/docs/latest/develop/interact/transactions/) — `MULTI`/`EXEC` queue a
  batch and run it all-or-none with nothing interleaved.
- [Valkey — EVALSHA](https://valkey.io/commands/evalsha/) — run a cached script by its SHA1; the pipelined call the
  bulk admission flushes per item.
- [Valkey — SET](https://valkey.io/commands/set/) — write a value with options; the per-field write the shadow
  build replaces with one atomic swap.

### Related in this course

- R2.01 · Atomic updates — the module hub.
- R2.01.2 · Lua for logic — the sibling RMW tool, the script as the lock.
- R2 · Coordination — the chapter.
- `/echomq` — the EchoMQ protocol, where the bulk pipeline is taught in depth.
- `/elixir` — the functional-Elixir & OTP craft behind the echo umbrella.
