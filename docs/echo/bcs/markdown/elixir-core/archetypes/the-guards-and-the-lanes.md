# B2.4.3 · The Guards and the Lanes — shape, rows, and the read cost

> Route: `/bcs/elixir-core/archetypes/the-guards-and-the-lanes` (dive 3 of B2.4). The route-mirror
> source-of-record. Teaches `content/bcs2.4.md` (A3 + A4 + A5); figures verbatim from
> `bcs_rung_2_4_check.out`. Build stamp: `BCS0NuxnyAGJ5U`.

## Hero

Kicker: `B2.4 · dive 3 — the guards and the lanes`. Title: **Unrepresentable, ordinary, and cheap.** Lede —
three closings: A3 gates what the data model makes unrepresentable rather than merely discouraged, A4 proves
archetypes are ordinary rows under the same law as everything else, and A5 times the read path across three
lanes — with the third lane delivering the chapter's best sentence. Heronote — source: `content/bcs2.4.md`,
quoting `bcs_rung_2_4_check.out`; the working chains are depth two, and depth eight is a cap, not a
recommendation.

### The guards, exercised (interactive SVG)

A pure model of the resolver's shape guards over fixed inputs. Select a shape; the readout names the verdict:

- a one-parent chain (base ← future ← ESZ6) → resolves; the composed view comes back.
- a diamond — two parents — → cannot be written: `:extends` is one field, so the diamond is unrepresentable.
- a cycle (a → b → a) → refused typed: `{:error, :cycle}`.
- a chain past eight → refused typed: `{:error, :depth}`.
- an `AST` name offered to the archetype store → refused before any walk: `{:error, :namespace}`.

Degrades to the static verdict list without JavaScript.

## §1 · The transcript (#transcript)

`bcs_rung_2_4_check.out` · verbatim · this dive reads A3, A4, and A5:

```text
A3 guard ok -- the diamond is unrepresentable (one :extends) and the cycle is refused: {:error, :cycle}; depth capped at 8: {:error, :depth}
A4 rows ok -- archetypes are rows: an AST name refused with {:error, :namespace}; ARC pages newest-first like any property
A5 cost ok -- read-time composition over a depth-2 chain: store-lane 5442 ns/op vs snapshot-lane 1048 ns/op; a bare row get is 2653 ns/op
```

(The full transcript, `PASS 5/5`, is frozen on the module hub.)

## §2 · A3 — the guards are shape, not lint (#guards)

Source: `content/bcs2.4.md` · What · Decisions. A3 gates what the design makes unrepresentable rather than
merely discouraged: `:extends` is one field, so the diamond cannot be written; a cycle is refused typed
(`{:error, :cycle}`); a chain past eight is refused typed (`{:error, :depth}`). The hierarchy disease is
prevented at the data model, where prevention is free. One `:extends`, by shape: multiple mixins are modeled
as chains or as explicit per-property choices, never as multiple parents. A dangling `:extends` surfaces as
the fetch's own `{:error, :not_found}`; the resolver adds no second vocabulary.

## §3 · A4 — archetypes are ordinary rows (#rows)

Source: `content/bcs2.4.md` · What. A4 closes the loop with Part I: an `AST` name offered to the archetype
store earns `{:error, :namespace}`, and `ARC pages newest-first like any property` — definitions are gated,
paged, and windowed like everything else, which means they are also *versionable* like everything else: hold
the definitions in Chapter 2.3's forest and every archetype edit is a kept epoch, the desk's "what did the
margin rules say on Tuesday" answered by a binding. The forest belongs to **The CHAMP Property Database**
(B2.3); the store discipline to **Property Stores on ETS** (B2.2).

## §4 · A5 — three lanes, one punchline (#lanes)

Source: `content/bcs2.4.md` · What. A5 times the read path: `store-lane 5442 ns/op vs snapshot-lane 1048
ns/op` for a depth-2 resolve, against `a bare row get is 2653 ns/op`. The snapshot-lane resolve — the full
composition, pure, over a defs snapshot — is *cheaper than a single bare get through the boundary*.
Composition was never the cost; the boundary crossing was, and Chapter 2.3's snapshot-out pattern pays for
itself one chapter later.

### The lane comparator (interactive)

Three fixed measurements from A5; select a lane and the readout draws the comparison and computes the ratios
from the committed figures:

- store-lane resolve, depth-2 chain — `5442 ns/op`.
- snapshot-lane resolve, the same composition — `1048 ns/op`.
- a bare row get through the boundary — `2653 ns/op`.

The snapshot-lane resolve runs below the bare get; the store-lane resolve carries the boundary crossing per
bundle. Snapshot the definitions store the moment resolves outnumber edits — which on a trading platform is
immediately — and re-snapshot per epoch, not per read. Degrades to the static figure list.

## References (#refs)

Sources: West, M. — Evolve Your Hierarchy (`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/`)
· Venners, B. — Design Principles from Design Patterns, a conversation with Erich Gamma
(`https://www.artima.com/articles/design-principles-from-design-patterns`).
Related: `/bcs/elixir-core/archetypes` (B2.4 — the module hub) · `/bcs/elixir-core` (B2 · The Elixir BCS
Core) · `/bcs/elixir-core/property-stores` (B2.2 — the store archetypes live in) · `/bcs/ideas` (B1 — the law
and the contract) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/archetypes/one-definition-a-thousand-instruments` — One Definition, a Thousand
Instruments. Next: `/bcs/elixir-core/archetypes` — B2.4 · the hub.
