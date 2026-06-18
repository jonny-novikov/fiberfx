# Jobs, lanes & the consumer — module hub

**Route:** `/echomq/queue/jobs-lanes-consumer` · **Pillar:** The Queue · **Surface:** module hub

> All real code in `echo/apps/echo_mq` (`jobs.ex`, `lanes.ex`, `consumer.ex`, `keyspace.ex`). No `[RECONCILE]`
> markers — every surface is grounded on disk.

## Thesis

The lifecycle is the *machine*; this module is the *people who run it*. Three roles meet over one wire:

- **the producer** — `EchoMQ.Jobs.enqueue/4` admits a job with one idempotent script;
- **the fair worker** — `EchoMQ.Lanes.claim/3` serves identities in turn off a constructed ring, so no one starves;
- **the loop that owns the rhythm** — `EchoMQ.Consumer`, a supervised process that **parks rather than polls**.

## Framing interactive (≥1 on the hub)

A **three-role catalog**: pick a role (producer / fair worker / the loop), read the real surface it owns — the
handle, what it touches, the verdict. Pure lookup over a fixed dataset, live `.geo-readout`.

## The three dives

1. **enqueue-and-claim** — the `@enqueue` two-beat Lua: the `EMQKIND` kind-gate (`string.sub(ARGV[1],1,3) ~= 'JOB'`),
   the `EXISTS` idempotency (return 0), the `HSET` three-field row, the `ZADD pending`. `enqueue/4` →
   `{:ok,:enqueued}|{:ok,:duplicate}|{:error,:kind}`; and the flat `claim/3`.
2. **fair-lanes-and-the-ring** — per-group lanes `emq:{q}:g:<group>:pending`; the `ring` LIST is the rota of
   serviceable lanes; the `@gclaim` two-beat with `LMOVE KEYS[1] KEYS[1] LEFT RIGHT` rotating one step. Fairness is
   constructed, not hashed. `enqueue/5`, `claim/3` (returns `{id,payload,att,group}`), `pause/3`, `resume/3`,
   `limit/4`, `depth/3`.
3. **the-consumer-loop** — the supervised `reap → promote → drain → park` beat; `BLPOP` the `wake` key (park,
   don't poll); a dedicated connector lane for the blocking verb; the raising handler caught and converted to a
   typed retry; `stop/2` drains the job in hand. Defaults `:lease_ms` 30_000, `:beat_ms` 1_000, `:max_attempts` 3,
   `:pump_batch` 100.

## Bridge

`.applied` is a landing-only block; the hub carries a normal `.bridge` framing: the redis-patterns reliable-queue /
consumer pattern (R3 `/redis-patterns/queues`) → these three surfaces.

## References

### Sources
- Valkey — `LMOVE` — https://valkey.io/commands/lmove/
- Valkey — `ZPOPMIN` — https://valkey.io/commands/zpopmin/
- Valkey — `BLPOP` — https://valkey.io/commands/blpop/
- Redis — `EVALSHA` — https://redis.io/commands/evalsha/

### Related in this course
- `/echomq/queue` — The Queue (the pillar this module belongs to)
- `/echomq/protocol/the-lua-layer` — the scripts the verbs run
- `/redis-patterns/queues` — R3, the reliable-queue / consumer pattern
