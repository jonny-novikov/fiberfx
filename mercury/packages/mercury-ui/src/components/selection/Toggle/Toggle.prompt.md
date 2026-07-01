# Toggle — the two-state pressable button

A single button that holds a pressed/unpressed state — a formatting toggle (bold, italic), a pinned
filter, a "show grid" switch. Reach for it when the affordance is a button (vs. a Switch's track) and
its state persists. Import: `import { Toggle } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `pressed` | `boolean` | — | Controlled pressed state. Omit for uncontrolled. |
| `defaultPressed` | `boolean` | `false` | Initial pressed state when uncontrolled. |
| `onPressedChange` | `(pressed: boolean) => void` | — | Fires with the **next** pressed boolean on click. |
| `size` | `ToggleSize` (`"sm" \| "md" \| "lg"`) | `"md"` | Height ramp (see the enum language). |
| `children` | `ReactNode` | — | The button content — a label and/or an `<Icon />`. |
| `disabled` | `boolean` | — | Native disabled. |
| …rest | `ButtonHTMLAttributes` (minus `onChange`) | — | `onClick`, `aria-*`, `className` pass through; `forwardRef` targets the `<button>`. |

`Toggle` extends `Omit<ButtonHTMLAttributes<HTMLButtonElement>, "onChange">`, so it is a real button
under the hood (`type="button"`, `aria-pressed`).

## The enum language

`size` is a dimensional ramp — height/padding, no color change (canon §6 size ramp): `sm` (32px) ·
`md` · `lg`. The on/off colors are fixed surface tokens, not an enum: idle is transparent, hover is
`--bg-hover`, the **on** (`is-on`) state fills `--bg-tertiary` with `--fg-primary` text; focus draws
the `--ring-focus` halo. (Inside a `ToggleGroup`, an on item uses `--bg-secondary`.)

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — optional, in `children` for an
  icon-only or icon+label toggle.
- **Composed by:** nothing yet — a leaf with no app call site. The co-located `ToggleGroup` (same
  module) arranges several toggles as a bordered single-/multiple-select row.
- **Peers:** [Segmented](../Segmented/Segmented.prompt.md) — the other bordered single-select row;
  reach for Segmented for a mutually-exclusive view switch, `ToggleGroup` when items may be
  multi-select or individually pressable.

## Examples

```tsx
// Uncontrolled icon toggle (source-grounded; no app call site)
<Toggle defaultPressed aria-label="Bold"><Icon name="star" size={16} /></Toggle>

// Controlled, with a label (source-grounded; no app call site)
<Toggle pressed={bold} onPressedChange={setBold}>Bold</Toggle>

// The companion group — single-select (source-grounded; no app call site)
<ToggleGroup
  type="single"
  value={align}
  onValueChange={(v) => setAlign(v as string)}
  items={[
    { value: "left", label: "Left" },
    { value: "center", label: "Center" },
    { value: "right", label: "Right" },
  ]}
/>
```

## Notes

- **(source-grounded; no app call site)** — every snippet above is constructed from the `.tsx`
  interface, not lifted from `showcase`/`economy`; `Toggle` has no usage in either app.
- **Controlled vs. uncontrolled:** pass `pressed` to control it (the parent owns state), or `defaultPressed`
  to let the component hold its own; either way `onPressedChange(next)` fires on click. `aria-pressed`
  reflects the live state, so an icon-only toggle still needs an `aria-label`.
- **`ToggleGroup` (co-located export, same module):** props `items: ToggleGroupItem[]` (each
  `{ value; label?; icon?; disabled?; ariaLabel? }`), `type` `"single"` (default) | `"multiple"`,
  `value` / `defaultValue` (`string | string[]`), `onValueChange(value)`, `size`, `accent`
  (`"iris" | "indigo" | "green" | "orange" | "plum" | "red"` — recolors each item's on-state to the
  `--<id>-3` soft fill + `--<id>-11` text), `disabled` (a group-wide flag composing with each item's
  own `disabled`), `className`. In `single` mode `onValueChange` yields the lone value; in `multiple`
  it yields the array. It is a `role="group"` of `aria-pressed` buttons — likewise no app call site.
