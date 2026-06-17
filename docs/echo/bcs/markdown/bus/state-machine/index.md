# B3.3 · The State Machine in Lua

> Module hub · route `/bcs/bus/state-machine` · teaches `content/bcs3.3.md` · the rung is
> `bcs_rung_3_3_check.exs`, its committed record `bcs_rung_3_3_check.out` closes `PASS 6/6`.

Four states, four transitions, two pumps — every one a single script.

The bus learns to move work through states: pending, active, scheduled, dead — four states, four transitions,
two pumps, every one of them a single script over the versioned bundle. The rung gates the surface delta, the
happy path, a fenced zombie, a job's second life through the schedule, the morgue, and crash recovery by reap —
and the design's quiet center is one integer doing two jobs: the `attempts` counter, incremented inside the
claim script, is also the fencing token every other transition verifies.

The chapter is `content/bcs3.3.md`; the rung behind it is `bcs_rung_3_3_check.exs`, and its committed transcript
closes `PASS 6/6`. The surface, the happy path, the fence, the schedule, the morgue, the reap — six gates, each
asserted on stage.

## §1 Fenced from the first transition

A queue that hands out work without leases leaks jobs the first time a consumer dies; a queue with leases but no
fencing corrupts data the first time a consumer *pauses* — the classic failure where a process stalls past its
lease, the job is handed to another worker, and then the first wakes up and completes stale work over fresh
state. Kleppmann's analysis named the cure — a lock service that "generates strictly monotonically increasing
tokens", with the resource refusing any token that goes backwards. On a trading desk the stakes are not
abstract — a paused consumer finishing a stale fill is a double execution — so the machine is built fenced from
its first transition, not patched fenced after its first incident.

The chapter's five decisions:

- **The server clock owns leases.** Clients never send `now`; `TIME` inside the script is the one clock,
  skew-immune by construction, with mint time staying history inside the id — the two-clocks law, applied to the
  bus exactly as the preface promised.
- **`attempts` is the fencing token.** One counter, two duties: it counts lives and it fences them, monotonic
  because only the claim script increments it. A second token field would be a second authority.
- **One constructed key, sanctioned by grammar.** Claim builds the job key from a prefix because the id is
  unknown until popped; every other script declares its keys in full. The exception is safe *because of* the
  co-location law and exists *only* under it.
- **`EMQSTALE` joins `EMQKIND`.** The wire-class family grows by one; every refusal a bundle script issues leads
  with its class.
- **Completion deletes.** A successful job leaves no residue by default — the row is gone, the receipt is the
  caller's reply. The audit and event trail is the lane the manuscript assigns to **B3.5 · Bus Meets Stores**,
  pre-stated here so deletion reads as a decision rather than an omission.

## §2 The proof

The full committed transcript, verbatim (source: `content/echo_data/runtimes/elixir/bcs_rung_3_3_check.out`):

```
L1 surface ok -- the machine's surface: claim, complete, retry, promote, reap join enqueue, browse, pending_size -- five new verbs, every transition one script
L2 happy ok -- claim hands out the oldest job with a server-clock lease and fencing token 1; complete with the right token retires the row -- nothing remains
L3 fence ok -- a stale token is refused on the wire: EMQSTALE; the lease holder's work survives the zombie's complete
L4 schedule ok -- retry parks the job in the schedule, promote moves the due back to pending, and the next claim hands token 2 -- one job, two lives, one counter
L5 dead ok -- attempts 2 against max 2 is the morgue: state dead, last_error kept, and the dead set browses in mint order like everything else
L6 reap ok -- a 40 ms lease expires unanswered; reap returns the orphan to pending and the next claim holds token 2 -- crash recovery is one zset scan on the server's clock
PASS 6/6
```

L1 fixes the surface delta: claim, complete, retry, promote, reap join enqueue, browse, pending_size — five new
verbs, every transition one script, the surface gated at exactly the eight verbs. The bundle lives inside
`runtimes/elixir/lib/echo_mq/jobs.ex` — five `Script.new` constants, SHA-pinned, dispatched EVALSHA-first.

## §3 The dives

1. **Claim, the Token Mint** (`claim-the-token-mint`) — the four sets completing 3.1's map, each earning its
   score semantics; L1, the surface delta; L2, the happy path — "claim hands out the oldest job with a
   server-clock lease and fencing token 1; complete with the right token retires the row — nothing remains";
   the claim script quoted whole — server `TIME`, `HINCRBY` minting the token, the constructed-key exception
   sanctioned by the co-location law.
2. **The Fencing Token** (`the-fencing-token`) — L3, the zombie: a consumer holding token 1 watches an
   impostor's `complete` with token 99 earn `EMQSTALE`; L4, the round trip — "retry parks the job in the
   schedule, promote moves the due back to pending, and the next claim hands token 2 — one job, two lives, one
   counter"; the verification half of the Lua and Kleppmann's monotonic-token argument.
3. **The Morgue and the Reaper** (`the-morgue-and-the-reaper`) — L5, the cap: "attempts 2 against max 2 is the
   morgue: state dead, last_error kept, and the dead set browses in mint order like everything else"; L6, crash
   recovery: "a 40 ms lease expires unanswered; reap returns the orphan to pending and the next claim holds
   token 2 — crash recovery is one zset scan on the server's clock"; completion deletes, and the boundaries
   stated honestly.

## References

Sources:

- Valkey — Programmability — https://valkey.io/topics/programmability/ (atomic script execution: "all of the
  script's effects either have yet to happen or had already happened"; declared keys)
- Kleppmann, M. — How to do distributed locking —
  https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html (the fencing-token argument the
  `attempts` counter satisfies)
- Valkey — Replication — https://valkey.io/topics/replication/ (scripts replicate by effects; time frozen during
  a script, which makes `TIME` inside a write script sound)

Related:

- /bcs/bus — B3 · The Bus, the chapter landing; Part III's arc
- /bcs/bus/fence-and-keyspace — B3.1 · The Fence and the Keyspace, the co-location law that sanctions the
  constructed key
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the row and the pending set the machine moves
- /bcs/elixir-core/otp-application — B2.1 · The OTP Application, the supervision frame the consumers live in
- /echomq — EchoMQ, the protocol in rung-level depth on the far side of the door
- /redis-patterns — Redis Patterns Applied, the substrate: sorted sets, atomic Lua
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus` · next `/bcs/bus/state-machine/claim-the-token-mint`.
