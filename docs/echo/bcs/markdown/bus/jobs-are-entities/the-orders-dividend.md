# B3.2.3 · The Order Theorem's Dividend

> Dive 3 of B3.2 · route `/bcs/bus/jobs-are-entities/the-orders-dividend` · teaches `content/bcs3.2.md`
> §"The pending set" (J4) + §"Idempotency and cargo" (J5) · transcript lines `J4`, `J5` of
> `bcs_rung_3_2_check.out`.

One set is three indexes.

Because job ids are branded snowflakes, the pending structure gets Chapter 1.2's theorem for free on a new
substrate: the ids are the chronology. The set is "simultaneously the FIFO (lex-min is the oldest job) and the
browse index (lex-max-down is newest-first) and the time-range index (an id-prefix range is a time window)".
J4 collects the dividend on stage; J5 closes the loop on the cargo law.

Source: `content/bcs3.2.md`, quoting `bcs_rung_3_2_check.out`.

Interactive 1 (hero): the three indexes, performed — over six `JOB` ids minted in sequence for this model with
the course's minting tool (demonstration data, not committed evidence). The FIFO answer is lex-min, the first
id minted; newest-first browse is reverse lex order, the last five in reverse mint order; a time window is an
id-prefix cut, no timestamp column anywhere.

## §1 The transcript

This dive reads J4 and J5 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_2_check.out`):

```
J4 dividend ok -- the order theorem's dividend: newest-first browse over the ids themselves returns the last five minted in reverse mint order; the very first job sits at the head; 301 pending, no second index anywhere
J5 cargo ok -- the cargo law holds: the payload carries ORD0Nt6z93U3dY and a quantity, never a row -- decoded and re-parsed on the far side of the wire
PASS 5/5
```

## §2 The dividend

J4 collects on stage what the structure promised: `newest-first browse over the ids themselves returns the
last five minted in reverse mint order; the very first job sits at the head; 301 pending, no second index
anywhere`. The rung holds three hundred and one pending jobs and asks the set the operator's questions —
newest-first, oldest-first — and the answers fall out of the bytes, because equal scores order
lexicographically and for branded ids byte order is mint order.

For producers: retry-safe enqueue by construction — fire it again on any doubt, the id is the receipt. For
operators: browse pending newest-first with one command and cut time windows as lex ranges over id prefixes,
"no schema migration ever having happened because the grammar *is* the schema and keys appear on first use."
And **B3.3 · The State Machine in Lua** inherits a pending set whose lex-min is always the claimable head.

## §3 The cargo law

J5 closes the loop: `the payload carries ORD0Nt6z93U3dY and a quantity, never a row -- decoded and re-parsed on
the far side of the wire`. The payload decodes on the far side to a map carrying `ORD0Nt6z93U3dY` and a
quantity, the id re-parses through the contract, and no row ever crossed the wire.

The chapter's When states the rule for callers: "Put ids and parameters in the payload; never rows, and never
blobs — a large artifact gets stored where artifacts live and referenced by its name, like everything else in
this series."

Interactive 2: the cargo, inspected — decode the payload (the committed record names two fields: the order id
and a quantity; the id is on the record, the number stays off stage), re-parse the id through the contract's
own arithmetic (`ORD0Nt6z93U3dY` → namespace `ORD`, node `7`, seq `0`, minted `2026-06-11 09:01:41 UTC` — the
same decoder the footer stamp runs), and ask what shipping the row instead would mean (the law's refusal).

## References

Sources:

- Valkey — ZRANGE — https://valkey.io/commands/zrange/ (the REV and BYLEX forms behind newest-first browse;
  equal-score elements order lexicographically)
- Valkey — Sorted sets — https://valkey.io/topics/sorted-sets/ (the same-score lexicographic family as a
  generic index; the different-scores caveat behind the score-zero decision)

Related:

- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/bus/fence-and-keyspace — B3.1 · The Fence and the Keyspace, the keys the browse ranges over
- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the inheritor of the claimable lex-min head
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, where chronology-without-a-column first performed
- /echomq — EchoMQ, the bus protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate: sorted sets as indexes

Pager: previous `/bcs/bus/jobs-are-entities/enqueue-one-script` · next `/bcs/bus/jobs-are-entities` (back to
the hub).
