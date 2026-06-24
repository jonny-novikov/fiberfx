# Codemojex · The pragmatic node, and the operations it carries: the guess path and the bot on echo_mq

<show-structure depth="2"/>

A guess and a notification look like two casual taps, but each one becomes a branded job on a fair lane, scored or delivered by a single authority, and the node that holds those lanes is sized by latency steadiness rather than capacity. This article gives the pragmatic Valkey machine and configuration for Codemojex, then walks the two operations end to end through the real `echo_mq` code — the per-player guess lane and the per-chat notification lane — naming the modules each step rides. As an architecture decision of record: the playable entity is a **game** (`GAM`), a state machine inside a room (`ROM`), superseding the earlier `round`/`RND`; the keyspace and prose use it, and the committed modules still carry the `round` identifier pending the rename. The version is `9.1`, settled in the companion comparison; the machine is a Fly `shared-cpu-2x` with one gigabyte.

## Scope and method

The node is Valkey `9.1` over its bundled jemalloc on a Fly `shared-cpu-2x` machine, reached by the `codemojex` umbrella whose pinned build is Elixir 1.18.4 on OTP 28. Sizing and platform statements carry a numbered reference to the source that published them; the operational walkthrough is grounded in the committed modules under `echo/apps/codemojex/lib` and `echo/apps/echo_mq/lib`, cited by module and function. No benchmark was run; the figures here are cited externals or derivations, never measurements of this system. The configuration files are the ones the companion article ships under `valkey/`. Out of frame: the version comparison itself, and the allocator argument, both carried elsewhere.

## The pragmatic node

The recommendation is short because the constraint is sharp: Valkey runs commands on one thread [1], so the machine is sized for a steady latency tail, not for throughput headroom. Two shared vCPUs, one gigabyte, eviction off.

One gigabyte forces the shared class — Fly's minimum memory is 256 megabytes per shared vCPU but 2048 per performance vCPU, so a one-gigabyte node cannot be a performance machine [8]. The shared class is a burstable quota: each shared vCPU has a baseline near six percent of a period and accrues a balance to burst to full, and the two vCPUs share one combined quota [9]. That shapes the configuration. `io-threads` stays at one, because extra I/O threads busy-wait and would drain the shared burst balance even while idle [3]; the second vCPU is left for the background threads that sleep — the `everysec` AOF fsync, which runs on its own thread [2], jemalloc's background purge, and the lazy frees. `maxmemory` is a loud 512-megabyte guardrail under `noeviction`, far above a working set that is single-digit megabytes because player balances live in Postgres, so a runaway keyspace rejects writes rather than being killed. Durability is AOF alone, one fork source; jemalloc is the allocator the resident-size budget depends on [4]. The node is private by construction — no public service, bound to the IPv6 wildcard so it answers only on the organization's 6PN [11], reachable at `codemojex-valkey.internal:6390`, which is on by default for apps in one organization [10]. Its volume lives on one host in one region [12], the single point of failure to retire with a replica before real money flows.

The pragmatic upgrade ladder, in order: add a replica in the primary region; split the Phoenix web and worker process groups; move Phoenix to a performance machine when guess throughput is sustained; and shard Valkey by hash tag only when one command thread is finally the bottleneck. Each step is taken on evidence — `used_active_time_main_thread` for true single-thread headroom, which 9.1 added because the busy-wait pins raw CPU near full and hides spare capacity [3].

## The game as a state machine

A room is a template and a container; a game is one playthrough inside it, with a small state machine. When a player joins a waiting room, a game is formed: a fresh six-emoji secret is minted, the room's properties are snapshotted onto it, an end instant `ends_ms` is set, and the game enters `open`. The transitions:

