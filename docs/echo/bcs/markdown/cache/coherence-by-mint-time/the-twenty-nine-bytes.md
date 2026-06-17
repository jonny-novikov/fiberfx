# B4.2.1 · The Twenty-Nine Bytes

> Dive 1 of B4.2 · route `/bcs/cache/coherence-by-mint-time/the-twenty-nine-bytes` · teaches
> `content/bcs4.2.md` (What: the message, newer-wins) · reads gates F1–F2 of `bcs_rung_4_2_check.out`.

A cached name, a colon, and the writer's mint-time version.

`EchoCache.Coherence.payload/2` frames two names and nothing else; `parse/1` refuses anything that is not
exactly two valid branded ids. The committed surface gate: `a twenty-nine-byte payload of two names, parse
refusing garbage`. The cargo law of the whole series — only identities cross — rides into coherence unchanged.
And because the version is a branded id, the whole conflict protocol is one comparison of payload bytes:
newer-wins, with teeth the rung stages and freezes.

## §1 The transcript

Gates F1 and F2, verbatim (source: `content/echo_data/runtimes/elixir/bcs_rung_4_2_check.out`; the record
continues through F6 — the hub holds it whole):

```
F1 surface ok -- the vocabulary is whole: channel, queue, a twenty-nine-byte payload of two names, parse refusing garbage; tables declare their lane in the directory; and the connector's push path refuses a protocol 2 connection with a typed :requires_resp3
F2 newer-wins ok -- a late stale invalidation bounced off both layers -- the L1 row survived holding px=105.00 and the L2 drop script answered 0 -- while a genuinely newer version applied and the replay of the old one stayed stale: idempotence is a comparison, not a log
…
PASS 6/6
```

## §2 The message and its vocabulary

The frame is twenty-nine bytes: a cached name, a colon, and the writer's mint-time version — two branded ids of
fourteen characters each, one separator byte. `parse/1` refuses anything that is not exactly two valid branded
ids, so garbage dies at the boundary, the same move the stores made at theirs. The rest of the vocabulary
derives from the table name and nothing else: the channel is `ecc:{<table>}:coh`; the queue is
`ecc.coh.<table>`; tables declare their lane in the directory. And the connector grows the send-only push path
the broadcast lane stands on — `push_command/3` and `subscribe/2`, nothing enqueued on the FIFO, RESP3 required
and refused otherwise with a typed `:requires_resp3`. A SUBSCRIBE confirmation arrives as a push, so awaiting it
on the FIFO starves the queue — the new verb sends without enqueueing an expectation, and refuses protocol 2
where pushes and replies cannot share a wire.

The writer's side, after its store write (source: `content/bcs4.2.md`, How):

```elixir
version = BrandedId.generate!("TXN")           # the write's own identity
:ok = Table.put(:quotes, ast_id, "px=106.00", version)
{:ok, _heard} = Coherence.broadcast(conn, "quotes", ast_id, version)
# or, when at-least-once matters:
{:ok, :enqueued} = Coherence.enqueue(conn, "quotes", group, ast_id, version)
```

Mint versions where the write happens: the version is the write's identity, so the writer who changed the store
is the only true source of it — `put/3` mints one for writers who have no event id of their own, `put/4`
carries the writer's own.

## §3 Newer-wins has teeth

The dangerous case is not the fresh invalidation; it is the *stale* one arriving late — a slow lane, a retry, a
replay. The committed drill stages it: a row written at version `v_new`, then an invalidation carrying an older
version. The record: `a late stale invalidation bounced off both layers -- the L1 row survived holding
px=105.00 and the L2 drop script answered 0`. The L1 side is one comparison in the owner; the L2 side is one
Lua script — read the framed version, compare payloads, delete only if newer — the same predicate in two
places, because a late invalidation that can erase a newer row is a coordination bug wearing a latency costume.
And the same comparison is the idempotence story: `idempotence is a comparison, not a log` — replaying a
version answers `:stale` the second time, with no dedup table anywhere.

The comparison that is the whole protocol (source: `content/bcs4.2.md`, How):

```elixir
Coherence.newer?("TXN0NuG2aaaaaaa", "TXN0NuFzzzzzzzz")
# payload bytes in mint order: true — no decode, no clock, no quorum
```

Why a comparison is enough: Valkey's own tracking sends an unversioned *forget this key*; Nebulex synchronizes
by deletion; neither message carries an order, so a late invalidation and a fresh write race, and the loser is
whoever applied last. The fix the literature reached in 1978 is a total order constructed from timestamps, and
this series has carried that order in every identity since Part I. Two writes minted in the same millisecond on
different nodes order by node-and-sequence bits — "an arbitrary-but-total tiebreak in exactly Lamport's sense."
The manuscript plans the measured face-off in **B4.5 · The Cache Referee**; until that chapter ships, the
comparison set is characterized, never measured. The `coherence:` slot this message fills is declared by
**B4.1 · Cache-Aside at ETS Speed**'s table directory.

Files: `runtimes/elixir/lib/echo_cache/coherence.ex`, the grown `lib/echo_cache/table.ex`, the grown
`lib/echo_mq/connector.ex`.

## References

Sources:

- Valkey — Pub/Sub — https://valkey.io/topics/pubsub/ (the lane the message rides; RESP3 push frames)
- Valkey — Client-side caching — https://valkey.io/topics/client-side-caching/ (the comparison set's
  deletion-shaped coherence: no version, no order)
- Lamport, L. — Time, Clocks, and the Ordering of Events in a Distributed System —
  https://dl.acm.org/doi/10.1145/359545.359563 (the 1978 total order; the arbitrary-but-total tiebreak)

Related:

- /bcs/cache/coherence-by-mint-time — B4.2 · the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/bus — B3 · The Bus, the wire and the connector the vocabulary grows on
- /bcs/elixir-core/property-stores — B2.2 · Property Stores on ETS, the boundary discipline parse repeats
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate patterns
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/cache/coherence-by-mint-time` · next
`/bcs/cache/coherence-by-mint-time/the-broadcast-lane`.
