# B3.2.2 · Enqueue, One Script

> Dive 2 of B3.2 · route `/bcs/bus/jobs-are-entities/enqueue-one-script` · teaches `content/bcs3.2.md`
> §"Enqueue, one script" + §"The wire class, discovered live" + How (Elixir) · transcript lines `J2`, `J3` of
> `bcs_rung_3_2_check.out`.

Policy before existence before write.

The whole admission law is ten lines of Lua, and the ordering of its three acts is a decision: an invalid id is
refused before it can half-exist, a duplicate is answered before anything is touched, and the row and the
pending entry land in one atomic step or not at all.

Source: `content/bcs3.2.md`, quoting `bcs_rung_3_2_check.out`; the script travels inside
`runtimes/elixir/lib/echo_mq/jobs.ex`, SHA-pinned by `Script.new`.

Interactive 1 (hero): the admission simulator — three fixed presentations stepped through the script's three
acts. A minted `JOB` id on its first call passes the kind check, finds no existing row, and lands the row and
the pending entry in one atomic step: `1` on the wire, `{:ok, :enqueued}` at the caller. The same id again
passes the kind check and is answered at the existence check: `0`, `{:ok, :duplicate}`, nothing touched. The
committed `ORD0Nt6z93U3dY` in the job position is refused at act one: `EMQKIND job id must be JOB-namespaced`,
before existence is even asked.

## §1 The transcript

This dive reads J2 and J3 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_2_check.out`):

```
J2 idempotent ok -- enqueue is one script and idempotent by id: first call enqueued, second answered duplicate, the row untouched and pending holds 1
J3 kind ok -- kind policy lives in the script: an ORD id in the job position answers EMQKIND on the wire -- the key let it pass, the law did not
PASS 5/5
```

## §2 The script

The whole admission law, verbatim from the chapter:

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

"Policy before existence before write: an invalid id is refused before it can half-exist, a duplicate is
answered before anything is touched, and the row and the pending entry land in one atomic step or not at all.
Both keys live in one queue's family, so the script is single-slot legal by 3.1's grammar without a thought
spent." The act order is normative for every bundle script to come: refuse kinds first, answer duplicates
second, mutate last.

J2 gates the duplicate path as a *success shape*: `first call enqueued, second answered duplicate, the row
untouched and pending holds 1`. At-least-once producers retry; the bus answers calmly and changes nothing —
`duplicate` is the normal vocabulary of a healthy producer, not a defect signal.

## §3 The wire class, discovered live

The rung's first run failed J3 on a real wire fact: the engine wraps class-less custom errors in its generic
`ERR` prefix, and the connector's eval path surfaces server errors as `{:error, {:server, msg}}`. The fix was
better protocol citizenship, not a looser match — the refusal now carries its own error class as its first
word, `EMQKIND`, exactly the way the boot fence types its refusal, and the committed line reads `an ORD id in
the job position answers EMQKIND on the wire -- the key let it pass, the law did not`. That last clause is
3.1's division performing: wellformedness at the key, policy at the script, each refusing in its own voice.

The decision generalizes: refusals carry their own wire class — every typed refusal a bundle script issues
leads with its class word, never riding the generic `ERR`.

## §4 The client half

The Lua is the implementation; the client half is a pattern match on the typed classes, verbatim from the
chapter:

```elixir
case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
  {:ok, 1} -> {:ok, :enqueued}
  {:ok, 0} -> {:ok, :duplicate}
  {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
  other -> other
end
```

Interactive 2: the wire-answer matcher — four server replies traced to the clause that takes them: `1` to
`{:ok, :enqueued}`; `0` to `{:ok, :duplicate}`; a reply leading with `EMQKIND` to `{:error, :kind}`; and a
class-less error riding the generic `ERR` falling through to `other` — the first run's J3 failure mode, the
reason the class word exists.

The cross-runtime note from the chapter's How: the script *is* the contract — the same source string yields the
same SHA1, and any client on any runtime that loads it speaks identical semantics. The Go consumer embeds the
same bytes, computes the same digest, and gets the same three answers.

## References

Sources:

- Valkey — Sorted sets — https://valkey.io/topics/sorted-sets/ (the same-score lexicographic family the
  script's ZADD-at-zero feeds)
- Valkey — ZRANGE — https://valkey.io/commands/zrange/ (the REV and BYLEX forms the pending set answers;
  equal-score elements order lexicographically)

Related:

- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/bus/fence-and-keyspace — B3.1 · The Fence and the Keyspace, the division of labor this script completes
- /echomq — EchoMQ, the bus protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate: atomic Lua
- /elixir — Functional Programming in Elixir, the umbrella the runtimes live in

Pager: previous `/bcs/bus/jobs-are-entities/the-job-row` · next
`/bcs/bus/jobs-are-entities/the-orders-dividend`.
