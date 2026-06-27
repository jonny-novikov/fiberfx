# A reliable guess-command queue — lose no guess, score it once

> Route: `/redis-patterns/queues/workshop` · R3.06 · the chapter capstone (no dives) · Chapter R3 Reliable Queues.
> The worked consumer is **codemojex** (`echo/apps/codemojex`), a six-emoji code-breaking game on the BCS stack.
> A guess is a real job on a real queue today: `Codemojex.Guesses.submit/3` mints a branded `JOB` and enqueues it
> on the player's lane; `Codemojex.ScoreWorker` is the scoring consumer the bus drains. This capstone assembles the
> five R3 patterns over that path. Grounding (verified on disk): `EchoMQ.Jobs` (`claim/3`, `complete/5`, `retry/7`,
> `reap/2`), `EchoMQ.Lanes` (`enqueue/5`, `claim/3`), `EchoMQ.Consumer`, `EchoMQ.Stalled.check/2`,
> `EchoMQ.Keyspace.queue_key/2` + `job_key/2`; `Codemojex.Guesses.submit/3`, `Codemojex.ScoreWorker.handle/1`.
> The engine is Valkey.

The chapter taught five patterns: the processing list (R3.01), at-least-once delivery (R3.02), stalled recovery
(R3.03), the atomic state machine (R3.04), and blocking versus polling (R3.05). This capstone is the one worked design
that needs all five at once — a reliable queue for a single, concrete job: **scoring a player's guess in codemojex.**

## The scenario — a guess as a job

codemojex is a competition to crack a six-emoji code. A player submits a guess; the game scores it against the secret;
the score lands on the leaderboard. The host never scores — a single consumer is the authority. That split is already a
queue. `Codemojex.Guesses.submit/3` validates the guess against the round's keyboard, overlays the player's locked
positions, charges the right currency through the wallet, then mints a branded `JOB` and enqueues it:

```elixir
job = EchoData.BrandedId.generate!("JOB")
payload = :erlang.term_to_binary({:guess, game, player, guess})
EchoMQ.Lanes.enqueue(Bus.conn(), "cm", player, job, payload)
```

The lane is named by the player's `PLR`, so the bus rotates service across players and one masher cannot starve the
field. `Codemojex.ScoreWorker.handle/1` is the consumer the bus drains through `EchoMQ.Lanes.claim/3`: it reads the
secret, scores with the pure linear engine, writes a `GES` guess, counts the attempt, and records the result.

"Reliable" means two things at the same time. A worker crash never drops a guess — the guess is scored, eventually,
even if the first worker dies mid-score. And a worker crash never scores one guess twice — the leaderboard counts each
guess once, even when the job is redelivered. The whole point of R3 was to build a queue that holds both at once.

## The assembled path — R3.01 through R3.05, in order

Five patterns assemble into one reliable loop. Each prevents a different failure of the naive form (pop a job, process
it, done), and they build in order.

**R3.01 — the processing list.** The claim moves the job from its player lane to `active` in one atomic step.
`EchoMQ.Lanes.claim/3`'s inline `@gclaim` script `LMOVE`s the ring of serviceable lanes one step, `ZPOPMIN`s the head
of the rotated lane, `HSET state active` on the job row, and `ZADD`s onto the active set at a lease deadline read from
the server clock (`TIME`) — one `EVALSHA`, never two. (The flat `EchoMQ.Jobs.claim/3` is the same move over a single
`emq:{cm}:pending` set; codemojex uses the per-player lanes.) The job lands in `emq:{cm}:active` as one command. A crash
mid-score leaves the job in `active` with a lease that will expire — recoverable, not lost.

**R3.02 — at-least-once.** The lease makes redelivery *possible*, which is the point. A worker that scores a guess, then
dies before it acknowledges, leaves the job in `active`; its lease expires and the job is reclaimed and run again. So
delivery is at-least-once: a guess runs one or more times, never zero. The price is that the consumer must be safe to
run twice — and the branded `JOB` id is what pays it.

