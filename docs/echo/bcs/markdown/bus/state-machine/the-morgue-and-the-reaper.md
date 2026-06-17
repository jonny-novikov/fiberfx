# B3.3.3 · The Morgue and the Reaper

> Dive 3 of B3.3 · route `/bcs/bus/state-machine/the-morgue-and-the-reaper` · teaches `content/bcs3.3.md` (the
> morgue and the reaper; completion deletes; boundaries) · reads gates `L5` and `L6` of
> `bcs_rung_3_3_check.out`.

Crash recovery is one zset scan on the server's clock.

L5 gates the cap: attempts 2 against max 2 is the morgue — state dead, last_error kept, and the dead set browses
in mint order like everything else. L6 gates the crash story end to end: a 40 ms lease expires unanswered; reap
returns the orphan to pending and the next claim holds token 2. No heartbeat protocol, no consumer registry —
lateness is already written into the active set's scores.

## §1 The transcript

This dive reads L5 and L6 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_3_check.out`, verbatim):

```
L5 dead ok -- attempts 2 against max 2 is the morgue: state dead, last_error kept, and the dead set browses in mint order like everything else
L6 reap ok -- a 40 ms lease expires unanswered; reap returns the orphan to pending and the next claim holds token 2 -- crash recovery is one zset scan on the server's clock
PASS 6/6
```

## §2 The morgue

L5 gates the cap: `attempts 2 against max 2 is the morgue: state dead, last_error kept`, with the dead set
lex-browsable in mint order — the dead set is score-zero like pending, so the morgue browses newest-first like
everything else in this series. Set `max_attempts` per queue class — a fill confirmation and a report render do
not deserve the same patience. The postmortem reader browses the morgue newest-first and finds `last_error`
waiting on every row.

## §3 The reaper

L6 gates the crash story end to end: `a 40 ms lease expires unanswered; reap returns the orphan to pending and
the next claim holds token 2 -- crash recovery is one zset scan on the server's clock`. No heartbeat protocol,
no consumer registry — the active set is scored by lease deadline, so lateness is already written into its
scores, and recovery is one range scan against the server's `TIME`. The next claim mints token 2 by the same
`HINCRBY`, so a late `complete` carrying token 1 meets the fence from the previous dive: refused on the wire,
`EMQSTALE`.

Size the lease above the worst legitimate work time and well below your retry tolerance — the lease is a crash
detector, not a deadline for excellence.

## §4 Completion deletes, and the boundaries

**Completion deletes.** A successful job leaves no residue by default — the row is gone, the receipt is the
caller's reply. The audit and event trail is the lane the manuscript assigns to **B3.5 · Bus Meets Stores**,
where results flow back into the stores as first-class writes — pre-stated here so deletion reads as a decision
rather than an omission.

The boundaries, stated honestly:

- **No lease extension yet.** A long job either gets a long lease or gets split, and the heartbeat verb is a
  carried follow-up with its own review gate.
- **Reap caps at one hundred per call** and promote at the caller's batch — both pumps need a driver, which is
  the loop the manuscript assigns to **B3.4 · Fair Lanes**, so this chapter ships beats without a metronome.
- **Backoff curves live above the wire.** Backoff policy (exponential, jittered, class-dependent) is application
  judgment and Lua is the wrong home for judgment.
- **The constructed-key exception does not generalize.** A script wanting keys it cannot declare and cannot
  derive from the queue's own prefix is a design smell, not a precedent.

## References

Sources:

- Valkey — Programmability — https://valkey.io/topics/programmability/ (atomic script execution: the reap's scan
  and the requeue land together or not at all)
- Valkey — Replication — https://valkey.io/topics/replication/ (time frozen during a script — the reap's clock
  reading is one value for the whole scan; scripts replicate by effects)
- Kleppmann, M. — How to do distributed locking —
  https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html (why the reaped job's next life is
  safe: the token moves forward, stale completes are refused)

Related:

- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/bus/fence-and-keyspace — B3.1 · The Fence and the Keyspace, the keyspace the four sets live in
- /bcs/elixir-core/otp-application — B2.1 · The OTP Application, the supervision frame around crashing consumers
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate patterns under the bus
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus/state-machine/the-fencing-token` · next `/bcs/bus/state-machine` (back to the hub).
