# RadioCards — an exclusive grid of card-shell radios

The card-shell variant of [RadioGroup](../RadioGroup/RadioGroup.prompt.md): each choice is a bordered
card carrying an optional icon, a title, and a description, with a [Radio](../Radio/Radio.prompt.md)
as its control — exactly one selected at a time. Reach for it for a "pick one plan" or "pick one
shipping speed" decision where each option needs a line of explanation. Import:
`import { RadioCards } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `{ value: string; label?: ReactNode; description?: ReactNode; icon?: IconName; disabled?: boolean }[]` | — | The cards. `value` is the selected identity; `label` is the title, `description` the sub-line, `icon` a leading glyph; per-item `disabled` opts one card out. |
| `value` | `string` | — | Controlled selection. Pair with `onChange`. |
| `defaultValue` | `string` | `""` | Initial selection when uncontrolled. |
| `onChange` | `(value: string) => void` | — | Fires with the **newly-selected value**. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | — | Recolors the selected card's ring + soft wash; omit for the brand ring. |
| `columns` | `number` | `1` | The grid column count (an inline `grid-template-columns` layout value). |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Scales the card padding. |

## The enum language

- **`accent`** selects a shared color family — `iris` / `indigo` / `green` / `orange` / `plum` /
  `red`. The selected card takes that ramp's `--<id>-9` ring over a `--<id>-3` soft wash; no accent =
  the brand ring over `--bg-brand-subtle`.
- **`columns`** maps to `grid-template-columns: repeat(<columns>, minmax(0, 1fr))`.
- **`size`** maps card padding: `sm` → `--space-8`, `md` → `--space-12`, `lg` → `--space-16`.

## Composition

- **Composes:** [Radio](../Radio/Radio.prompt.md) as the control — all cards share one generated
  `name` (via `useId`) so the native inputs are mutually exclusive — with an optional Icon glyph
  (`icon: IconName`) inside the card body. The card is the single-select peer of the
  [Card](../../data-display/Card/Card.prompt.md) surface.
- **Peers:** [RadioGroup](../RadioGroup/RadioGroup.prompt.md) is the compact list form of the same
  single-select.

## Examples

```tsx
// Shipping speed, one column
const [speed, setSpeed] = useState("standard");
<RadioCards
  accent="green"
  value={speed}
  onChange={setSpeed}
  items={[
    { value: "standard", label: "Standard", description: "3–5 business days.", icon: "credit-card" },
    { value: "express", label: "Express", description: "Next business day.", icon: "bolt" },
  ]}
/>
// showcase/src/pages/components/SelectionPage.tsx
```

## Notes

- **The card is a `<div>`, not a `<label>`.** The composed Radio renders the only `<label>`, and the
  card body (icon + title + description) is placed in that Radio's `label` slot — so the one native
  label toggles the input. There is no card-level click handler and no nested labels.
- **Mutual exclusivity** comes from the shared, generated radio `name`; exactly one card carries the
  selected ring.
- **Theming:** the selected ring + wash recolor via the wrapper accent class; every family themes
  light/dark through the token flip.