**R3.03 — stalled recovery.** The dead worker's lease expires by the server clock, and a sweep returns the job for
another worker. `EchoMQ.Jobs.reap/2` is the single server-side scan that returns any expired-lease job from `active` to
`pending` once — crash recovery. `EchoMQ.Stalled.check/2` is the count-thresholded layer on top: each pass `HINCRBY`s a
per-job `stalled` field, recovers a job below `max_stalled`, and dead-letters one at or above it (`state = dead`, onto
the `emq:{cm}:dead` set). A guess that stalls forever is not recovered forever — past the threshold it lands in the
morgue.

**R3.04 — the atomic state machine.** The finish is one `EVALSHA`. `EchoMQ.Jobs.complete/5` runs the inline `@complete`
script: it checks the fencing token (`attempts`), `ZREM`s the job from the active set, `DEL`s the row, and bumps the
completed metric — indivisible. A torn finish is impossible because there is no second command to tear away from the
first. The states are locations in the braced `emq:{cm}:` keyspace — `pending`, `active`, `scheduled`, `dead` — and the
branded `JOB` id is gated at the key builder (`EchoMQ.Keyspace.job_key/2` raises on an ill-formed id).

**R3.05 — the blocking pickup.** The consumer does not busy-poll. `EchoMQ.Consumer` beats on a cadence — reap expired
leases, promote due schedules, drain the ring with rotating claims — then parks on the wake key with `BLPOP` until
readiness arrives as a wake or the beat elapses. An enqueue pushes a wake, so a parked consumer costs the wire nothing
between guesses and wakes the moment a guess arrives. The default lease is 30 000 ms.

```text
The assembled path, over a codemojex guess job (real today):
  submit  → Codemojex.Guesses.submit/3 mints a branded JOB, EchoMQ.Lanes.enqueue on the player lane
  worker  → EchoMQ.Consumer parks on emq:{cm}:wake (BLPOP); an enqueue pushes a wake          [R3.05]
  claim   → @gclaim: LMOVE ring, ZPOPMIN the lane, HSET state active, ZADD active (lease, TIME) [R3.01]
  process → Codemojex.ScoreWorker.handle/1 scores, writes one GES guess, records the result
  finish  → complete/5: one EVALSHA, token-fenced (attempts), ZREM active + DEL row            [R3.04]
  crash?  → lease expires → reap/2 / Stalled.check/2 returns it to pending; re-claimed         [R3.02 + R3.03]
  past max_stalled → dead-letter onto emq:{cm}:dead → the durable floor (the archive)          [DELTA-4]
```

## The synthesis — at-least-once + the branded id is exactly-once-in-effect

The assembled queue guarantees at-least-once delivery, so a guess job can run twice. That is safe because the **branded
`JOB` id is the idempotency key**, and the bus dedups on it by construction. `EchoMQ.Jobs`' enqueue script is one
idempotent step:

```lua
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

`KEYS[1]` is the job key — `emq:{cm}:job:<JOB id>`. A second enqueue of the same branded id finds the row present and
returns `0`, which the host reads as `{:ok, :duplicate}`: the same guess submitted twice is admitted once. And the
finish is token-fenced: `EchoMQ.Jobs.complete/5` refuses a stale `attempts` token (`{:error, :stale}`), so a worker
whose lease was reaped and re-claimed by another worker cannot complete a job it no longer owns. The id orders the
queue (mint order is byte order is sort order), names the row, and dedups admission — one 14-byte value doing the work
of an index and a guard.

So a guess that is redelivered after a crash is scored once, not twice. The first run writes the `GES` guess and the
attempt; a redelivered job re-claims and re-runs against the same secret, and the consumer is the authority that holds
the count. At-least-once delivery over a branded-id-deduped, token-fenced effect is **exactly-once-in-effect** — the
achievable truth. Exactly-once delivery is a lie; this is what a reliable queue plus a careful consumer actually buys.

## Grounded in the real EchoMQ surfaces and the codemojex consumer

Every primitive in the assembled path is real EchoMQ code under `echo/apps/echo_mq`, and the consumer is real codemojex
code under `echo/apps/codemojex`.

| Guarantee | The EchoMQ surface (Elixir, verified) | The location |
| --- | --- | --- |
| in-flight move | `EchoMQ.Lanes.claim/3` → `@gclaim` (rotate the ring, `ZPOPMIN` the lane, `HSET active`, `ZADD` lease) | the player lane → `emq:{cm}:active` |
| stalled recovery | `EchoMQ.Stalled.check/2`, `EchoMQ.Jobs.reap/2` (expired lease, server `TIME`) | `emq:{cm}:active` → `pending` / `dead` |
| atomic finish | `EchoMQ.Jobs.complete/5` → `@complete` (one `EVALSHA`, token-fenced) | `emq:{cm}:active` → row `DEL` |
| blocking pickup | `EchoMQ.Consumer` (`BLPOP` on the wake key, `:lease_ms` 30 000) | `emq:{cm}:wake` |
| idempotency key | the branded `JOB` id; `enqueue` refuses a duplicate row | `emq:{cm}:job:<JOB id>` |

The consumer is `Codemojex.ScoreWorker.handle/1` — it takes `%{id: job_id, payload: payload, group: player}`, reads the
game's secret through the cache, scores with `Codemojex.Scoring.score/2`, writes a `GES` guess with
`Codemojex.Store.put_guess/2`, counts the attempt, and records the result on the board. The producer is
`Codemojex.Guesses.submit/3`, which mints the `JOB` and calls `EchoMQ.Lanes.enqueue/5`. Both are real on disk; the
queue over guesses is how codemojex runs today, not a hypothetical.

## The durability frontier — what happens to a dead-lettered job

A guess that stalls past `max_stalled` is dead-lettered, and a trimmed stream is not discarded. `EchoStore.StreamArchive`
folds trimmed `EchoMQ.Stream` segments into the native `EchoStore.Graft` engine's CubDB at a reserved high page range,
and on to Tigris object storage behind a create-only commit fence — deep history without resident memory, readable
beside the live tail on an engine-derived watermark. Durability is a dial the system turns, not a fixed cost on the hot
path: the enqueue and claim touch only the bus. The persistence floor is its own course.

## References

### Sources

- [Valkey — RPOPLPUSH](https://valkey.io/commands/rpoplpush/) — the atomic in-flight move family; the claim is its
  sorted-set form (`ZPOPMIN` then `ZADD`), one job in exactly one set at every instant.
- [Valkey — EVALSHA](https://valkey.io/commands/evalsha/) — the atomic finish: `complete/5` runs as one cached script,
  so there is no second command to tear away.
- [Valkey — BLPOP](https://valkey.io/commands/blpop/) — the consumer blocks on the wake key between jobs; park, do not
  poll.
- [Valkey — SET](https://valkey.io/commands/set/) — `SET … PX`, value and expiry in one atomic command, the lease idiom
  read back on the server clock.
- [Redis — Documentation](https://redis.io/docs/) — sorted sets, hashes, and scripting: the command families the
  reliable-queue path is built from.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this workshop closes.
- [R3.01 · The processing list](/redis-patterns/queues/processing-list) — the in-flight move (pending → active under a
  lease).
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the delivery guarantee the branded id pays for.
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the sweep that returns a dead worker's job.
- [R3.04 · The atomic state machine](/redis-patterns/queues/atomic-state-machine) — the one-script finish.
- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the blocking pickup on the wake key.
- [EchoMQ · The Queue pillar](/echomq/queue) — the door: the engine that runs these scripts, rung by rung.
- [The persistence floor](/echo-persistence) — where a dead-lettered job and a trimmed stream land: the durability dial.
