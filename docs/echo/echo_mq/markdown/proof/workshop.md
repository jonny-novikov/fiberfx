# Workshop — Prove it on a live queue

> Route: `/echomq/proof/workshop` · Pillar VI (The Proof) · the closing capstone of the course.
> Single page, no dives. Dark-editorial. Grounds in real `echo/apps/echo_mq` + the live `echo/apps/codemojex`
> consumer. No Lua (the Proof issues read/telemetry verbs direct). No hard scenario count. The build stamp is
> `EMQ0OGUWI87UdF`.

## The thesis

This is the last page of EchoMQ, In Depth. Everything before it built the system; this page **exercises it on a
running queue** and watches it answer for itself. The claim of the Proof pillar is small and total: **the whole
system holds, meters itself, and reports honestly** — and you can watch all three happen against a live server in
one sitting.

The worked queue is **codemojex** — the Telegram emoji-guessing game that rides the same bus. A guess is enqueued,
scored, and notified over real queues (`cm`, `cm.notify`); the workshop runs the bus's own proofs against that
traffic. Three beats:

1. **Run the conformance suite** (`EchoMQ.Conformance.run/2` → `{:ok, n}`) — the bus contract, written as
   runnable scenarios, holds against the live server.
2. **Attach a meter** (`EchoMQ.Meter.attach_many/4` on the codemojex lifecycle) and watch the `[:emq, :job, …]`
   events flow as a codemojex job runs — the system observes itself by emitting.
3. **Read the plane** (`EchoMQ.Metrics.get_counts/3` + `lane_depth/3` + `is_maxed/2`) — the queue answers how it
   is doing without being asked to change a thing.

The system holds, meters itself, and reports honestly — proven, observed, and answered, all on one live queue.

## Beat 1 — run the contract

The bus contract is not asserted in prose; it is **run**. `EchoMQ.Conformance.run/2` drives every scenario —
each a name and a one-line contract — against a **live server**, on per-scenario sub-queues it purges when it is
done, printing one `CONF` line per scenario and a closing tally. It returns `{:ok, n}` when every scenario passes,
or `{:error, failed_names}` with the names that did not. Point it at a sub-queue of the live codemojex queue and
the whole contract runs against the same server codemojex runs on:

```elixir
# run the bus contract against the live server, under a codemojex sub-queue
{:ok, n} = EchoMQ.Conformance.run(Codemojex.Bus.conn(), "cm.conf")
# CONF fence ok — the version fence is claimed before any work …
# CONF mint  ok — enqueue writes the three-field row: state pending, attempts 0, payload
# CONF claim ok — claim mints token 1, returns the payload, moves the row to active
# … one CONF line per scenario …
# CONFORMANCE n/n
```

`n` is the count of scenarios that passed — it is **not pinned on this page**, because the set grows by additive
minor: prior scenarios stay byte-frozen and git-verified, each new one is probe-registered, and the count is
re-pinned in the suite's own pinning tests. The shape is the contract, not the number: drive each scenario against
a live server, assert the externally visible verdict, and answer `{:ok, n}` when they all hold. A port of the bus
in another runtime is **conformant** exactly when it drives the same server to the same verdicts — the polyglot
promise made testable.

The suite purges what it mints, so running it against `cm.conf` leaves the real codemojex queues untouched: the
contract is proven beside live traffic, not on top of it.

> takeaway: The contract holds because it is run, not asserted — `{:ok, n}` is the whole bus, proven against the
> same server the game plays on.

## Beat 2 — attach a meter, watch the lifecycle

A holding contract is the floor. The next question is *how is it doing right now* — and the bus answers that two
ways. The **push** side is `EchoMQ.Meter`: the job lifecycle metered the standard Elixir `:telemetry` way,
re-rooted under `[:emq, …]`, one event tree with the connector's own `[:emq, :connector, …]`. Attach a handler to
the lifecycle events and every codemojex job that runs fires them as it moves:

```elixir
# attach one handler to the whole job lifecycle on the live bus
:ok =
  EchoMQ.Meter.attach_many(
    "cm-feed",
    [[:job, :add], [:job, :start], [:job, :complete], [:job, :fail]],
    fn event, measurements, metadata, _config ->
      # event :: [:emq, :job, :start | :complete | …] — already rooted under :emq
      Logger.info("#{inspect(event)} q=#{metadata.queue} job=#{metadata.job_id}")
    end,
    nil
  )
```

Now play the game. `Codemojex.Guesses.submit/3` enqueues a guess on the player's fair lane
(`EchoMQ.Lanes.enqueue(conn, "cm", player, job, payload)`), `Codemojex.ScoreWorker` claims and scores it, and
`Codemojex.NotificationWorker` drains the `cm.notify` queue to push the result. Each transition the bus meters
emits onto the tree — `job_added/4`, `job_started/4`, `job_completed/5`, `job_failed/6` are the convenience
emitters that fire `[:emq, :job, :add | :start | :complete | :fail]` — so the attached handler sees the codemojex
job's whole life flow past, queue and job id in the metadata, with no change to any transition script.

The cost is named, and it is zero. Every emission guards `:erlang.function_exported(:telemetry, :execute, 3)`:
with no `:telemetry` dependency loaded, an emit is a no-op and the `attach_many` above answers `:ok` with no
effect. **The bus carries no `:telemetry` dependency edge** — a host opts in by adding the dependency itself. (The
surface is named `EchoMQ.Meter` — a collision-free name, deliberately not a plainer one, so it never shadows
another module on the shared code path.) Metering is a thing the host turns on, not a tax the bus charges.

> takeaway: Attach a handler and the lifecycle reports itself — `[:emq, :job, …]` events flow as the game plays,
> at zero cost when no one is listening.

