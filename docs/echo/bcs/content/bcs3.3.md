# BCS · Chapter 3.3 — The state machine in Lua

<show-structure depth="2"/>

The bus learns to move work through states: pending, active, scheduled, dead — four states, four transitions, two pumps, every one of them a single script over the versioned bundle. The rung (`bcs_rung_3_3_check.exs`, committed record ending `PASS 6/6`) gates the surface delta, the happy path, a fenced zombie, a job's second life through the schedule, the morgue, and crash recovery by reap — and the design's quiet center is one integer doing two jobs: the `attempts` counter, incremented inside the claim script, is also the fencing token every other transition verifies.

## Why

A queue that hands out work without leases leaks jobs the first time a consumer dies; a queue with leases but no fencing corrupts data the first time a consumer *pauses* — the classic failure where a process stalls past its lease, the job is handed to another worker, and then the first wakes up and completes stale work over fresh state. Kleppmann's analysis named the cure — a lock service that "generates strictly monotonically increasing tokens" [2], with the resource refusing any token that goes backwards. On a trading desk the stakes are not abstract — a paused consumer finishing a stale fill is a double execution — so the machine is built fenced from its first transition, not patched fenced after its first incident.

## What

**The keys, completing 3.1's map.** Four sorted sets per queue, each earning its score semantics: `pending` stays score-zero forever (3.2's decision honored — lex order is mint order); `active` is scored by *lease deadline*, so the active set is simultaneously the in-flight roster and the expiry index, and crash recovery is one range scan; `schedule` is scored by *run-at*, exactly the separate set 3.2 pre-stated so scores never mix into the lex law; and `dead` is score-zero again, which means the morgue browses newest-first like everything else in this series — the order theorem's third appearance on the bus.

**Claim, the token mint.** The claim script pops the lex-oldest pending id, increments `attempts`, stamps the lease, and returns the job:

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

Three design facts live here. The clock is the *server's*: `TIME` inside the script means leases never see client skew, the engine's frozen-time rule keeps the reading stable for the script's duration [3], and atomic execution guarantees the pop, the increment, and the lease land together or not at all [1]. The token is minted by `HINCRBY` — monotonic per job by construction, which is precisely the property the fencing argument requires. And the job key is *constructed* from a prefix argument, the bundle's one sanctioned exception to declared keys: the id is unknown until popped, and 3.1's co-location law is what makes the construction safe — every key the prefix can produce lives in the same slot as the declared ones, by grammar.

**The fence, performing.** Complete and retry both verify the token before touching anything, and refuse backwards tokens with the part's second wire class. L3 stages the zombie: a consumer holding token 1 watches an impostor's `complete` with token 99 earn `EMQSTALE; the lease holder's work survives the zombie's complete` — the row still active, the real holder unharmed. L2 closes the happy path with the right token: `complete with the right token retires the row -- nothing remains`.

**Two lives, one counter.** L4 runs the full round trip: `retry` parks the job in the schedule (state `scheduled`, pending empty), `promote` moves the due back after the delay, and the next claim hands out *token 2* — the committed line reads `one job, two lives, one counter`, which is the chapter in six words: the same integer that counts the attempts fences each life against the last.

**The morgue and the reaper.** L5 gates the cap: `attempts 2 against max 2 is the morgue: state dead, last_error kept`, with the dead set lex-browsable in mint order. L6 gates the crash story end to end: `a 40 ms lease expires unanswered; reap returns the orphan to pending and the next claim holds token 2 -- crash recovery is one zset scan on the server's clock`. No heartbeat protocol, no consumer registry — the active set's scores already know who is late.

## Who

Consumers, whose contract is three verbs and one discipline: claim, then complete or retry, always carrying the token you were handed and never one from a previous life. Operators, for whom `reap` and `promote` are the two pumps a supervisor will drive on a cadence — Chapter 3.4's loop owns the rhythm; this chapter owns the correctness of each beat. And the postmortem reader, who browses the morgue newest-first and finds `last_error` waiting on every row.

