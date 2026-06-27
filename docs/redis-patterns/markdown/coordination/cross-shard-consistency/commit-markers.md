# Commit markers — make an incomplete transaction invisible

> Route: `/redis-patterns/coordination/cross-shard-consistency/commit-markers` · Dive R2.04.3 · Source:
> `content/coordination/cross-shard-consistency.md.txt` (slice: *Pattern 3: Commit Marker*, plus the *Commit markers*
> row of *Comparison with Prevention Strategies*).
> · Grounding: EchoMQ needs **no** commit marker, because the single Lua `EVAL` over co-located keys is the
> serialization point. `EchoMQ.Jobs.complete/4` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:313`) runs the `@complete`
> script (jobs.ex:139) as one `Connector.eval/5` over declared keys; it applies in full or not at all, with no
> two-phase marker to gate. The generic marker is the multi-shard substitute for that one-EVAL atomicity.

A detector catches the tear after the read. A commit marker keeps the half-finished write from ever being read — the
data is present, but switched off until the marker turns it on. Write every data key first, then one final
`SET txn:id:committed 1 EX 3600`; a reader checks `EXISTS txn:id:committed` before touching the data. A crash before
that marker leaves the data on disk but invisible, so a torn state is never read — a two-phase-commit shape, the
marker as the decision record.

## Write the marker last

The shared token and the version field both detect a tear: the read pulls both values back, compares them, and reacts
to a mismatch. The torn pair still reaches the caller, and the caller has to repair it. A commit marker changes the
order of operations so the incomplete pair never reaches a read at all.

Write every data key first. Then, as a separate final step, write one extra key that records the decision to commit:

```
# Phase 1: write the data (may partially fail)
SET txn:abc:A "{payload_A}"
SET txn:abc:B "{payload_B}"

# Phase 2: mark the transaction committed
SET txn:abc:committed "1" EX 3600
```

The ordering is the whole mechanism. Phase 1 places the data; phase 2 publishes it. Until the marker key exists, the
data keys are present but uncommitted — written to the store, yet not yet declared whole. The `EX 3600` bounds the
marker's lifetime so abandoned transaction records do not accumulate without bound.

## Read through the gate

A reader does not touch the data keys until it has confirmed the marker. `EXISTS txn:abc:committed` is the gate: a `1`
means phase 2 completed, so the pair is whole and safe to use; a `0` means the marker was never written, so the
transaction is incomplete and the data is treated as absent.

```
if EXISTS txn:abc:committed:
    a = GET txn:abc:A
    b = GET txn:abc:B
    # safe to use — the marker proves both writes landed
else:
    # transaction incomplete — ignore the data, or wait and re-check
```

If the writer dies after phase 1 but before phase 2, the data keys exist — possibly torn, A new and B old — but the
marker does not. The gate returns `0`, the read never touches the half-written pair, and the incomplete transaction is
invisible. A crash *after* phase 2 is a complete transaction by definition: every data key and the marker are present,
so the gate returns `1` and the pair is read. This is the property the detection patterns cannot offer: a token
detector lets the torn pair through and asks the caller to clean it up; the marker keeps the torn pair from ever being
visible. The trade is one extra key per transaction and one extra round trip on the read.

## A two-phase-commit shape

The pattern resembles two-phase commit, with the marker acting as the decision record. Phase 1 is the prepare: stage
every value, commit to nothing. Phase 2 is the single write that flips the whole transaction from prepared to
committed. The marker is the one bit the entire read keys off — present means committed, absent means not.

It is a *shape*, not a full protocol. There is no coordinator forcing all participants to commit, no rollback that
removes the staged data, and the marker write is itself a single key that can fail. What it buys is a clean visibility
rule across keys that cannot share a slot: a read returns a committed transaction or it returns nothing. Where
ordering matters too, the marker composes with a version field — the version names the newer write, the marker gates
whether either write is visible yet.

## Marker versus a bare token

The same partial-failure timeline reads two ways. A bare shared token is a *detector*: the read fetches both values,
parses both tokens, and on a mismatch returns a torn pair the caller must repair. A commit marker is a *gate*: the
read checks `EXISTS …:committed` first and, finding it absent, returns nothing — the incomplete write is not visible,
so there is nothing to repair. Detection exposes the tear and pushes the recovery onto the reader; the marker hides
the tear and removes the recovery step entirely. The comparison table in the source places them side by side — a
transaction stamp buys *detect only*, a commit marker buys *detect plus visibility*.

## The pattern, applied — one EVAL removes the marker

EchoMQ does not write a commit marker on its own queue transitions, because the transition it would gate is already
atomic in one step. A queue's keys share one slot (the `{q}` hashtag in `EchoMQ.Keyspace.queue_key/2`), so the whole
move is one inline Lua script. `EchoMQ.Jobs.complete/4` (jobs.ex:313) hands `Connector.eval/5` the `@complete` script
(jobs.ex:139) over two declared keys — `KEYS[1] = emq:{q}:active`, `KEYS[2] = emq:{q}:job:<id>`:

```lua
local att = redis.call('HGET', KEYS[2], 'attempts')
if not att then return 0 end
if att ~= ARGV[2] then
  return redis.error_reply('EMQSTALE complete token mismatch')
