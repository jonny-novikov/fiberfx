# Tag — a dotted status label

A thin wrapper over [Chip](../Chip/Chip.prompt.md): a status-toned label that prepends a small
`currentColor` dot by default. Reach for it for inline status in tables and flows where a leading
status dot reads cleaner than a filled pill. Import: `import { Tag } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | `ReactNode` | — (required) | The label. |
| `tone` | `ChipVariant` (`"neutral" \| "brand" \| "positive" \| "negative" \| "caution" \| "info" \| "discovery"`) | `"neutral"` | The status tone — passed straight through as the `Chip` `variant`. |
| `dot` | `boolean` | `true` | Renders the 6px leading dot (`background: currentColor`); set `false` to drop it. |
| `size` | `"sm" \| "md" \| "lg"` | `"sm"` | The `Chip` size — note the default is `sm`, denser than `Chip`'s `md`. |

`Tag` has no `className`/`onClick`/`onRemove` of its own — it composes `Chip` with a fixed `leading`
dot; reach for `Chip` directly when you need those.

## The enum language

`tone` is the `ChipVariant` union — it resolves to the same `.mx-chip--<tone>` **status families**
(canon §6): `neutral` · `brand` (`--bg-brand`) · `positive` · `negative` · `caution` · `info` ·
`discovery`. The dot inherits the resolved tone via `currentColor`, so it always matches the label.
Tokens, never raw hex.

## Composition

- **Composes:** [Chip](../Chip/Chip.prompt.md) — `Tag` *is* a `Chip` with `variant={tone}` and a
  `currentColor` dot in the `leading` slot.
- **Composed by:** [Table](../Table/Table.prompt.md) cells (a `render` returning a `Tag` for a status
  column).

## Examples

```tsx
// Dotless tags in a revenue flow
<Tag tone="info" dot={false}>…</Tag>
<Tag tone={g.marginNegative ? "negative" : "positive"} dot={false}>…</Tag>
// codemojex-node/apps/economy/src/components/RevenueFlow.tsx

// A status cell renderer (dot on)
{ key: "status", label: "Status",
  render: (r) => <Tag tone={r.status}>{statusLabel(r.status)}</Tag> }
// showcase/src/pages/components/TablePage.tsx
```

## Notes

- `dot` defaults **on** and `size` defaults to **`sm`** — the opposite density from a bare `Chip`.
  In dense tables/flows the call sites typically pass `dot={false}` for a flat label.
- A `tone` is a **status family** (`neutral`/`brand`/`positive`/`negative`/`caution`/`info`/
  `discovery`), so a status driven by data (`marginNegative ? "negative" : "positive"`) stays inside
  the token vocabulary — never a hard-coded color.
- Inherits `Chip`'s root `<span>` semantics; it is a label, not a control.
