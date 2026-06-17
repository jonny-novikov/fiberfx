# B2.4.2 · One Definition, a Thousand Instruments — the amplification

> Route: `/bcs/elixir-core/archetypes/one-definition-a-thousand-instruments` (dive 2 of B2.4). The
> route-mirror source-of-record. Teaches `content/bcs2.4.md` (A2 + the Why's lineage + the Decisions);
> figures verbatim from `bcs_rung_2_4_check.out`. Build stamp: `BCS0Nuxny4rvcG`.

## Hero

Kicker: `B2.4 · dive 2 — one definition, a thousand instruments`. Title: **One edit, a thousand answers.**
Lede — A2 is the feature the whole shape exists for: a thousand instruments reference the future archetype,
one edit raises its multiplier, and every sampled instrument answers `multiplier 100 at next read` — no
migration, no fan-out write. Heronote — source: `content/bcs2.4.md`, quoting `bcs_rung_2_4_check.out`; the
resolver at `runtimes/elixir/lib/echo_data/bcs/archetypes.ex` composes the view at read time, which is what
makes the amplification possible.

### The amplification, performed (interactive SVG)

One definition node fanning out to a thousand instrument rows. Two states over the fixed dataset:

- **Before the edit** — the future archetype carries `multiplier: 50`; a sampled instrument's composed view
  reads `multiplier 50`.
- **After the edit** — one write raises the definition's multiplier; every sampled instrument answers
  `multiplier 100 at next read`. Writes performed: one, to the definition. Instrument rows touched: none.

The readout recomputes the sampled views through the same pure fold both times — the rows never changed, the
definition did. Degrades to the static before/after table without JavaScript.

## §1 · The transcript (#transcript)

`bcs_rung_2_4_check.out` · verbatim · this dive reads A2:

```text
A2 amplify ok -- one definition edited, a thousand instruments follow: multiplier 100 at next read; an instrument row is 18 words, its composed view 14
```

(The full transcript, `PASS 5/5`, is frozen on the module hub.)

## §2 · The economics — 18 words stored, 14 composed (#economics)

Source: `content/bcs2.4.md` · What. The economics ride along: `an instrument row is 18 words, its composed
view 14` — the row stores a reference and deltas, and the view is computed, which is the part preface's
*snapshot is a structure* guideline wearing its taxonomy clothes. The desk's "all index futures now mark
daily" is an edit to one entity, not a redeploy of a class; the desk's configuration changes become auditable
entity history instead of deploy events.

### Where does the fact live? (interactive)

The Decisions section states the line so reviews can hold it: overrides carry facts; archetypes carry
semantics. Select a fact from the chapter's own examples; the readout places it:

- tick — varies per contract → an override.
- lot — varies per contract → an override.
- expiry — varies per contract → an override.
- daily marking — semantics that vary per kind → a new bundle (daily marking is not a big tick).

A number that varies per contract is an override; a behavior that varies per kind is a new bundle. Degrades
to the static placement list.

## §3 · The lineage — West's turn, Gamma's decade (#lineage)

Source: `content/bcs2.4.md` · Why. Instrument taxonomies are where class hierarchies go to grow teeth, and
twenty years of inherited game-engine wisdom says the subclass tree ends in tears — West's component turn was
the industry-scale retreat from exactly this shape. The Gang of Four had stated the principle a decade
earlier: favor composition over class inheritance, a judgment Gamma stood by — "I still think it's true even
after ten years" — because the base-subclass coupling is implicit and brittle. BCS gives the principle its
data-only form: the shared semantics are a *row*, the kind is a *reference*, and the specialization is a
*map*.

## §4 · The rejected alternative — baked views (#baked)

Source: `content/bcs2.4.md` · Decisions. Composition happens at read time. Baking views in at write time was
considered and rejected: A2's amplification is the product feature, and a baked view is denormalized drift
with a delay fuse. The boundaries hold the same line from the other side: resolution is uncached by design at
this rung — the epoch-snapshot lane *is* the cache strategy, and per-read memoization inside the resolver
would hide the boundary cost A5 exists to show. The lanes and their measured costs are dive 3's subject; the
snapshot they resolve against is the snapshot-out pattern of **The CHAMP Property Database** (B2.3).

## References (#refs)

Sources: West, M. — Evolve Your Hierarchy (`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/`)
· Venners, B. — Design Principles from Design Patterns, a conversation with Erich Gamma
(`https://www.artima.com/articles/design-principles-from-design-patterns`).
Related: `/bcs/elixir-core/archetypes` (B2.4 — the module hub) · `/bcs/elixir-core` (B2 · The Elixir BCS
Core) · `/bcs/elixir-core/property-stores` (B2.2 — the store archetypes live in) · `/bcs/ideas` (B1 — the law
and the contract) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/archetypes/archetypes-are-data` — Archetypes Are Data. Next:
`/bcs/elixir-core/archetypes/the-guards-and-the-lanes` — The Guards and the Lanes.
