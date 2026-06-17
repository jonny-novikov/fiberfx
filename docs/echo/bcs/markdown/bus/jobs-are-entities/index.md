# B3.2 · Jobs Are Entities

> Module hub · route `/bcs/bus/jobs-are-entities` · teaches `content/bcs3.2.md` · the rung is
> `bcs_rung_3_2_check.exs`, its committed record `bcs_rung_3_2_check.out` closes `PASS 5/5`.

Work without identity is logging.

The registry grows a second time: `JOB`, work as a kind, registered under the same bar `ARC` cleared — identity
and lifecycle of its own. A job's row is a hash of three fields, its pending home is a sorted set whose members
are the ids themselves, and its admission is one idempotent Lua script that refuses wrong kinds with a typed
wire error before anything half-exists.

The chapter is `content/bcs3.2.md`; the rung behind it is `bcs_rung_3_2_check.exs`, and its committed transcript
closes `PASS 5/5`. The surface, the idempotency, the kind law, the order theorem's dividend, the cargo rule —
five gates, each asserted on stage.

## §1 Why a job needs a name

Work without identity is logging. The moment a job can be retried, audited, cancelled, or asked about, it needs
a name — and idempotency, the bus's most important property, is *definitionally* identity: deduplicate by what,
if not a key? The oldest bug on any queue is the producer that enqueues twice because a reply got lost in a
reconnect; an id-keyed enqueue makes the second attempt a cheap, truthful `duplicate` instead of a phantom
double-fill on the trading desk. And because job ids are branded snowflakes, the pending structure gets
Chapter 1.2's theorem for free on a new substrate: the ids are the chronology — the committed line closes
`no second index anywhere`.

The chapter's five decisions:

- **D-10 — the registry grows by `JOB`.** Work is a kind: minted, gated, browsed, audited, and one day
  replayed, platform scope, same bar as `ARC`.
- **Policy before existence before write.** The script's act order is normative for every bundle script to
  come: refuse kinds first, answer duplicates second, mutate last — gated by J2 and J3.
- **`duplicate` is a success shape.** At-least-once producers retry; the bus answers calmly and changes
  nothing — gated by J2.
- **Refusals carry their own wire class.** `EMQKIND` sets the pattern: every typed refusal a bundle script
  issues leads with its class word, never riding the generic `ERR` — gated by J3.
- **Pending stays score-zero forever.** The lex law holds only under equal scores, so delayed and scheduled
  work will never mix scores into this set — **B3.3 · The State Machine in Lua** inherits a pre-stated plan: the
  schedule is a *separate* sorted set scored by run-time, migrating members into pending when due.

## §2 The proof

The full committed transcript, verbatim (source: `content/echo_data/runtimes/elixir/bcs_rung_3_2_check.out`):

```
boot: the registry grows by one -- JOB, work as a kind with identity and lifecycle
J1 surface ok -- the bus module's surface: enqueue, browse, pending_size -- scripts and key shapes are nobody's business
J2 idempotent ok -- enqueue is one script and idempotent by id: first call enqueued, second answered duplicate, the row untouched and pending holds 1
J3 kind ok -- kind policy lives in the script: an ORD id in the job position answers EMQKIND on the wire -- the key let it pass, the law did not
J4 dividend ok -- the order theorem's dividend: newest-first browse over the ids themselves returns the last five minted in reverse mint order; the very first job sits at the head; 301 pending, no second index anywhere
J5 cargo ok -- the cargo law holds: the payload carries ORD0Nt6z93U3dY and a quantity, never a row -- decoded and re-parsed on the far side of the wire
PASS 5/5
```

The rung's one live failure is part of the record's teaching: the first run failed J3 on a real wire fact — the
engine wraps class-less custom errors in its generic `ERR` prefix. The fix was better protocol citizenship, not
a looser match: the refusal now carries its own error class as its first word, `EMQKIND`, exactly the way the
boot fence types its refusal. The committed line's last clause — `the key let it pass, the law did not` — is
3.1's division performing: wellformedness at the key, policy at the script, each refusing in its own voice.

## §3 The dives

1. **The Job Row** (`the-job-row`) — the boot line: the registry grows by one. J1, the surface: `enqueue,
   browse, pending_size` — scripts and key shapes are nobody's business. The three-field hash `state` /
   `attempts` / `payload` — no `enqueued_at`, because the two-clocks law already placed that fact — and the
   score-zero pending set whose members are the ids themselves.
2. **Enqueue, One Script** (`enqueue-one-script`) — the ten-line Lua quoted whole; policy before existence
   before write. J2: first call enqueued, second answered duplicate, the row untouched and pending holds 1.
   J3: the `EMQKIND` wire class, discovered live — the key let it pass, the law did not.
3. **The Order Theorem's Dividend** (`the-orders-dividend`) — J4: newest-first browse over the ids themselves
   returns the last five minted in reverse mint order; the very first job sits at the head; 301 pending, no
   second index anywhere. J5: the payload carries `ORD0Nt6z93U3dY` and a quantity, never a row.

The obligation 3.1's F2 deferred — kind policy at the enqueue script — is collected in dive 2. And
**B3.3 · The State Machine in Lua** inherits a pending set whose lex-min is always the claimable head.

## References

Sources:

- Valkey — ZRANGE — https://valkey.io/commands/zrange/ (the REV and BYLEX forms behind newest-first browse;
  equal-score elements order lexicographically)
- Valkey — Sorted sets — https://valkey.io/topics/sorted-sets/ (the same-score lexicographic family as a
  generic index; the different-scores caveat behind the score-zero decision)

Related:

- /bcs/bus — B3 · The Bus, the chapter landing; Part III's arc
- /bcs/bus/fence-and-keyspace — B3.1 · The Fence and the Keyspace, the keyspace this module's keys obey
- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the lifecycle this module's pending set feeds
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, where rows already stayed home and ids crossed
- /echomq — EchoMQ, the bus protocol in rung-level depth on the far side of the door
- /redis-patterns — Redis Patterns Applied, the substrate: sorted sets, atomic Lua
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus` · next `/bcs/bus/jobs-are-entities/the-job-row`.
