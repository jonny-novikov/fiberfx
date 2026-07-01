# CheckboxCards — a multi-select grid of card-shell checkboxes

The card-shell variant of [CheckboxGroup](../CheckboxGroup/CheckboxGroup.prompt.md): each choice is a
bordered card carrying an optional icon, a title, and a description, with a
[Checkbox](../Checkbox/Checkbox.prompt.md) as its control. Reach for it when choices deserve room to
explain themselves — plan add-ons, feature bundles, integrations. Multi-select, controlled or
uncontrolled. Import: `import { CheckboxCards } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `{ value: string; label?: ReactNode; description?: ReactNode; icon?: IconName; disabled?: boolean }[]` | — | The cards. `value` is the identity toggled in/out; `label` is the title, `description` the sub-line, `icon` a leading glyph; per-item `disabled` opts one card out. |
| `value` | `string[]` | — | Controlled selection. Pair with `onChange`. |
| `defaultValue` | `string[]` | `[]` | Initial selection when uncontrolled. |
| `onChange` | `(value: string[]) => void` | — | Fires with the **next full array** after a toggle. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | — | Recolors the selected card's ring + soft wash; omit for the brand ring. |
| `columns` | `number` | `1` | The grid column count (an inline `grid-template-columns` layout value). |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Scales the card padding. |

## The enum language

- **`accent`** selects a shared color family — `iris` / `indigo` / `green` / `orange` / `plum` /
  `red`. A selected card takes that ramp's `--<id>-9` ring over a `--<id>-3` soft wash; no accent =
  the brand ring over `--bg-brand-subtle`.
- **`columns`** maps to `grid-template-columns: repeat(<columns>, minmax(0, 1fr))`.
- **`size`** maps card padding: `sm` → `--space-8`, `md` → `--space-12`, `lg` → `--space-16`.

## Composition

- **Composes:** [Checkbox](../Checkbox/Checkbox.prompt.md) as the control, with an optional Icon glyph
  (`icon: IconName`) inside the card body. The card is the multi-select peer of the
  [Card](../../data-display/Card/Card.prompt.md) surface.
- **Peers:** [CheckboxGroup](../CheckboxGroup/CheckboxGroup.prompt.md) is the compact list form of the
  same multi-select.

## Examples

```tsx
// Plan add-ons, two columns
const [addons, setAddons] = useState<string[]>(["analytics"]);
<CheckboxCards
  columns={2}
  accent="indigo"
  value={addons}
  onChange={setAddons}
  items={[
    { value: "analytics", label: "Analytics", description: "Dashboards and export.", icon: "trending-up" },
    { value: "support", label: "Priority support", description: "Same-day replies.", icon: "bolt" },
  ]}
/>
// showcase/src/pages/components/SelectionPage.tsx
```

## Notes

- **The card is a `<div>`, not a `<label>`.** The composed Checkbox renders the only `<label>`, and
  the card body (icon + title + description) is placed in that Checkbox's `label` slot — so the one
  native label toggles the input. There is no card-level click handler and no nested labels.
- **`onChange` carries the next full array**, not the toggled card.
- **Theming:** the selected ring + wash recolor via the wrapper accent class; every family themes
  light/dark through the token flip.
