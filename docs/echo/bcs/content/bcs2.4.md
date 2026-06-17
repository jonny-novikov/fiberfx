# BCS · Chapter 2.4 — Archetypes and composition

<show-structure depth="2"/>

The part preface promised the Looking Glass move on the BEAM; this chapter performs it. An archetype is data — an entity under a newly registered `ARC` namespace whose value is a property bundle, extending at most one parent — and an instrument is a reference plus overrides, composed into a view at read time by a pure fold. No behaviour modules, no protocol dispatch on kind, no hierarchy of code anywhere in the design. The rung (`bcs_rung_2_4_check.exs`, committed record ending `PASS 5/5`) gates the composition order, the one-definition amplification, the shape guards, archetypes as ordinary rows, and the read cost across three lanes — with the third lane delivering the chapter's best sentence.

## Why

Instrument taxonomies are where class hierarchies go to grow teeth: equity, future, option, each sharing margin and settlement machinery, each diverging somewhere, and twenty years of inherited game-engine wisdom says the subclass tree ends in tears — West's component turn [1] was the industry-scale retreat from exactly this shape, and the Gang of Four had stated the principle a decade earlier: favor composition over class inheritance, a judgment Gamma stood by — "I still think it's true even after ten years" [2] — because the base-subclass coupling is implicit and brittle. BCS gives the principle its data-only form: the shared semantics are a *row*, the kind is a *reference*, and the specialization is a *map* — so the trading desk's "all index futures now mark daily" is an edit to one entity, not a redeploy of a class.

## What

**The model.** An archetype bundle lives in the `:archetypes` store under `ARC`; it may carry `:extends` naming one parent. An instrument row carries `archetype:` (the reference) and `overrides:` (the deltas). The composed view is `compose(chain, overrides)` — bundles folded root-first, overrides applied last, right-most wins — produced by a resolver that is pure by construction: it takes a fetch function, so the same walk runs against a store boundary or a snapshot.

**Composition order, proven.** A1 builds the working chain — a derivative base (`margin: true, settlement: :t1, tick: 0.01`), a future extending it (`settlement: :daily_mark, multiplier: 50`), and the ESZ6 instrument overriding tick — and gates the exact view: `tick 0.25 from the instrument, settlement :daily_mark from the archetype, margin true from the base`. Three sources, one map, no ambiguity about who wins.

**One definition, a thousand instruments.** A2 is the feature the whole shape exists for: a thousand instruments reference the future archetype, one edit raises its multiplier, and every sampled instrument answers `multiplier 100 at next read` — no migration, no fan-out write. The economics ride along: `an instrument row is 18 words, its composed view 14` — the row stores a reference and deltas, and the view is computed, which is the part preface's *snapshot is a structure* guideline wearing its taxonomy clothes.

**The guards are shape, not lint.** A3 gates what the design makes unrepresentable rather than merely discouraged: `:extends` is one field, so the diamond cannot be written; a cycle is refused typed (`{:error, :cycle}`); a chain past eight is refused typed (`{:error, :depth}`). The hierarchy disease is prevented at the data model, where prevention is free.

**Archetypes are ordinary rows.** A4 closes the loop with Part I: an `AST` name offered to the archetype store earns `{:error, :namespace}`, and `ARC pages newest-first like any property` — definitions are gated, paged, and windowed like everything else, which means they are also *versionable* like everything else: hold the definitions in Chapter 2.3's forest and every archetype edit is a kept epoch, the desk's "what did the margin rules say on Tuesday" answered by a binding.

**Three lanes, one punchline.** A5 times the read path: `store-lane 5442 ns/op vs snapshot-lane 1048 ns/op` for a depth-2 resolve, against `a bare row get is 2653 ns/op`. The snapshot-lane resolve — the full composition, pure, over a defs snapshot — is *cheaper than a single bare get through the boundary*. Composition was never the cost; the boundary crossing was, and Chapter 2.3's snapshot-out pattern pays for itself one chapter later.

## Who

