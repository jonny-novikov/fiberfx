# BCS · Chapter 2.3 — The CHAMP property database

<show-structure depth="2"/>

The production-drop pattern returns in its original direction: the Operator's CHAMP implementation — three modules, 1,458 lines, delivered on June 7 — is integrated into the tree under review, and the review earned its keep. One amendment was performed and gated: the drop's placement hash was a one-round mix, and it now delegates to the contract's `hash32` — one placement law, in-process too. The seven-gate rung (`bcs_rung_2_3_check.exs`, committed record ending `PASS 7/7`) puts the forest on stage: persistence, structural sharing at the honest metric, the namespace census, the by-snowflake hot path, the crossover against the flat table stated plainly in both directions, and the snapshot-out read pattern with the BEAM's copy semantics priced rather than hidden.

## Why

The desk asks questions in tenses the flat table cannot answer without copying itself: *what did the book look like at 14:30*, *show me the portfolio as-of yesterday's close*, *fork this risk scenario and mutate the copy*. Chapter 2.2's stores own the present perfectly; the moment history or hypotheticals become product features, every answer is a snapshot, and a snapshot of an ETS table is a copy-out priced per row. Structural sharing is the BEAM-native alternative — the immutable heap was built for exactly this — and the part preface's guideline (*a snapshot is a structure, not a copy*) is cashed here with words counted.

## What

**The drop's design, read against its source.** `EchoData.BrandedChamp` is a forest: a top-level map from the 3-byte namespace to a CHAMP trie, with the trie keyed by the *snowflake integer* — the id is split at the boundary, the base62 payload decoded once, and the integer enters the trie. The brand routes; the integer hashes. The nodes are the CHAMP design proper [1]: two 32-bit bitmaps per node — `datamap` for inline pairs, `nodemap` for children — over a popcount-indexed compact array, 5-bit hash fragments for 32-way branching, and the canonical representation the paper introduced so that equal maps are equal structures. Around the core: an O(1) cached census per namespace (`namespace_size/2`), the `Access`, `Enumerable`, and `Collectable` protocols, and a by-snowflake operation family that skips string handling when the caller already holds the integer.

**The review's finding.** The drop's `compute_hash_int` carried a single mixing round — the first `fmix64` constant, once — under a comment claiming it matches the Go side. The canon's Go *is* the full `fmix64` behind `hash32` (the committed `234878118` vector, at 0.9586 ns), and Chapter 1.2's law admits exactly one placement function. The integration therefore performs the alignment as a delegation — the amendment is three lines and a comment — and H1 gates it from both sides: `compute_hash_int -> BrandedId.hash32` asserted in the integrated source, and the reference snowflake round-tripping through the trie. The comment's intent is now true.

**Persistence and sharing, at the honest metric.** H2 writes a thousand `ORD` rows into `v1`, derives `v2` with one more put, and gates the defining property: `v1 holds 1000, v2 holds 1001`, and v1 cannot see the new row. H3 then counts heap words — and records a methods lesson worth keeping: the first metric ("percent of the pair shared") mathematically caps near fifty for two near-identical structures and *failed a correct implementation*. The metric of record is marginal cost: `v2 costs 122 words beside v1 (one path copy) against 6688 standalone -- 98% of v2 is shared with v1`. A version is a path; a thousand versions are a thousand paths, not a thousand maps.

**The forest and the hot path.** H4 interleaves five hundred instruments and five hundred orders into one structure and reads the partition exactly — `namespace_size AST=500 ORD=500` from the cached census, every `get_namespace` row carrying its prefix. H5 times the integer lane: `by-snowflake 1858 ns/op vs string-id 2344 ns/op` over twenty thousand puts with the mint included in both arms — the lane a queue consumer holding raw snowflakes should take.

**The crossover, stated plainly.** H6 builds both stores at twenty thousand rows and refuses to pick a winner it did not measure. The flat table wins the present: build `champ 41 ms vs ets 7 ms`, point reads `champ 799 ns vs ets 315 ns`. The forest wins history categorically: a snapshot is a binding — one thousand of them in 90 microseconds — against `one ets copy-out in 2540 us`, a price paid *per snapshot, per row count*. And one trade the trie makes silently is named here rather than discovered later: hashing scatters the keys, so the order theorem's free byte-walk does not survive — `to_list/1` returns hash order, and a chronological read over the forest is a sort or a sibling ETS index. The forest buys time travel and pays in chronology.

