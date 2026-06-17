# B3.3.2 · The Fencing Token

> Dive 2 of B3.3 · route `/bcs/bus/state-machine/the-fencing-token` · teaches `content/bcs3.3.md` (the fence,
> performing; two lives, one counter; the verification half) · reads gates `L3` and `L4` of
> `bcs_rung_3_3_check.out`.

One job, two lives, one counter.

L3 stages the zombie: a consumer holding token 1 watches an impostor's `complete` with token 99 earn
`EMQSTALE; the lease holder's work survives the zombie's complete` — the row still active, the real holder
unharmed. L4 runs the full round trip: retry parks the job in the schedule, promote moves the due back to
pending, and the next claim hands token 2 — one job, two lives, one counter. The same integer that counts the
attempts fences each life against the last.

## §1 The transcript

This dive reads L3 and L4 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_3_check.out`, verbatim):

```
L3 fence ok -- a stale token is refused on the wire: EMQSTALE; the lease holder's work survives the zombie's complete
L4 schedule ok -- retry parks the job in the schedule, promote moves the due back to pending, and the next claim hands token 2 -- one job, two lives, one counter
```

## §2 The fence, performing

A queue that hands out work without leases leaks jobs the first time a consumer dies; a queue with leases but no
fencing corrupts data the first time a consumer *pauses* — the classic failure where a process stalls past its
lease, the job is handed to another worker, and then the first wakes up and completes stale work over fresh
state. Kleppmann's analysis named the cure — a lock service that "generates strictly monotonically increasing
tokens", with the resource refusing any token that goes backwards. The `attempts` counter is that token:
monotonic per job because only the claim script increments it, and a second token field would be a second
authority.

Complete and retry both verify the token before touching anything, and refuse backwards tokens with the part's
second wire class. The client half of fencing is two lines of Lua and one pattern match per transition (source:
`content/bcs3.3.md`, verbatim):

```lua
local att = redis.call('HGET', KEYS[2], 'attempts')
if att ~= ARGV[2] then return redis.error_reply('EMQSTALE complete token mismatch') end
```

```elixir
{:error, {:server, "EMQSTALE" <> _}} -> {:error, :stale}
```

`EMQSTALE` joins `EMQKIND`: the wire-class family grows by one, and every refusal a bundle script issues leads
with its class. And read `{:error, :gone}` from complete as the calm answer it is: the row was already retired,
usually by a racing twin of yourself, and at-least-once semantics promised exactly this possibility.

## §3 Two lives, one counter

L4 runs the full round trip: `retry` parks the job in the schedule (state `scheduled`, pending empty), `promote`
moves the due back after the delay, and the next claim hands out *token 2* — the committed line reads `one job,
two lives, one counter`, which is the chapter in six words: the same integer that counts the attempts fences
each life against the last.

Choose the retry delay at the caller: the script takes a literal milliseconds argument by design, because
backoff *policy* (exponential, jittered, class-dependent) is application judgment and Lua is the wrong home for
judgment.

## §4 The Go side

Nothing ports because nothing needs to: the five scripts are the contract, same bytes, same SHA1, same semantics
from any client. A Go consumer is a loop around the same EVALSHA calls (source: `content/bcs3.3.md`):

```go
id, payload, token, ok := claim(conn, q, lease)
if !ok { time.Sleep(idle); continue }
if err := work(payload); err != nil {
    retry(conn, q, id, token, backoff(attempt), maxAttempts, err.Error())
} else {
    complete(conn, q, id, token)
}
```

## References

Sources:

- Kleppmann, M. — How to do distributed locking —
  https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html (the fencing-token argument the
  `attempts` counter satisfies: strictly monotonically increasing tokens, the resource refusing backwards ones)
- Valkey — Programmability — https://valkey.io/topics/programmability/ (atomic script execution: the verify and
  the write land together or not at all)
- Valkey — Replication — https://valkey.io/topics/replication/ (scripts replicate by effects; the frozen-time
  rule)

Related:

- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/bus/fence-and-keyspace — B3.1 · The Fence and the Keyspace, the wire-class pattern EMQSTALE extends
- /bcs/elixir-core/otp-application — B2.1 · The OTP Application, the supervision frame around crashing consumers
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate patterns under the bus
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus/state-machine/claim-the-token-mint` · next
`/bcs/bus/state-machine/the-morgue-and-the-reaper`.