```
        join a waiting room
                │
                ▼
          ┌──────────┐   guess → score (the cm lane)
          │   open   │◀──────────────────┐
          └────┬─────┘                   │ board + events
   600 crack   │  or timer ends_ms       │
   or a sweep  ▼                          │
        SET cm:<game>:closed NX ──────────┘
                │  (only the winner of the SET proceeds)
                ▼
          ┌────────────┐  the cm-settle lane, lane = game id
          │  settling  │  winner-take-all payout
          └────┬───────┘
                │  paid, winners notified
                ▼
          ┌──────────┐   the room returns to waiting,
          │  closed  │   ready to form the next game
          └──────────┘
```

`open` accepts guesses; `Codemojex.Guesses.submit/3` admits a guess only while the game's status is open and `ends_ms` has not passed. Two events leave `open`: a perfect crack of 600 inside the scoring authority, or the timer elapsing under a sweep. Both call into `Codemojex.Rooms`, where an exactly-once `SET cm:<game>:closed NX` is the gate — the single caller that wins that set advances the game to `settling`; every other caller is a no-op. `settling` is the payout, run as a separate job; `closed` is terminal, and the room returns to waiting to form the next game. The keyspace under the game is one sorted set `cm:<game>:board`, the hashes `cm:<game>:base`, `cm:<game>:ptier`, `cm:<game>:bonus`, and `cm:<game>:tierfirst`, the counter `cm:<game>:attempts`, the `cm:<game>:closed` marker, and a per-player lock hash `cm:<game>:lock:<player>`.

## The guess operation, on echo_mq

A guess crosses two queues. The first, named `cm`, competes; the second, `cm-settle`, pays. The split is the move-then-settle pattern: the authority that scores never holds the payout.

**Admission.** `Codemojex.Guesses.submit/3` validates the guess against the game's keyboard, overlays the player's locked positions with `Codemojex.Locks.merge/3`, charges the right currency through `Codemojex.Wallet.charge_guess/3` — keys for a paid room, clips for a free one — mints a `JOB` branded id, and calls `EchoMQ.Lanes.enqueue(conn, "cm", player, job, payload)`. The lane key is the player's `USR`. Inside `EchoMQ.Lanes`, enqueue is one idempotent script: it admits by kind, refuses a duplicate id, writes the job row, places the entry on the player's lane, updates the ring that orders the lanes, and wakes a parked consumer — atomically, on the single slot the queue's keys share. The host never scores; admission is all the submit path does, and it does one enqueue with no network round trip beyond it.

**The keyspace and the fairness.** `EchoMQ.Keyspace` composes per-queue keys as `emq:{cm}:<type>`, the brace making the queue name the hash tag so every key of the queue lands on one slot — the cluster-routable shape, computed client-side by CRC16. Lanes are why one player hammering guesses cannot starve the field: the ring rotates service across the per-`USR` lanes, so a busy lane waits its turn rather than monopolising the worker.

**Draining.** `EchoMQ.Consumer` owns the rhythm. It is a supervised loop with its own connector that beats on a cadence — reap expired leases, promote any due scheduled jobs, drain the ring with rotating claims through `EchoMQ.Lanes.claim/3` — then parks on the wake key with a blocking pop until a wake arrives or the beat elapses. It parks rather than polls, so an idle consumer costs the wire nothing. Each claim delivers a map of id, payload, attempts, and group, the group being the player. A pool can opt into a metronome so one blocker per queue fans readiness out fairly instead of a thundering herd. The lease is the active-set score itself; a long-but-alive handler keeps its lease through the opt-in `EchoMQ.Locks` plane, which re-scores the active member on a timer and refreshes the lock marker beside it.

**Scoring.** `Codemojex.ScoreWorker.handle/1` is the authority. It reads the game's secret through the cache — the one immutable value the scoring path trusts the cache for — scores with the pure `Codemojex.Scoring`, writes a `GES` guess row, increments `cm:<game>:attempts`, and records the result on the board with `Codemojex.Board.record/4`, which awards a first-mover tier bonus through an `HSETNX` race so the first id to reach a tier claims it. It then publishes a `scored` event with `EchoMQ.Events.publish/4` and broadcasts a secret-free live update over Phoenix PubSub for the room channel. A score of 600 calls `Codemojex.Rooms.close_round/1`; a guess for an unknown game answers `:ok` — a drop, never a retry loop.

