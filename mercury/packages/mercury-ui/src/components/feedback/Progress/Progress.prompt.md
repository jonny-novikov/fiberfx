# Progress — a determinate / indeterminate progress bar

A token-colored horizontal bar in three heights, fillable to a percentage or run as an indeterminate
shimmer. Reach for it for a completion meter — an upload, a task row, a password-strength track. Import:
`import { Progress } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `number` | `0` | Current progress; clamped to `0…max` then to 0–100%. |
| `max` | `number` | `100` | Denominator for the percentage. |
| `variant` | `ProgressVariant` | `"brand"` | Bar color (see the enum language). |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Track height. |
| `indeterminate` | `boolean` | `false` | Runs an animated shimmer; drops `aria-valuenow`. |

`ProgressVariant` = `"brand" \| "positive" \| "negative" \| "caution" \| "info"`.

The component takes **no `…rest`** and is **not** `forwardRef`.

## The enum language

`variant` resolves to a `.mx-pr--<variant>` recipe over the **status families** (canon §6, the
`Badge`/`Progress` set `brand | negative | positive | caution | info`):

- `brand` — the `brand` / iris accent (the default — neutral progress).
- `positive` — the `positive` family (success / healthy).
- `negative` — the `negative` family (failing / over budget).
- `caution` — the `caution` family (a watch threshold).
- `info` — the `info` family.

`size` → `sm | md | lg` track-height ramps (`sm` is the strength-meter height).

## Composition

- **Composes:** nothing — a leaf. It renders its own track + bar and embeds no other Mercury component.
- **Composed by:** [PasswordStrength](../PasswordStrength/PasswordStrength.prompt.md) — which renders a
  `size="sm"` Progress as its strength track; also dashboard task rows. *(Sibling contracts authored
  across mx.2; links resolve at set completion.)*

## Examples

```tsx
// Sizes
<Progress value={60} size="sm" />
<Progress value={60} size="md" />
<Progress value={60} size="lg" />
// Variants
<Progress value={progress} variant="brand" />
<Progress value={progress} variant="positive" />
<Progress value={progress} variant="caution" />
<Progress value={progress} variant="negative" />
// showcase/src/pages/components/ProgressPage.tsx

// Per-row, variant switched on status
<Progress size="sm" value={r.progress} variant={r.status === "caution" ? "caution" : "brand"} />
// showcase/src/pages/patterns/DashboardPage.tsx
```

## Notes

- **`value` is clamped** — `(value / max) * 100` is bounded to 0–100, so an out-of-range value can't
  overflow the track.
- **Indeterminate** drops `aria-valuenow` (the position is unknown) and ignores `value`; use it only
  when you genuinely can't measure progress.
- Accessibility: it renders `role="progressbar"` with `aria-valuemin/now/max` — no extra label needed
  on the bar itself, but pair it with a visible caption for the metric it tracks.
- Status-family map: `brand → brand/iris` · `positive → positive` · `negative → negative` ·
  `caution → caution` · `info → info`.
