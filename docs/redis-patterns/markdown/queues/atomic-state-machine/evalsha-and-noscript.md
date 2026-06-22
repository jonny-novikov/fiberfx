# EVALSHA and NOSCRIPT — load once, run by SHA

> Route: `/redis-patterns/queues/atomic-state-machine/evalsha-and-noscript` · Dive R3.04.3 · Module R3.04 Atomic state
> machine. Grounding: `EchoMQ.Scripts.execute_raw/4` tries `EVALSHA` first (the cached SHA), and on a `NOSCRIPT` error
> matches `{:error, %Redix.Error{message: "NOSCRIPT" <> _}}` and falls back to `EVAL` with the full body, which
> re-caches the script. The moduledoc states scripts are "loaded and cached for efficient execution using Redis
> EVALSHA". All real in `echo/apps/echomq`.

The transition script runs by its SHA, not by its body. `SCRIPT LOAD` returns a SHA; the client calls `EVALSHA`; a
flushed cache returns `NOSCRIPT`, and the client falls back to `EVAL` and re-caches.

## Load once, call by SHA

A Lua script can be sent on every call with `EVAL script numkeys …`, but that puts the whole body on the wire each
time — for a fourteen-key lifecycle script, kilobytes of Lua per transition. Redis offers a cheaper path. `SCRIPT
LOAD script` caches the body on the server once and returns its SHA-1 digest. From then on the client calls `EVALSHA
sha numkeys …` — the forty-character SHA stands in for the body, and Redis runs the cached script. The transition is
identical; only the bytes on the wire change.

EchoMQ takes this path. Its scripts are loaded and cached, and every named-script call runs by `EVALSHA`. The
fourteen-key `moveToFinished` reaches Redis as a SHA plus its keys and args, not as a body — so a high-throughput
worker pool is not re-sending the lifecycle script on every finish.

## The NOSCRIPT fallback

The server's script cache is not permanent. A restart clears it; `SCRIPT FLUSH` clears it. After that, an `EVALSHA`
for a SHA the server no longer holds returns a `NOSCRIPT` error — the SHA is unknown, the body is needed. A robust
client handles this without giving up the transition: on `NOSCRIPT`, send the full body with `EVAL`, which both runs
the script and re-caches it under the same SHA. The next `EVALSHA` hits the cache again.

EchoMQ's `EchoMQ.Scripts.execute_raw/4` is exactly this fallback. It tries `EVALSHA` first; on the error it matches
`{:error, %Redix.Error{message: "NOSCRIPT" <> _}}` and re-runs with `EVAL` and the full body. The transition succeeds
either way — the only cost of a flushed cache is one fallback round trip that re-caches the script.

## The wire cost

The contrast is concrete. `EVAL` every time sends the whole body on every call: N transitions cost N script bodies on
the wire. `EVALSHA` after one `SCRIPT LOAD` sends the body once and a SHA thereafter: N transitions cost one body plus
N short SHAs. For a fourteen-key lifecycle script under a busy worker pool, that is the difference between re-sending
the protocol on every finish and sending a digest. The fallback path only re-sends the body when the cache is actually
gone — once per flush, not once per call.

### The pattern, applied

The atomic-updates pattern runs the read-modify-write as one server-side script; `EVALSHA` is how that script reaches
the server cheaply. In EchoMQ `EchoMQ.Scripts.execute_raw/4` tries `EVALSHA` (the cached SHA), and on `NOSCRIPT`
falls back to `EVAL` (the full body), which re-caches — so the transition is both cheap on the wire and resilient to a
flushed cache.

A door, not a depth: the full script-load and SHA-cache management across the worker pool — when scripts are loaded,
how the SHAs are held — is E2 · the engine in the dedicated EchoMQ course.

## References

### Sources
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — run a cached script by its SHA; the `NOSCRIPT` error when
  the SHA is unknown.
- [Redis — SCRIPT LOAD](https://redis.io/commands/script-load/) — cache the body once and get back the SHA the client
  calls by.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — the full-body call the client falls back to on
  `NOSCRIPT`.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — the
  script-caching model behind `EVALSHA` and the `NOSCRIPT` fallback.
- [BullMQ — the queue protocol](https://bullmq.io/) — where "the Lua scripts are the protocol" EchoMQ loads and runs
  by SHA.

### Related in this course
- [R3.04 · Atomic state machine](/redis-patterns/queues/atomic-state-machine) — the module: the transition as one
  EVALSHA.
- [R3.04.2 · Read-decide-write in one EVALSHA](/redis-patterns/queues/atomic-state-machine/read-decide-write-in-one-evalsha) —
  the prior dive: the fourteen-key transition this dive runs by SHA.
- [R3.04.1 · States as locations](/redis-patterns/queues/atomic-state-machine/states-as-locations) — the locations the
  transition travels between.
- [R3.03.3 · Atomic vs non-atomic](/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic) — the EVALSHA the
  recovery sweep also runs.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-script read-modify-write pattern.
- [E2 · The engine](/echomq/core) — the dedicated EchoMQ course: the script dispatch and SHA cache in full.
