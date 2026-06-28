# Stat — a KPI / metric tile

A standalone token-styled box: a label, a big mono value, and an optional tone-colored delta, hint, and
leading icon. Reach for it for a dashboard headline number — a balance, a percentage, a margin — when a
full `Card` is too heavy. Import: `import { Stat } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | `string` | — (required) | The metric name above the value. |
| `value` | `ReactNode` | — (required) | The headline figure — **formatted by the caller** (renders in DM Mono). |
| `delta` | `ReactNode` | — | Optional change chip, e.g. `"+30.3%"`. |
| `deltaTone` | `StatTone` | `"neutral"` | Colors the `delta` chip (see the enum language). |
| `hint` | `ReactNode` | — | Sub-caption under the value (and beside the delta). |
| `leading` | `ReactNode` | — | Optional leading icon before the label — usually an `<Icon />`. |
| `align` | `"left" \| "center"` | `"left"` | Text alignment of the tile. |

`StatTone` = `"neutral" \| "positive" \| "negative" \| "caution" \| "brand" \| "info"`.

The component takes **no `…rest`** and is **not** `forwardRef` — it is a plain styled `<div>`.

## The enum language

`deltaTone` resolves to a `.mx-stat__delta--<tone>` recipe over the **status families** (canon §6, each
ships `--bg-*` / `--fg-*` / `--border-*` / `--bg-*-subtle`):

- `neutral` — muted, no status color (the default — a delta with no good/bad meaning).
- `positive` — the `positive` family (a gain).
- `negative` — the `negative` family (a loss).
- `caution` — the `caution` family (a watch value).
- `brand` — the `brand` / iris accent (a headline figure to highlight).
- `info` — the `info` family.

`align` is layout only (`left | center`), not a token enum.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — in the optional `leading` slot
  (`leading={<Icon … />}`); otherwise it composes nothing (`value`/`delta`/`hint` are open `ReactNode`
  slots the caller formats).
- **Composed by:** [Card](../Card/Card.prompt.md) (the KPI panel container) and
  [Table](../Table/Table.prompt.md) — `Stat` · `Card` · `Table` form the dashboard surface; KPI rows
  and pool panels lay Stat tiles beside a table. *(Sibling contracts authored across mx.2; links resolve
  at set completion.)*

## Examples

```tsx
// A row of KPI tiles — value, delta, deltaTone, hint
<Stat label="House / guess" value={usd(s.houseUsd)} delta={pct(s.housePct)} deltaTone="brand" hint="of gross" />
<Stat
  label="Mobile margin"
  value={signedUsd(mob.margin)}
  delta={signedPct(mob.squeezePct)}
  deltaTone={mob.negative ? "negative" : "positive"}
  hint="after store fee"
/>
// codemojex-node/apps/economy/src/components/KpiRow.tsx

// Bare label + value (no delta/hint)
<Stat label="Keys held" value={state.keys} />
<Stat label="WAC / key" value={usd(currentWac, 4)} deltaTone="brand" />
// codemojex-node/apps/economy/src/components/BalanceSimPanel.tsx

// Inside a prize-pool panel
<Stat label="Prize pool" value={usd(pp.poolUsd)} hint={dia(pp.poolDiamonds)} />
<Stat label="House revenue" value={usd(pp.houseUsd)} deltaTone="brand" />
// codemojex-node/apps/economy/src/components/PrizePoolTable.tsx
```

## Notes

- **`value` is pre-formatted** — Stat applies the mono type but does no number formatting; the caller
  passes a finished string/node (`usd(…)`, `dia(…)`).
- The footer row renders only when `delta` **or** `hint` is set; with neither, the tile is just
  label + value.
- `deltaTone` colors only the `delta` chip — `neutral` (the default) leaves it muted, so always set a
  tone when the delta has good/bad meaning.
- Status-family map: `positive → positive` · `negative → negative` · `caution → caution` ·
  `brand → brand/iris` · `info → info`; `neutral` resolves to no status color.
