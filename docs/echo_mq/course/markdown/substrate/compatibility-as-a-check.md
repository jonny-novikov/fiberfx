# Conformance, not compatibility

> E3 · EchoMQ 2.0 — the protocol break · orientation dive — Movement II, tracks `emq.1` (drafted — the 2.0 break).
> EchoMQ 2.0 does not check that it stayed compatible with BullMQ. It checks that it *conforms* to its own protocol.

## The fact — from compatibility to conformance

The v1 line was measured against BullMQ: a probe asked "did the wire stay the same?" EchoMQ 2.0 breaks from BullMQ
on purpose, so that question is retired. emq.1 ships two new probes that measure the break instead:

1. **the v2 conformance probe** — an `add → process` round-trip on a v2 queue asserts the deployment conforms to the
   2.0 protocol: the produced key set is `emq:{q}:*`-only · a single hashtag per queue · zero `emq:*` reads or
   writes · every key declared (the scripts run under Dragonfly's default strict mode, no
   `--default_lua_flags=allow-undeclared-keys`) · `meta.version` = `echomq:2.0.0`.
2. **the fleet-interop probe** — a job enqueued by one first-party runtime is fetched and completed by another, both
   directions. Today only the Elixir reference speaks v2; the Go port (`apps/echomq-go`) must port v2, and the
   proposed `echomq-node` is proposed. The honest seam: **stock BullMQ clients cannot speak v2, by design.**

Why declare every key? Because the v1 inheritance is real. Roughly half the v1 scripts — about 24 to 26 of the 50 —
concatenate per-job keys *inside* the script from an ARGV prefix, never declaring them in `KEYS[]`. emq.1 ships the
declared-keys set as the resolution.

## The worked example — the real grounding

### The v1 undeclared-keys flaw (present-tense)

The v1 line, today, reaches Redis keys it never declares. In `moveToActive-11.lua` the worker fetch loop builds a
job key with `local jobKey = keyPrefix .. jobId` (`:148`), then a lock key with `local lockKey = jobKey .. ':lock'`
(`:162`) — both from an ARGV `keyPrefix`, neither in the script's `KEYS[]`. The caller sends only the declared list:
`EchoMQ.Scripts.execute_raw/4` issues `["EVALSHA", sha, num_keys | keys ++ encoded_args]` (`scripts.ex:256`), where
`num_keys = length(keys)` and `keys` is the declared list — the concatenated `jobKey`/`lockKey` are not in it.

On single-threaded Redis this is invisible. On DragonflyDB — thread-per-shard, where a key's `{…}` hashtag decides
its owning thread — an undeclared key forces `--default_lua_flags=allow-undeclared-keys`, which locks the **whole
datastore** per Lua call and destroys the multithreading. Roughly 24–26 of the 50 v1 scripts share the pattern; the
runtime-pick scripts (`moveToActive` pops the id at runtime via `RPOPLPUSH`/`ZPOPMIN`) are the hard ones, because
the id is not an input the caller can declare.

### The v2 conformance probe (emq.1 ships, D5)

emq.1 ships the resolution: every v2 script declares every operand key, and the runtime-pick core is redesigned so a
popped id resolves to a key inside the queue's native `{q}` slot. The v2 conformance probe asserts the deployment
conforms. On an `add → process` round-trip over a v2 `payments` queue it checks five things: the produced key set is
`emq:{q}:*`-only; every key of the transition shares one hashtag; zero `emq:*` reads or writes; the scripts ran with
all keys declared (Dragonfly strict mode, no escape-hatch flag); `meta.version` = `echomq:2.0.0`. The conformance
checklist interactive runs each assertion over a fixed v2 capture.

### The fleet-interop probe (emq.1 ships, D6)

emq.1 ships a probe that round-trips a job between first-party runtimes:

- **Elixir → Elixir.** The reference runtime enqueues and another consumer completes — green today.
- **Elixir ⇄ Go (once ported).** The Go port must implement v2 to join the fleet — not yet; tracked, status honest.
- **echomq-node.** A proposed first-party Node.js runtime — proposed; it does not exist.

