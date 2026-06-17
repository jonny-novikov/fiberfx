# The Streams Horizon — the entry-id injection

> Route: `/bcs/ideas/id-system/the-streams-horizon` (dive 4 of 4, B1.3). Teaches the streams horizon of
> `content/bcs1.3.md` (The streams horizon · How); evidence per
> `content/echo_data/bench/valkey-id/streams_bench.out`. Build stamp: `BCS0NtOSgVP4bI`.

## Hero

Kicker: `B1.3 · DIVE 4 OF 4 — the entry-id injection`. Title: **The id carries its window.** Lede — stream
entry ids are millisecond-sequence pairs, range-queryable by time because the id carries it. The injection
`unix_ms(snow)` dash `low-22-bits(snow)` is order-preserving — carrying the contract into the entry id costs
nothing and buys exact replay windows. Heronote — measured on 200,000 entries per stream against Valkey 9.1.0;
EchoMQ 3.0 plans Streams with PubSub, and this is the groundwork that plan stands on.

### The injection (interactive SVG)

The snowflake's bit fields — ts(41) · node(10) · seq(12) — split into the entry id's two halves: the
milliseconds above the epoch become the entry's time part, the low 22 bits become its sequence part. Buttons
per committed snowflake vector compute the mapping live with pure functions; a third button decodes the bench's
own first id. Degrades to the static bit-field diagram.

## §1 · The entry id (#entryid)

A stream entry id is a millisecond-sequence pair, range-queryable by time because the id carries it, under the
same monotonic top-id law the contract's minter obeys. The injection `unix_ms(snow)` dash `low-22-bits(snow)`
is therefore order-preserving: the snowflake's high bits are the milliseconds, and the low 22 bits — node and
sequence — break ties within the millisecond the same way on both sides.

## §2 · Measured (#measured)

Frozen (content/echo_data/bench/valkey-id/streams_bench.out · verbatim):

    # streams: Valkey 9.1.0, 200,000 entries, one 8B field/value pair each
    s_auto  entries=200000 bytes=4174928 per-entry=20
    s_brd   entries=200000 bytes=4161888 per-entry=20
    window [+10ms, +20ms) via branded-derived ids: 40960 entries (expected 40960)
    first id in window: "1781000000010-28672"  (low 22 bits = node 7 << 12 | seq 0 = 28672)

Explicit branded-derived ids cost the same 20 bytes per entry as `XADD *` auto-ids, and a ten-millisecond
window addressed purely by id arithmetic returned its predicted 40960 entries.

## §3 · The window arithmetic (#window)

Carrying the contract into the entry id buys exact replay windows addressed by the same `min_for` arithmetic
every runtime already implements. Interactive: buttons verify the bench's facts live — decode the first id's
low 22 bits (7 << 12 | 0 computed live), restate the window count against its expectation, and check order
preservation by mapping the two committed snowflake vectors and comparing both orders.

## §4 · The recipes (#recipes)

The fleet guarantee is that two runtimes shaping the same key produce the same bytes (content/bcs1.3.md · How):

    # Elixir — the connector side
    job_key   = "emq:{" <> queue <> "}:job:" <> EchoData.Snowflake.next_branded("ORD")
    stream_id = "#{EchoData.Snowflake.unix_ms(snow)}-#{Bitwise.band(snow, 0x3FFFFF)}"

    // Go — the consumer side
    jobKey   := "emq:{" + queue + "}:job:" + brandedid.MustEncode("ORD", snow)
    streamID := fmt.Sprintf("%d-%d", brandedid.UnixMs(snow), snow&0x3FFFFF)

Same grammar, same accessors-by-contract, byte-identical keys — so the hashtag's slot decision agrees across
the fleet. The injection is the one stream-id scheme (INV-K4 in the chapter's spec of record); a parallel
mapping would be the second clock in new clothing.

## References (#refs)

Sources: Valkey — Streams introduction (`https://valkey.io/topics/streams-intro/`) · Valkey — XADD
(`https://valkey.io/commands/xadd/`) · Valkey 8.1.0 GA (`https://valkey.io/blog/valkey-8-1-0-ga/`).
Related: `/bcs/ideas/id-system` (the hub) · `/bcs/ideas` · `/bcs` · `/echomq` (the bus whose engine this is) ·
`/redis-patterns`.

## Pager

Previous: dive 3 · `/bcs/ideas/id-system/the-chooser`. Next: back to the hub · `/bcs/ideas/id-system`.
