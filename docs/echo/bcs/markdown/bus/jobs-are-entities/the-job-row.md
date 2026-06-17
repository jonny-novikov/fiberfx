# B3.2.1 · The Job Row

> Dive 1 of B3.2 · route `/bcs/bus/jobs-are-entities/the-job-row` · teaches `content/bcs3.2.md` §"The row" +
> §"The pending set" · transcript lines `boot`, `J1` of `bcs_rung_3_2_check.out`.

Three fields, one of them cargo.

A job is a hash at the job key — `state`, `attempts`, `payload` — and deliberately nothing more. Its surface is
gated at `enqueue, browse, pending_size`, its pending home is a sorted set with every member at score zero, and
the members are the job ids themselves — so the structure inherits the identity contract's ordering instead of
maintaining its own.

Source: `content/bcs3.2.md`, quoting `bcs_rung_3_2_check.out`; the module is committed at
`runtimes/elixir/lib/echo_mq/jobs.ex`.

Interactive 1 (hero): the row, field by field — `state` (written `'pending'` by the enqueue script),
`attempts` (written `'0'`; written but not yet incremented — the field belongs to this chapter's row, its
arithmetic to the next chapter's transitions), `payload` (the cargo: ids and parameters, never rows), and the
absent fourth field `enqueued_at` (the two-clocks law already placed that fact: mint time lives *inside* the
identity — `unixMs` of the snowflake — and server-time fields belong to leases).

## §1 The transcript

This dive reads the boot line and J1 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_2_check.out`):

```
boot: the registry grows by one -- JOB, work as a kind with identity and lifecycle
J1 surface ok -- the bus module's surface: enqueue, browse, pending_size -- scripts and key shapes are nobody's business
PASS 5/5
```

(The full record holds J2–J5; the dives that follow read them.)

## §2 The surface

J1 gates the module's surface: `enqueue, browse, pending_size` — scripts and key shapes are nobody's business.
The boot line registers the kind: the registry grows by one — `JOB`, work as a kind with identity and
lifecycle, registered under the same bar `ARC` cleared (decision D-10: minted, gated, browsed, audited, and one
day replayed, platform scope). The module lives at `runtimes/elixir/lib/echo_mq/jobs.ex`; the script travels
inside the module, SHA-pinned by `Script.new` and dispatched EVALSHA-first through the appendix's loader.

## §3 The row

A job is a hash at the job key — `state`, `attempts`, `payload` — "and deliberately nothing more. No
`enqueued_at` field exists because the two-clocks law already placed that fact: mint time lives *inside* the
identity (`unixMs` of the snowflake), and server-time fields belong to leases, which are Chapter 3.3's
business. Three fields, one of them cargo."

Two honesty notes from the chapter's Boundaries: `attempts` is written but not yet incremented — the field
belongs to this chapter's row, its arithmetic to the next chapter's transitions. And payload size is caller
discipline at this rung; a policy cap is a later knob, not a silent truncation.

## §4 The pending set

Pending is a sorted set with every member at score zero, members the job ids themselves. Equal scores order
lexicographically — byte-by-byte, which for branded ids is mint order — so the set is "simultaneously the FIFO
(lex-min is the oldest job) and the browse index (lex-max-down is newest-first) and the time-range index (an
id-prefix range is a time window)". The dividend is collected on stage by J4, which the third dive reads.

The score-zero decision is forever: the lex law holds only under equal scores, so delayed and scheduled work
will never mix scores into this set — **B3.3 · The State Machine in Lua** inherits a pre-stated plan, a
*separate* sorted set scored by run-time.

Interactive 2: the pending-set model — six `JOB` ids minted in sequence for this model with the course's
minting tool (demonstration data, not committed evidence): `JOB0Nvmd8aV5iy`, `JOB0Nvmd8gSfSK`,
`JOB0Nvmd8mzRRo`, `JOB0Nvmd8tnoZM`, `JOB0Nvmd90tmoy`, `JOB0Nvmd96ZlQG`. Sorting a scrambled copy byte-by-byte
reproduces mint order exactly; every member holds score 0; mixing a score in would break the lex law — which is
the score-zero decision.

## References

Sources:

- Valkey — Sorted sets — https://valkey.io/topics/sorted-sets/ (the same-score lexicographic family as a
  generic index; the different-scores caveat behind the score-zero decision)
- Valkey — ZRANGE — https://valkey.io/commands/zrange/ (the REV and BYLEX forms behind newest-first browse;
  equal-score elements order lexicographically)

Related:

- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/bus/fence-and-keyspace — B3.1 · The Fence and the Keyspace, the job key this row lives under
- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the separate schedule set the score-zero decision pre-states
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, the store discipline the row echoes
- /echomq — EchoMQ, the bus protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate patterns under the bus

Pager: previous `/bcs/bus/jobs-are-entities` · next `/bcs/bus/jobs-are-entities/enqueue-one-script`.