**The shell and the snapshot-out pattern.** `ChampServer` is the thin owning process; H7 exercises the read pattern the immutability enables: `get_champ/1` ships the whole structure across the process boundary *once* — the BEAM copies messages, so this is one O(n) copy, priced in the gate — and then reads are pure calls on the caller's own heap: `10000 server calls 28 ms vs snapshot-once-then-pure 8 ms (copy cost included)`. Within a process, a snapshot is free; across processes, it costs one copy and then scales without the owner.

## Who

The desk's historians: as-of reads, end-of-day forks, audit reconstructions — each is a binding kept, not a table copied. System authors choosing a store class per system, with the litmus below. And agents, whose surface is the drop's documented API: `put/3`, `fetch/2`, the `*_by_snowflake` family for integer-bearing paths, `get_namespace/2` and `namespace_size/2` for the census, `get_champ/1` for the snapshot-out pattern.

## When

One question decides the store class: *does any read ask about a moment other than now?* If yes — versions, as-of, forks, undo — the forest is the representation and the per-write path copy is fair rent. If no, Chapter 2.2's flat table wins on every measured axis and should be chosen without sentiment. Hybrids are legitimate and ordinary: the present in ETS for point speed and ordered walks, periodic forest snapshots for history — two representations, one identity key, no translation layer because the key is the same fourteen bytes everywhere. And take the integer lane whenever the snowflake is already in hand; the string path exists for boundaries, not for loops.

## Where

The integrated modules live at `runtimes/elixir/lib/echo_data/champ/` — `branded_champ.ex`, `champ_node.ex`, `champ_server.ex` — with the drop's provenance and the single amendment recorded in the source comment. The rung and its committed record sit beside the others; the server's own boot line (`ChampServer started with 0 entries`) appears in the record because the drop logs its starts, and the record keeps the drop's voice.

## How — the structure in Elixir, the epoch in Go

**Elixir.** The chapter's implementation *is* the drop; the amendment is the part worth quoting:

```elixir
# Chapter 2.3 integration review: placement delegated to the contract hash.
defp compute_hash_int(key) when is_integer(key) and key >= 0 do
  EchoData.BrandedId.hash32(key)
end
```

One function, one law, and H3's arithmetic as the payoff: a write is a root-to-leaf path — 122 words at a thousand entries — and everything off the path is the previous version, shared.

**Go.** The BEAM's economics do not port — structural sharing rides an immutable heap and a sharing-aware GC — so the honest Go counterpart is not a persistent trie but the epoch snapshot: an `atomic.Pointer[map[string]V]` the owner swaps after copy-on-write batches, readers loading the pointer lock-free and holding their epoch as long as they please:

```go
cur := state.Load()              // a snapshot is a pointer load
next := maps.Clone(*cur)         // the owner pays the copy, batched
next[id] = v
state.Store(&next)               // readers on old epochs are undisturbed
```

Coarser grain, same contract: a snapshot is a thing you hold, not a thing you rebuild — and if the epochs shard, they shard by the same `hash32`.

## Decisions

**One placement law, in-process too.** The alignment is performed and source-gated; any future structure that hashes identities delegates to the contract or does not merge.

**The marginal-cost metric is the sharing metric of record.** The denominator trap — a correct implementation failing a half-blind percentage — is documented so it is paid for once.

**Store class is chosen by the tense litmus, per system.** Forest for history, flat table for the present, hybrids welcome over the shared key.

**Silent-unchanged is the structure's contract; typed refusal is the boundary's.** The drop returns the champ unchanged on an undecodable payload — correct for a pure structure, insufficient for an ingress. The BCS-grade shell (namespace-scoped, `Bcs.gate` at every call, typed errors) is the carried integration rung, not a patch smuggled into the drop.

## Boundaries

Writes serialize through the owning process; concurrent-writer behavior is unmeasured because the architecture does not permit concurrent writers. Chronological reads over the forest are a sort or a sibling index — named above as the trie's standing trade. No disk persistence; the structure is memory-resident and the durability story remains where Part II put it. The node module's internal binary-hash fallback is unused on the branded path and stays as delivered. GC interplay under heavy version churn is real and unmeasured here.

## Companion files

`runtimes/elixir/lib/echo_data/champ/{branded_champ,champ_node,champ_server}.ex`; `bcs_rung_2_3_check.exs` and its committed record `bcs_rung_2_3_check.out`; the drop's originals preserved in the session uploads.

## References

1. Steindorfer, M. J. & Vinju, J. J. — Optimizing Hash-Array Mapped Tries for Fast and Lean Immutable JVM Collections. OOPSLA 2015, pp. 783–800 (the two-bitmap node, popcount indexing, cache locality, and the canonical representation this implementation carries): [dl.acm.org/doi/10.1145/2814270.2814312](https://dl.acm.org/doi/10.1145/2814270.2814312)