## Beat 3 — read the plane

Push tells you when things happen. **Pull** answers a question on demand, and changes nothing in the asking:
`EchoMQ.Metrics` is a set of pure-read verbs over the bus's as-built structures — every verb observes, none
mutates. Ask the live codemojex queue how it is doing:

```elixir
# per-state counts over the four sorted sets — a pure read
{:ok, counts} =
  EchoMQ.Metrics.get_counts(Codemojex.Bus.conn(), "cm",
    ["pending", "active", "schedule", "dead"])
# => {:ok, %{"pending" => 7, "active" => 3, "schedule" => 1, "dead" => 0}}

# one player's lane backlog — the fair-lane depth behind a PLR id
{:ok, depth} = EchoMQ.Metrics.lane_depth(Codemojex.Bus.conn(), "cm", player_id)
# => {:ok, 4}

# the read-and-refuse gate at the concurrency ceiling
EchoMQ.Metrics.is_maxed(Codemojex.Bus.conn(), "cm")
# => :ok               (below the ceiling — claim may proceed)
# => {:error, :rate}   (at the ceiling — a worker should back off, not claim)
```

`get_counts/3` reads `ZCARD` of each state's sorted set (and the terminal-outcome counter for
`completed`/`failed`, which the completion transition leaves no set for); an unregistered state name is
`{:error, {:unknown_state, name}}`, never an open read. `lane_depth/3` answers the pending depth behind one
player's lane — codemojex names each lane by the player's `PLR` id, so the read tells you exactly how far one
player is backed up. `is_maxed/2` reads the active set against the configured ceiling and answers `:ok` below it
or `{:error, :rate}` at it — a read that refuses, moving nothing. Every read script declares its keys, so the
`{q}` slot is pinned even on a metric-only request; the read plane is honest by construction.

This is the system answering for itself: counts, lane depth, the rate gate — read off the same structures the
queue runs on, with no transition, no mutation, no phantom write.

> takeaway: The queue answers how it is doing without being asked to change — counts, lane depth, and the rate
> gate are pure reads over the live structures.

## The worked session — one round, all three proofs

Run a single codemojex round and watch all three proofs in one feed: the contract verdict, the lifecycle events as
the round plays, and the read-plane answers at each step. `Codemojex.Guesses.submit/3` enqueues each guess on the
player's lane; `Codemojex.ScoreWorker` claims and scores it with `Codemojex.Scoring.score/2`; the lifecycle fires
`[:emq, :job, …]` to the attached meter; and at any point `get_counts/3` / `lane_depth/3` / `is_maxed/2` answer
how the queue is doing. The contract held before the round began, holds during it, and holds after — proven once,
observed throughout, answered on demand.

## Pattern → implementation

The pattern side — *run a conformance contract, meter the work with telemetry, and read the system's state without
changing it* — is what the production-operations chapter of Redis Patterns Applied frames as running a queue in
production. Here it is built from the implementation side: `EchoMQ.Conformance.run/2`, `EchoMQ.Meter.attach_many/4`,
and the `EchoMQ.Metrics` read plane, all over a live codemojex queue. The pattern names the moves; the pillar runs
the shipped code that makes them.

> takeaway: The same idea read two ways — the pattern names *prove it, meter it, read it*; the pillar runs the
> shipped verbs that do, against the same server the game plays on.

## Recap — the pillar, exercised

The Proof pillar taught three concerns: the conformance suite that runs the contract, the telemetry surface and the
read plane that report on the running system, and the benchmark frontier still ahead. This workshop exercised the
two that are shipped, on one live queue. **Run** the suite and the contract answers `{:ok, n}`. **Attach** a meter
and the codemojex lifecycle reports itself as `[:emq, :job, …]` events, at zero cost when no one listens. **Read**
the plane and the queue answers its counts, its lane depths, and its rate gate without changing anything. The
system holds, meters itself, and reports honestly — proven, observed, and answered. That is the whole bus, on a
live queue, the close of the course.

The architecture law these proofs realize — the four libraries composed as one umbrella, one identity carried
through — is the BCS *together* chapter.

## References

### Sources
- Elixir — the `:telemetry` library — https://hexdocs.pm/telemetry/readme.html — the standard metering surface
  `EchoMQ.Meter` re-roots under `[:emq, …]`; the bus carries no edge to it until a host opts in.
- Erlang/OTP — `:telemetry.execute/3` — https://hexdocs.pm/telemetry/telemetry.html — the guarded call every
  emission checks for before firing (zero cost when absent).
- Valkey — ZCARD — https://valkey.io/commands/zcard/ — the per-state count the read plane reads off each sorted
  set.
- Valkey — HGET — https://valkey.io/commands/hget/ — the row-field and counter read behind `get_job`/`get_metrics`.
- Kent Beck — Test-Driven Development — https://www.oreilly.com/library/view/test-driven-development/0321146530/ —
  the verdict-asserting scenario as the contract, run not asserted.

### Related in this course
- /echomq/proof/the-conformance-suite — beat 1: the bus contract as runnable scenarios.
- /echomq/proof/telemetry-and-the-read-plane — beats 2 and 3: push (the meter) and pull (the read plane).
- /echomq/proof — the pillar this workshop closes.
- /echomq/queue — the Queue, whose lifecycle the meter watches and the read plane reports.
- /echomq/bus — the Bus, the second pillar the suite proves whole.
- /echomq/cache — the Cache, the third product surface.
- /redis-patterns/coordination — the atomicity the conformance suite proves, from the pattern side (R2).
- /redis-patterns/production-operations — running the tier in production, the pattern side of this workshop (R8).
- /bcs/together — the architecture law: the four libraries as one umbrella (B6).
