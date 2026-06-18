# E2.01 · The lifecycle & state machine

> Route: `/echomq/core/lifecycle` · Movement I · The Core (as-built, present tense) · module hub
> Back-link: ← redis-patterns R3 (`/redis-patterns/queues`)

The module hub for the eight-state machine: the states a job occupies, the one atomic Lua script behind each move
between them, the lock that keeps a job owned while a worker runs it, and the closed `-1`…`-11` return vocabulary the
scripts share.

## The fact

A job in EchoMQ is always in exactly **one of eight states**, and every move between states is **one atomic Lua
script**. The state is a Redis location built by one function in `EchoMQ.Keys`; the move is a script Redis runs
server-side in a single step. Four scripts perform the moves the running library makes — `moveToActive-11` (pickup),
`moveToFinished-14` (completion), `moveToDelayed-8` (retry), `moveStalledJobsToWait-8` (stalled recovery) — and when a
script cannot complete it returns a negative integer from a **closed set of eleven**, named and never expanded. The
core is shipped, so every surface this module teaches is read from the real `echo/apps/echomq` source.

## The worked example — stepping a captured job

Over the fixed lifecycle dataset, a captured job can be stepped through two real paths and the transition script named
at each edge:

- **The happy path** — `add` (no delay/priority) lands the job in `wait` via `addStandardJob-9`; a worker pickup runs
  `moveToActive-11`, which acquires the lock and moves `wait → active`; success runs `moveToFinished-14`, which
  verifies the lock token, removes from `active`, and `ZADD`s to `completed`.
- **The retry path** — from `active`, a failure with attempts remaining runs `moveToDelayed-8`: it `DEL`s the lock,
  computes the backoff `delay = base * 2^(attempt-1)`, moves `active → delayed` with the new run-at score, and
  increments `atm` (attempts made). When the delay expires the job is promoted back to `wait`, and a later pickup
  runs `moveToActive-11` again.

Each edge names exactly one script, and each script touches a fixed number of keys (its `KEYS` arity, the number in
the filename): `moveToActive-11` eleven, `moveToFinished-14` fourteen, `moveToDelayed-8` eight,
`moveStalledJobsToWait-8` eight.

## The protocol ↔ runtime pairing (the Golden Rule)

L1 (the state's keys and the field names) and L2 (the transition's Lua script and the closed `-1`…`-11` codes) are
**immutable and shared** across the three runtimes; L3 (the executor) and L4 (the API) **vary**.

- **The protocol (immutable L1/L2)** — the state keys `EchoMQ.Keys.wait/1`, `active/1`, `completed/1`, … and the
  transition scripts `moveToActive-11`, `moveToFinished-14`, with the same closed return codes in every runtime.
- **Its three runtimes (variable L3/L4)** — Elixir dispatches the moves with `EchoMQ.Scripts` over a Redix pool and
  renews locks with one `EchoMQ.LockManager` timer per worker; Go and Node.js drive the same scripts their own way.
  The wire underneath does not move.

The runtime above is free precisely because the protocol below is fixed.

## The dives

- **E2.01.1 · The eight states** — `wait · paused · delayed · prioritized · active · completed · failed ·
  waiting-children`, each with its Redis location and type, the key function that builds it, and terminal-vs-non-terminal.
- **E2.01.2 · Every transition & its script** — the script behind each move (`moveToActive-11`, `moveToFinished-14`,
  `moveToDelayed-8`, `moveStalledJobsToWait-8`), its `KEYS` arity, the atomic step list, and the closed `-1`…`-11` codes.
- **E2.01.3 · The lock protocol** — the `SET …:lock <uuid> PX <lockDuration>` acquire (inside `moveToActive-11`), the
  `extendLock-2.lua` heartbeat, the token verification that returns `-2`/`-6`, and the timing.

## Recap

The eight states are the locations a job occupies; the four transition scripts are the moves between them, each
atomic and each with a fixed `KEYS` arity; the lock keeps a job owned while a worker runs it; the `-1`…`-11` codes are
the scripts' fixed return vocabulary. L1 and L2 are the same in every runtime; only the executor that dispatches them
varies.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the wire protocol EchoMQ implements: the eight states, the
  transition scripts, and the lock protocol.
- Redis — *RPOPLPUSH* (`https://redis.io/commands/rpoplpush/`) — the reliable wait→active move at the heart of
  `moveToActive`.
- Redis — *LPUSH* (`https://redis.io/commands/lpush/`) — the push onto the `active` list a pickup performs.
- Redis — *Sorted sets* (`https://redis.io/docs/latest/develop/data-types/sorted-sets/`) — the ZSET scoring behind
  delayed, prioritized, and the terminal sets.

### Related in this course

- `/echomq/core` — E2 · The core (the chapter landing).
- `/echomq/protocol/lua-scripts` — E1.03 · The Lua script layer (the scripts these transitions run).
- `/echomq/protocol` — E1 · The protocol (the immutable wire this chapter sets in motion).
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (the pattern this chapter deepens).