## When

Size the lease above the worst legitimate work time and well below your retry tolerance — the lease is a crash detector, not a deadline for excellence. Choose the retry delay at the caller: the script takes a literal milliseconds argument by design, because backoff *policy* (exponential, jittered, class-dependent) is application judgment and Lua is the wrong home for judgment. Set `max_attempts` per queue class — a fill confirmation and a report render do not deserve the same patience. And read `{:error, :gone}` from complete as the calm answer it is: the row was already retired, usually by a racing twin of yourself, and at-least-once semantics promised you exactly this possibility.

## Where

The bundle lives inside `runtimes/elixir/lib/echo_mq/jobs.ex` — five `Script.new` constants, SHA-pinned, dispatched EVALSHA-first through the appendix's loader, surface gated at exactly the eight verbs. The rung and its committed record sit with the part's others.

## How — the verification half, and the Go side

**Elixir.** The client half of fencing is two lines of Lua and one pattern match per transition:

```lua
local att = redis.call('HGET', KEYS[2], 'attempts')
if att ~= ARGV[2] then return redis.error_reply('EMQSTALE complete token mismatch') end
```

```elixir
{:error, {:server, "EMQSTALE" <> _}} -> {:error, :stale}
```

**Go.** Nothing ports because nothing needs to: the five scripts are the contract, same bytes, same SHA1, same semantics from any client — 3.2's *scripts are vectors for behavior* now covering the whole machine. A Go consumer is a loop around the same EVALSHA calls:

```go
id, payload, token, ok := claim(conn, q, lease)
if !ok { time.Sleep(idle); continue }
if err := work(payload); err != nil {
    retry(conn, q, id, token, backoff(attempt), maxAttempts, err.Error())
} else {
    complete(conn, q, id, token)
}
```

## Decisions

**The server clock owns leases.** Clients never send `now`; `TIME` inside the script is the one clock, skew-immune by construction, with mint time staying history inside the id — the two-clocks law, applied to the bus exactly as the preface promised.

**`attempts` is the fencing token.** One counter, two duties: it counts lives and it fences them, monotonic because only the claim script increments it. A second token field would be a second authority.

**One constructed key, sanctioned by grammar.** Claim builds the job key from a prefix because the id is unknown until popped; every other script declares its keys in full. The exception is safe *because of* the co-location law and exists *only* under it.

**`EMQSTALE` joins `EMQKIND`.** The wire-class family grows by one; every refusal a bundle script issues leads with its class, per D-10's pattern.

**Completion deletes.** A successful job leaves no residue by default — the row is gone, the receipt is the caller's reply. The audit and event trail is Chapter 3.5's lane, where results flow back into the stores as first-class writes, and is pre-stated here so deletion reads as a decision rather than an omission.

## Boundaries

No lease extension yet: a long job either gets a long lease or gets split, and the heartbeat verb is a carried follow-up with its own review gate. Reap caps at one hundred per call and promote at the caller's batch — both pumps need a driver, which is 3.4's loop, so this chapter ships beats without a metronome. Backoff curves, as decided, live above the wire. And the constructed-key exception does not generalize: a script wanting keys it cannot declare and cannot derive from the queue's own prefix is a design smell, not a precedent.

## Companion files

`runtimes/elixir/lib/echo_mq/jobs.ex`; `bcs_rung_3_3_check.exs` and its committed record `bcs_rung_3_3_check.out`.

## References

1. Valkey documentation — Programmability (atomic script execution: "all of the script's effects either have yet to happen or had already happened"): [valkey.io/topics/programmability](https://valkey.io/topics/programmability/)
2. Kleppmann, M. — How to do distributed locking (the fencing-token argument the `attempts` counter satisfies): [martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
3. Valkey documentation — Replication (the frozen-time rule for scripts and effects replication, which make `TIME` inside a write script sound): [valkey.io/topics/replication](https://valkey.io/topics/replication/)