The honest seam (INV6): v2 interop is the EchoMQ fleet's own. Stock BullMQ clients cannot speak v2 — by design, not
by omission. The cross-runtime status is reported on every surface that claims interop, never smoothed: today the
Elixir reference is the only v2 speaker.

## The triangle

| corner | what it is | this dive |
|---|---|---|
| **the pattern** (← redis-patterns) | R2 atomicity — an invariant must be checked, not promised; R0 foundations — load-once SHA-dispatched scripts | the *why*: the probes defend the 2.0 protocol by measuring conformance |
| **the spec** (⇄ emq.1, drafted — the 2.0 break) | `specs/emq/emq.1.md` — D2 (declared-keys v2 set), D5 (v2 conformance probe), D6 (fleet-interop probe), INV1 (the break is total), INV2 (declared keys, no escape hatch), INV6 (the honest fleet seam) | the *what is being built*: two probes that measure the break |
| **the as-built code** | the v1 flaw `moveToActive-11.lua:148,162` + `scripts.ex:256` (the undeclared-keys inheritance, present-tense) — the WHY the 2.0 set declares every key | the *how*: the probes assert against the real v1 facts the fork resolves |

**Bridge.** R2 says an invariant must be *checked*, not promised → emq.1 ships the v2 conformance probe (key set,
single hashtag, zero `emq:*`, declared keys, version) and the fleet-interop probe that measure the 2.0 protocol.

## The 2.0 fork

The v1 scripts reach keys they never declare (`moveToActive-11.lua:148,162`; the caller's declared list is
`scripts.ex:256`) — roughly 24–26 of 50 — which on DragonflyDB forces the whole-store lock. emq.1 ships the
declared-keys v2 set as the root resolution, and the v2 conformance probe asserts it: `emq:{q}:*`-only, one hashtag
per queue, zero `emq:*`, every key declared. Stock BullMQ clients cannot speak v2, by design — the interop is the
fleet's own.

## Recap

EchoMQ 2.0 does not check compatibility with BullMQ; it checks conformance to its own protocol. emq.1 ships two
probes: the v2 conformance probe (`add → process` on a v2 queue asserts `emq:{q}:*`-only · one hashtag per queue ·
zero `emq:*` · every key declared, Dragonfly strict mode · `meta.version` = `echomq:2.0.0`) and the fleet-interop
probe (Elixir reference ⇄ Go once it ports v2 ⇄ the proposed echomq-node). The WHY is the v1 undeclared-keys
inheritance — `moveToActive-11.lua:148,162`, about 24–26 of the 50 scripts, the caller's declared list at
`scripts.ex:256` — which on DragonflyDB forces the whole-store lock; 2.0 declares every key. The honest seam: stock
BullMQ clients cannot speak v2, by design.

## References

### Sources

- BullMQ — *Documentation* — the reference implementation whose wire the v1 line speaks and the 2.0 break leaves.
  <https://docs.bullmq.io/>
- DragonflyDB — *Server flags* — `--default_lua_flags=allow-undeclared-keys` (the whole-store-lock escape hatch the
  declared-keys set never sets) and `--lock_on_hashtags`. <https://www.dragonflydb.io/docs/managing-dragonfly/flags>
- DragonflyDB — *BullMQ on Dragonfly* — the undeclared-keys ceiling on a thread-per-shard datastore.
  <https://www.dragonflydb.io/docs/integrations/bullmq>
- Redis — *EVALSHA* — the load-once, run-by-SHA dispatch the v2 set rides. <https://redis.io/commands/evalsha/>

### Related in this course

- /echomq/substrate — E3 · the chapter landing (the owned keyspace and the triangle).
- /echomq/core — E2 · the core (the v1 line the fork freezes).
- /redis-patterns/coordination — R2 · atomicity (the pattern: prove the invariant).
- /redis-patterns/overview — R0 · foundations (load-once scripts; the facade seam).
