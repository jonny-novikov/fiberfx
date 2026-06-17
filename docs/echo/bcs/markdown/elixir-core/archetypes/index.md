# B2.4 · Archetypes and Composition — an archetype is data

> Route: `/bcs/elixir-core/archetypes` (module hub, B2.4). The route-mirror source-of-record. Teaches
> `content/bcs2.4.md`; every figure verbatim from the committed `bcs_rung_2_4_check.out` (`PASS 5/5`).
> Build stamp: `BCS0NuxnxtnZXk`.

## Hero

Kicker: `B2.4 · ARCHETYPES AND COMPOSITION — manuscript chapter 2.4`. Title: **An archetype is data.** Lede —
the part preface promised the Looking Glass move on the BEAM; this chapter performs it. An archetype is an
entity under a newly registered `ARC` namespace whose value is a property bundle, extending at most one parent
— and an instrument is a reference plus overrides, composed into a view at read time by a pure fold. No
behaviour modules, no protocol dispatch on kind, no hierarchy of code anywhere in the design. Heronote — the
chapter is `content/bcs2.4.md`; the rung behind it is `bcs_rung_2_4_check.exs`, and its committed record closes
`PASS 5/5`. Composition order, amplification, shape guards, ordinary rows, and the read cost across three
lanes — each gated on stage.

### The five gates, mapped to the dives (interactive SVG)

Five gates in transcript order (A1–A5). Select a gate to read its verbatim line and the dive that teaches it:

- **A1** — `A1 order ok -- composition order proven: tick 0.25 from the instrument, settlement :daily_mark
  from the archetype, margin true from the base` → dive 1, Archetypes Are Data.
- **A2** — `A2 amplify ok -- one definition edited, a thousand instruments follow: multiplier 100 at next
  read; an instrument row is 18 words, its composed view 14` → dive 2, One Definition, a Thousand Instruments.
- **A3** — `A3 guard ok -- the diamond is unrepresentable (one :extends) and the cycle is refused:
  {:error, :cycle}; depth capped at 8: {:error, :depth}` → dive 3, The Guards and the Lanes.
- **A4** — `A4 rows ok -- archetypes are rows: an AST name refused with {:error, :namespace}; ARC pages
  newest-first like any property` → dive 3.
- **A5** — `A5 cost ok -- read-time composition over a depth-2 chain: store-lane 5442 ns/op vs snapshot-lane
  1048 ns/op; a bare row get is 2653 ns/op` → dive 3.

Degrades to a static labelled diagram without JavaScript.

## §1 · Why — composition over class inheritance (#why)

Source: `content/bcs2.4.md` · Why. Instrument taxonomies are where class hierarchies go to grow teeth: equity,
future, option, each sharing margin and settlement machinery, each diverging somewhere — and twenty years of
inherited game-engine wisdom says the subclass tree ends in tears. West's component turn was the
industry-scale retreat from exactly this shape, and the Gang of Four had stated the principle a decade
earlier: favor composition over class inheritance, a judgment Gamma stood by — "I still think it's true even
after ten years" — because the base-subclass coupling is implicit and brittle. BCS gives the principle its
data-only form: the shared semantics are a *row*, the kind is a *reference*, and the specialization is a *map*
— so the trading desk's "all index futures now mark daily" is an edit to one entity, not a redeploy of a
class. Four facets: the semantics are a row · the kind is a reference · the specialization is a map · the
registry grows by one (`ARC`, recorded as a decision — registration is the governance act Chapter 1.2 said it
is).

## §2 · The proof (#proof)

The full committed transcript (`content/bcs2.4.md`, quoting `bcs_rung_2_4_check.out`), verbatim:

```text
boot: the registry grows by one -- ARC, archetype definitions as rows
A1 order ok -- composition order proven: tick 0.25 from the instrument, settlement :daily_mark from the archetype, margin true from the base
A2 amplify ok -- one definition edited, a thousand instruments follow: multiplier 100 at next read; an instrument row is 18 words, its composed view 14
A3 guard ok -- the diamond is unrepresentable (one :extends) and the cycle is refused: {:error, :cycle}; depth capped at 8: {:error, :depth}
A4 rows ok -- archetypes are rows: an AST name refused with {:error, :namespace}; ARC pages newest-first like any property
A5 cost ok -- read-time composition over a depth-2 chain: store-lane 5442 ns/op vs snapshot-lane 1048 ns/op; a bare row get is 2653 ns/op
PASS 5/5
```

The resolver lives at `runtimes/elixir/lib/echo_data/bcs/archetypes.ex`; it is pure by construction — it takes
a fetch function, so the same walk runs against a store boundary or a snapshot, and the fetch-function seam
doubles as the test seam. The third lane delivers the chapter's best sentence: the snapshot-lane resolve — the
full composition, pure, over a defs snapshot — is cheaper than a single bare get through the boundary.
Composition was never the cost; the boundary crossing was. The module stands between **The CHAMP Property
Database** (B2.3) and **Relations Are Systems** (B2.5) in the Part II arc.

## §3 · The dives (#dives)

- **Archetypes Are Data** (`archetypes-are-data`) — the model and the `compose` fold: an archetype is a row
  under `ARC`, at most one `:extends`; an instrument is a reference plus overrides; composition at read time
  by a pure fold. A1's composition order proven — `tick 0.25 from the instrument, settlement :daily_mark from
  the archetype, margin true from the base`. The `ARC` registration as a governance act.
- **One Definition, a Thousand Instruments** (`one-definition-a-thousand-instruments`) — A2 the amplification:
  one definition edited, a thousand instruments answer `multiplier 100 at next read`, no migration. The
  economics — `an instrument row is 18 words, its composed view 14`. West's component turn, Gamma's defended
  principle, and the baked-views-rejected decision.
- **The Guards and the Lanes** (`the-guards-and-the-lanes`) — A3 the guards are shape, not lint: one
  `:extends` makes the diamond unrepresentable, `{:error, :cycle}`, `{:error, :depth}`. A4 archetypes are
  ordinary rows: an `AST` name refused `{:error, :namespace}`, `ARC pages newest-first like any property`.
  A5 the three lanes: `store-lane 5442 ns/op vs snapshot-lane 1048 ns/op`, `a bare row get is 2653 ns/op`.

## References (#refs)

Sources: West, M. — Evolve Your Hierarchy (`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/`)
· Venners, B. — Design Principles from Design Patterns, a conversation with Erich Gamma
(`https://www.artima.com/articles/design-principles-from-design-patterns`).
Related: `/bcs/elixir-core` (B2 · The Elixir BCS Core) · `/bcs/elixir-core/property-stores` (B2.2 — the store
archetypes live in) · `/bcs/elixir-core/champ` (B2.3 — the forest the snapshot lane resolves against) ·
`/bcs/elixir-core/relations` (B2.5 — the module the arc continues into) · `/bcs/ideas` (B1 — the law and the
contract) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core` — B2 · The Elixir BCS Core. Next:
`/bcs/elixir-core/archetypes/archetypes-are-data` — Archetypes Are Data.
