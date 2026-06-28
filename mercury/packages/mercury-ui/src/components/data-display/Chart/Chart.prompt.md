# Chart — a token-driven SVG curve / area primitive

A geometry-**dumb** SVG plotter: the caller precomputes every path, scale, and tick, and Chart renders
them with token strokes, a gradient-filled area, grid lines, threshold markers, and axis rails. Reach
for it for a dashboard line/area curve where a pure geometry module already produced the paths. Import:
`import { Chart } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `viewBox` | `string` | — (required) | e.g. `"0 0 1000 300"`; parsed for grid/marker extents. |
| `series` | `ChartSeries[]` | — (required) | The lines/areas to draw (shape below). |
| `gridY` | `number[]` | `[]` | Horizontal grid-line y positions (viewBox units). |
| `gridX` | `number[]` | `[]` | Vertical grid-line x positions (viewBox units). |
| `yTicks` | `string[]` | — | Labels down the left rail (top → bottom). |
| `xTicks` | `string[]` | — | Labels along the bottom rail (left → right). |
| `gradients` | `{ id: string; stroke: string }[]` | `[]` | Linear gradients (top → transparent) referenced by `series.fillId`. |
| `markers` | `ChartMarker[]` | `[]` | Full-width threshold lines (e.g. a zero/loss boundary). |
| `height` | `number \| string` | `240` | CSS height of the chart box. |
| `ariaLabel` | `string` | — | Accessible name for the `role="img"` SVG. |

**`ChartSeries`** — `{ d: string; area?: string; stroke: string; fillId?: string; width?: number; dashed?: boolean }`:
`d` is the precomputed line path (`"M.. L.."`); `area` an optional closed area path filled by `fillId`'s
gradient; `stroke` a token color expression (e.g. `"rgb(var(--iris-9))"`); `width` defaults to `2.5`;
`dashed` switches to a `6 5` dasharray.

**`ChartMarker`** — `{ y: number; dashed?: boolean }`: `y` in viewBox units; markers are dashed by
default — `dashed: false` draws a solid line.

The component takes **no `…rest`** and is **not** `forwardRef`.

## The enum language

No enum props. Color is passed in directly as a **token expression** on each `series.stroke` /
`gradient.stroke` (e.g. `"rgb(var(--iris-9))"`), never a raw hex — the curve inherits the brand/status
token the caller chooses. Strokes use `vector-effect="non-scaling-stroke"`, so they stay crisp under
`preserveAspectRatio="none"`.

## Composition

- **Composes:** nothing — a leaf. It renders raw SVG from precomputed geometry and embeds no other
  Mercury component.
- **Composed by:** [Card](../Card/Card.prompt.md) — each curve panel wraps a Chart in a `raised` Card;
  with [Stat](../Stat/Stat.prompt.md) and [Table](../Table/Table.prompt.md) it forms the dashboard
  surface. *(Sibling contracts authored across mx.2; links resolve at set completion.)*

## Examples

```tsx
// A full curve — the caller's geometry module supplies every field
<Chart viewBox={g.viewBox} series={g.series} gridY={g.gridY} yTicks={g.yTicks} xTicks={g.xTicks} gradients={g.gradients} ariaLabel={g.ariaLabel} />
// codemojex-node/apps/economy/src/components/HousePctCurve.tsx
// (same call shape: PoolGrowthCurve.tsx)

// With a zero-line threshold marker
<Chart
  viewBox={g.viewBox}
  series={g.series}
  gridY={g.gridY}
  yTicks={g.yTicks}
  xTicks={g.xTicks}
  markers={g.zeroY != null ? [{ y: g.zeroY }] : []}
  ariaLabel={g.ariaLabel}
/>
// codemojex-node/apps/economy/src/components/MarginCurve.tsx
```

## Notes

- **Geometry-dumb by design** — Chart never computes a scale or a path. A pure geometry module owns
  `viewBox` / `series` / ticks; Chart only paints. Keep the math out of the component.
- An `area` fill only appears when its `fillId` matches a `gradients[].id`; a series with no `fillId`
  draws the line alone.
- `ariaLabel` is the only accessibility hook — the SVG is `role="img"`; pass a sentence describing the
  trend, since the curve itself is not readable.
- `markers` default to dashed; pass `dashed: false` for a solid boundary line.
