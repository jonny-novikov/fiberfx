# BCS · Chapter 3.2 — Jobs are entities

<show-structure depth="2"/>

The registry grows a second time: `JOB`, work as a kind, registered under the same bar `ARC` cleared — identity and lifecycle of its own. A job's row is a hash of three fields, its pending home is a sorted set whose members are the ids themselves, and its admission is one idempotent Lua script that refuses wrong kinds with a typed wire error before anything half-exists. The rung (`bcs_rung_3_2_check.exs`, committed record ending `PASS 5/5`) gates the surface, the idempotency, the server-side kind law, the order theorem's dividend, and the cargo rule — and its one live failure taught the part how custom errors travel on this wire.

## Why

Work without identity is logging. The moment a job can be retried, audited, cancelled, or asked about, it needs a name — and idempotency, the bus's most important property, is *definitionally* identity: deduplicate by what, if not a key? The oldest bug on any queue is the producer that enqueues twice because a reply got lost in a reconnect; an id-keyed enqueue makes the second attempt a cheap, truthful `duplicate` instead of a phantom double-fill on the trading desk. And because job ids are branded snowflakes, the pending structure gets Chapter 1.2's theorem for free on a new substrate: the ids are the chronology, so the queue never builds a second index to know its own order.

## What

**The row.** A job is a hash at the job key — `state`, `attempts`, `payload` — and deliberately nothing more. No `enqueued_at` field exists because the two-clocks law already placed that fact: mint time lives *inside* the identity (`unixMs` of the snowflake), and server-time fields belong to leases, which are Chapter 3.3's business. Three fields, one of them cargo.

**The pending set.** Pending is a sorted set with every member at score zero, members the job ids themselves. Equal scores order lexicographically [1] — byte-by-byte, which for branded ids is mint order — so the set is simultaneously the FIFO (lex-min is the oldest job) and the browse index (lex-max-down is newest-first) and the time-range index (an id-prefix range is a time window, the documentation's own generic-index pattern [2]). J4 collects the dividend on stage: `the last five minted in reverse mint order; the very first job sits at the head; 301 pending, no second index anywhere`.

**Enqueue, one script.** The whole admission law is ten lines of Lua, and the ordering of its three acts is a decision:

```lua
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

Policy before existence before write: an invalid id is refused before it can half-exist, a duplicate is answered before anything is touched, and the row and the pending entry land in one atomic step or not at all. Both keys live in one queue's family, so the script is single-slot legal by 3.1's grammar without a thought spent.

**The wire class, discovered live.** The rung's first run failed J3 on a real wire fact: the engine wraps class-less custom errors in its generic `ERR` prefix, and the connector's eval path surfaces server errors as `{:error, {:server, msg}}`. The fix was better protocol citizenship, not a looser match — the refusal now carries its own error class as its first word, `EMQKIND`, exactly the way the boot fence types its refusal, and the committed line reads `an ORD id in the job position answers EMQKIND on the wire -- the key let it pass, the law did not`. That last clause is 3.1's division performing: wellformedness at the key, policy at the script, each refusing in its own voice.

**Idempotency and cargo.** J2 gates the duplicate path as a *success shape*: `first call enqueued, second answered duplicate, the row untouched and pending holds 1` — duplicate is what an at-least-once producer wants to hear, not an exception to rescue. J5 closes the loop on the cargo law: the payload decodes on the far side to a map carrying `ORD0Nt6z93U3dY` and a quantity, the id re-parses through the contract, and no row ever crossed the wire.

## Who

Producers, who get retry-safe enqueue by construction — fire it again on any doubt, the id is the receipt. Operators, who browse pending newest-first with one command and can cut time windows as lex ranges over id prefixes, no schema migration ever having happened because the grammar *is* the schema and keys appear on first use. And Chapter 3.3, which inherits a pending set whose lex-min is always the claimable head.

## When

Put ids and parameters in the payload; never rows, and never blobs — a large artifact gets stored where artifacts live and referenced by its name, like everything else in this series. Treat `duplicate` as the normal vocabulary of a healthy producer, not a defect signal. And create queues by enqueueing into them: there is no create step, because a queue is a key family and key families are grammar.

## Where

The module at `runtimes/elixir/lib/echo_mq/jobs.ex` — surface gated at `enqueue, browse, pending_size` with scripts and key shapes as nobody's business; the script travels inside the module, SHA-pinned by `Script.new` and dispatched EVALSHA-first through the appendix's loader; the rung and its committed record beside the part's others.

## How — the script is the contract, in any runtime

**Elixir.** The Lua above is the implementation; the client half is a pattern match on the typed classes:

```elixir
case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
  {:ok, 1} -> {:ok, :enqueued}
  {:ok, 0} -> {:ok, :duplicate}
  {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
  other -> other
end
```

**Go.** The cross-runtime story needs no port at all, because the script *is* the contract: the same source string yields the same SHA1, and any client on any runtime that loads it speaks identical semantics — scripts are vectors for behavior the way `vectors.json` is for arithmetic. The Go consumer embeds the same bytes, computes the same digest, and gets the same three answers; the Go keyspace wrapper rides the existing follow-on.

## Decisions

**D-10 — the registry grows by `JOB`.** Work is a kind: minted, gated, browsed, audited, and one day replayed, platform scope, same bar as `ARC`.

**Policy before existence before write.** The script's act order is normative for every bundle script to come: refuse kinds first, answer duplicates second, mutate last.

**`duplicate` is a success shape.** At-least-once producers retry; the bus answers calmly and changes nothing.

**Refusals carry their own wire class.** `EMQKIND` sets the pattern: every typed refusal a bundle script issues leads with its class word, never riding the generic `ERR`.

**Pending stays score-zero forever.** The lex law holds only under equal scores [2], so delayed and scheduled work will never mix scores into this set — Chapter 3.3's schedule is a *separate* sorted set scored by run-time, migrating members into pending when due. The shape is pre-stated here so 3.3 inherits a plan.

## Boundaries

Payload size is caller discipline at this rung; a policy cap is a later knob, not a silent truncation. Browse covers pending only — terminal-state browsing arrives with the states themselves. Multi-producer ordering is arrival-interleaved, as any queue's is; within one producer, mint order holds. And `attempts` is written but not yet incremented: the field belongs to this chapter's row, its arithmetic to the next chapter's transitions.

## Companion files

`runtimes/elixir/lib/echo_mq/jobs.ex`; `bcs_rung_3_2_check.exs` and its committed record `bcs_rung_3_2_check.out`.

## References

1. Valkey documentation — ZRANGE (the REV and BYLEX forms behind newest-first browse; equal-score elements order lexicographically): [valkey.io/commands/zrange](https://valkey.io/commands/zrange/)
2. Valkey documentation — Sorted sets (the same-score lexicographic family and its use as a generic index; the different-scores caveat behind the score-zero decision): [valkey.io/topics/sorted-sets](https://valkey.io/topics/sorted-sets/)
