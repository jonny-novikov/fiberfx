# B3.3.1 · Claim, the Token Mint

> Dive 1 of B3.3 · route `/bcs/bus/state-machine/claim-the-token-mint` · teaches `content/bcs3.3.md` (the keys,
> completing 3.1's map; claim, the token mint) · reads gates `L1` and `L2` of `bcs_rung_3_3_check.out`.

The oldest job, a server-clock lease, and token 1.

L1 fixes the machine's surface: claim, complete, retry, promote, reap join enqueue, browse, pending_size — five
new verbs, every transition one script. L2 closes the happy path: claim hands out the oldest job with a
server-clock lease and fencing token 1; complete with the right token retires the row — nothing remains. The
script that opens every life is ten lines of Lua, and three design decisions live inside it.

## §1 The transcript

This dive reads L1 and L2 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_3_check.out`, verbatim):

```
L1 surface ok -- the machine's surface: claim, complete, retry, promote, reap join enqueue, browse, pending_size -- five new verbs, every transition one script
L2 happy ok -- claim hands out the oldest job with a server-clock lease and fencing token 1; complete with the right token retires the row -- nothing remains
```

## §2 The keys, completing 3.1's map

Four sorted sets per queue, each earning its score semantics:

- **pending** stays score-zero forever — lex order is mint order, the decision **B3.2 · Jobs Are Entities**
  recorded, honored here.
- **active** is scored by *lease deadline*, so the active set is simultaneously the in-flight roster and the
  expiry index, and crash recovery is one range scan.
- **schedule** is scored by *run-at* — exactly the separate set 3.2 pre-stated, so scores never mix into the
  lex law.
- **dead** is score-zero again, which means the morgue browses newest-first like everything else in this
  series — the order theorem's third appearance on the bus.

## §3 Claim, the token mint

The claim script pops the lex-oldest pending id, increments `attempts`, stamps the lease, and returns the job
(source: `content/bcs3.3.md`, quoted whole):

```lua
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

Three design facts live here.

1. **The clock is the server's.** `TIME` inside the script means leases never see client skew, the engine's
   frozen-time rule keeps the reading stable for the script's duration, and atomic execution guarantees the pop,
   the increment, and the lease land together or not at all.
2. **The token is minted by `HINCRBY`** — monotonic per job by construction, which is precisely the property the
   fencing argument requires.
3. **The job key is *constructed* from a prefix argument** — the bundle's one sanctioned exception to declared
   keys: the id is unknown until popped, and 3.1's co-location law is what makes the construction safe — every
   key the prefix can produce lives in the same slot as the declared ones, by grammar.

## §4 Where the bundle lives

The bundle lives inside `runtimes/elixir/lib/echo_mq/jobs.ex` — five `Script.new` constants, SHA-pinned,
dispatched EVALSHA-first through the appendix's loader, surface gated at exactly the eight verbs. Size the lease
above the worst legitimate work time and well below your retry tolerance — the lease is a crash detector, not a
deadline for excellence.

## References

Sources:

- Valkey — Programmability — https://valkey.io/topics/programmability/ (atomic script execution: "all of the
  script's effects either have yet to happen or had already happened"; declared keys)
- Kleppmann, M. — How to do distributed locking —
  https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html (the monotonic-token property the
  `HINCRBY` mint satisfies)
- Valkey — Replication — https://valkey.io/topics/replication/ (time frozen during a script, which makes `TIME`
  inside a write script sound; scripts replicate by effects)

Related:

- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/bus/fence-and-keyspace — B3.1 · The Fence and the Keyspace, the co-location law that sanctions the
  constructed key
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the score-zero decision the claim's pop honors
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate patterns under the bus
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus/state-machine` · next `/bcs/bus/state-machine/the-fencing-token`.