end
...
redis.call('ZREM', KEYS[1], ARGV[1])
redis.call('DEL', KEYS[2])
return 1
```

That whole sequence — the fencing check, the `ZREM` off the active set, the `DEL` of the row — is one `EVAL`. It is
visible-or-not in a single step: the job is retired in full, or `EMQSTALE` is returned and nothing changed. There is
no half-written pair to gate, so there is nothing for a commit marker to do. The v2 law that makes this one step safe
is in `Connector.eval/5` (`connector.ex:63`): every key the script touches is declared in `KEYS`, so the engine keeps
them on one slot and runs the move as a unit.

A commit marker is the multi-shard substitute for exactly that atomicity. You reach for it when the writes land on
keys that genuinely cannot share a slot — a Valkey read-model paired with codemojex's database of record,
where a single move script is not available and a torn write would otherwise be readable. There the marker rebuilds,
at the cost of one extra key, the visible-or-not property the one-`EVAL` move gives EchoMQ for free.

The colocation that removes the need for any of these — the marker, the token, the version — is the chapter's next
module, **R2.05 hash-tag colocation** (return to the [Coordination chapter](/redis-patterns/coordination) to reach
it). The full v2 script bundle belongs to the dedicated EchoMQ course.

## References

### Sources
- [Redis — EXISTS](https://redis.io/commands/exists/) — the gate the reader checks before touching the data;
  `EXISTS txn:id:committed` returns `1` for a committed transaction and `0` for an incomplete one.
- [Valkey — EXISTS](https://valkey.io/commands/exists/) — the engine's own presence check; the read-visibility gate
  behind the commit marker.
- [Redis — SET](https://redis.io/commands/set/) — the data writes and the marker write; `SET txn:id:committed 1 EX
  3600` publishes the transaction and bounds the marker's lifetime.
- [Redis — Transactions](https://redis.io/docs/latest/develop/interact/transactions/) — `MULTI`/`EXEC` and the
  two-phase-commit framing the marker mirrors across keys that cannot share a slot.
- [Redis — Cluster specification](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/) — hash
  tags, the 16384 slots, and `CROSSSLOT` for multi-key commands that span slots.

### Related in this course
- [R2.04 · Cross-shard consistency](/redis-patterns/coordination/cross-shard-consistency) — the module hub: all four
  detection patterns and the prevention comparison.
- [R2.04.2 · Version tokens](/redis-patterns/coordination/cross-shard-consistency/version-tokens) — the previous dive:
  the version field that orders a tear, which a marker composes with.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the single-slot atomic move that is
  visible-or-not in one step, so it needs no marker.
- [/echomq/protocol](/echomq/protocol) — the dedicated EchoMQ course: the full v2 script bundle in depth.
- [/elixir · CQRS](/elixir/pragmatic/cqrs) — the single-writer engine where a commit boundary keeps a half-finished
  update unseen.
