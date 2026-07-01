# CheckboxGroup — a set of checkboxes bound to one array value

A vertical or horizontal set of [Checkbox](../Checkbox/Checkbox.prompt.md) controls sharing one
`string[]` value — the multi-select counterpart to a single Checkbox. Reach for it when a form asks
"pick any of these": notification channels, feature opt-ins, filter facets. Controlled or
uncontrolled; an optional `accent` recolors the checked fill. Import:
`import { CheckboxGroup } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `{ value: string; label?: ReactNode; disabled?: boolean }[]` | — | The choices. `value` is the identity toggled in/out of the array; `label` renders beside the box; per-item `disabled` opts one row out. |
| `value` | `string[]` | — | Controlled selection. Pair with `onChange`. |
| `defaultValue` | `string[]` | `[]` | Initial selection when uncontrolled. |
| `onChange` | `(value: string[]) => void` | — | Fires with the **next full array** after a toggle (not a delta). |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | — | Recolors the checked box fill; omit for the default brand fill. |
| `orientation` | `"vertical" \| "horizontal"` | `"vertical"` | A stacked column or a wrapping row. |
| `disabled` | `boolean` | — | Disables every row (composes with per-item `disabled`). |

## The enum language

- **`accent`** selects a shared color family — `iris` / `indigo` / `green` / `orange` / `plum` /
  `red` — tinting the checked fill to that ramp's `--<id>-9`. No accent = the brand fill
  (`--bg-brand`). The tint is a wrapper class; the composed Checkbox takes no `accent` prop.
- **`orientation`** is layout only: `vertical` is a `--space-8` column, `horizontal` a wrapping
  `--space-16` row.

## Composition

- **Composes:** [Checkbox](../Checkbox/Checkbox.prompt.md) — one per item. The group owns the
  selection array and hands each child its `checked` + a value-toggling `onChange`; it never forwards
  `accent` to a child (the tint belongs to the wrapper).
- **Peers / composed by:** [CheckboxCards](../CheckboxCards/CheckboxCards.prompt.md) is the
  card-shell variant of the same multi-select; pair a group with a
  [Label](../../inputs/Label/Label.prompt.md) for a fieldset caption, or place it inside a
  [Card](../../data-display/Card/Card.prompt.md) form section.

## Examples

```tsx
// Controlled notification channels
const [channels, setChannels] = useState<string[]>(["email"]);
<CheckboxGroup
  value={channels}
  onChange={setChannels}
  items={[
    { value: "email", label: "Email" },
    { value: "sms", label: "SMS" },
    { value: "push", label: "Push notifications" },
  ]}
/>
// showcase/src/pages/components/SelectionPage.tsx

// A horizontal filter row with a green accent
<CheckboxGroup
  accent="green"
  orientation="horizontal"
  defaultValue={["open"]}
  items={[
    { value: "open", label: "Open" },
    { value: "closed", label: "Closed" },
    { value: "archived", label: "Archived" },
  ]}
/>
```

## Notes

- **`onChange` carries the next full array**, not the toggled item — wire it straight to a
  `useState<string[]>` setter.
- **Controlled vs. uncontrolled:** pass `value` for controlled, rely on `defaultValue` otherwise; the
  internal state stays untouched while `value` is set.
- **Theming:** the accent recolors only the checked fill via the wrapper class; every family themes
  light/dark through the token flip.
