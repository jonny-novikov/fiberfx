# Idempotent consumers — score twice, scored once

> Route: `/redis-patterns/queues/at-least-once/idempotent-consumers` · Dive R3.02.2.
> · Grounding: the real codemojex scoring consumer in `echo/apps/codemojex`. `Codemojex.ScoreWorker.handle/1` drains
> the guess queue through `Lanes.claim`, scores the guess against the game's secret, writes a `GES` guess, and answers
> `:ok` for an unknown game — "a drop, never a retry loop" (the module's own words). The guess job carries a stable
> branded `JOB` id; the worker's effect is keyed by the game's secret and the player, so a redelivery scores the same
> emojis to the same result. The branded `JOB` id refuses a duplicate *enqueue* (`Jobs.enqueue → :duplicate`); the
> consumer absorbs a duplicate *delivery*. Two disciplines, two moments.

Score twice, scored once. At-least-once delivery hands the consumer a job that may arrive again; an idempotent effect
runs once however many times the job arrives.

## Naturally idempotent effects

An effect is idempotent when applying it twice changes nothing the second time. `SET key value` is the clearest case:
it overwrites to the same value however many times it runs, so a redelivered job that sets the same value is harmless.
Set membership is another — adding a member already in the set is a no-op. Writing a row by a fixed primary key with an
upsert is idempotent; so is sending mail keyed by a dedup id the provider honours.

A naturally idempotent consumer needs no extra machinery. The redelivery runs the effect again, the effect produces
the same state, and at-least-once delivery has already become an exactly-once effect at no cost. The discipline is to
*recognise* which effects are naturally idempotent and lean on them — choosing a `SET` over an `INCR`, an upsert over
a blind insert — before reaching for a marker.

```text
# naturally idempotent — a redelivery changes nothing
SET game:G:secret <value>       # run once or twice: the secret is the same either way
SADD room:R:players PLR0...      # add a member already in the set: a no-op
```

## Non-idempotent effects need a marker

The hard cases are effects where the second run *does* change the state. `INCR counter` is the canonical one — two
deliveries increment it twice. A card charge, a row insert with a fresh id, an outbound message without a dedup id:
each accumulates on every redelivery. A non-idempotent consumer double-counts on the duplicate the previous dive
proved is structural.

The guard is a marker keyed by a stable id. Before the effect runs, claim the marker with `SET … NX` — set only if
absent. If the claim succeeds, this is the first delivery: run the effect. If the claim fails, the marker is already
set, so the effect already ran on an earlier delivery: skip it. The marker carries the exactly-once decision that the
effect itself cannot.

```text
# a non-idempotent effect, guarded by an NX marker keyed by the stable job id
if SET seen:JOB0... 1 NX PX 86400000:    # claim the marker; NX = only if absent
    count_the_attempt()                  # first delivery: count once
else:
    skip()                               # a redelivery: the marker is set, do nothing
```

The marker needs a TTL (`PX`) long enough to outlive the redelivery window but bounded so the key does not live
forever. The marker and the effect are not atomic — a crash between the `SET NX` and the effect leaves the marker set
and the effect un-run — so the guard is a best-effort reduction of duplicates for effects that cannot be made
naturally idempotent, not a hard transaction. Where the effect can be made naturally idempotent, prefer that.

## The worked example — a codemojex guess

A codemojex guess is the cleanest illustration. A player submits six emojis; `Codemojex.Guesses.submit/3` mints a
branded `JOB` id (`EchoData.BrandedId.generate!("JOB")`), charges the wallet, and enqueues the job on the player's
lane (`Lanes.enqueue`). The scoring consumer is the authority: `Codemojex.ScoreWorker.handle/1` drains the lane,
reads the game's secret through the cache, scores the six emojis with the pure linear engine, and writes a `GES`
guess. The scoring itself is naturally idempotent — the same secret and the same six emojis produce the same score
every time the job runs.

The one part that accumulates is the per-game attempt counter, an `INCR` on `cm:<game>:attempts`. Counting an
attempt on every redelivery would over-count. That is the `INCR`-shaped effect, and a marker keyed by the stable
`JOB` id is what makes it redeliver-safe: claim `seen:<JOB>` with `SET … NX`; on the first delivery the claim succeeds
and the attempt is counted once; on a redelivery the claim fails and the count is skipped. The score rides on its
natural idempotency; the attempt count rides on the marker. Score twice, scored once.

`ScoreWorker` carries the discipline at its boundary too: a guess for an unknown game answers `:ok` — a drop, never a
retry loop. A redelivery that no longer maps to a live game settles cleanly rather than looping, because the consumer
treats the same identity the same way each time it sees it.

```elixir
# Codemojex.ScoreWorker.handle/1 — score the guess, write a GES (real, trimmed)
def handle(%{id: job_id, payload: payload, group: player}) do
  {:guess, game, ^player, emojis} = :erlang.binary_to_term(payload)
  case Cache.fetch_game(game) do
    %{secret: secret} = g ->
      s   = Scoring.score(secret, emojis)            # naturally idempotent: same secret + emojis -> same score
      gid = EchoData.BrandedId.generate!("GES")
      Store.put_guess(gid, %{game: game, player: player, emojis: emojis, points: s.total, ...})
      Cmd.incr("cm:" <> game <> ":attempts") |> Wire.run(conn)   # the accumulating effect — guard with a marker
    _ -> :ok                                          # unknown game: a drop, never a retry loop
  end
end
```

**The bridge.** Absorb at-least-once redelivery by making the consumer's effect idempotent — natural idempotency
where the effect allows it, a marker where it does not. In a codemojex guess, the scoring is naturally idempotent
(same secret and emojis, same `GES`), the per-game attempt count is guarded by an `NX` marker keyed by the `JOB` id,
and an unknown game answers `:ok` — so scoring a guess twice equals scoring it once.

## A note on producer-side admission

EchoMQ refuses a duplicate at *enqueue*, and it is a different mechanism from the consumer marker above.
`EchoMQ.Jobs.enqueue/4` runs one idempotent script whose first guard after the kind check is `if redis.call('EXISTS',
KEYS[1]) == 1 then return 0 end` — two enqueues of the same branded `JOB` id collapse to one row, and the host reads
the `0` as `{:ok, :duplicate}`. That is **producer-side** admission; it stops two enqueues of the same id from both
creating work. It does not make a single in-flight job exactly-once at the consumer, because the recovery path can
still redeliver a job that entered the queue once. The consumer marker in this dive is claimed at *effect-time*, keyed
by the job's identity, and is what absorbs that redelivery. Two markers, two moments — the third dive separates them
in full.

## References

### Sources
- [Redis — SET](https://redis.io/commands/set/) — the `NX` and `PX` options behind the effect-time idempotency
  marker.
- [Valkey — SADD](https://valkey.io/commands/sadd/) — the set add whose membership is a no-op on a redelivery, on the
  engine the connector is gated against.
- [Redis — Redis queue](https://redis.io/glossary/redis-queue/) — the queue and its delivery-guarantee overview.

### Related in this course
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the module hub.
- [R3.02.1 · At-least-once semantics](/redis-patterns/queues/at-least-once/at-least-once-semantics) — why the
  duplicate the marker absorbs is structural.
- [R3.02.3 · Why exactly-once is a lie](/redis-patterns/queues/at-least-once/why-exactly-once-is-a-lie) — producer
  admission versus consumer idempotency.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic `SET … NX` claim under the
  marker.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the worker loop and the lane the consumer drains.
