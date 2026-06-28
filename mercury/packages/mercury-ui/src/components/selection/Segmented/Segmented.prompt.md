# Segmented — the inline single-select switch

A pill of side-by-side options where exactly one is active — a compact alternative to a Radio group or a
`Select` when there are few choices. Reach for it for a view toggle (theme, date range, channel).
Generic over the value union: `Segmented<T>`. Import: `import { Segmented } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `segments` | `Segment<T>[]` | — (required) | The options: `{ label: string; value: T; disabled?: boolean }`. |
| `value` | `T` | — (required) | The active segment's value. |
| `onChange` | `(value: T) => void` | — | Fires with the **clicked segment's value** (skipped for a `disabled` segment). |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Padding/font ramp (see the enum language). |
| `fullWidth` | `boolean` | `false` | Stretch to the container, segments share width equally (`is-full`). |

`Segment<T>` carries an optional per-option `disabled`. The component does **not** `forwardRef` and
passes through only the props above (no `…rest`).

## The enum language

`size` is a dimensional ramp — padding + font-size, no color change (canon §6 size ramp):

- `sm` — `5px 10px`, 12px text; a dense toolbar/panel switch.
- `md` — `7px 14px`; the default.
- `lg` — `9px 18px`, 14px text.

The colors are fixed surface tokens, not an enum: the container is `--bg-tertiary`, the **active**
segment lifts to `--bg-primary` with `--shadow-100`, idle labels are `--fg-secondary` (→ `--fg-primary`
on hover/active). Focus draws the `--ring-focus` outline.

## Composition

- **Composes:** nothing — a leaf (segments are native `<button>`s, not sibling components).
- **Composed by:** [Card](../../data-display/Card/Card.prompt.md) (a panel's view switch, e.g. the
  economy `RevenueFlow` / `RailPanel` / `CalibrationForm`); also the showcase chrome (the `Topbar`
  theme switch). *(Sibling contract authored across mx.2; link resolves at set completion.)*

## Examples

```tsx
// Date-range switch
<Segmented<string>
  segments={[
    { label: "Day", value: "day" },
    { label: "Week", value: "week" },
    { label: "Month", value: "month" },
    { label: "Year", value: "year" },
  ]}
  value={period}
  onChange={setPeriod}
/>
// showcase/src/pages/components/SelectionPage.tsx

// Theme toggle (typed to the Theme union)
<Segmented<Theme>
  segments={[{ label: "Light", value: "light" }, { label: "Dark", value: "dark" }]}
  value={theme}
  onChange={setTheme}
/>
// showcase/src/chrome/Topbar.tsx

// Dense, full-width pay-rail switch
<Segmented<RailId> value={rail} onChange={setRail} fullWidth size="sm"
  segments={RAILS.map((r) => ({ label: r.label, value: r.id }))} />
// codemojex-node/apps/economy/src/components/RailPanel.tsx
```

## Notes

- **Type it** — pass the value union as `Segmented<T>` so `value`, each segment's `value`, and the
  `onChange` arg are checked together.
- **Controlled only** — there is no internal state; the parent holds `value` and updates it from
  `onChange`.
- **a11y:** the container is `role="radiogroup"`, each button `role="radio"` with `aria-checked`; a
  per-segment `disabled` skips both the click and `onChange`.
