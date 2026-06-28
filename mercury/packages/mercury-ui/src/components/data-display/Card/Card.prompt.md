# Card — a surface container with elevation

A padded surface `<div>` with three elevation variants and a numeric padding control — the default
container for a panel, a form, a metric tile, or a wrapped table. Reach for it to group related
content on its own surface. Import: `import { Card } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `variant` | `"flat" \| "raised" \| "floating"` | `"flat"` | Elevation (see the enum language); `flat` is the base and emits no modifier class. |
| `padding` | `number \| string` | `20` | Inner padding, applied as inline `style.padding` (a number is px). |
| `children` | `ReactNode` | — | The card content. |
| `className` | `string` | — | Merged onto the root `<div>` via `cx`. |
| `style` | `CSSProperties` | — | Merged after `padding` (your `style` can override it). |
| …rest | `HTMLAttributes<HTMLDivElement>` | — | `id`, `onClick`, `aria-*`, etc. pass through to the `<div>`. |

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
```

## Notes

- `Card` is presentational and unopinionated about content — it spreads native `div` attrs and merges
  `className`/`style`, so `onClick` and `aria-*` reach the element.
- `padding` is applied as inline `style.padding` and a spread `style` is merged **after** it, so a
  later `style={{ padding: 0 }}` wins.
- `flat` is the default and emits no `--<variant>` modifier; pass `raised`/`floating` to opt into the
  elevation ramp.
