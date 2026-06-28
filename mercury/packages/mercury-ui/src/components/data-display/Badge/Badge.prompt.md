# Badge — a count / status marker

A tiny status-toned marker for a count or a one-word state — denser than a `Chip`, no remove or
selection affordance. Reach for it for notification counts, list-row states, and inline status pips.
Import: `import { Badge } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | `ReactNode` | — (required) | The count or short label. |
| `variant` | `"brand" \| "negative" \| "positive" \| "caution" \| "info"` | `"negative"` | Status tone (see the enum language). Exported as `BadgeVariant`. **Note the default is `negative`** (the count-alert case). |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Size ramp (`md` is the base, no modifier class). |

## The enum language

`variant` resolves to the `.mx-badge--<variant>` token recipe — one per **status family** (canon §6):

- `brand` — the brand family (`--bg-brand`); a "new" marker.
- `negative` — the negative family; an alert count (the default).
- `positive` — the positive family; done / healthy.
- `caution` — the caution family; a warning count.
- `info` — the info family; an informational pip.

Badge's tone set is the **five-family subset** of the status palette — it has no `neutral` or
`discovery` (that wider set lives on [Chip](../Chip/Chip.prompt.md)/[Tag](../Tag/Tag.prompt.md)).
Tokens, never raw hex.

## Composition

- **Composes:** nothing — a leaf.
- **Composed by:** nothing in the set yet — `Badge` is placed directly on nav rows, list items, and
  dashboards as a count/status pip.

## Examples

```tsx
// The five tones
<Badge variant="negative">3</Badge>
<Badge variant="caution">12</Badge>
<Badge variant="positive">Done</Badge>
<Badge variant="brand">New</Badge>
<Badge variant="info">i</Badge>
// showcase/src/pages/components/ChipBadgePage.tsx
```

## Notes

- The default `variant` is **`negative`** — `<Badge>3</Badge>` renders the alert tone unset, matching
  the common notification-count case; pass an explicit `variant` for any other state.
- No interaction surface (no `onClick`/`onRemove`/`selected`): a `Badge` is a marker, not a control.
  For a removable or selectable pill, reach for [Chip](../Chip/Chip.prompt.md).
- Every tone is a **status family** (`brand`/`negative`/`positive`/`caution`/`info`) — recolor by
  `variant`, never a `style`.