The instrument domain's owners, for whom a new kind is a new row and a rule change is an edit with A2's amplification. The desk's configuration changes, which become auditable entity history instead of deploy events. And agents, whose contract is the resolver's: inject the fetch, walk the chain, right-most wins — the fetch-function seam doubling as the test seam.

## When

Reach for an archetype the moment two instruments share semantics; before that, plain properties suffice. Put a fact in `overrides:` when it is per-contract (tick, lot, expiry); mint a new archetype when the *semantics* differ (daily marking is not a big tick). Snapshot the definitions store the moment resolves outnumber edits — which on a trading platform is immediately — and re-snapshot per epoch, not per read. And grow the registry the way `ARC` grew it: a namespace registers when a kind needs identity and lifecycle of its own, and definitions qualified because they are edited, audited, and one day replayed.

## Where

The resolver at `runtimes/elixir/lib/echo_data/bcs/archetypes.ex`; the rung and its committed record beside the others; the registration recorded as a decision in [`bcs.progress.md`](bcs.progress.md). Definitions live in the `:archetypes` property store today and in the forest the day history is asked for — same key, both homes.

## How — the fold, in Elixir and in Go

**Elixir.** The whole mechanism is four lines, and pure:

```elixir
def compose(chain, overrides) when is_list(chain) and is_map(overrides) do
  chain
  |> Enum.reduce(%{}, &Map.merge(&2, &1))
  |> Map.merge(overrides)
  |> Map.delete(:extends)
end
```

The walk above it carries the seen-set and the depth cap; the store's own gate supplies a guard the resolver never had to write — an `:extends` pointing outside `ARC` meets the archetype store's namespace refusal before any bundle loads.

**Go.** The same fold, the same one-`extends` law, over the owner's map:

```go
func Compose(chain []map[string]any, over map[string]any) map[string]any {
    out := map[string]any{}
    for _, b := range chain {
        maps.Copy(out, b)
    }
    maps.Copy(out, over)
    delete(out, "extends")
    return out
}
```

The chain walk carries a seen-set and a depth cap on that side too, and the snapshot lane is Chapter 2.3's epoch pointer: resolve against the loaded epoch, pay the boundary never.

## Decisions

**Archetypes are entities.** The registry grows by one: `ARC`, archetype definitions, platform scope — recorded as a decision because registration is the governance act Chapter 1.2 said it is.

**One `:extends`, by shape.** The diamond is unrepresentable rather than reviewed away; multiple mixins are modeled as chains or as explicit per-property choices, never as multiple parents.

**Composition happens at read time.** Baking views in at write time was considered and rejected: A2's amplification is the product feature, and a baked view is denormalized drift with a delay fuse.

**Overrides carry facts; archetypes carry semantics.** The line is stated so reviews can hold it: a number that varies per contract is an override, a behavior that varies per kind is a new bundle.

## Boundaries

Resolution is uncached by design at this rung — the epoch-snapshot lane *is* the cache strategy, and per-read memoization inside the resolver would hide the boundary cost A5 exists to show. A dangling `:extends` surfaces as the fetch's own `{:error, :not_found}`; the resolver adds no second vocabulary. Depth eight is a cap, not a recommendation — the working chains are depth two. Single node, one writer per store, as the part prescribes.

## Companion files

`runtimes/elixir/lib/echo_data/bcs/archetypes.ex`; `bcs_rung_2_4_check.exs` and its committed record `bcs_rung_2_4_check.out`.

## References

1. West, M. — Evolve Your Hierarchy: Refactoring Game Entities with Components. Cowboy Programming / Game Developer Magazine, 2007: [cowboyprogramming.com/2007/01/05/evolve-your-heirachy](https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/)
2. Venners, B. — Design Principles from Design Patterns: a conversation with Erich Gamma (the composition-over-inheritance principle from the Gang of Four book, defended a decade on): [artima.com/articles/design-principles-from-design-patterns](https://www.artima.com/articles/design-principles-from-design-patterns)
