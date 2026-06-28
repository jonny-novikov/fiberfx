# Table — a column-driven data table

A generic, presentational `<table>` driven by a typed column config and a row array, with optional
zebra striping and a stable row key. Reach for it for any tabular data; cells `render` arbitrary
content, so it is the group's key composer. Import: `import { Table } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `columns` | `Column<Row>[]` | — (required) | The column config (shape below); order is render order. |
| `data` | `Row[]` | — (required) | The rows. `Row` is constrained `extends Record<string, unknown>`. |
| `striped` | `boolean` | — | Applies `mx-table--striped` (zebra rows). |
| `getRowKey` | `(row: Row, index: number) => string \| number` | — | The React row key; falls back to the row index when omitted. |

**`Column<Row>` (the cell config):**

| Field | Type | Notes |
|---|---|---|
| `key` | `string` | Column id + the `data[key]` lookup when no `render`; also the cell React key. |
| `label` | `ReactNode` | The header cell content. |
| `align` | `"left" \| "right"` | Optional; `"right"` applies `is-right` to the `<th>`/`<td>` (left is default). |
| `render` | `(row: Row) => ReactNode` | Optional cell renderer; when absent the cell shows `row[key]` cast to `ReactNode`. |

## Composition

- **Composes:** its cell `render`ers — [Tag](../Tag/Tag.prompt.md) (a status column),
  [Chip](../Chip/Chip.prompt.md), [Avatar](../Avatar/Avatar.prompt.md) (an owner/user column), and
  [Progress](../../feedback/Progress/Progress.prompt.md) (a meter column) — the data-display
  composition surface (acceptance story S-4).
- **Composed by:** [Card](../Card/Card.prompt.md) — a `raised` card wraps the panel's table.

## Examples

```tsx
// Showcase — columns render Chip / Tag / Avatar in cells
const cols = [
  { key: "name",  label: "Name",   render: (r) => <Chip variant="neutral" size="sm">…</Chip> },
  { key: "status",label: "Status", render: (r) => <Tag tone={r.status}>{statusLabel(r.status)}</Tag> },
  { key: "owner", label: "Owner",  render: (r) => <Avatar name={r.owner} size={22} /> },
];
<Table columns={cols} data={rows} striped getRowKey={(r) => r.name} />
// showcase/src/pages/components/TablePage.tsx

// Economy — typed Table with an explicit Row type + right-aligned values
const COLS: Column<MetricRow>[] = [
  { key: "metric", label: "Metric", render: (r) => r.metric },
  { key: "value",  label: "Value",  align: "right", render: (r) => r.value },
];
<Table<MetricRow> columns={COLS} data={rows} striped getRowKey={(r) => r.metric} />
// codemojex-node/apps/economy/src/components/PrizePoolTable.tsx
```

## Notes

- **Generic.** `Table<Row>` infers `Row` from `columns`/`data`; declare `Column<Row>[]` (as the
  economy panels do) for full type-checking of each `render`/`key`.
- **Always pass `getRowKey`** for stable rows — without it the key is the array index, which thrashes
  on reorder/filter. The `key` field also keys cells, so column `key`s must be unique within a table.
- `render` makes the table the **composition seam**: status cells use [Tag](../Tag/Tag.prompt.md)/
  [Chip](../Chip/Chip.prompt.md) (status families), user cells use [Avatar](../Avatar/Avatar.prompt.md),
  meter cells use [Progress](../../feedback/Progress/Progress.prompt.md) — keep tone in the token
  vocabulary by choosing the child's `tone`/`variant`, never a per-cell color.
- No `variant`/`size`/`tone` enum props of its own — only `striped` (boolean) and per-column `align`.
