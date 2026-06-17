# B2.4.1 · Archetypes Are Data — the model and the compose fold

> Route: `/bcs/elixir-core/archetypes/archetypes-are-data` (dive 1 of B2.4). The route-mirror
> source-of-record. Teaches `content/bcs2.4.md` (the What's model + the How's `compose/2`); figures verbatim
> from `bcs_rung_2_4_check.out`. Build stamp: `BCS0NuxnxzTY92`.

## Hero

Kicker: `B2.4 · dive 1 — archetypes are data`. Title: **A row, a reference, a map.** Lede — an archetype is
data: an entity under the newly registered `ARC` namespace whose value is a property bundle, extending at
most one parent. An instrument is a reference plus overrides. The composed view is a pure fold — bundles
folded root-first, overrides applied last, right-most wins. Heronote — source: `content/bcs2.4.md`, quoting
`bcs_rung_2_4_check.out`; the resolver is committed at `runtimes/elixir/lib/echo_data/bcs/archetypes.ex`.

### The chain, property by property (interactive SVG)

The working chain A1 builds: a derivative base (`margin: true, settlement: :t1, tick: 0.01`), a future
extending it (`settlement: :daily_mark, multiplier: 50`), and the ESZ6 instrument overriding tick
(`tick: 0.25`). Select a property; the readout names every source that offers it and the right-most one that
wins:

- `margin` → offered by the base only → `true` from the base.
- `settlement` → base offers `:t1`, the future archetype offers `:daily_mark` → `:daily_mark` from the
  archetype.
- `multiplier` → offered by the future archetype only → `50` from the archetype.
- `tick` → base offers `0.01`, the instrument overrides `0.25` → `0.25` from the instrument.

The composed view matches A1's gated sentence: `tick 0.25 from the instrument, settlement :daily_mark from
the archetype, margin true from the base`. Degrades to a static labelled diagram without JavaScript.

## §1 · The transcript (#transcript)

`bcs_rung_2_4_check.out` · verbatim · this dive reads the boot line and A1:

```text
boot: the registry grows by one -- ARC, archetype definitions as rows
A1 order ok -- composition order proven: tick 0.25 from the instrument, settlement :daily_mark from the archetype, margin true from the base
```

(The full transcript, `PASS 5/5`, is frozen on the module hub.)

## §2 · The model (#model)

Source: `content/bcs2.4.md` · What. An archetype bundle lives in the `:archetypes` store under `ARC`; it may
carry `:extends` naming one parent. An instrument row carries `archetype:` (the reference) and `overrides:`
(the deltas). The composed view is `compose(chain, overrides)` — bundles folded root-first, overrides applied
last, right-most wins — produced by a resolver that is pure by construction: it takes a fetch function, so the
same walk runs against a store boundary or a snapshot, and the fetch-function seam doubles as the test seam.
No behaviour modules, no protocol dispatch on kind, no hierarchy of code anywhere in the design.

## §3 · The fold, in Elixir and in Go (#fold)

The whole mechanism is four lines, and pure (`content/bcs2.4.md` · How):

```elixir
def compose(chain, overrides) when is_list(chain) and is_map(overrides) do
  chain
  |> Enum.reduce(%{}, &Map.merge(&2, &1))
  |> Map.merge(overrides)
  |> Map.delete(:extends)
end
```

The walk above it carries the seen-set and the depth cap; the store's own gate supplies a guard the resolver
does not re-implement — an `:extends` pointing outside `ARC` meets the archetype store's namespace refusal
before any bundle loads. The Go counterpart — the same fold, the same one-`:extends` law, over the owner's
map:

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

### The fold, stepped (interactive)

Step the fold over the fixed A1 chain: start at `%{}` → merge the base → merge the future archetype → merge
the ESZ6 overrides → drop `:extends`. The readout shows the accumulated map at every step, so right-most-wins
is visible as it happens. Degrades to the static step list.

## §4 · The ARC registration as a governance act (#arc)

Source: `content/bcs2.4.md` · Decisions. Archetypes are entities. The registry grows by one: `ARC`, archetype
definitions, platform scope — recorded as a decision because registration is the governance act Chapter 1.2
said it is. The boot line carries it verbatim: `boot: the registry grows by one -- ARC, archetype definitions
as rows`. A namespace registers when a kind needs identity and lifecycle of its own, and definitions qualified
because they are edited, audited, and one day replayed. Definitions live in the `:archetypes` property store
today — the store family **Property Stores on ETS** (B2.2) built — and in the forest of **The CHAMP Property
Database** (B2.3) the day history is asked for; same key, both homes.

## References (#refs)

Sources: West, M. — Evolve Your Hierarchy (`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/`)
· Venners, B. — Design Principles from Design Patterns, a conversation with Erich Gamma
(`https://www.artima.com/articles/design-principles-from-design-patterns`).
Related: `/bcs/elixir-core/archetypes` (B2.4 — the module hub) · `/bcs/elixir-core` (B2 · The Elixir BCS
Core) · `/bcs/elixir-core/property-stores` (B2.2 — the store archetypes live in) · `/bcs/ideas` (B1 — the law
and the contract) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/archetypes` — B2.4 · the hub. Next:
`/bcs/elixir-core/archetypes/one-definition-a-thousand-instruments` — One Definition, a Thousand Instruments.