**Settling.** Closing enqueues a `JOB` on `cm-settle` with the game id as the lane, through `Codemojex.Settle.close/1`. Its consumer runs the winner-take-all payout: the effective pool — boosted for a Golden Room — goes to the top-scoring player through `Codemojex.Wallet.deposit_prize/3`, the global counter `cm:total_won` is bumped, winners are notified, and the room returns to waiting. The guess queue competed; the settle queue paid.

**Backpressure and failure.** A player's lane can be paused and resumed without touching another's — `Codemojex.Guesses.pause/1`, `resume/1`, and `depth/1` map onto `EchoMQ.Lanes`, and the lane recovery is group-scoped so a sibling lane's expired members are left for the queue-wide reaper rather than evicted. A handler that raises is converted to a typed retry and the loop survives; a stalled worker's expired lease is reclaimed by the sweep on the server's own clock.

**Delayed work.** When a transition needs a future trigger — a timed close, a reminder — `EchoMQ.Jobs.enqueue_in/6` and `enqueue_at/6` park a job on the schedule set with its row written scheduled; the mint stays the sort key so a job minted earlier but scheduled later still sorts by its mint once promoted, and the delay is measured on the same clock that promote and reap read.

## The Telegram bot notification operation, on echo_mq

Notifications run on their own queue with a per-chat lane, so a chat's messages are spread behind a rate limit rather than fired at once. The path runs both ways.

**Outbound, game to player.** `Codemojex.Notifier.notify/3` mints a `NOT` branded id, encodes a JSON payload of the chat, text, options, id, and attempt, and calls `EchoMQ.Lanes.enqueue(conn, NotificationWorker.queue(), to_string(chat_id), job, payload)` — the lane key is the chat id. The call returns the job id and does no network work; delivery, rate limiting, retries, and backoff are the worker's job. The game-facing helpers `round_result/3`, `prize_won/3`, and `golden_win/4` are thin wrappers that keep the wording in one place. `Codemojex.NotificationWorker` drains the lane, paces a chat through `Codemojex.RateLimiter`, and hands the text to `Codemojex.Bot.deliver/2`, which calls `EchoBot.Platform.Telegram.send_reply/3` — the text-only send seam through the vendored client. A failed send returns a typed retry, and the queue's backoff schedules the next attempt; the per-chat lane keeps one chat's retries from delaying another's first message.

**Inbound, player to game.** An update arrives and `Codemojex.EchoBot.ingest/1` decodes and normalizes it through `EchoBot.Platform.Telegram.decode_and_normalize/1`, then bridges it onto the `cm.bot.commands` queue with the chat reference as the lane. `Codemojex.CommandWorker` drains that queue and dispatches the normalized shape — a `start` or `help` command answers through the Notifier; an update with no chat reference is ignored. The same fair-lane discipline applies: a chat's commands rotate with every other chat's.

**Lifecycle and durability.** `EchoMQ.Events` rides the connector's pub/sub seam, subscribing once to `emq:{q}:events` and dispatching each lifecycle message on its event name, so a consumer reacts to completed, failed, scheduled, and progress events without polling. That feed is at-most-once: a publish with no live subscriber, or one issued in the window between a socket drop and the resubscribe, is lost, and the resubscribe is the mitigation. The durable, replayable receipt is `EchoMQ.Stream`, whose `append/4` mints an EVT-branded id host-side so stream order equals id-sort order equals mint order, and whose `trim/4` bounds the stream with `XTRIM` over a keep-newest count or a Snowflake-derived minimum instant. Out-of-band, the RESP3 push seam delivers cache-invalidation hints on a `{:emq_push, …}` message without consuming a queue slot.

