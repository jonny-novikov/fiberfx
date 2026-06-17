# B2.3.3 · The Crossover — the forest buys time travel and pays in chronology

> Route: `/bcs/elixir-core/champ/the-crossover` (dive 3 of B2.3). The route-mirror source-of-record. Teaches
> the H4–H7 slice of `content/bcs2.3.md`; figures verbatim from `bcs_rung_2_3_check.out`. Build stamp:
> `BCS0Nuxm8oLpc8`.

## Hero

Kicker: `B2.3 · DIVE 3 — THE CROSSOVER`. Title: **The forest buys time travel and pays in chronology.** Lede
— H6 builds both stores at twenty thousand rows and refuses to pick a winner it did not measure: the flat
table wins the present, the forest wins history categorically — and the trade the trie makes silently is
named here rather than discovered later. Heronote — source: `content/bcs2.3.md`; the gates are H4–H7 in
`bcs_rung_2_3_check.out`; the comparison arm is Chapter 2.2's ETS store.

### The crossover, drawn (interactive SVG)

Four measured axes between the two store classes. Segments to select — **build** (`champ 41 ms vs ets 7 ms`),
**point read** (`champ 799 ns vs ets 315 ns`), **snapshot** (`1000 champ snapshots in 90 us` vs
`one ets copy-out in 2540 us`), **chronology** (`to_list/1` returns hash order; the byte-walk does not
survive). Live readout with the verbatim figures and which side the axis falls to; degrades to the static
labelled diagram.

## §1 · The transcript (#transcript)

`bcs_rung_2_3_check.out`, verbatim — this dive reads H4 through H7:

```text
H4 forest ok -- two kinds, one forest: namespace_size AST=500 ORD=500 from the cached census, partition exact
H5 hotpath ok -- by-snowflake 1858 ns/op vs string-id 2344 ns/op over 20000 puts
H6 crossover ok -- at 20000 rows -- build: champ 41 ms vs ets 7 ms; point read: champ 799 ns vs ets 315 ns; snapshot: 1000 champ snapshots in 90 us (a snapshot is a binding) vs one ets copy-out in 2540 us

07:31:13.583 [debug] ChampServer started with 0 entries
H7 server ok -- read scale-out: 10000 server calls 28 ms vs snapshot-once-then-pure 8 ms (copy cost included)
PASS 7/7
```

(The full record, H1–H3 included, is frozen on the module hub; the `[debug]` line stays — the drop logs its
starts, and the record keeps the drop's voice.)

## §2 · H4 and H5 — the census and the hot path (#forest)

Source: `content/bcs2.3.md` · What. H4 interleaves five hundred instruments and five hundred orders into one
structure and reads the partition exactly — `namespace_size AST=500 ORD=500` from the cached census, every
`get_namespace` row carrying its prefix. H5 times the integer lane: `by-snowflake 1858 ns/op vs string-id
2344 ns/op` over twenty thousand puts with the mint included in both arms — the lane a queue consumer holding
raw snowflakes should take. Take the integer lane whenever the snowflake is already in hand; the string path
exists for boundaries, not for loops.

## §3 · H6 — the crossover, stated plainly (#crossover)

Source: `content/bcs2.3.md` · What. The flat table wins the present: build `champ 41 ms vs ets 7 ms`, point
reads `champ 799 ns vs ets 315 ns`. The forest wins history categorically: a snapshot is a binding — one
thousand of them in 90 microseconds — against `one ets copy-out in 2540 us`, a price paid *per snapshot, per
row count*. And one trade the trie makes silently is named here rather than discovered later: hashing
scatters the keys, so the order theorem's free byte-walk does not survive — `to_list/1` returns hash order,
and a chronological read over the forest is a sort or a sibling ETS index. The forest buys time travel and
pays in chronology.

### The crossover comparator (interactive)

A pure function over the committed H6/H7 figures: select an axis (build · point read · snapshot · read
scale-out) and the readout computes which arm carries it and by what factor, from the verbatim numbers —
41 ms against 7 ms, 799 ns against 315 ns, 90 us per thousand bindings against 2540 us per copy-out, 28 ms
against 8 ms. Degrades to the static table of the committed figures.

## §4 · H7 — the snapshot-out pattern, and the Go counterpart (#server)

Source: `content/bcs2.3.md` · What, How. `ChampServer` is the thin owning process; H7 exercises the read
pattern the immutability enables: `get_champ/1` ships the whole structure across the process boundary *once*
— the BEAM copies messages, so this is one O(n) copy, priced in the gate — and then reads are pure calls on
the caller's own heap: `10000 server calls 28 ms vs snapshot-once-then-pure 8 ms (copy cost included)`.
Within a process, a snapshot is free; across processes, it costs one copy and then scales without the owner.

The BEAM's economics do not port — structural sharing rides an immutable heap and a sharing-aware GC — so the
honest Go counterpart is not a persistent trie but the epoch snapshot: an `atomic.Pointer[map[string]V]` the
owner swaps after copy-on-write batches, readers loading the pointer lock-free and holding their epoch as
long as they please:

```go
cur := state.Load()              // a snapshot is a pointer load
next := maps.Clone(*cur)         // the owner pays the copy, batched
next[id] = v
state.Store(&next)               // readers on old epochs are undisturbed
```

Coarser grain, same contract: a snapshot is a thing you hold, not a thing you rebuild — and if the epochs
shard, they shard by the same `hash32`.

## §5 · The tense litmus (#litmus)

Source: `content/bcs2.3.md` · When. One question decides the store class: *does any read ask about a moment
other than now?* If yes — versions, as-of, forks, undo — the forest is the representation and the per-write
path copy is fair rent. If no, Chapter 2.2's flat table wins on every measured axis and should be chosen
without sentiment. Hybrids are legitimate and ordinary: the present in ETS for point speed and ordered walks,
periodic forest snapshots for history — two representations, one identity key, no translation layer because
the key is the same fourteen bytes everywhere. A small interactive applies the litmus: select the workload's
tense (only now · other moments · both) and the readout names the store class the manuscript assigns.

## References (#refs)

Sources: Steindorfer & Vinju — OOPSLA 2015 (`https://dl.acm.org/doi/10.1145/2814270.2814312`) · Erlang/OTP —
the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core/champ` (B2.3 — the module hub) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) ·
`/bcs/elixir-core/property-stores` (B2.2 — the flat table that wins the present) · `/redis-patterns` (the
substrate door) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/champ/sharing-at-the-honest-metric` — Sharing at the Honest Metric. Next:
`/bcs/elixir-core/champ` — B2.3 · the hub.
