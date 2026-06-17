# B4.1.1 · Declared, Not Discovered

> Dive 1 of B4.1 · route `/bcs/cache/cache-aside/declared-not-discovered` · teaches `content/bcs4.1.md` §"The
> declaration" + §"Three sources of one answer" · transcript lines `header`, `E1`, `E2` of
> `bcs_rung_4_1_check.out`.

A cache absent from the directory does not exist.

A cache comes into existence by declaring itself: name, kind, TTL, jitter, size bound, sweep interval, and
coherence mode, registered in the node's directory the moment the table starts and removed the moment it stops
or crashes — the directory monitors its tables, so the roster is true even after a failure. The committed
gate: "two caches enumerable with their full declarations -- kind, ttl, coherence -- an undeclared name
answers `:error`". And the kind law stands at the door exactly as it stands at every door in this series: "a
wrong-kind id is refused at the door: zero loader runs, zero keys on the wire".

Source: `content/bcs4.1.md`, quoting `bcs_rung_4_1_check.out`; the modules are committed at
`runtimes/elixir/lib/echo_cache/echo_cache.ex`, `lib/echo_cache/keyspace.ex`, `lib/echo_cache/table.ex`.

Interactive 1 (hero): the directory, asked three questions — the roster (the manuscript's `EchoCache.tables()`
answer for `:quotes`, verbatim), an undeclared name (`:error`), and a wrong-kind id at the door (the kind gate
performed live over the committed `AST0NuE6bV7FoH` and a demonstration `ORD` id minted for this model with the
course's minting tool — `ORD0NvppqSzgiO`, demonstration data, not committed evidence).

## §1 The transcript

This dive reads the header, E1, and E2 (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_1_check.out`):

```
header: Valkey 9.1.0 on 6390 | Elixir 1.14.0 OTP 25 | schedulers 1
E1 declared ok -- two caches enumerable with their full declarations -- kind, ttl, coherence -- an undeclared name answers :error, and a wrong-kind id is refused at the door: zero loader runs, zero keys on the wire
E2 sources ok -- one name, three sources in order: a cold read fills (loader ran once), a warm read hits L1 without touching the owner, and an L1 drop falls back to L2 -- the loader still ran once; the L2 row carries the declared TTL (PTTL 300 ms of 300)
PASS 6/6
```

(The full record holds E3–E6 and the derive lines; the dives that follow read them, and the hub freezes the
record whole.)

## §2 The declaration

A quote cache, declared (verbatim from the chapter's How):

```elixir
{:ok, _} =
  EchoCache.Table.start_link(
    name: :quotes,
    kind: "AST",
    ttl_ms: 300,
    jitter: 0.2,
    sweep_ms: 100,
    coherence: :none,          # wired by Chapter 4.2
    loader: &PriceFeed.load/1,
    connector: [port: 6390]
  )
```

The decision is "declared, not discovered": the directory is a monitored registry, not a convention — a table
registers its full specification at start, and a crash removes it. Enumeration is the operator's right, and
the negative is gated — an undeclared name answers `:error`. For operators, `EchoCache.tables/0` is the law
made callable: every cache on the node, with its full declaration, and nothing else — a cache absent from the
directory does not exist.

```elixir
EchoCache.tables()
# [{:quotes, %{kind: "AST", ttl_ms: 300, jitter: 0.2, coherence: :none, ...}}, ...]
```

The declared `coherence: :none` is a socket, not a shrug: **B4.2 · Coherence by Mint Time** wires it, and
inherits `invalidate/2` as the hook its coherence messages will pull. The declaration's wire is the production
connector, "reused untouched" — the manuscript plans the connector's prose appendix.

## §3 Three sources of one answer

A read resolves from L1, L2, or the declared loader, in that order, and the record walks one name through all
three: "a cold read fills (loader ran once), a warm read hits L1 without touching the owner, and an L1 drop
falls back to L2 -- the loader still ran once". The L2 row carries the declared TTL on the server's own clock
— `PTTL 300 ms of 300` — written with `SET ... PX` so the second layer expires itself even if every node
forgets.

The surface is `fetch/2` with source tags `:hit | :l2 | :fill` — observability, not ceremony:

```elixir
{:ok, quote, :hit} = EchoCache.Table.fetch(:quotes, "AST0NuE6bV7FoH")
```

The keyspace is its own — `ecc:{<table>}:<id>`, "a fresh prefix beside `emq:`, never inside it", hashtagged on
the table name for the clustered day.

Interactive 2: the three-sources walk — cold read → `:fill` (loader ran once, both layers written), warm read
→ `:hit` (L1, without touching the owner), L1 drop → `:l2` (the loader still ran once; `PTTL 300 ms of 300`).
The loader-runs counter holds 1 across the whole walk.

## References

Sources:

- Erlang/OTP — ets — https://www.erlang.org/doc/apps/stdlib/ets.html (public `read_concurrency` tables: the
  L1's storage, read caller-side)
- Valkey — SET — https://valkey.io/commands/set/ (the `PX` option: the L2 row written with its expiry in one
  command)
- Valkey — EXPIRE — https://valkey.io/commands/expire/ (expiration semantics: the server expires the L2 row on
  its own clock)

Related:

- /bcs/cache/cache-aside — B4.1 · Cache-Aside at ETS Speed, the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, the stores being cached
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the neighbouring keyspace discipline under `emq:`
- /redis-patterns — Redis Patterns Applied, the caching substrate patterns
- /echomq — EchoMQ, the bus protocol in rung-level depth

Pager: previous `/bcs/cache/cache-aside` · next `/bcs/cache/cache-aside/one-fill-per-herd`.
