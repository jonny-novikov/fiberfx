# Card — a surface container with elevation

A padded surface `<div>` with three elevation variants and a numeric padding control — the default
container for a panel, a form, a metric tile, or a wrapped table. Reach for it to group related
content on its own surface. Import: `import { Card } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `variant` | `"flat" \| "raised" \| "floating"` | `"flat"` | Elevation (see the enum language); `flat` is the base and emits no modifier class. |
| `padding` | `number \| string` | `20` | Inner padding, applied as inline `style.padding` (a number is px). |
| `title` | `ReactNode` | — | When present, renders a header row above `children`, left-aligned in the uppercase `.mx-card__title` label. Absent (with no `actions`) ⇒ no header (back-compat). |
| `actions` | `ReactNode` | — | Right-aligned slot in the header row (`justify-content:space-between`, plus `margin-left:auto` so it hugs the right even when `title` is absent). Renders the header even if `title` is absent. |
| `children` | `ReactNode` | — | The card content, below the optional header. |
| `className` | `string` | — | Merged onto the root `<div>` via `cx`. |
| `style` | `CSSProperties` | — | Merged after `padding` (your `style` can override it). |
| …rest | `Omit<HTMLAttributes<HTMLDivElement>, "title">` | — | `id`, `onClick`, `aria-*`, etc. pass through to the `<div>`. The native `title` (tooltip) attr is dropped so the `title` header prop can be a `ReactNode`. |

## The enum language

`variant` resolves to the `.mx-card--<variant>` token recipe — an **elevation ramp** over the surface
tokens (canon §6), `flat → raised → floating`:

- `flat` — the base surface, no shadow (no modifier class).
- `raised` — a low shadow; the standard panel.
- `floating` — a higher shadow; popovers / emphasized tiles.

Padding is a layout value, not an enum — pass px directly. Surfaces resolve to `--bg-*`/shadow tokens,
never raw hex.

## Composition

- **Composes:** its `children` — commonly a [Button](../../actions/Button/Button.prompt.md) CTA
  (auth/sign-in), a [Table](../Table/Table.prompt.md) (a `raised` card wraps the panel's table), or a
  metric/`Stat` block.
- **Composed by:** nothing — `Card` is a top-level surface, placed directly by a page or panel.

## Examples

```tsx
// A raised auth card with a Button CTA inside
<Card variant="raised" padding={32}>
  …
  <Button fullWidth size="lg" onClick={submit}>…</Button>
</Card>
// showcase/src/pages/patterns/SignInPage.tsx

// A dashboard metric tile (flat, tight padding)
<Card key={m.label} padding={18}>…</Card>
// showcase/src/pages/patterns/DashboardPage.tsx

// A raised panel wrapping a Table
<Card variant="raised">
  <Table<RailDisplay> columns={COLS} data={rows} striped getRowKey={(r) => r.id} />
</Card>
// codemojex-node/apps/economy/src/components/RailPanel.tsx

// A header row (title left, actions right) — the panel pattern the economy cards hand-roll
<Card variant="raised" title="Revenue flow / guess" actions={<Segmented … />}>
  <svg … />
</Card>
// absorbs codemojex-node/apps/economy/src/components/RevenueFlow.tsx (the
// `.ecn-card-title` + flex `justify-content:space-between` header) — see also
// MarginCurve.tsx, BalanceSimPanel, PrizePoolTable, MarginTable, RailPanel
```

## Notes

- `Card` is presentational and unopinionated about content — it spreads native `div` attrs and merges
  `className`/`style`, so `onClick` and `aria-*` reach the element.
- `padding` is applied as inline `style.padding` and a spread `style` is merged **after** it, so a
  later `style={{ padding: 0 }}` wins.
- `flat` is the default and emits no `--<variant>` modifier; pass `raised`/`floating` to opt into the
  elevation ramp.
- **Header back-compat** — the header row renders **only when** `title != null || actions != null`. A
  `<Card>` with neither prop is byte-identical to before (just `children` under the root `<div>`), so
  no existing call site changes. `actions` carries `margin-left:auto`, so it hugs the right edge even
  when `title` is absent.
