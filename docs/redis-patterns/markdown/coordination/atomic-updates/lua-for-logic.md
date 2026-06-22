# R2.01.2 · Lua scripts for atomic logic — the script is the lock

> Dive 2 · route `/redis-patterns/coordination/atomic-updates/lua-for-logic`
> Source: `content/fundamental/atomic-updates.md.txt` (Pattern 2, *Lua Scripts for Atomic Logic*).
> Grounding: the real branching transition scripts — `echo/apps/echo_mq/lib/echo_mq/jobs.ex` `@claim` (jobs.ex:126),
> `@complete` (jobs.ex:139), `@retry` (jobs.ex:173); dispatched EVALSHA-first by `EchoMQ.Connector.eval/5`
> (`echo/apps/echo_wire/lib/echo_mq/connector.ex:63`). Committed figure `docs/echo/bcs/content/bcs3.3.md`.
> Engine: Valkey.

A Lua script runs to the end with nothing else interleaved. A multi-step conditional with side effects becomes one
indivisible move.

Redis runs a script on a single thread to completion before serving the next command on that connection. So a read,
a branch on the value, and several writes are one atomic step — no second client lands a command in the middle.
This is how EchoMQ moves every job between states: one inline Lua script per transition.

## One script, no window

A WATCH/MULTI/EXEC transaction reads the value outside the server and branches on the client; a Lua script moves
the whole read-branch-write *into* the server. Redis evaluates a script on a single thread to completion before the
next command on that connection runs, so a script that reads a key, branches on its value, and writes several keys
is one atomic step. No other command lands in the middle.

That is the window a non-atomic sequence cannot close. A bare `GET`, then a branch, then a `SET` leaves a gap:
between the read and the write, another client can read the same key and act on the same stale value. Both pass the
check; both write; one update is lost — or, in a queue, one job is picked twice. The script removes the gap because
there is no point inside it for another command to run.

- **EVAL script numkeys k… a…** — run a Lua script atomically. `KEYS` are the keys it touches, `ARGV` the arguments.
- **redis.call(…)** — issue a Redis command from inside the script. Every call runs within the one atomic
  execution.
- **atomic step** — the whole script runs to the end with no other command interleaved on the server.
- **the window** — the gap a non-atomic `GET … SET` leaves, where a second client can act on a value about to
  change.

## Compare-and-set, then a conditional with side effects

The smallest atomic conditional is compare-and-set: write only if the current value still matches what was read.
The `GET`, the comparison, and the `SET` are one operation, so the set is conditioned on a value still current at
the instant it is written — the property a separate read and write cannot promise.

```lua
-- CAS: set only if the current value still matches the expected one
if redis.call('GET', KEYS[1]) == ARGV[1] then
  redis.call('SET', KEYS[1], ARGV[2])
  return 1
end
return 0
```

The pattern scales past a single key. A script can read a field, branch on it, write the field, and append a log
entry — all atomic, so any read returns either the whole before-state or the whole after-state, never a
half-applied one.

## How EchoMQ's transitions are single Lua scripts

This is the chapter's central bridge. EchoMQ moves a job between states with a Lua script, because moving a job
*is* a multi-step conditional with side effects: pop the source set, increment a counter, stamp a lease, return the
job. `EchoMQ.Jobs.claim/3` runs the `@claim` script (jobs.ex:126) through `EchoMQ.Connector.eval/5` — `ZPOPMIN` the
oldest pending id, `HINCRBY` the attempts counter (the fencing token), set the row active, and `ZADD` the lease on
the server clock, all in one atomic step:

```lua
-- @claim (echo_mq/lib/echo_mq/jobs.ex:126) — pop, fence, lease, return; one atomic step.
local popped = redis.call('ZPOPMIN', KEYS[1])
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id
local att = redis.call('HINCRBY', jk, 'attempts', 1)
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
return {id, redis.call('HGET', jk, 'payload'), att}
```

