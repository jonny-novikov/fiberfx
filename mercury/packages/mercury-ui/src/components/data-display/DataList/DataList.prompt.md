# DataList — key/value pairs in a semantic description list

A `<dl>` of term/description pairs — account fields, transaction metadata, settings summaries. Reach
for it to lay out labelled values; reach for `Table` when the data is rows × columns. Import:
`import { DataList } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `DataListEntry[]` | — (required) | The pairs; each `DataListEntry` is `{ label: ReactNode; value: ReactNode }`. |
| `orientation` | `"horizontal" \| "vertical"` (`DataListOrientation`) | `"horizontal"` | `horizontal` lays the term beside the value; `vertical` stacks them. |
| `size` | `"sm" \| "md" \| "lg"` (`DataListSize`) | `"md"` | Type size (13/14/16px) and the row gap. |
| `labelWidth` | `number` | `140` | Term-column width (px) in the horizontal layout; ignored when `vertical`. |
| …rest | `HTMLAttributes<HTMLDListElement>` | — | `id`, `className`, `aria-*`, … pass through to the `<dl>`. |

## The enum language

- `orientation` resolves to `.mx-datalist--<orientation>`: `horizontal` makes each row a baseline-aligned
  flex row (term in the fixed `labelWidth` column, value taking the rest); `vertical` makes each row a
  stacked column.
- `size` resolves to `.mx-datalist--<size>` → the 13/14/16px type ramp and the 10/14/18px row gap. The
  term ink is `--fg-secondary`; the value ink is `--fg-primary`.

## Composition

- **Composes:** nothing — a leaf primitive over `DataListEntry` data.
- **Pairs with:** [Stat](../Stat/Stat.prompt.md) — Stat is one headline metric; DataList is a flat run of
  labelled fields. [Table](../Table/Table.prompt.md) — Table is rows × columns; DataList is one record's
  key/value pairs.

## Examples

```tsx
<DataList
  items={[
    { label: "Account", value: "ACME Holdings" },
    { label: "Status", value: "Active" },
    { label: "Renews", value: "30 Jun 2026" },
  ]}
/>

<DataList orientation="vertical" size="sm" items={fields} />
```

## Notes

- Renders a semantic `<dl>` with a `<dt>`/`<dd>` per pair (one wrapping `<div>` per row for layout).
- `labelWidth` is applied as a non-color dynamic inline style on the `<dt>` in the horizontal layout only;
  the value cell wraps long content (`word-break`).
- (source-grounded; no app call site — a net-new mx.7.2 import.)
