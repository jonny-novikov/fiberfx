# Spinner — an indeterminate loading indicator

A token-coloured ring on a continuous 360°/1s spin, for an operation with no measurable progress.
Reach for it for a button-local or inline busy state; reach for `Progress` when completion is
measurable, `Skeleton` when holding the shape of content that is loading. Import:
`import { Spinner } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `size` | `"sm" \| "md" \| "lg"` (`SpinnerSize`) \| `number` | `"md"` | Named size (16/20/24px) or an explicit pixel diameter. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` (`SpinnerAccent`) | — | Arc colour from a ramp (`--<ramp>-9`). Omit to inherit `currentColor`. |
| `label` | `string` | `"Loading"` | Accessible name (`aria-label`) announced for `role="status"`. |
| …rest | `HTMLAttributes<HTMLSpanElement>` | — | `id`, `className`, `style`, `aria-*`, … pass through to the root `<span>`. |

## The enum language

- `size` (when named) resolves to `.mx-spinner--<size>` → the 16/20/24px diameters with a matching
  border width. A numeric `size` sets the diameter (and a proportional border width) as a non-color
  inline style.
- `accent` resolves to `.mx-spinner--accent-<id>` → the arc takes `--<ramp>-9`; the track stays
  `--border-secondary`. With no `accent` the arc is `currentColor` (inherits the surrounding ink).

## Composition

- **Composes:** nothing — a leaf indicator.
- **Pairs with:** [Skeleton](../Skeleton/Skeleton.prompt.md) — Spinner for a busy spot, Skeleton for a
  content placeholder that holds layout. Used by `Button` as its `loading` indicator (the arc inherits
  the button ink via `currentColor`).

## Examples

```tsx
<Spinner />

<Spinner size="lg" accent="iris" label="Loading courses" />

<Spinner size={48} />
```

## Notes

- `role="status"` + `aria-label` announce the busy state; the default label is `Loading` — override it
  with context (`label="Loading courses"`).
- Honours `prefers-reduced-motion`: the spin slows rather than stopping outright, so the busy state stays
  legible.
- (source-grounded; no app call site — a net-new mx.7.2 import.)