Three facts live here. The clock is the *server's* — `redis.call('TIME')` inside the script, so leases never see
client skew. The token is minted by `HINCRBY` — monotone per job by construction, the property the fencing argument
requires. And the keys are declared in KEYS (`KEYS[1]` pending, `KEYS[2]` active); the job key is built from the
prefix argument, the one sanctioned exception, safe because every key the prefix can produce shares the queue's
hashtag and lands on one slot.

The other transitions are the same shape and verify that token before they touch anything. `@complete` (jobs.ex:139)
refuses a stale token, then retires the row:

```lua
-- @complete (echo_mq/lib/echo_mq/jobs.ex:139) — only the current token holder may retire the row.
local att = redis.call('HGET', KEYS[2], 'attempts')
if not att then return 0 end
if att ~= ARGV[2] then
  return redis.error_reply('EMQSTALE complete token mismatch')
end
```

`@retry` (jobs.ex:173) carries the same `EMQSTALE retry token mismatch` fence and dead-letters a job past
`max_attempts`. The committed manuscript record reads the law in six words: `one job, two lives, one counter`
(`docs/echo/bcs/content/bcs3.3.md`) — the same integer that counts the attempts fences each life against the last,
and a zombie consumer's stale `complete` earns `EMQSTALE; the lease holder's work survives the zombie's complete`.

## EVALSHA, NOSCRIPT, SCRIPT LOAD — the script cache

Sending a kilobyte of Lua on every call would waste bandwidth. Redis caches scripts by the SHA1 of their body, so a
client sends the full source once and a 40-byte hash thereafter. `EVALSHA` runs a cached script; if the script is
not in the cache, the server replies `NOSCRIPT`, the client retries with `SCRIPT LOAD` (which caches the body) and
re-issues the `EVALSHA`, and every later call hits the cache.

`EchoMQ.Connector.eval/5` (connector.ex:63) is that dispatch verbatim: `EVALSHA` first, and on a `NOSCRIPT` error,
`SCRIPT LOAD` then re-run by SHA. The SHA1 is precomputed once at `EchoMQ.Script.new/2`. The committed connector
record shows the result holding across a busy session — `script_loads=1`, exactly one NOSCRIPT load before EVALSHA
serves from cache, with pipelined EVALSHA at `161192` ops/s (`docs/echo/bcs/content/bcsA.md`).

### Bridge — the pattern, and its echo_mq application

| The pattern | Its EchoMQ application |
|---|---|
| A Lua script runs atomically: a read, a branch, and several writes with no command interleaved. One of three Redis read-modify-write tools, alongside WATCH/MULTI/EXEC and the shadow-key swap. | `@claim`, `@complete`, `@retry` (`echo_mq/lib/echo_mq/jobs.ex`) are the real job transitions — each one inline Lua script, each atomic, the `attempts` counter the fencing token, so no two workers pick the same job. |

The take: when the logic is conditional and touches several keys, the script is the lock — the check and the writes
run with no command between them.

### Door — the EchoMQ course

EchoMQ's full Lua bundle — every transition script, the EVALSHA/NOSCRIPT dispatch internals, and the governance
that keeps the transitions immutable — is the dedicated **EchoMQ course** at `/echomq`. This dive cites three real
transitions as proof the pattern is real; the depth is the next course.

## References

### Sources

- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) —
  `EVAL`/`EVALSHA`, atomic execution, and the script cache.
- [Valkey — EVALSHA](https://valkey.io/commands/evalsha/) — run a cached script by its SHA1; replies `NOSCRIPT`
  when the script is not cached.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic script execution: the basis of
  the single-script transition.
- [Redis — Transactions](https://redis.io/docs/latest/develop/interact/transactions/) — the WATCH/MULTI/EXEC
  alternative a script replaces on the transition path.

### Related in this course

- R2.01 · Atomic updates — the module hub.
- R2.01.1 · WATCH / MULTI / EXEC — the sibling read-modify-write tool, with a retry loop.
- R2.01.3 · Shadow key + bulk — atomic swap, atomic batch admission.
- R2 · Coordination — the chapter.
- `/echomq` — the EchoMQ protocol, where the transition bundle is taught in depth.
- `/elixir` — the functional-Elixir & OTP craft behind the echo umbrella.
