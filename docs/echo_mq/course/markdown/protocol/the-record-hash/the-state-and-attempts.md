# The state and attempts — dive

**Route:** `/echomq/protocol/the-record-hash/the-state-and-attempts` · **surface:** dive

> Source-of-record. All grounding is real code in `echo/apps/echo_mq` — no `[RECONCILE]` except the unbuilt R7 door.

## The fact

Two of the three fields carry the job's machinery.

**`state`** is the lifecycle position. One field holds where the job is, and the transitions move it:
`@enqueue` writes `pending`; `@claim` writes `active`; `@schedule` writes `scheduled`; `@retry` writes `dead` at the
attempt ceiling or `scheduled` for a backoff; `reprocess` returns a `dead` job to `pending`. The state machine is one
hash field rewritten atomically by whichever script ran.

**`attempts`** is the retry count and, at the same time, the **fencing token**. Enqueue sets it to `'0'`. Claim runs
`HINCRBY attempts 1` and returns the new value to the worker — that value is the worker's token for this lease. Every
later transition the worker drives (`complete`, `retry`, `extend_lock`) passes the token back, and the script refuses
the call if it no longer matches:

```
if att ~= ARGV[2] then return redis.error_reply('EMQSTALE complete token mismatch') end
```

So a worker whose lease expired and was reaped — its job reclaimed and `attempts` bumped again — cannot complete a job
another worker now holds. The retry count doubles as the lease generation. One field, two jobs.

## The worked example (the real grounding)

**Beat one — the named handle.** `EchoMQ.Jobs.claim/3` pops the oldest pending id, then the `@claim` script does the
work. **Beat two — the body** increments `attempts`, writes `state = active`, leases the id on the active set at the
server clock, and returns `{id, payload, attempts}`. The returned `attempts` is the token; `complete/5` and `retry/7`
fence on it.

The hero interactive walks the `state` field through the lifecycle — pick a transition, read the state it writes. The
main interactive runs the fencing check: a fresh token completes; a stale token (a reaped, re-claimed job) is refused
with `EMQSTALE`.

## The bridge — R7 data modeling → the EchoMQ record

- **The pattern:** **Data Modeling & Memory (R7)** — carry control state in the entity's own fields, and reuse a field
  for two roles when the roles are one fact (the attempt count and the lease generation are the same counter).
  [RECONCILE: R7 unbuilt on disk; `<strong>`-name it.]
- **The implementation:** `state` is the lifecycle position the transitions rewrite; `attempts` is the retry fence and
  the token `@claim` mints with `HINCRBY` and `@complete`/`@retry` check.

## Recap

`state` holds the job's lifecycle position, rewritten by each atomic transition. `attempts` is the retry count and the
fencing token: claim mints it with `HINCRBY`, and a stale token is refused `EMQSTALE`. Two fields, the job's machinery.

## References

### Sources
- Valkey — HINCRBY (`https://valkey.io/commands/hincrby/`) — the atomic increment that mints the fencing token.
- Valkey — HSET (`https://valkey.io/commands/hset/`) — the write each transition uses to set `state`.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record.

### Related in this course
- `/echomq/protocol/the-record-hash` — the module hub.
- `/echomq/protocol/the-record-hash/the-hash-and-its-fields` — the previous dive.
- `/echomq/protocol/the-record-hash/the-payload` — the next dive.
- `/echomq/protocol` — the chapter landing.