## Where version 9 touches these operations

The version choice lands on exactly these paths. The closed-game keys — the board, the four hashes, the counter, the marker, the lock hashes — are not deleted or expired by the close today, so under `noeviction` they accumulate; a key-level expiry at close fixes it on any version, and `HEXPIRE` gives per-field control where a hash should outlive some of its fields [5]. The lock plane's marker can collapse to one self-expiring hash field on 9.x and release by token with `DELIFEQ` rather than an unconditional delete [7]. The pipelined claim and complete bursts and `EchoMQ.Stream.append_batch` gain from 9.0 pipeline prefetch. And the 9.1 fixes sit on paths the bus exercises directly — the stream-trim null-deref on `EchoMQ.Stream.trim`, and the rehashing latency reduction on the lane sorted sets and the job-hash dictionary as they grow [6].

## Boundaries

This article measures nothing; the sizing and platform figures are cited to their publishers, and the walkthrough is read from the committed source rather than benchmarked. The state machine is the architecture of record; the committed modules name the entity `round` pending the rename, so a reader diffing the tree sees the older identifier. The single-node, single-region, single-volume shape is adequate for launch and not for the availability a money game eventually needs. The lingering-key behaviour at close is read from the close path, not observed on a long-running node, and the order-of-magnitude footprint claims are derivations, not measurements.

## Companion files

The node ships with the configuration the comparison article carries: `valkey/conf/valkey.conf`, `valkey/Dockerfile` pinned to `9.1`, and `valkey/fly.toml` for the private `shared-cpu-2x`, one-gigabyte machine. This article adds no new files; it documents the operations that run against that node.

## References

1. Valkey — Benchmarking (single-threaded command execution): [valkey.io/topics/benchmark](https://valkey.io/topics/benchmark/)
2. Valkey — Diagnosing latency (one command at a time, fork latency, everysec fsync thread): [valkey.io/topics/latency](https://valkey.io/topics/latency/)
3. Valkey — INFO command (used_active_time_main_thread on 9.1, I/O-thread busy-wait): [valkey.io/commands/info](https://valkey.io/commands/info/)
4. Valkey — project README (jemalloc the Linux default for fragmentation): [github.com/valkey-io/valkey](https://github.com/valkey-io/valkey)
5. Valkey — Introducing Hash Field Expirations (per-field TTL and active expiry): [valkey.io/blog/hash-fields-expiration](https://valkey.io/blog/hash-fields-expiration/)
6. Valkey — Release 9.1.0 (stream-trim null fix, rehashing page release): [github.com/valkey-io/valkey/releases/tag/9.1.0](https://github.com/valkey-io/valkey/releases/tag/9.1.0)
7. Google Cloud — Memorystore for Valkey 9.0 (DELIFEQ guarded delete): [cloud.google.com](https://cloud.google.com/blog/products/databases/memorystore-for-valkey-9-0-is-now-ga)
8. Fly.io — Machine sizing (shared minimum 256 and maximum 2048 per vCPU): [fly.io/docs/machines/guides-examples/machine-sizing](https://fly.io/docs/machines/guides-examples/machine-sizing/)
9. Fly.io — CPU performance (shared baseline and burst, shared quota across vCPUs): [fly.io/docs/machines/cpu-performance](https://fly.io/docs/machines/cpu-performance/)
10. Fly.io — Private Networking (6PN on by default, internal addresses): [fly.io/docs/networking/private-networking](https://fly.io/docs/networking/private-networking/)
11. Fly.io — Connect to an App Service (bind the wildcard, no service or IP needed): [fly.io/docs/networking/app-services](https://fly.io/docs/networking/app-services/)
12. Fly.io — Volumes overview (one volume to one machine, single region): [fly.io/docs/volumes/overview](https://fly.io/docs/volumes/overview/)
