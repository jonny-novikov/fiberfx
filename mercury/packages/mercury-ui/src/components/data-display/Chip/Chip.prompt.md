# Chip — a compact, status-toned label pill

A small rounded pill that labels or filters — seven status tones, three sizes, an optional selected
state, an optional leading slot, and an optional remove affordance. Reach for it for tags-as-filters,
inline labels, and dismissable selections. Import: `import { Chip } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | `ReactNode` | — (required) | The pill label. |
| `variant` | `"neutral" \| "brand" \| "positive" \| "negative" \| "caution" \| "info" \| "discovery"` | `"neutral"` | Status tone (see the enum language). Exported as `ChipVariant`. |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Pill height + padding ramp (`md` is the base, no modifier class). |
| `selected` | `boolean` | — | Applies `is-selected`; the chosen state of a selectable chip. |
| `leading` | `ReactNode` | — | Element rendered before the label — a dot, an `Icon`, an avatar. |
| `onRemove` | `() => void` | — | When set, renders a trailing `×` button (`aria-label="Remove"`); its click `stopPropagation`s so it never triggers `onClick`. |
| `onClick` | `() => void` | — | When set, makes the chip selectable (`mx-chip--selectable`) and clickable. |
| `className` | `string` | — | Merged onto the root `<span>` via `cx`. |

## The enum language

`variant` resolves to the `.mx-chip--<variant>` token recipe — one per **status family** (canon §6):

- `neutral` — the `--bg-*` neutral surface; an unweighted label.
- `brand` — the brand family (`--bg-brand`); a product/plan mark.
- `positive` — the positive family; live / healthy / done.
- `negative` — the negative family; blocked / failed.
- `caution` — the caution family; pending / at-risk.
- `info` — the info family; an informational note.
- `discovery` — the discovery family; beta / experimental.

`size` → `sm | md | lg` height ramps (`md` emits no modifier). Tokens, never raw hex.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — the `close` glyph inside the `onRemove`
  button (`size={12}`, `strokeWidth={2.5}`); and any `leading` node (often a dot or an `Icon`).
- **Composed by:** [Tag](../Tag/Tag.prompt.md) (a `Tag` is a `Chip` with a `currentColor` dot),
  [Table](../Table/Table.prompt.md) cells (a `render` returning a `Chip`).

## Examples

```tsx
// Seven tones
<Chip>Neutral</Chip>
<Chip variant="brand">Pro</Chip>
<Chip variant="positive">Live</Chip>
<Chip variant="discovery">Beta</Chip>
// showcase/src/pages/components/ChipBadgePage.tsx

// Sizes
<Chip variant="brand" size="sm">…</Chip>
<Chip variant="brand" size="lg">…</Chip>
// showcase/src/pages/components/ChipBadgePage.tsx

// Removable + selectable
<Chip onRemove={() => toast.info("Removed")}>design</Chip>
<Chip selected onClick={() => {}}>…</Chip>
// showcase/src/pages/components/ChipBadgePage.tsx

// In a table cell
<Chip variant="neutral" size="sm">…</Chip>
// showcase/src/pages/components/TablePage.tsx
```

## Notes

- The root is a `<span>`, not a `<button>` — the only focusable element is the `onRemove` `×` button.
  When `onClick` is set the span becomes clickable but carries no native button semantics; provide
  keyboard handling at the call site if the chip is a primary control.
- `onRemove`'s handler calls `stopPropagation` first, so removing a selectable chip never also fires
  its `onClick`.
- Every tone maps to a **status family** (`neutral`/`brand`/`positive`/`negative`/`caution`/`info`/
  `discovery`), never a one-off color — recolor by choosing the `variant`, never a `style`.
