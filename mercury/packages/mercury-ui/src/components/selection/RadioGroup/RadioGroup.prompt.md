# RadioGroup — a set of radios bound to one exclusive value

A vertical or horizontal set of [Radio](../Radio/Radio.prompt.md) controls sharing one `string`
value — exactly one choice at a time. Reach for it for a "pick one of these" decision: a payment
method, a plan tier, a sort order. Controlled or uncontrolled; an optional `accent` recolors the
checked ring. Import: `import { RadioGroup } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `{ value: string; label?: ReactNode; disabled?: boolean }[]` | — | The choices. `value` is the selected identity; `label` renders beside the dot; per-item `disabled` opts one row out. |
| `value` | `string` | — | Controlled selection. Pair with `onChange`. |
| `defaultValue` | `string` | `""` | Initial selection when uncontrolled. |
| `onChange` | `(value: string) => void` | — | Fires with the **newly-selected value**. |
| `name` | `string` | *auto* | The shared native radio `name`. Omitted, a stable `useId()` name is generated so the set stays mutually exclusive. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | — | Recolors the checked ring; omit for the default brand ring. |
| `orientation` | `"vertical" \| "horizontal"` | `"vertical"` | A stacked column or a wrapping row. |
| `disabled` | `boolean` | — | Disables every row (composes with per-item `disabled`). |

## The enum language

- **`accent`** selects a shared color family — `iris` / `indigo` / `green` / `orange` / `plum` /
  `red` — tinting the checked ring to that ramp's `--<id>-9` (and keeping the focus halo). No accent
  = the brand ring (`--bg-brand`). The composed Radio takes no `accent` prop.
- **`orientation`** is layout only: `vertical` is a `--space-8` column, `horizontal` a wrapping
  `--space-16` row.

## Composition

- **Composes:** [Radio](../Radio/Radio.prompt.md) — one per item, all sharing the group `name` so the
  native inputs are mutually exclusive. The group owns the value and hands each child its `checked` +
  an `onChange` carrying that item's value; it never forwards `accent`.
- **Peers / composed by:** [RadioCards](../RadioCards/RadioCards.prompt.md) is the card-shell variant
  of the same single-select; pair a group with a [Label](../../inputs/Label/Label.prompt.md) caption
  or nest it in a [Card](../../data-display/Card/Card.prompt.md) form section.

## Examples

```tsx
// Controlled payment method
const [method, setMethod] = useState("card");
<RadioGroup
  value={method}
  onChange={setMethod}
  items={[
    { value: "card", label: "Credit card" },
    { value: "bank", label: "Bank transfer" },
    { value: "wallet", label: "Wallet balance" },
  ]}
/>
// showcase/src/pages/components/SelectionPage.tsx

// A horizontal sort selector with an iris accent
<RadioGroup
  accent="iris"
  orientation="horizontal"
  defaultValue="newest"
  items={[
    { value: "newest", label: "Newest" },
    { value: "oldest", label: "Oldest" },
    { value: "popular", label: "Popular" },
  ]}
/>
```

## Notes

- **`onChange` carries the selected value** — wire it straight to a `useState` setter.
- **The shared `name`** is what makes native radios mutually exclusive; a generated `useId()` name
  covers the common case, and an explicit `name` integrates with a surrounding `<form>`.
- **Theming:** the accent recolors only the checked ring via the wrapper class; every family themes
  light/dark through the token flip.
